extends RefCounted
## V142 : le kit de l'Île des Géants — les matières et les grandes constructions, à l'échelle des
## géants (7,5 fois la nôtre) : la maison des Grandpré (moellons, chaînes d'angle en pierre de taille,
## tuiles, fenêtres à petits carreaux, volets, jardinières de géraniums, la porte et sa chatière), la
## grange (planches, chaume, foin), le moulin de la butte (ses ailes tournent), le puits, la clôture du
## potager (on se glisse entre les piquets), la corde à linge, les objets oubliés dehors (la brouette,
## l'arrosoir, le seau, les bottes, le râteau, le fauteuil à bascule de Grand-mère), les murets de
## pierres sèches, les balles de foin, l'épouvantail.
## Tout est fusionné par matière (Batch) ; les collisions sont des boîtes et des cylindres simples.

const Ile = preload("res://scripts/ile_geants_v142.gd")
const MJ := "res://assets/textures/montjoie/"
const TX := "res://assets/textures/geants/"
static var _cache: Dictionary = {}


static func _t(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Une surface texturée ; « tile » : la taille (m) d'un motif de la texture
static func _surface(tex: String, normal: String, tint: Color, rough: float, tile: float, nscale: float = 1.0, base := Color(0.7, 0.68, 0.64)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t: Texture2D = _t(tex)
	m.albedo_texture = t
	m.albedo_color = tint if t != null else Color(base.r * tint.r, base.g * tint.g, base.b * tint.b)
	var n: Texture2D = _t(normal) if normal != "" else null
	if n != null:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = nscale
	m.roughness = rough
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func _flat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func mat(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var m: Material = null
	match key:
		"moellons":
			m = _surface(MJ + "moellons.png", MJ + "moellons_n.png", Color(1.0, 0.97, 0.92), 0.9, 15.0, 1.2, Color(0.62, 0.58, 0.52))
		"pierre":
			m = _surface(MJ + "pierre_rempart.png", MJ + "pierre_rempart_n.png", Color(1.08, 1.04, 0.96), 0.86, 12.0, 1.0, Color(0.74, 0.7, 0.62))
		"enduit":
			m = _surface(MJ + "enduit.png", MJ + "enduit_n.png", Color(1.02, 0.98, 0.9), 0.93, 14.0, 0.8, Color(0.9, 0.86, 0.78))
		"tuiles":
			m = _surface(MJ + "tuiles.png", MJ + "tuiles_n.png", Color(1.0, 0.9, 0.84), 0.8, 14.0, 1.3, Color(0.66, 0.3, 0.2))
		"chaume":
			m = _surface(MJ + "chaume.png", MJ + "chaume_n.png", Color(1.0, 0.96, 0.86), 0.96, 12.0, 1.3, Color(0.62, 0.5, 0.3))
		"planches":
			m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.96, 0.9, 0.82), 0.84, 9.0, 1.0, Color(0.55, 0.4, 0.28))
		"planches_rouges":
			# la grange peinte en rouge sang-de-bœuf (la peinture s'écaille)
			m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(1.25, 0.52, 0.42), 0.82, 9.0, 1.0, Color(0.55, 0.2, 0.15))
		"bois_vert":
			m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.55, 0.92, 0.68), 0.7, 7.0, 0.8, Color(0.2, 0.42, 0.28))
		"bois_clair":
			m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(1.3, 1.16, 0.96), 0.78, 6.0, 0.8, Color(0.7, 0.56, 0.4))
		"poutre":
			m = _surface(MJ + "bois_planches.png", MJ + "bois_planches_n.png", Color(0.62, 0.48, 0.38), 0.86, 7.0, 0.9, Color(0.4, 0.3, 0.22))
		"blanc":
			m = _flat(Color(0.92, 0.9, 0.86), 0.6)
		"vitre":
			var vf: StandardMaterial3D = _surface(MJ + "fenetre_plomb.png", "", Color(0.62, 0.68, 0.74), 0.14, 1.0)
			vf.uv1_scale = Vector3.ONE
			vf.metallic_specular = 0.9
			m = vf
		"vitre_on":
			# une fenêtre éclairée de l'intérieur (elle s'allume à la nuit : temps_v56)
			var vo: StandardMaterial3D = _surface(MJ + "fenetre_plomb.png", "", Color(1, 1, 1), 0.18, 1.0)
			vo.uv1_scale = Vector3.ONE
			vo.emission_enabled = true
			var nt: Texture2D = _t(MJ + "fenetre_plomb_nuit.png")
			vo.emission_texture = nt if nt != null else vo.albedo_texture
			vo.emission = Color(1.0, 0.78, 0.45)
			vo.emission_energy_multiplier = 0.05
			m = vo
		"fer":
			m = _flat(Color(0.12, 0.12, 0.13), 0.42, 0.75)
		"zinc":
			m = _flat(Color(0.62, 0.65, 0.68), 0.36, 0.85)
		"cuivre":
			m = _flat(Color(0.8, 0.5, 0.3), 0.3, 0.9)
		"caoutchouc":
			m = _flat(Color(0.2, 0.34, 0.18), 0.55)
		"rouge":
			m = _flat(Color(0.7, 0.12, 0.1), 0.6)
		"foin":
			m = _surface(MJ + "chaume.png", MJ + "chaume_n.png", Color(1.25, 1.15, 0.78), 0.97, 8.0, 1.4, Color(0.82, 0.68, 0.36))
		"foin_bout":
			m = _flat(Color(0.8, 0.68, 0.38), 0.97)
		"toile":
			var tl := _flat(Color(0.92, 0.88, 0.78), 0.92)
			tl.cull_mode = BaseMaterial3D.CULL_DISABLED
			m = tl
		"corde":
			m = _flat(Color(0.62, 0.52, 0.36), 0.95)
		"terre_cuite":
			m = _flat(Color(0.72, 0.38, 0.24), 0.86)
		"geranium":
			m = _flat(Color(0.86, 0.1, 0.12), 0.7)
		"geranium_rose":
			m = _flat(Color(0.95, 0.42, 0.62), 0.7)
		"feuille":
			m = _flat(Color(0.18, 0.38, 0.12), 0.8)
		"roche":
			m = _surface(MJ + "roche_crocs.png", MJ + "roche_crocs_n.png", Color(1.06, 1.04, 1.0), 0.92, 6.0, 1.2, Color(0.56, 0.52, 0.46))
		"dalles":
			m = _surface(MJ + "dalles.png", MJ + "dalles_n.png", Color(1.0, 0.98, 0.94), 0.8, 12.0, 0.9, Color(0.74, 0.72, 0.66))
		"sombre":
			m = _flat(Color(0.05, 0.045, 0.04), 1.0)
		"paille":
			m = _surface(MJ + "chaume.png", MJ + "chaume_n.png", Color(1.3, 1.18, 0.8), 0.95, 3.0, 1.0, Color(0.86, 0.74, 0.46))
		"veste":
			m = _flat(Color(0.3, 0.3, 0.42), 0.95)
		"citrouille_tete":
			m = _flat(Color(0.95, 0.5, 0.1), 0.7)
		"sable":
			m = _surface(MJ + "sable_lac.png", MJ + "sable_lac_n.png", Color(1.08, 1.04, 0.94), 0.95, 5.0, 1.2, Color(0.82, 0.74, 0.58))
		"sable_mouille":
			m = _surface(MJ + "sable_lac.png", MJ + "sable_lac_n.png", Color(0.82, 0.76, 0.64), 0.7, 5.0, 1.2, Color(0.62, 0.56, 0.44))
		"jouet_rouge":
			m = _flat(Color(0.86, 0.12, 0.1), 0.32)
		"jouet_jaune":
			m = _flat(Color(0.98, 0.78, 0.12), 0.32)
		"linge_blanc", "linge_bleu", "linge_jaune", "linge_rouge", "linge_raye", "linge_vert":
			var col: Color = {"linge_blanc": Color(0.95, 0.94, 0.9), "linge_bleu": Color(0.4, 0.56, 0.8), "linge_jaune": Color(0.98, 0.8, 0.22),
				"linge_rouge": Color(0.78, 0.16, 0.14), "linge_raye": Color(0.92, 0.9, 0.86), "linge_vert": Color(0.42, 0.6, 0.38)}[key]
			var lm := ShaderMaterial.new()
			lm.shader = load("res://shaders/linge_v142.gdshader")
			lm.set_shader_parameter("couleur", col)
			lm.set_shader_parameter("rayures", 1.0 if key == "linge_raye" else 0.0)
			m = lm
	if m == null:
		m = _flat(Color(1, 0, 1), 0.5)
	_cache[key] = m
	return m


# =================================================================== le lot de maillages

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

	## Une boîte (UV en mètres, le long des faces)
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
					var lp: Vector3 = c0 + u * cc.x * hu + v * cc.y * hv
					pts.append(xf * lp)
					# UV en coordonnées « du monde » de la face : les motifs se raccordent d'une boîte à l'autre
					var wp: Vector3 = xf * lp
					var wn: Vector3 = (xf.basis * n).normalized()
					if absf(wn.y) > 0.7:
						uvs.append(Vector2(wp.x, wp.z))
					elif absf(wn.x) > absf(wn.z):
						uvs.append(Vector2(wp.z, -wp.y))
					else:
						uvs.append(Vector2(wp.x, -wp.y))
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
			var uv := [Vector2(circ * i / sides, 0), Vector2(circ * (i + 1) / sides, 0), Vector2(circ * (i + 1) / sides, -h), Vector2(circ * i / sides, -h)]
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

	## Un cylindre (ou un cône) de a à b
	func tube(key: String, a: Vector3, b: Vector3, r: float, sides: int = 8, r_end: float = -1.0, caps: bool = false) -> void:
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.001:
			return
		var y: Vector3 = d / l
		var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
		var z: Vector3 = x.cross(y)
		cyl(key, Transform3D(Basis(x, y, z), a), r, r if r_end < 0.0 else r_end, l, sides, caps)

	## Une sphère déformée (ellipsoïde)
	func blob(key: String, c: Vector3, r: Vector3, seg: int = 8, bs: Basis = Basis()) -> void:
		var half: int = int(seg / 2.0)
		for j in range(half):
			var t0: float = PI * j / half
			var t1: float = PI * (j + 1) / half
			for i in range(seg):
				var a0: float = TAU * i / seg
				var a1: float = TAU * (i + 1) / seg
				var q := []
				var nn := []
				var uv := []
				for tc in [[t0, a0], [t0, a1], [t1, a1], [t1, a0]]:
					var dd := Vector3(sin(tc[0]) * cos(tc[1]), cos(tc[0]), sin(tc[0]) * sin(tc[1]))
					q.append(c + bs * (dd * r))
					nn.append((bs * (dd / r)).normalized())
					uv.append(Vector2(float(tc[1]) / TAU * 2.0 * PI * maxf(r.x, r.z), float(tc[0]) * r.y))
				tri(key, [q[0], q[1], q[2]], [nn[0], nn[1], nn[2]], [uv[0], uv[1], uv[2]])
				tri(key, [q[0], q[2], q[3]], [nn[0], nn[2], nn[3]], [uv[0], uv[2], uv[3]])

	## Un prisme triangulaire (pignon, toit) : base (a, b) au sol du pignon, sommet c, épaisseur le long de « ep »
	func prism(key: String, a: Vector3, b: Vector3, c: Vector3, ep: Vector3) -> void:
		var n: Vector3 = (b - a).cross(c - a).normalized()
		if n.dot(ep) > 0.0:
			n = -n
		var e: Vector3 = ep
		var uvf := func(p: Vector3) -> Vector2:
			return Vector2(p.x + p.z, -p.y)
		tri(key, [a, b, c], [n, n, n], [uvf.call(a), uvf.call(b), uvf.call(c)])
		tri(key, [a + e, b + e, c + e], [-n, -n, -n], [uvf.call(a), uvf.call(b), uvf.call(c)])
		for pair in [[a, b], [b, c], [c, a]]:
			var p0: Vector3 = pair[0]
			var p1: Vector3 = pair[1]
			var sn: Vector3 = (p1 - p0).cross(e).normalized()
			var mid: Vector3 = (a + b + c) / 3.0
			if sn.dot((p0 + p1) * 0.5 - mid) < 0.0:
				sn = -sn
			quad(key, [p0, p1, p1 + e, p0 + e], sn, [uvf.call(p0), uvf.call(p1), uvf.call(p1) + Vector2(e.length(), 0), uvf.call(p0) + Vector2(e.length(), 0)])

	func commit(parent: Node3D, label: String, shadows: bool = true, vis_end: float = 0.0) -> MeshInstance3D:
		if sts.is_empty():
			return null
		var mesh := ArrayMesh.new()
		for k in sts:
			var st: SurfaceTool = sts[k]
			st.index()
			st.generate_tangents()
			st.commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, load("res://scripts/geants_kit_v142.gd").mat(str(k)))
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if vis_end > 0.0:
			mi.visibility_range_end = vis_end
			mi.visibility_range_end_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mi)
		sts.clear()
		return mi


# =================================================================== les collisions

class Cols:
	var body: StaticBody3D

	func _init(parent: Node3D, label: String) -> void:
		body = StaticBody3D.new()
		body.name = label
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)

	func box(xf: Transform3D, size: Vector3) -> void:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.transform = xf
		body.add_child(cs)

	func box_at(at: Vector3, size: Vector3, yaw: float = 0.0) -> void:
		box(Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * size.y * 0.5), size)

	func cyl(at: Vector3, r: float, h: float) -> void:
		var cs := CollisionShape3D.new()
		var c := CylinderShape3D.new()
		c.radius = r
		c.height = h
		cs.shape = c
		cs.position = at + Vector3.UP * h * 0.5
		body.add_child(cs)

	func cyl_xf(xf: Transform3D, r: float, h: float) -> void:
		var cs := CollisionShape3D.new()
		var c := CylinderShape3D.new()
		c.radius = r
		c.height = h
		cs.shape = c
		cs.transform = xf
		body.add_child(cs)


# =================================================================== la maison des Grandpré

## La maison : rez-de-chaussée en moellons, chaînes d'angle et encadrements en pierre de taille, le
## grand toit de tuiles (le faîtage est-ouest), la cheminée ; la porte au nord. Rend les repères utiles
## (le seuil, le haut de la cheminée, les fenêtres éclairées).
static func maison(b: Batch, cols: Cols, y0: float) -> Dictionary:
	var c: Vector3 = Ile.W(Ile.MAISON.x, Ile.MAISON.y, y0)
	var hx: float = Ile.MAISON_H.x
	var hz: float = Ile.MAISON_H.y
	var eaves: float = 34.0
	var ep: float = 3.6
	# le soubassement (un peu plus large, en pierre de taille)
	b.box_at("pierre", c + Vector3(0, -2.0, 0), Vector3(hx * 2.0 + 1.6, 3.6, hz * 2.0 + 1.6))
	# les quatre murs
	b.box_at("moellons", c + Vector3(0, 0, -hz + ep * 0.5), Vector3(hx * 2.0, eaves, ep))
	b.box_at("moellons", c + Vector3(0, 0, hz - ep * 0.5), Vector3(hx * 2.0, eaves, ep))
	b.box_at("moellons", c + Vector3(-hx + ep * 0.5, 0, 0), Vector3(ep, eaves, hz * 2.0 - ep * 2.0))
	b.box_at("moellons", c + Vector3(hx - ep * 0.5, 0, 0), Vector3(ep, eaves, hz * 2.0 - ep * 2.0))
	# l'intérieur (sombre, pour qu'on ne voie pas de vide par un interstice)
	b.box_at("sombre", c + Vector3(0, 0.2, 0), Vector3(hx * 2.0 - ep * 2.0, eaves - 0.4, hz * 2.0 - ep * 2.0))
	cols.box_at(c + Vector3(0, -1.0, 0), Vector3(hx * 2.0 + 1.6, eaves + 1.0, hz * 2.0 + 1.6))
	# les chaînes d'angle : de grosses pierres alternées
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var k: int = 0
			var y: float = 0.0
			while y < eaves - 1.0:
				var h: float = 3.2
				var long: float = 6.0 if k % 2 == 0 else 3.6
				var corner := c + Vector3(sx * hx, y, sz * hz)
				b.box_at("pierre", corner + Vector3(-sx * long * 0.5 + sx * 0.25, 0, -sz * 1.4 + sz * 0.25), Vector3(long, h - 0.15, 2.8 + 0.5))
				b.box_at("pierre", corner + Vector3(-sx * 1.4 + sx * 0.25, 0, -sz * (6.0 if k % 2 == 1 else 3.6) * 0.5 + sz * 0.25), Vector3(2.8 + 0.5, h - 0.15, (6.0 if k % 2 == 1 else 3.6)))
				y += h
				k += 1
	# le bandeau de pierre sous le toit
	b.box_at("pierre", c + Vector3(0, eaves - 1.6, -hz - 0.3), Vector3(hx * 2.0 + 1.2, 1.6, 1.2))
	b.box_at("pierre", c + Vector3(0, eaves - 1.6, hz + 0.3), Vector3(hx * 2.0 + 1.2, 1.6, 1.2))
	# le toit : deux pans de tuiles, les pignons est et ouest en moellons
	var over: float = 4.0
	var rise: float = 26.0
	var top: Vector3 = c + Vector3(0, eaves + rise, 0)
	for sz2 in [-1.0, 1.0]:
		var e0: Vector3 = c + Vector3(0, eaves - 1.2, sz2 * (hz + over))
		var slope: Vector3 = top - e0
		var lng: float = slope.length()
		var mid: Vector3 = (e0 + top) * 0.5
		var ang: float = atan2(slope.y, absf(slope.z))
		var bs: Basis = Basis(Vector3.RIGHT, -ang * sz2)
		b.box("tuiles", Transform3D(bs, mid + bs * Vector3(0, 0.8, 0)), Vector3(hx * 2.0 + over * 2.0, 1.6, lng))
		cols.box(Transform3D(bs, mid + bs * Vector3(0, 0.8, 0)), Vector3(hx * 2.0 + over * 2.0, 1.6, lng))
	b.box("tuiles", Transform3D(Basis(), top + Vector3(0, 0.9, 0)), Vector3(hx * 2.0 + over * 2.0 + 0.4, 1.4, 2.6))
	for sx2 in [-1.0, 1.0]:
		var x: float = c.x + sx2 * (hx - 0.1)
		b.prism("moellons", Vector3(x, c.y + eaves, c.z - hz), Vector3(x, c.y + eaves, c.z + hz), Vector3(x, c.y + eaves + rise - 1.0, c.z), Vector3(-sx2 * ep, 0, 0))
	# la cheminée (côté est), de pierre, avec son chapeau
	var ch: Vector3 = c + Vector3(hx * 0.55, 0, 6.0)
	var ch_top: float = eaves + rise + 14.0
	b.box_at("pierre", Vector3(ch.x, c.y + eaves + 6.0, ch.z), Vector3(8.0, ch_top - eaves - 6.0, 6.5))
	b.box_at("pierre", Vector3(ch.x, c.y + ch_top - 0.5, ch.z), Vector3(9.4, 1.6, 7.8))
	b.box_at("sombre", Vector3(ch.x, c.y + ch_top + 1.0, ch.z), Vector3(5.2, 0.3, 3.6))
	# les fenêtres : façade nord (deux de chaque côté de la porte), façade sud (quatre), pignons (une)
	var lit: Array = []
	for fx in [-31.0, -16.0, 16.0, 31.0]:
		lit.append(fenetre(b, c + Vector3(fx, 6.8, -hz - 0.2), Vector3(0, 0, -1), 8.0, 10.5, fx in [-16.0, 31.0]))
		lit.append(fenetre(b, c + Vector3(fx, 6.8, hz + 0.2), Vector3(0, 0, 1), 8.0, 10.5, fx in [-31.0, 16.0]))
	for fx2 in [-24.0, 0.0, 24.0]:
		lit.append(fenetre(b, c + Vector3(fx2, 21.5, -hz - 0.2), Vector3(0, 0, -1), 6.8, 8.0, fx2 == 0.0))
	for sx3 in [-1.0, 1.0]:
		lit.append(fenetre(b, c + Vector3(sx3 * (hx + 0.2), 6.8, -6.0), Vector3(sx3, 0, 0), 8.0, 10.5, sx3 > 0.0))
		# l'œil-de-bœuf du grenier
		var ob: Vector3 = c + Vector3(sx3 * (hx + 0.3), eaves + 9.0, 0)
		b.cyl("pierre", Transform3D(Basis(Vector3.FORWARD, PI * 0.5 * sx3), ob), 3.4, 3.4, 0.9, 16)
		b.cyl("vitre", Transform3D(Basis(Vector3.FORWARD, PI * 0.5 * sx3), ob + Vector3(sx3 * 0.2, 0, 0)), 2.6, 2.6, 0.9, 16)
	# la porte (au nord) : l'encadrement de pierre, les planches vertes, le heurtoir, la chatière
	var door: Vector3 = c + Vector3(0, 0, -hz - 0.4)
	b.box_at("pierre", door + Vector3(-5.2, 0, 0), Vector3(2.4, 18.6, 1.6))
	b.box_at("pierre", door + Vector3(5.2, 0, 0), Vector3(2.4, 18.6, 1.6))
	b.box_at("pierre", door + Vector3(0, 17.2, 0), Vector3(12.8, 2.4, 1.8))
	b.box_at("bois_vert", door + Vector3(0, 0, 0.5), Vector3(8.0, 17.2, 1.0))
	for yb in [3.0, 9.0, 14.0]:
		b.box_at("fer", door + Vector3(-1.0, yb, -0.05), Vector3(6.4, 0.5, 0.3))
	b.tube("fer", door + Vector3(0, 9.4, -0.3), door + Vector3(0, 9.4, -0.9), 0.35, 6)
	# le heurtoir (un anneau de fer)
	for k2 in range(12):
		var a0: float = TAU * k2 / 12.0
		var a1: float = TAU * (k2 + 1) / 12.0
		b.tube("fer", door + Vector3(cos(a0) * 1.1, 8.2 + sin(a0) * 1.1, -0.9), door + Vector3(cos(a1) * 1.1, 8.2 + sin(a1) * 1.1, -0.9), 0.18, 5)
	b.tube("cuivre", door + Vector3(2.8, 7.2, -0.3), door + Vector3(2.8, 7.2, -1.1), 0.45, 8, -1.0, true)
	# la chatière : un petit volet de bois, en bas de la porte (pour le chat… et, qui sait, pour un tout petit)
	b.box_at("bois_clair", door + Vector3(-1.6, 0.4, -0.12), Vector3(1.8, 1.7, 0.3))
	b.box_at("fer", door + Vector3(-1.6, 2.15, -0.2), Vector3(2.0, 0.18, 0.3))
	# la grande dalle du seuil
	b.box_at("pierre", door + Vector3(0, -0.6, -3.4), Vector3(11.0, 1.05, 6.0))
	cols.box_at(door + Vector3(0, -0.6, -3.4), Vector3(11.0, 1.05, 6.0))
	return {"seuil": door + Vector3(0, 0, -8.0), "fumee": Vector3(ch.x, c.y + ch_top + 1.2, ch.z), "porte": door, "chatiere": door + Vector3(-1.6, 0.0, -0.6)}


## Une fenêtre (encadrement de pierre, carreaux sertis de plomb, croisée blanche, volets ouverts,
## jardinière de géraniums) ; « at » : le milieu du bas de l'ouverture, sur le mur ; « out » : vers dehors.
static func fenetre(b: Batch, at: Vector3, out: Vector3, w: float, h: float, allumee: bool) -> Vector3:
	var side: Vector3 = Vector3.UP.cross(out).normalized()
	var bs := Basis(side, Vector3.UP, out)
	var xf := func(lp: Vector3) -> Transform3D:
		return Transform3D(bs, at + bs * lp)
	b.box("pierre", xf.call(Vector3(0, -0.6, 0.6)), Vector3(w + 2.4, 1.2, 1.6))
	b.box("pierre", xf.call(Vector3(0, h + 0.6, 0.3)), Vector3(w + 2.4, 1.2, 0.9))
	for s in [-1.0, 1.0]:
		b.box("pierre", xf.call(Vector3(s * (w * 0.5 + 0.6), h * 0.5, 0.3)), Vector3(1.2, h, 0.9))
	# la vitre (un peu en retrait), la croisée
	var glass_key: String = "vitre_on" if allumee else "vitre"
	var g0: Vector3 = at + bs * Vector3(0, 0, 0.08)
	var p := [g0 + side * (-w * 0.5), g0 + side * (w * 0.5), g0 + side * (w * 0.5) + Vector3.UP * h, g0 + side * (-w * 0.5) + Vector3.UP * h]
	b.quad(glass_key, p, out, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	b.box("blanc", xf.call(Vector3(0, h * 0.62, 0.22)), Vector3(w, 0.4, 0.28))
	b.box("blanc", xf.call(Vector3(0, h * 0.5, 0.22)), Vector3(0.4, h, 0.28))
	# les volets ouverts, plaqués contre le mur
	for s2 in [-1.0, 1.0]:
		b.box("bois_vert", xf.call(Vector3(s2 * (w * 0.5 + 1.2 + w * 0.25), h * 0.5, 0.25)), Vector3(w * 0.5, h, 0.4))
		for yy in [0.2, 0.8]:
			b.box("fer", xf.call(Vector3(s2 * (w * 0.5 + 1.2 + w * 0.25), h * yy, 0.5)), Vector3(w * 0.42, 0.25, 0.12))
	# la jardinière et ses géraniums (au rez-de-chaussée)
	if at.y - Ile.CENTER.y < 20.0:
		b.box("terre_cuite", xf.call(Vector3(0, -1.9, 1.6)), Vector3(w + 0.6, 1.6, 1.7))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(at.x * 13.0 + at.z * 7.0)
		for k in range(9):
			var fx: float = (float(k) / 8.0 - 0.5) * w
			b.blob("feuille", at + bs * Vector3(fx, -0.6 + rng.randf() * 0.3, 1.6), Vector3(0.9, 0.6, 0.8), 6)
			b.blob("geranium" if k % 3 != 1 else "geranium_rose", at + bs * Vector3(fx + rng.randf_range(-0.3, 0.3), 0.2 + rng.randf() * 0.5, 1.5 + rng.randf() * 0.4), Vector3(0.55, 0.5, 0.55), 6)
	return at + bs * Vector3(0, h * 0.5, 1.0)


# =================================================================== la grange

static func grange(b: Batch, cols: Cols, y0: float) -> Dictionary:
	var c: Vector3 = Ile.W(Ile.GRANGE.x, Ile.GRANGE.y, y0)
	var hx: float = Ile.GRANGE_H.x
	var hz: float = Ile.GRANGE_H.y
	var eaves: float = 24.0
	var ep: float = 1.4
	var door_w: float = 20.0
	var door_h: float = 21.0
	# le soubassement de pierre
	b.box_at("moellons", c + Vector3(0, -1.5, 0), Vector3(hx * 2.0 + 0.8, 4.0, hz * 2.0 + 0.8))
	# les murs de planches rouges ; au nord, la grande porte ouverte
	b.box_at("planches_rouges", c + Vector3(0, 0, hz - ep * 0.5), Vector3(hx * 2.0, eaves, ep))
	b.box_at("planches_rouges", c + Vector3(-hx + ep * 0.5, 0, 0), Vector3(ep, eaves, hz * 2.0))
	b.box_at("planches_rouges", c + Vector3(hx - ep * 0.5, 0, 0), Vector3(ep, eaves, hz * 2.0))
	var side_w: float = (hx * 2.0 - door_w) * 0.5
	for s in [-1.0, 1.0]:
		b.box_at("planches_rouges", c + Vector3(s * (door_w * 0.5 + side_w * 0.5), 0, -hz + ep * 0.5), Vector3(side_w, eaves, ep))
		cols.box_at(c + Vector3(s * (door_w * 0.5 + side_w * 0.5), -1.0, -hz + ep * 0.5), Vector3(side_w, eaves + 1.0, ep))
	b.box_at("planches_rouges", c + Vector3(0, door_h, -hz + ep * 0.5), Vector3(door_w, eaves - door_h, ep))
	cols.box_at(c + Vector3(0, -1.0, hz - ep * 0.5), Vector3(hx * 2.0, eaves + 1.0, ep))
	cols.box_at(c + Vector3(-hx + ep * 0.5, -1.0, 0), Vector3(ep, eaves + 1.0, hz * 2.0))
	cols.box_at(c + Vector3(hx - ep * 0.5, -1.0, 0), Vector3(ep, eaves + 1.0, hz * 2.0))
	# les montants et la traverse de la porte, les deux battants grands ouverts (en croix de Saint-André)
	for s2 in [-1.0, 1.0]:
		b.box_at("poutre", c + Vector3(s2 * (door_w * 0.5 + 0.6), 0, -hz + 0.2), Vector3(1.4, door_h + 1.0, 2.0))
		var hinge: Vector3 = c + Vector3(s2 * (door_w * 0.5 + 0.8), 0, -hz - 0.6)
		var leaf_dir: Vector3 = Vector3(s2 * 0.25, 0, -1.0).normalized()
		var bs := Basis(leaf_dir.cross(Vector3.UP).normalized(), Vector3.UP, leaf_dir)
		var mid: Vector3 = hinge + leaf_dir * door_w * 0.25 + Vector3.UP * door_h * 0.5
		b.box("planches_rouges", Transform3D(bs.rotated(Vector3.UP, PI * 0.5), mid), Vector3(door_w * 0.5, door_h, 0.9))
		cols.box(Transform3D(bs.rotated(Vector3.UP, PI * 0.5), mid), Vector3(door_w * 0.5, door_h, 0.9))
		var xb := Transform3D(bs.rotated(Vector3.UP, PI * 0.5), mid + leaf_dir.cross(Vector3.UP).normalized() * 0.0)
		for d in [-1.0, 1.0]:
			b.box("blanc", xb * Transform3D(Basis(Vector3.FORWARD, d * atan2(door_h, door_w * 0.5)), Vector3(0, 0, -0.55)), Vector3(sqrt(door_h * door_h + door_w * door_w * 0.25) - 1.0, 0.9, 0.3))
		b.box("blanc", xb * Transform3D(Basis(), Vector3(0, 0, -0.55)), Vector3(door_w * 0.5, 0.9, 0.3).rotated(Vector3.FORWARD, 0.0))
	b.box_at("poutre", c + Vector3(0, door_h, -hz + 0.2), Vector3(door_w + 2.6, 1.6, 2.0))
	# dedans : la pénombre, le foin entassé au fond, des sacs de farine
	b.box_at("sombre", c + Vector3(0, eaves - 0.6, 0), Vector3(hx * 2.0 - ep * 2.0, 0.3, hz * 2.0 - ep * 2.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1421
	for k in range(14):
		var hp: Vector3 = c + Vector3(rng.randf_range(-hx + 6.0, hx - 6.0), 0.0, rng.randf_range(2.0, hz - 6.0))
		b.blob("foin", hp + Vector3(0, 2.5, 0), Vector3(rng.randf_range(6.0, 9.0), rng.randf_range(4.0, 7.0), rng.randf_range(4.0, 6.0)), 10)
	cols.box_at(c + Vector3(0, -0.5, 9.0), Vector3(hx * 2.0 - 8.0, 6.5, hz - 2.0))
	for k2 in range(5):
		var sp: Vector3 = c + Vector3(-hx + 7.0 + k2 * 3.6, 0.0, -hz + 6.0 + (k2 % 2) * 2.0)
		b.blob("toile", sp + Vector3(0, 2.2, 0), Vector3(1.6, 2.4, 1.3), 8)
	# le toit de chaume, à deux pans (faîtage est-ouest)
	var over: float = 3.0
	var rise: float = 18.0
	var top: Vector3 = c + Vector3(0, eaves + rise, 0)
	for sz in [-1.0, 1.0]:
		var e0: Vector3 = c + Vector3(0, eaves - 1.0, sz * (hz + over))
		var slope: Vector3 = top - e0
		var mid2: Vector3 = (e0 + top) * 0.5
		var ang: float = atan2(slope.y, absf(slope.z))
		var bs2: Basis = Basis(Vector3.RIGHT, -ang * sz)
		b.box("chaume", Transform3D(bs2, mid2 + bs2 * Vector3(0, 1.0, 0)), Vector3(hx * 2.0 + over * 2.0, 2.2, slope.length()))
		cols.box(Transform3D(bs2, mid2 + bs2 * Vector3(0, 1.0, 0)), Vector3(hx * 2.0 + over * 2.0, 2.2, slope.length()))
	b.box("chaume", Transform3D(Basis(), top + Vector3(0, 1.4, 0)), Vector3(hx * 2.0 + over * 2.0 + 0.6, 2.0, 3.6))
	for sx in [-1.0, 1.0]:
		var x: float = c.x + sx * (hx - 0.1)
		b.prism("planches_rouges", Vector3(x, c.y + eaves, c.z - hz), Vector3(x, c.y + eaves, c.z + hz), Vector3(x, c.y + eaves + rise - 0.6, c.z), Vector3(-sx * ep, 0, 0))
	return {"porte": c + Vector3(0, 0, -hz - 4.0), "dedans": c + Vector3(0, 0, -hz + 8.0)}


# =================================================================== le moulin de la butte

## Le moulin : une tour ronde blanchie à la chaux, son bonnet de bois, et quatre ailes de toile (un
## nœud à part, qui tourne : on le rend). Les ailes regardent le sud-est (la ferme).
static func moulin(b: Batch, cols: Cols, parent: Node3D) -> Dictionary:
	var c: Vector3 = Ile.W(Ile.MOULIN.x, Ile.MOULIN.y, Ile.MOULIN_Y - 0.5)
	var h: float = 38.0
	var r0: float = 12.5
	var r1: float = 9.6
	b.cyl("pierre", Transform3D(Basis(), c + Vector3(0, -2.0, 0)), r0 + 1.2, r0 + 1.0, 3.2, 28)
	b.cyl("enduit", Transform3D(Basis(), c), r0, r1, h, 28, false)
	cols.cyl(c + Vector3(0, -2.0, 0), r0 + 0.6, h + 2.0)
	# le bonnet (un dôme de bardeaux)
	b.cyl("poutre", Transform3D(Basis(), c + Vector3(0, h, 0)), r1 + 1.2, r1 + 1.0, 1.4, 28)
	b.blob("planches", c + Vector3(0, h + 1.2, 0), Vector3(r1 + 1.0, 9.0, r1 + 1.0), 20)
	b.cyl("poutre", Transform3D(Basis(), c + Vector3(0, h + 9.6, 0)), 0.9, 0.2, 3.0, 8)
	var face: Vector3 = Vector3(0.62, 0, 0.78).normalized()       # vers le sud-est
	var side: Vector3 = Vector3.UP.cross(face).normalized()
	# la porte et deux fenêtres (du côté de la ferme)
	var dp: Vector3 = c + face * (r0 - 0.2)
	b.box("bois_vert", Transform3D(Basis(side, Vector3.UP, face), dp + Vector3.UP * 6.2), Vector3(6.4, 12.4, 1.0))
	b.box("pierre", Transform3D(Basis(side, Vector3.UP, face), dp + Vector3.UP * 12.8 + face * 0.2), Vector3(8.0, 1.2, 1.4))
	for k in [[14.0, 1.0], [26.0, -1.0]]:
		var a: float = atan2(face.z, face.x) + 0.35 * float(k[1])
		var rr: float = lerpf(r0, r1, float(k[0]) / h)
		var fp: Vector3 = c + Vector3(cos(a), 0, sin(a)) * (rr - 0.1) + Vector3.UP * float(k[0])
		var fo := Vector3(cos(a), 0, sin(a))
		b.box("vitre", Transform3D(Basis(Vector3.UP.cross(fo).normalized(), Vector3.UP, fo), fp + Vector3.UP * 2.5), Vector3(3.6, 5.0, 0.6))
		b.box("bois_vert", Transform3D(Basis(Vector3.UP.cross(fo).normalized(), Vector3.UP, fo), fp + Vector3.UP * 2.5 + fo * 0.1), Vector3(4.4, 0.5, 0.7))
	# l'arbre des ailes
	var hub: Vector3 = c + Vector3(0, h + 4.0, 0) + face * (r1 + 3.0)
	b.tube("poutre", c + Vector3(0, h + 4.0, 0), hub + face * 1.5, 1.4, 10, -1.0, true)
	var ailes := Node3D.new()
	ailes.name = "Ailes_moulin"
	parent.add_child(ailes)
	ailes.global_transform = Transform3D(Basis(side, Vector3.UP, face), hub + face * 1.0)
	var ab := Batch.new()
	var R: float = 33.0
	for k2 in range(4):
		var a2: float = TAU * k2 / 4.0 + 0.3
		var dir := Vector3(cos(a2), sin(a2), 0)
		var perp := Vector3(-sin(a2), cos(a2), 0)
		ab.tube("poutre", Vector3.ZERO, dir * R, 0.7, 6)
		# le treillis de l'aile (d'un côté de la vergue) et sa toile
		var w: float = 6.5
		var r_in: float = 7.0
		ab.tube("poutre", dir * r_in + perp * w, dir * R + perp * w, 0.3, 4)
		var nb: int = 9
		for j in range(nb + 1):
			var t: float = lerpf(r_in, R, float(j) / nb)
			ab.tube("poutre", dir * t, dir * t + perp * w, 0.22, 4)
		var p0: Vector3 = dir * (r_in + 0.6) + perp * 0.6 + Vector3(0, 0, 0.25)
		var p1: Vector3 = dir * (R - 0.6) + perp * 0.6 + Vector3(0, 0, 0.25)
		var p2: Vector3 = dir * (R - 0.6) + perp * (w - 0.6) + Vector3(0, 0, 0.25)
		var p3: Vector3 = dir * (r_in + 0.6) + perp * (w - 0.6) + Vector3(0, 0, 0.25)
		ab.quad("toile", [p0, p1, p2, p3], Vector3(0, 0, 1), [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	ab.cyl("poutre", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.5)), 2.2, 2.2, 1.8, 12)
	ab.commit(ailes, "Ailes", true)
	return {"ailes": ailes, "porte": dp + face * 3.0, "pied": c}


# =================================================================== la cour, le puits, le jardin

static func puits(b: Batch, cols: Cols, at: Vector3) -> Dictionary:
	b.cyl("moellons", Transform3D(Basis(), at + Vector3(0, -1.0, 0)), 4.4, 4.4, 7.0, 20, false)
	b.cyl("pierre", Transform3D(Basis(), at + Vector3(0, 5.6, 0)), 4.8, 4.8, 0.9, 20, true)
	b.cyl("sombre", Transform3D(Basis(), at + Vector3(0, 6.45, 0)), 3.4, 3.4, 0.1, 20)
	cols.cyl(at + Vector3(0, -1.0, 0), 4.6, 7.5)
	for s in [-1.0, 1.0]:
		b.box_at("poutre", at + Vector3(s * 4.0, 6.0, 0), Vector3(0.9, 10.0, 0.9))
	b.tube("poutre", at + Vector3(-4.6, 13.0, 0), at + Vector3(4.6, 13.0, 0), 0.55, 8)
	b.tube("fer", at + Vector3(4.6, 13.0, 0), at + Vector3(5.6, 13.0, 0), 0.15, 5)
	b.tube("fer", at + Vector3(5.6, 13.0, 0), at + Vector3(5.6, 11.6, 0), 0.15, 5)
	# le petit toit
	for s2 in [-1.0, 1.0]:
		var bs := Basis(Vector3.RIGHT, -0.6 * s2)
		b.box("tuiles", Transform3D(bs, at + Vector3(0, 17.0, s2 * 2.4)), Vector3(11.0, 0.5, 5.8))
	b.box_at("poutre", at + Vector3(0, 16.0, 0), Vector3(10.0, 0.6, 0.6))
	# la corde et le seau, posé sur la margelle
	b.tube("corde", at + Vector3(0.6, 13.0, 0), at + Vector3(0.6, 6.6, 0), 0.08, 4)
	seau(b, at + Vector3(2.6, 6.5, 1.6), 0.4)
	return {"pos": at}


static func seau(b: Batch, at: Vector3, yaw: float) -> void:
	b.cyl("zinc", Transform3D(Basis(Vector3.UP, yaw), at), 0.95, 1.2, 2.1, 14, false)
	b.cyl("sombre", Transform3D(Basis(), at + Vector3(0, 0.2, 0)), 0.85, 0.85, 0.05, 12)
	b.cyl("zinc", Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0, 2.0, 0)), 1.25, 1.25, 0.12, 14, false)
	var hd: Vector3 = Vector3(cos(yaw), 0, sin(yaw))
	for k in range(8):
		var a0: float = PI * k / 8.0
		var a1: float = PI * (k + 1) / 8.0
		b.tube("fer", at + hd * cos(a0) * 1.25 + Vector3.UP * (2.1 + sin(a0) * 1.0), at + hd * cos(a1) * 1.25 + Vector3.UP * (2.1 + sin(a1) * 1.0), 0.07, 4)


## La clôture du potager : des piquets blancs pointus, espacés de 1,6 m (on se glisse entre eux),
## deux lisses ; une porte ouverte à l'ouest (PORTE_POTAGER).
static func cloture(b: Batch, cols: Cols, ile: Node3D) -> void:
	var r: Array = Ile.POTAGER
	var corners := [Vector2(r[0], r[1]), Vector2(r[2], r[1]), Vector2(r[2], r[3]), Vector2(r[0], r[3])]
	for i in range(4):
		var a: Vector2 = corners[i]
		var c: Vector2 = corners[(i + 1) % 4]
		var d: Vector2 = c - a
		var n: int = int(d.length() / 1.6)
		var dir: Vector2 = d.normalized()
		var yaw: float = -atan2(dir.y, dir.x)
		var prev := Vector3.INF
		for k in range(n + 1):
			var l: Vector2 = a + dir * (float(k) * d.length() / n)
			if l.distance_to(Ile.PORTE_POTAGER) < 5.2:
				prev = Vector3.INF
				continue
			var y: float = ile.height_l(l.x, l.y)
			var w: Vector3 = Ile.W(l.x, l.y, y)
			b.box("blanc", Transform3D(Basis(Vector3.UP, yaw), w + Vector3(0, 3.4, 0)), Vector3(0.62, 7.6, 0.26))
			b.prism("blanc", w + Vector3(0, 7.2, 0) + Vector3(cos(yaw), 0, -sin(yaw)) * 0.31 + Vector3(sin(yaw), 0, cos(yaw)) * 0.13,
				w + Vector3(0, 7.2, 0) - Vector3(cos(yaw), 0, -sin(yaw)) * 0.31 + Vector3(sin(yaw), 0, cos(yaw)) * 0.13,
				w + Vector3(0, 8.0, 0) + Vector3(sin(yaw), 0, cos(yaw)) * 0.13, Vector3(sin(yaw), 0, cos(yaw)) * -0.26)
			cols.box(Transform3D(Basis(Vector3.UP, yaw), w + Vector3(0, 3.6, 0)), Vector3(0.62, 8.0, 0.3))
			if prev != Vector3.INF:
				for yy in [2.0, 5.6]:
					b.box("blanc", Transform3D(Basis(Vector3.UP, yaw), (prev + w) * 0.5 + Vector3(0, yy, 0) - Vector3(sin(yaw), 0, cos(yaw)) * 0.28), Vector3(prev.distance_to(w) + 0.3, 0.42, 0.16))
			prev = w


static func brouette(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	var xf := func(lp: Vector3) -> Vector3:
		return at + bs * lp
	# la caisse (planches), la roue, les brancards, les pieds
	for s in [-1.0, 1.0]:
		b.box("bois_clair", Transform3D(bs * Basis(Vector3.FORWARD, s * 0.35), xf.call(Vector3(s * 2.4, 3.6, 0))), Vector3(0.4, 2.6, 7.2))
	b.box("bois_clair", Transform3D(bs, xf.call(Vector3(0, 2.4, 0))), Vector3(5.0, 0.4, 7.2))
	b.box("bois_clair", Transform3D(bs * Basis(Vector3.RIGHT, 0.4), xf.call(Vector3(0, 3.4, 3.7))), Vector3(5.6, 2.6, 0.4))
	b.box("bois_clair", Transform3D(bs * Basis(Vector3.RIGHT, -0.4), xf.call(Vector3(0, 3.4, -3.7))), Vector3(5.6, 2.6, 0.4))
	b.cyl("caoutchouc", Transform3D(bs * Basis(Vector3.FORWARD, PI * 0.5), xf.call(Vector3(0.45, 1.6, 5.4))), 1.6, 1.6, 0.9, 16)
	b.cyl("fer", Transform3D(bs * Basis(Vector3.FORWARD, PI * 0.5), xf.call(Vector3(0.6, 1.6, 5.4))), 0.4, 0.4, 1.2, 8)
	for s2 in [-1.0, 1.0]:
		b.tube("poutre", xf.call(Vector3(s2 * 1.8, 1.6, 5.4)), xf.call(Vector3(s2 * 2.2, 2.6, -8.5)), 0.32, 6)
		b.tube("poutre", xf.call(Vector3(s2 * 1.9, 2.3, -3.0)), xf.call(Vector3(s2 * 2.0, 0.0, -3.4)), 0.3, 6)
	# un peu de terre et une citrouille, dedans
	b.blob("foin_bout", xf.call(Vector3(0, 3.3, 0.5)), Vector3(2.0, 0.6, 3.0), 8)
	b.blob("citrouille_tete", xf.call(Vector3(0.3, 4.4, -0.8)), Vector3(1.6, 1.3, 1.6), 12)
	cols.box(Transform3D(bs, xf.call(Vector3(0, 2.0, 0))), Vector3(5.2, 4.0, 8.0))


static func arrosoir(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.cyl("zinc", Transform3D(bs, at), 1.6, 1.4, 3.2, 18, true)
	b.cyl("zinc", Transform3D(bs, at + Vector3(0, 3.2, 0)), 1.4, 0.7, 0.6, 18, false)
	var sp0: Vector3 = at + bs * Vector3(0, 0.8, 1.4)
	var sp1: Vector3 = at + bs * Vector3(0, 4.4, 4.6)
	b.tube("zinc", sp0, sp1, 0.35, 8, 0.22)
	b.cyl("zinc", Transform3D(bs * Basis(Vector3.RIGHT, 0.75), sp1), 0.4, 0.75, 0.5, 12)
	for k in range(8):
		var a0: float = PI * k / 8.0
		var a1: float = PI * (k + 1) / 8.0
		b.tube("zinc", at + bs * Vector3(0, 3.6 + sin(a0) * 1.4, -cos(a0) * 1.5), at + bs * Vector3(0, 3.6 + sin(a1) * 1.4, -cos(a1) * 1.5), 0.17, 5)
	cols.cyl(at, 1.6, 3.8)


static func bottes(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	for s in [-1.0, 1.0]:
		var p: Vector3 = at + bs * Vector3(s * 0.85, 0, 0)
		b.cyl("caoutchouc", Transform3D(bs, p + Vector3(0, 0.6, 0)), 0.62, 0.66, 2.9, 12, false)
		b.cyl("sombre", Transform3D(bs, p + Vector3(0, 3.45, 0)), 0.58, 0.58, 0.05, 10)
		b.blob("caoutchouc", p + bs * Vector3(0, 0.55, 0.55), Vector3(0.66, 0.55, 1.15), 10)
	cols.box(Transform3D(bs, at + Vector3(0, 1.75, 0.25)), Vector3(3.0, 3.5, 2.4))


static func rateau(b: Batch, at: Vector3, top: Vector3) -> void:
	b.tube("bois_clair", at, top, 0.24, 6)
	var d: Vector3 = (top - at).normalized()
	var side: Vector3 = d.cross(Vector3.UP).normalized()
	b.box("fer", Transform3D(Basis(side, d, side.cross(d)), at), Vector3(4.0, 0.25, 0.3))
	for k in range(9):
		var t: float = (float(k) / 8.0 - 0.5) * 3.8
		b.tube("fer", at + side * t, at + side * t - d * 0.9 + side.cross(d) * 0.4, 0.07, 4)


## Le fauteuil à bascule de Grand-mère Ernestine (le dossier vers le sud-est)
static func fauteuil(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	var xf := func(lp: Vector3) -> Vector3:
		return at + bs * lp
	# les patins (deux arcs), l'assise (à 3,3 m), le dossier à barreaux, les accoudoirs
	for s in [-1.0, 1.0]:
		var prev := Vector3.INF
		for k in range(9):
			var u: float = (float(k) / 8.0 - 0.5) * 5.6
			var p: Vector3 = xf.call(Vector3(s * 2.2, 0.35 + u * u * 0.07, u))
			if prev != Vector3.INF:
				b.tube("bois_clair", prev, p, 0.26, 5)
			prev = p
		b.tube("bois_clair", xf.call(Vector3(s * 2.2, 0.4, -1.6)), xf.call(Vector3(s * 2.2, 3.3, -1.6)), 0.24, 6)
		b.tube("bois_clair", xf.call(Vector3(s * 2.2, 0.4, 1.8)), xf.call(Vector3(s * 2.3, 8.6, 2.4)), 0.26, 6)
		b.tube("bois_clair", xf.call(Vector3(s * 2.25, 5.0, -1.8)), xf.call(Vector3(s * 2.25, 5.0, 1.9)), 0.22, 6)
		b.tube("bois_clair", xf.call(Vector3(s * 2.25, 3.3, -1.6)), xf.call(Vector3(s * 2.25, 5.0, -1.8)), 0.18, 5)
	b.box("bois_clair", Transform3D(bs, xf.call(Vector3(0, 3.3, 0.1))), Vector3(4.6, 0.36, 3.8))
	for k2 in range(5):
		var x: float = (float(k2) / 4.0 - 0.5) * 3.6
		b.tube("bois_clair", xf.call(Vector3(x, 3.4, 2.0)), xf.call(Vector3(x, 8.2, 2.5)), 0.15, 5)
	b.tube("bois_clair", xf.call(Vector3(-2.3, 8.4, 2.45)), xf.call(Vector3(2.3, 8.4, 2.45)), 0.25, 6)
	# un coussin rouge, une pelote de laine sur le côté
	b.blob("rouge", xf.call(Vector3(0, 3.65, 0.2)), Vector3(2.0, 0.35, 1.7), 10)
	cols.box(Transform3D(bs, xf.call(Vector3(0, 1.8, 0.3))), Vector3(4.8, 3.6, 4.4))


static func pelote(b: Batch, at: Vector3, col: String) -> void:
	b.blob(col, at + Vector3(0, 0.8, 0), Vector3(0.85, 0.8, 0.85), 12)


## La corde à linge : deux poteaux, une corde qui pend un peu ; rend les points où pendre le linge
static func corde_linge(b: Batch, cols: Cols, a: Vector3, c: Vector3) -> Array:
	var h: float = 14.5
	for p in [a, c]:
		b.tube("poutre", p + Vector3(0, -0.5, 0), p + Vector3(0, h + 1.0, 0), 0.38, 8)
		b.tube("poutre", p + Vector3(0, h, 0) - (c - a).normalized().cross(Vector3.UP) * 1.6, p + Vector3(0, h, 0) + (c - a).normalized().cross(Vector3.UP) * 1.6, 0.25, 6)
		cols.cyl(p, 0.42, h + 1.0)
	var pts: Array = []
	var n: int = 16
	for k in range(n + 1):
		var t: float = float(k) / n
		var p2: Vector3 = a.lerp(c, t) + Vector3(0, h - 1.4 * sin(PI * t), 0)
		pts.append(p2)
	for k2 in range(n):
		b.tube("corde", pts[k2], pts[k2 + 1], 0.07, 4)
	return pts


## Une pièce de linge (un drap, une chemise, une robe, une chaussette), un maillage souple qui
## ondule au vent (shader linge_v142) ; « top » : le milieu du haut, sur la corde
static func linge(parent: Node3D, top: Vector3, along: Vector3, w: float, h: float, key: String, forme: String = "drap") -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 8
	var ny: int = 10
	var side: Vector3 = along.normalized()
	var nrm: Vector3 = side.cross(Vector3.UP).normalized()
	var grid: Array = []
	for j in range(ny + 1):
		var row: Array = []
		var v: float = float(j) / ny
		for i in range(nx + 1):
			var u: float = float(i) / nx
			var ww: float = w
			if forme == "chemise":
				ww = w * (1.0 if v < 0.35 else 0.62)
			elif forme == "robe":
				ww = w * lerpf(0.55, 1.15, v)
			var p: Vector3 = side * (u - 0.5) * ww + Vector3.DOWN * v * h
			if forme == "chaussette" and v > 0.75:
				p += side * (v - 0.75) * w * 1.6
			row.append(p)
		grid.append(row)
	for j2 in range(ny):
		for i2 in range(nx):
			var q := [[i2, j2], [i2 + 1, j2], [i2 + 1, j2 + 1], [i2, j2 + 1]]
			for idx in [0, 1, 2, 0, 2, 3]:
				var cc: Array = q[idx]
				st.set_normal(nrm)
				st.set_uv(Vector2(float(cc[0]) / nx, float(cc[1]) / ny))
				st.add_vertex(grid[cc[1]][cc[0]])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat(key)
	mi.name = "Linge"
	parent.add_child(mi)
	mi.global_position = top
	# les pinces à linge
	return mi


## Un muret de pierres sèches le long d'une polyligne (repère île), avec sa collision
static func muret(b: Batch, cols: Cols, ile: Node3D, pts: Array, rng: RandomNumberGenerator) -> void:
	for i in range(pts.size() - 1):
		var a := Vector2(float(pts[i][0]), float(pts[i][1]))
		var c := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		var d: Vector2 = c - a
		var n: int = int(d.length() / 2.6)
		var dir: Vector2 = d.normalized()
		for k in range(n + 1):
			var l: Vector2 = a + d * (float(k) / n)
			var y: float = ile.height_l(l.x, l.y)
			for layer in range(3):
				var off: Vector2 = Vector2(-dir.y, dir.x) * rng.randf_range(-0.6, 0.6) + dir * rng.randf_range(-0.6, 0.6) + dir * (1.3 if layer == 1 else 0.0)
				var s: float = rng.randf_range(1.3, 1.9) * (1.0 - 0.15 * layer)
				var w: Vector3 = Ile.W(l.x + off.x, l.y + off.y, y + 0.6 + layer * 2.1)
				b.blob("roche", w, Vector3(s * rng.randf_range(0.9, 1.3), s * rng.randf_range(0.6, 0.85), s * rng.randf_range(0.8, 1.1)), 7, Basis(Vector3.UP, rng.randf() * TAU))
		var mid: Vector2 = (a + c) * 0.5
		var ym: float = ile.height_l(mid.x, mid.y)
		cols.box(Transform3D(Basis(Vector3.UP, -atan2(dir.y, dir.x)), Ile.W(mid.x, mid.y, ym + 2.8)), Vector3(d.length() + 2.0, 6.4, 3.0))


## Une balle de foin ronde, couchée
static func balle_foin(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, PI * 0.5)
	b.cyl("foin", Transform3D(bs, at + Vector3(0, 4.3, 0) + Basis(Vector3.UP, yaw) * Vector3(-4.2, 0, 0)), 4.3, 4.3, 8.4, 20, false)
	for s in [-1.0, 1.0]:
		b.cyl("foin_bout", Transform3D(bs, at + Vector3(0, 4.3, 0) + Basis(Vector3.UP, yaw) * Vector3(s * 4.2, 0, 0)), 4.25, 4.25, 0.05, 20)
	cols.cyl_xf(Transform3D(bs, at + Vector3(0, 4.3, 0)), 4.3, 8.4)


## L'épouvantail du potager (un vieux manteau, un chapeau de paille, une citrouille pour tête)
static func epouvantail(b: Batch, cols: Cols, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.tube("poutre", at + Vector3(0, -0.5, 0), at + Vector3(0, 13.0, 0), 0.4, 6)
	b.tube("poutre", at + bs * Vector3(-5.4, 9.6, 0), at + bs * Vector3(5.4, 9.6, 0), 0.32, 6)
	b.box("veste", Transform3D(bs, at + Vector3(0, 7.6, 0)), Vector3(4.4, 5.2, 1.8))
	for s in [-1.0, 1.0]:
		b.tube("veste", at + bs * Vector3(s * 2.0, 9.6, 0), at + bs * Vector3(s * 5.0, 9.3, 0.2), 0.85, 8)
		b.blob("paille", at + bs * Vector3(s * 5.5, 9.3, 0.2), Vector3(0.7, 0.9, 0.7), 6)
	b.blob("citrouille_tete", at + Vector3(0, 11.6, 0), Vector3(1.7, 1.5, 1.6), 12)
	b.cyl("paille", Transform3D(bs, at + Vector3(0, 12.6, 0)), 3.6, 3.6, 0.3, 16)
	b.cyl("paille", Transform3D(bs, at + Vector3(0, 12.8, 0)), 1.7, 1.4, 1.6, 14)
	b.blob("paille", at + Vector3(0, 4.8, 0), Vector3(1.2, 0.8, 0.8), 6)
	cols.cyl(at, 0.5, 13.0)


## Sur la grève : le château de sable de Pâquerette (des tours aussi hautes que des maisons), son
## seau rouge et sa pelle jaune ; on en fait le tour, on se glisse dans la cour du château.
static func chateau_sable(b: Batch, cols: Cols, ile: Node3D, c: Vector2) -> void:
	var y: float = ile.height_l(c.x, c.y)
	var base: Vector3 = Ile.W(c.x, c.y, y - 0.3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1429
	# la motte du château, les quatre tours aux coins, le donjon au milieu (moulé dans le seau)
	b.cyl("sable_mouille", Transform3D(Basis(), base + Vector3(0, -0.2, 0)), 13.0, 11.5, 2.2, 28)
	var tours: Array = []
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		tours.append(base + Vector3(cos(a), 0, sin(a)) * 8.0)
	for t in tours:
		b.cyl("sable", Transform3D(Basis(), t + Vector3(0, 1.6, 0)), 2.8, 2.3, 6.2, 16)
		for j in range(6):
			var a2: float = TAU * j / 6.0
			b.box("sable", Transform3D(Basis(Vector3.UP, -a2), t + Vector3(cos(a2), 0, sin(a2)) * 2.0 + Vector3(0, 8.2, 0)), Vector3(1.0, 1.0, 1.0))
		cols.cyl(t + Vector3(0, 1.6, 0), 2.6, 6.2)
	for k2 in range(4):
		var a0: Vector3 = tours[k2]
		var a1: Vector3 = tours[(k2 + 1) % 4]
		var mid: Vector3 = (a0 + a1) * 0.5
		var d: Vector3 = a1 - a0
		var yaw: float = -atan2(d.z, d.x)
		# le mur, avec une porte côté mer (au nord)
		if k2 == 2:
			for sgn in [-1.0, 1.0]:
				var seg_c: Vector3 = mid + d.normalized() * sgn * (d.length() * 0.5 - 2.6) * 0.62
				b.box("sable", Transform3D(Basis(Vector3.UP, yaw), seg_c + Vector3(0, 3.0, 0)), Vector3(d.length() * 0.36, 3.6, 1.6))
				cols.box(Transform3D(Basis(Vector3.UP, yaw), seg_c + Vector3(0, 3.0, 0)), Vector3(d.length() * 0.36, 3.6, 1.6))
		else:
			b.box("sable", Transform3D(Basis(Vector3.UP, yaw), mid + Vector3(0, 3.0, 0)), Vector3(d.length() - 4.0, 3.6, 1.6))
			cols.box(Transform3D(Basis(Vector3.UP, yaw), mid + Vector3(0, 3.0, 0)), Vector3(d.length() - 4.0, 3.6, 1.6))
	b.cyl("sable", Transform3D(Basis(), base + Vector3(0, 1.6, 0)), 3.6, 3.0, 9.0, 18)
	b.cyl("sable", Transform3D(Basis(), base + Vector3(0, 10.6, 0)), 3.0, 0.4, 3.2, 18)
	cols.cyl(base + Vector3(0, 1.6, 0), 3.4, 9.0)
	# un drapeau : un bâtonnet de sucette et une feuille
	b.tube("bois_clair", base + Vector3(0, 13.4, 0), base + Vector3(0, 17.0, 0), 0.08, 5)
	b.box("geranium", Transform3D(Basis(), base + Vector3(0.7, 16.3, 0)), Vector3(1.4, 0.9, 0.05))
	# le seau renversé (rouge) et la pelle (jaune), à côté
	var sb: Vector3 = base + Vector3(16.5, 0.2, 4.0)
	b.cyl("jouet_rouge", Transform3D(Basis(), sb), 3.4, 2.7, 4.6, 22, true)
	for k3 in range(10):
		var a3: float = PI * k3 / 10.0
		var a4: float = PI * (k3 + 1) / 10.0
		b.tube("jouet_rouge", sb + Vector3(cos(a3) * 3.0, 0.4 + sin(a3) * 0.4, sin(a3) * 0.0 + 0.0) + Vector3(0, 0, 0), sb + Vector3(cos(a4) * 3.0, 0.4 + sin(a4) * 0.4, 0.0), 0.16, 5)
	cols.cyl(sb, 3.3, 4.6)
	var pb: Vector3 = base + Vector3(-15.0, 0.3, 6.0)
	var dir := Vector3(0.8, 0.0, 0.6).normalized()
	b.tube("jouet_jaune", pb, pb + dir * 7.5 + Vector3(0, 0.6, 0), 0.32, 8)
	b.box("jouet_jaune", Transform3D(Basis(Vector3.UP, -atan2(dir.z, dir.x)), pb - dir * 1.6 + Vector3(0, 0.15, 0)), Vector3(3.4, 0.3, 2.8))
	b.box("jouet_jaune", Transform3D(Basis(Vector3.UP, -atan2(dir.z, dir.x)), pb + dir * 7.8 + Vector3(0, 0.65, 0)), Vector3(0.5, 0.6, 1.8))
	# des coquillages ramassés (des « galets » roses et blancs gros comme des coussins)
	for k4 in range(9):
		var q := base + Vector3(rng.randf_range(-18, 18), 0.2, rng.randf_range(10, 18))
		b.blob("blanc" if k4 % 2 == 0 else "geranium_rose", q, Vector3(0.9, 0.35, 0.7), 8, Basis(Vector3.UP, rng.randf() * TAU))

extends RefCounted
## V94 : la boîte à outils de Néopolis. Les matières (béton, métal, verre, lampes, néons…), le
## « lot » (Batch : des morceaux rassemblés par matière dans un seul maillage), et les objets de la
## ville faits de morceaux simples : les réverbères, les distributeurs, les bancs, les étals du
## Marché de Nuit, les conteneurs du port, les climatiseurs et les citernes des toits, les
## cerisiers du Jardin Zen, la carpe des hologrammes, les voitures volantes, le monorail.
## Pour Godot, la face avant d'un triangle tourne dans le sens des aiguilles d'une montre vue de
## devant : chaque triangle est remis dans le bon sens d'après la normale qu'il doit montrer.

const Decor = preload("res://scripts/decor_v53.gd")

static var _mcache: Dictionary = {}

## Les couleurs des néons (et des liserés des tours)
const NEONS := {"cyan": Color(0.1, 0.85, 1.0), "rose": Color(1.0, 0.22, 0.75), "ambre": Color(1.0, 0.6, 0.12),
	"vert": Color(0.2, 1.0, 0.5), "rouge": Color(1.0, 0.18, 0.2), "violet": Color(0.6, 0.3, 1.0), "blanc": Color(0.9, 0.95, 1.0)}


static func _std(albedo: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = albedo
	s.roughness = rough
	s.metallic = metal
	return s


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
	if key.begins_with("neon_"):
		m = _glow(NEONS.get(key.substr(5), Color.WHITE), 3.0)
		_mcache[key] = m
		return m
	match key:
		"beton":
			m = Decor.stone(Color(0.52, 0.52, 0.54))
		"beton_clair":
			m = Decor.stone(Color(0.72, 0.71, 0.69))
		"metal":
			m = _std(Color(0.5, 0.52, 0.55), 0.35, 0.85)
		"metal_noir":
			m = _std(Color(0.08, 0.085, 0.1), 0.4, 0.7)
		"chrome":
			m = _std(Color(0.85, 0.86, 0.9), 0.12, 1.0)
		"peinture_blanche":
			m = _std(Color(0.88, 0.9, 0.92), 0.28, 0.2)
		"peinture_jaune":
			m = _std(Color(0.95, 0.75, 0.1), 0.45, 0.1)
		"plastique_rouge":
			m = _std(Color(0.75, 0.08, 0.1), 0.35)
		"plastique_bleu":
			m = _std(Color(0.08, 0.3, 0.75), 0.35)
		"plastique_noir":
			m = _std(Color(0.05, 0.05, 0.06), 0.45)
		"verre":
			var v := _std(Color(0.55, 0.7, 0.75, 0.16), 0.03, 0.2)
			v.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m = v
		"verre_fume":
			m = _std(Color(0.03, 0.05, 0.06), 0.05, 0.6)
		"bois":
			m = Decor.wood(Color(0.55, 0.38, 0.26))
		"bois_clair":
			m = Decor.planks(Color(0.86, 0.74, 0.58))
		"tissu_rouge":
			m = _std(Color(0.6, 0.06, 0.08), 0.85)
		"tissu_bleu":
			m = _std(Color(0.06, 0.18, 0.45), 0.85)
		"tissu_vert":
			m = _std(Color(0.05, 0.35, 0.22), 0.85)
		"tissu_jaune":
			m = _std(Color(0.85, 0.62, 0.08), 0.85)
		"conteneur_orange":
			m = _std(Color(0.72, 0.3, 0.08), 0.55, 0.5)
		"conteneur_bleu":
			m = _std(Color(0.08, 0.22, 0.42), 0.55, 0.5)
		"conteneur_vert":
			m = _std(Color(0.1, 0.32, 0.2), 0.55, 0.5)
		"conteneur_rouge":
			m = _std(Color(0.45, 0.07, 0.06), 0.55, 0.5)
		"ecorce":
			m = _std(Color(0.22, 0.14, 0.12), 0.9)
		"sakura":
			var s := _std(Color(1.0, 0.68, 0.82), 0.8)
			s.emission_enabled = true
			s.emission = Color(1.0, 0.45, 0.7)
			s.emission_energy_multiplier = 0.08
			m = s
		"herbe":
			var g := StandardMaterial3D.new()
			if ResourceLoader.exists("res://assets/textures/terrain/grass.jpg"):
				g.albedo_texture = load("res://assets/textures/terrain/grass.jpg")
				g.uv1_triplanar = true
				g.uv1_world_triplanar = true
				g.uv1_scale = Vector3(0.25, 0.25, 0.25)
			g.albedo_color = Color(0.75, 0.85, 0.7)
			g.roughness = 0.9
			m = g
		"gravier_zen":
			m = _std(Color(0.42, 0.41, 0.39), 0.95)
		"eau":
			var e := _std(Color(0.04, 0.12, 0.14, 0.85), 0.02, 0.3)
			e.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m = e
		"pierre":
			m = Decor.stone(Color(0.6, 0.6, 0.58))
		"rouge_laque":
			m = _std(Color(0.7, 0.08, 0.06), 0.3)
		"lampe_blanche":
			m = _glow(Color(0.85, 0.92, 1.0), 2.5)
		"lampe_chaude":
			m = _glow(Color(1.0, 0.75, 0.45), 2.5)
		"phare":
			m = _glow(Color(1.0, 0.98, 0.92), 6.0)
		"feu_arriere":
			m = _glow(Color(1.0, 0.08, 0.1), 5.0)
		"ecran_bleu":
			m = _glow(Color(0.2, 0.6, 1.0), 1.6)
		_:
			m = _std(Color(0.5, 0.5, 0.5), 0.6)
	_mcache[key] = m
	return m


## Le soir, les lampes et les néons brillent plus fort (n : 0 le jour, 1 la nuit).
static func set_night(n: float) -> void:
	for k in _mcache:
		var key: String = str(k)
		var m: Material = _mcache[k]
		if not (m is StandardMaterial3D) or not (m as StandardMaterial3D).emission_enabled:
			continue
		if key.begins_with("neon_"):
			(m as StandardMaterial3D).emission_energy_multiplier = lerpf(1.2, 4.0, n)
		elif key in ["lampe_blanche", "lampe_chaude"]:
			(m as StandardMaterial3D).emission_energy_multiplier = lerpf(0.2, 3.0, n)
		elif key == "sakura":
			(m as StandardMaterial3D).emission_energy_multiplier = lerpf(0.0, 0.25, n)


# =================================================================== le lot (Batch)

class Batch:
	var sts: Dictionary = {}

	func _st(key: String) -> SurfaceTool:
		if not sts.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[key] = st
		return sts[key]

	## Un triangle ; n : la normale qu'il doit montrer (le sens est remis d'après elle).
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

	## Une boîte (xf : sa position (le centre) et son orientation ; size : ses dimensions ; UV en mètres).
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

	## Une boîte posée : at = le milieu de sa base.
	func box_at(key: String, at: Vector3, size: Vector3, yaw: float = 0.0) -> void:
		box(key, Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * size.y * 0.5), size)

	## Un cylindre (ou un cône) dressé sur l'axe y local, la base en xf.origin.
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

	## Un tube entre deux points (un câble, un barreau, un tuyau).
	func tube(key: String, a: Vector3, b: Vector3, r: float, sides: int = 6) -> void:
		var d: Vector3 = b - a
		var l: float = d.length()
		if l < 0.001:
			return
		var y: Vector3 = d / l
		var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
		var z: Vector3 = x.cross(y)
		cyl(key, Transform3D(Basis(x, y, z), a), r, r, l, sides, false)

	## Une sphère aplatie (feuillage, lanterne)
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
			mesh.surface_set_material(mesh.get_surface_count() - 1, load("res://scripts/neo_kit_v94.gd").mat(str(k)))
		var mi := MeshInstance3D.new()
		mi.name = label
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		sts.clear()
		return mi


# =================================================================== les objets de la rue

## Un réverbère : un mât, un bras, une tête qui éclaire la chaussée (face : vers la chaussée).
## Renvoie le point où mettre la lumière.
static func lamp_post(b: Batch, at: Vector3, face: Vector3) -> Vector3:
	b.cyl_at("metal_noir", at, 0.12, 0.08, 7.2, 8)
	var top: Vector3 = at + Vector3.UP * 7.0
	b.tube("metal_noir", top, top + face * 1.6 + Vector3.UP * 0.2, 0.06)
	var head: Vector3 = top + face * 1.7 + Vector3.UP * 0.12
	b.box("metal_noir", Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), head), Vector3(0.45, 0.14, 0.9))
	b.box("lampe_blanche", Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), head + Vector3.DOWN * 0.08), Vector3(0.36, 0.03, 0.8))
	# un anneau de lumière autour du mât, à hauteur d'homme
	b.cyl_at("neon_cyan", at + Vector3.UP * 2.6, 0.13, 0.13, 0.08, 10)
	return head + Vector3.DOWN * 0.4


## Un distributeur de boissons (face : vers le passant)
static func vending(b: Batch, at: Vector3, face: Vector3, couleur: String) -> void:
	var yaw: float = atan2(face.x, face.z)
	var bs := Basis(Vector3.UP, yaw)
	b.box(couleur, Transform3D(bs, at + Vector3.UP * 0.95), Vector3(1.05, 1.9, 0.8))
	b.box("ecran_bleu", Transform3D(bs, at + bs * Vector3(-0.12, 1.25, 0.41)), Vector3(0.62, 0.9, 0.02))
	for k in range(4):
		b.box("lampe_chaude", Transform3D(bs, at + bs * Vector3(-0.12 + (k - 1.5) * 0.14, 0.82, 0.41)), Vector3(0.08, 0.04, 0.02))
	b.box("plastique_noir", Transform3D(bs, at + bs * Vector3(0.0, 0.35, 0.41)), Vector3(0.7, 0.22, 0.04))
	b.box("metal", Transform3D(bs, at + bs * Vector3(0.38, 1.0, 0.41)), Vector3(0.14, 0.4, 0.03))


## Un banc de métal et de bois
static func bench(b: Batch, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box("bois_clair", Transform3D(bs, at + Vector3.UP * 0.45), Vector3(1.9, 0.07, 0.48))
	b.box("bois_clair", Transform3D(bs, at + bs * Vector3(0, 0.75, -0.22)), Vector3(1.9, 0.35, 0.05))
	for sx in [-0.8, 0.8]:
		b.box("metal_noir", Transform3D(bs, at + bs * Vector3(sx, 0.22, 0)), Vector3(0.06, 0.44, 0.45))


## Un étal du Marché de Nuit : un comptoir, un auvent de toile, des lanternes ; face : vers l'allée.
static func stall(b: Batch, at: Vector3, face: Vector3, toile: String, w: float = 3.2) -> Array:
	var yaw: float = atan2(face.x, face.z)
	var bs := Basis(Vector3.UP, yaw)
	b.box("bois", Transform3D(bs, at + bs * Vector3(0, 0.5, 0.3)), Vector3(w, 1.0, 0.7))
	b.box("metal", Transform3D(bs, at + bs * Vector3(0, 1.02, 0.3)), Vector3(w + 0.06, 0.04, 0.76))
	b.box("bois", Transform3D(bs, at + bs * Vector3(0, 0.9, -0.6)), Vector3(w, 1.8, 0.5))
	for sx in [-1.0, 1.0]:
		b.box("metal_noir", Transform3D(bs, at + bs * Vector3(sx * (w * 0.5 - 0.05), 1.3, 0.62)), Vector3(0.06, 2.6, 0.06))
		b.box("metal_noir", Transform3D(bs, at + bs * Vector3(sx * (w * 0.5 - 0.05), 1.3, -0.82)), Vector3(0.06, 2.6, 0.06))
	b.box(toile, Transform3D(bs.rotated(bs * Vector3.RIGHT, -0.22), at + bs * Vector3(0, 2.62, 0.0)), Vector3(w + 0.4, 0.05, 2.1))
	var lights: Array = []
	for k in range(3):
		var lp: Vector3 = at + bs * Vector3((k - 1) * w * 0.33, 2.25, 0.95)
		b.blob("lampe_chaude" if k != 1 else "neon_rouge", lp, Vector3(0.16, 0.2, 0.16), 8)
		lights.append(lp)
	# des bols, des marmites
	b.cyl_at("metal", at + bs * Vector3(-w * 0.25, 1.04, 0.25), 0.22, 0.24, 0.32, 10)
	b.cyl_at("peinture_blanche", at + bs * Vector3(w * 0.15, 1.04, 0.35), 0.1, 0.13, 0.08, 10)
	b.cyl_at("peinture_blanche", at + bs * Vector3(w * 0.3, 1.04, 0.3), 0.1, 0.13, 0.08, 10)
	return lights


## Une table ronde et quatre tabourets
static func table(b: Batch, at: Vector3) -> void:
	b.cyl_at("metal", at, 0.04, 0.04, 0.75, 6)
	b.cyl_at("plastique_rouge", at + Vector3.UP * 0.74, 0.45, 0.45, 0.04, 14)
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.4
		var s: Vector3 = at + Vector3(cos(a), 0, sin(a)) * 0.75
		b.cyl_at("metal", s, 0.03, 0.03, 0.45, 6)
		b.cyl_at("plastique_bleu", s + Vector3.UP * 0.44, 0.18, 0.18, 0.04, 10)


## Un conteneur (12 × 2,5 × 2,6 m), ses nervures
static func container(b: Batch, at: Vector3, yaw: float, couleur: String) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(couleur, Transform3D(bs, at + Vector3.UP * 1.3), Vector3(12.0, 2.6, 2.45))
	for k in range(13):
		var x: float = -5.9 + k * 0.98
		for sz in [-1.0, 1.0]:
			b.box(couleur, Transform3D(bs, at + bs * Vector3(x, 1.3, sz * 1.24)), Vector3(0.12, 2.5, 0.06))
	b.box("metal_noir", Transform3D(bs, at + bs * Vector3(6.02, 1.3, 0)), Vector3(0.05, 2.5, 2.3))


## Les toits : un climatiseur, une citerne
static func ac_unit(b: Batch, at: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box("metal", Transform3D(bs, at + Vector3.UP * 0.6), Vector3(2.2, 1.2, 1.4))
	b.cyl("plastique_noir", Transform3D(bs, at + Vector3.UP * 1.2), 0.5, 0.5, 0.05, 12)


static func water_tank(b: Batch, at: Vector3) -> void:
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.78
		b.box("metal_noir", Transform3D(Basis(), at + Vector3(cos(a) * 1.2, 1.0, sin(a) * 1.2)), Vector3(0.15, 2.0, 0.15))
	b.cyl_at("bois", at + Vector3.UP * 2.0, 1.5, 1.5, 3.0, 14)
	b.cyl_at("metal_noir", at + Vector3.UP * 5.0, 1.55, 0.1, 1.0, 14)


## Un cerisier en fleurs (le Jardin Zen)
static func cherry(b: Batch, at: Vector3, rng: RandomNumberGenerator, s: float = 1.0) -> void:
	var top: Vector3 = at + Vector3(rng.randf_range(-0.4, 0.4), 2.2 * s, rng.randf_range(-0.4, 0.4))
	b.tube("ecorce", at, top, 0.17 * s, 7)
	for k in range(5):
		var a: float = TAU * k / 5.0 + rng.randf() * 0.8
		var tip: Vector3 = top + Vector3(cos(a) * 1.7, rng.randf_range(0.3, 1.1), sin(a) * 1.7) * s
		b.tube("ecorce", top, tip, 0.07 * s, 5)
		# des grappes de fleurs (plusieurs petites boules, pas une grosse)
		for q in range(3):
			var o := Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.1, 0.5), rng.randf_range(-0.7, 0.7)) * s
			b.blob("sakura", tip + o, Vector3(0.75, 0.55, 0.75) * s * rng.randf_range(0.7, 1.15), 8)
	for q2 in range(5):
		var o2 := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.5, 1.4), rng.randf_range(-1.0, 1.0)) * s
		b.blob("sakura", top + o2, Vector3(0.9, 0.65, 0.9) * s * rng.randf_range(0.8, 1.2), 8)


# =================================================================== les maillages animés

## La carpe des hologrammes : un corps fuselé (tour de révolution), une queue, des nageoires.
## Elle nage vers +x.
static func koi_mesh(l: float = 8.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = 14
	var seg: int = 12
	var prof: Array = []
	for i in range(rings + 1):
		var t: float = float(i) / rings
		var r: float = sin(PI * pow(t, 0.75)) * 0.16 * l * (1.0 - 0.55 * t)
		prof.append([lerpf(0.5, -0.5, t) * l, maxf(r, 0.01)])
	for i in range(rings):
		for j in range(seg):
			var a0: float = TAU * j / seg
			var a1: float = TAU * (j + 1) / seg
			var p := []
			for c in [[i, a0], [i, a1], [i + 1, a1], [i + 1, a0]]:
				var e: Array = prof[c[0]]
				p.append(Vector3(float(e[0]), sin(c[1]) * float(e[1]) * 0.9, cos(c[1]) * float(e[1]) * 0.75))
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal((p[k] - Vector3(p[k].x, 0, 0)).normalized())
				st.add_vertex(p[k])
	# la queue (deux grands lobes) et les nageoires (cull désactivé dans le shader)
	var tail: float = -0.5 * l
	for v in [[Vector3(tail, 0, 0), Vector3(tail - 0.28 * l, 0.22 * l, 0), Vector3(tail - 0.18 * l, 0.02 * l, 0)],
			[Vector3(tail, 0, 0), Vector3(tail - 0.28 * l, -0.2 * l, 0), Vector3(tail - 0.18 * l, -0.02 * l, 0)],
			[Vector3(0.12 * l, -0.05 * l, 0.08 * l), Vector3(-0.02 * l, -0.12 * l, 0.22 * l), Vector3(0.02 * l, -0.05 * l, 0.08 * l)],
			[Vector3(0.12 * l, -0.05 * l, -0.08 * l), Vector3(-0.02 * l, -0.12 * l, -0.22 * l), Vector3(0.02 * l, -0.05 * l, -0.08 * l)],
			[Vector3(0.1 * l, 0.12 * l, 0), Vector3(-0.15 * l, 0.22 * l, 0), Vector3(-0.2 * l, 0.1 * l, 0)]]:
		for q in v:
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(q)
	return st.commit()


## La voiture volante : une coque fuselée, une bulle de verre, les phares, les feux, la lueur dessous.
## Chaque pièce est un maillage (posés en MultiMesh, une instance par voiture). Elle file vers +z.
static func car_meshes() -> Dictionary:
	var out := {}
	var b := Batch.new()
	b.blob("x", Vector3(0, 0, 0), Vector3(1.05, 0.42, 2.4), 12)
	b.box("x", Transform3D(Basis(), Vector3(0, -0.2, -0.6)), Vector3(2.5, 0.16, 1.2))       # les ailerons
	out["coque"] = _single(b)
	b.blob("x", Vector3(0, 0.3, 0.4), Vector3(0.7, 0.34, 1.0), 10)
	out["bulle"] = _single(b)
	b.box("x", Transform3D(Basis(), Vector3(0, 0.0, 2.3)), Vector3(1.2, 0.1, 0.1))
	out["phares"] = _single(b)
	b.box("x", Transform3D(Basis(), Vector3(0, 0.05, -2.33)), Vector3(1.5, 0.1, 0.08))
	out["feux"] = _single(b)
	b.box("x", Transform3D(Basis(), Vector3(0, -0.36, 0)), Vector3(1.3, 0.04, 3.4))
	out["lueur"] = _single(b)
	return out


static func _single(b: Batch) -> ArrayMesh:
	var st: SurfaceTool = b.sts["x"]
	st.index()
	var m: ArrayMesh = st.commit()
	b.sts.clear()
	return m


## Une voiture du monorail (12 m de long, vers +z) : la caisse blanche, la bande de fenêtres.
static func monorail_car(b: Batch) -> void:
	b.box("peinture_blanche", Transform3D(Basis(), Vector3(0, 1.5, 0)), Vector3(2.8, 2.6, 11.6))
	b.blob("peinture_blanche", Vector3(0, 1.5, 0), Vector3(1.4, 1.3, 6.1), 12)
	b.box("verre_fume", Transform3D(Basis(), Vector3(0, 1.85, 0)), Vector3(2.86, 0.9, 10.4))
	b.box("neon_cyan", Transform3D(Basis(), Vector3(0, 1.2, 0)), Vector3(2.84, 0.08, 11.0))
	b.box("metal_noir", Transform3D(Basis(), Vector3(0, 0.1, 0)), Vector3(1.4, 0.5, 10.0))

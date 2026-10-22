extends "res://scripts/carene_kit_v59.gd"
## V62 : les pièces de Ramure, le village des oreilles perché dans les arbres géants.
## Même principe que les autres kits (azur_kit_v56.gd, carene_kit_v59.gd) : la géométrie est
## regroupée par matériau, un seul maillage par matériau ; les collisions vont dans un seul
## corps statique. En plus :
##  - giant_tree : un tronc d'arbre géant (écorce en relief, lissé), ses contreforts (racines),
##    ses maîtresses branches et sa couronne de feuilles (cartes de feuillage, flora_v25.gd) ;
##  - deck : une plate-forme circulaire autour du tronc (planches, poutre de rive, jambes de
##    force, garde-corps), avec des ouvertures pour les ponts et la cage d'escalier ;
##  - spiral : un escalier en colimaçon autour du tronc (marches, rampe, garde-corps) ;
##  - rope_bridge : un pont de corde qui pend entre deux plates-formes ;
##  - round_hut : une cabane ronde en rondins, toit conique de chaume ;
##  - paper_lantern : une lanterne de papier (elles s'allument le soir).

const RM := "res://assets/textures/ramure/"
const Flora = preload("res://scripts/flora_v25.gd")

var _glow_keys: Dictionary = {}


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: StandardMaterial3D = null
	match key:
		"ecorce", "ecorce_racine":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "ecorce.png")
			m.normal_enabled = true
			m.normal_texture = load(RM + "ecorce_n.png")
			m.normal_scale = 1.4
			m.roughness = 0.95
			m.albedo_color = Color(1, 1, 1) if key == "ecorce" else Color(0.78, 0.86, 0.7)
		"planches_r", "planches_r_sombre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "planches.png")
			m.normal_enabled = true
			m.normal_texture = load(RM + "planches_n.png")
			m.roughness = 0.82
			m.albedo_color = Color(1, 1, 1) if key == "planches_r" else Color(0.55, 0.48, 0.42)
		"rondins":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "rondins.png")
			m.normal_enabled = true
			m.normal_texture = load(RM + "rondins_n.png")
			m.roughness = 0.9
		"chaume_r":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "chaume.png")
			m.normal_enabled = true
			m.normal_texture = load(RM + "chaume_n.png")
			m.normal_scale = 1.3
			m.roughness = 0.95
		"poutre":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "rondins.png")
			m.albedo_color = Color(0.62, 0.52, 0.42)
			m.roughness = 0.9
		"corde_r":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.5, 0.32)
			m.roughness = 0.95
		"bambou":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.62, 0.34)
			m.roughness = 0.6
		"papier", "papier_rouge", "papier_bleu":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "papier.png")
			m.albedo_color = {"papier": Color(1.0, 0.95, 0.85), "papier_rouge": Color(1.0, 0.55, 0.42), "papier_bleu": Color(0.7, 0.85, 1.0)}[key]
			m.emission_enabled = true
			m.emission = {"papier": Color(1.0, 0.6, 0.26), "papier_rouge": Color(1.0, 0.26, 0.1), "papier_bleu": Color(0.3, 0.58, 1.0)}[key]
			m.emission_texture = load(RM + "papier.png")
			m.emission_energy_multiplier = 0.0
			m.roughness = 0.85
			if temps != null:
				temps.register_glow(m, 1.5, 0.0)
		"fenetre_r":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.22, 0.18, 0.12)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.7, 0.38)
			m.emission_energy_multiplier = 0.0
			if temps != null:
				temps.register_glow(m, 1.8, 0.0)
		"porte_r":
			m = StandardMaterial3D.new()
			m.albedo_texture = load(RM + "planches.png")
			m.albedo_color = Color(0.42, 0.28, 0.18)
			m.roughness = 0.85
		"mousse":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.22, 0.34, 0.14)
			m.roughness = 1.0
		"champi_lune":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.82, 0.95)
			m.emission_enabled = true
			m.emission = Color(0.45, 0.75, 1.0)
			m.emission_energy_multiplier = 0.4
			m.roughness = 0.5
			if temps != null:
				temps.register_glow(m, 2.2, 0.4)
		"champi_rouge":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.72, 0.16, 0.1)
			m.roughness = 0.5
		"champi_pied":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.92, 0.9, 0.84)
			m.roughness = 0.7
		"feu":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.55, 0.15)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.45, 0.1)
			m.emission_energy_multiplier = 3.0
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"cendre":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.16, 0.14, 0.13)
			m.roughness = 1.0
		"peau_tambour":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.84, 0.7)
			m.roughness = 0.7
		"laque_rouge":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.66, 0.1, 0.08)
			m.roughness = 0.35
		"laque_noire":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.06, 0.05, 0.05)
			m.roughness = 0.35
		"carotte":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.92, 0.45, 0.12)
		"fanes":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.25, 0.52, 0.16)
		"terreau":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.22, 0.15, 0.1)
			m.roughness = 1.0
		"fer_r":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.16, 0.15, 0.15)
			m.metallic = 0.7
			m.roughness = 0.45
		"or_r":
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.9, 0.7, 0.3)
			m.metallic = 0.85
			m.roughness = 0.3
	# les étals de Carène (kit parent) : ici, du bois de Ramure plutôt que des planches d'épave peintes
	if m == null and key in ["cabane", "cabane_sombre"]:
		var mp: StandardMaterial3D = (mat("planches_r" if key == "cabane" else "planches_r_sombre") as StandardMaterial3D).duplicate()
		mp.albedo_color = Color(0.92, 0.84, 0.74) if key == "cabane" else Color(0.5, 0.43, 0.37)
		m = mp
	if m == null and (key.begins_with("noren_") or key in ["banniere_lune", "records"]):
		m = StandardMaterial3D.new()
		m.albedo_texture = load(RM + key + ".png")
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.9
	if m == null:
		return super.mat(key)
	mats[key] = m
	return m


# =================================================================== formes de base

## Un repère dont l'axe Y local suit a -> b.
func axis_xf(a: Vector3, b: Vector3) -> Transform3D:
	var y: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT
	var x: Vector3 = y.cross(ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), a)


## Une poutre (ou une corde) de section carrée entre deux points.
func beam(a: Vector3, b: Vector3, w: float, key: String, tile: float = 1.0) -> void:
	var L: float = a.distance_to(b)
	if L < 0.01:
		return
	var xf: Transform3D = axis_xf(a, b)
	box(Transform3D(xf.basis, (a + b) * 0.5), Vector3(w, L, w), key, tile)


## Une corde (cylindre fin) entre deux points.
func rope(a: Vector3, b: Vector3, r: float = 0.025) -> void:
	var L: float = a.distance_to(b)
	if L < 0.01:
		return
	cyl(axis_xf(a, b), r, r, L, "corde_r", 5, false, 1.0)


## Point sur un cercle horizontal (angle en degrés : 0 = +X, 90 = +Z).
static func ring_pt(c: Vector3, r: float, a_deg: float, y: float) -> Vector3:
	var a: float = deg_to_rad(a_deg)
	return Vector3(c.x + cos(a) * r, y, c.z + sin(a) * r)


# =================================================================== l'arbre géant

## Le tronc, ses racines, ses branches maîtresses (un maillage lissé, à part), sa collision et
## sa couronne de feuilles. base : le pied (monde). skip : angles (°) sans racine (le départ
## de l'escalier). Renvoie le nœud du feuillage (pour la carte et les ombres).
func giant_tree(t: Dictionary, base: Vector3, skip: Array, seed_value: int) -> void:
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var H: float = float(t["h"])
	var R0: float = float(t["r"])
	# le tronc : 18 anneaux, 22 côtés, l'écorce enroulée (une tuile d'écorce tous les 3 m)
	var path: Array = []
	var radii: Array = []
	var n: int = 18
	for i in range(n + 1):
		var y: float = H * 0.86 * float(i) / n
		var wob := Vector3(sin(y * 0.11 + seed_value) * 0.35, 0.0, cos(y * 0.09 + seed_value * 0.7) * 0.35) * clampf(y / 20.0, 0.0, 1.0)
		path.append(base + Vector3.UP * (y - 1.5) + wob)
		var rr: float = (Relief.trunk_r(t, y) if y > 0.5 else R0 * 1.18)
		if y < 3.0:
			rr *= 1.0 + 0.18 * (1.0 - y / 3.0)
		radii.append(rr)
	_tube(st, path, radii, 22, roundf(R0 * 2.1), 0.33, rng2)
	# les contreforts : des racines qui s'écartent du pied et plongent dans le sol
	var nr: int = 7
	for k in range(nr):
		var a: float = 360.0 * k / nr + rng2.randf_range(-12.0, 12.0)
		var bad: bool = false
		for s in skip:
			# pas de racine sous le bas de l'escalier (il tourne dans le sens des angles croissants)
			var da: float = wrapf(a - float(s), -180.0, 180.0)
			if da > -40.0 and da < 110.0:
				bad = true
		if bad:
			continue
		var dir := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		var reach: float = R0 * rng2.randf_range(0.5, 0.7) + 1.0
		var rp: Array = [base + dir * R0 * 0.55 + Vector3.UP * 4.5, base + dir * (R0 + reach * 0.35) + Vector3.UP * 1.6,
			base + dir * (R0 + reach * 0.8) + Vector3.UP * 0.2, base + dir * (R0 + reach * 1.15) + Vector3.DOWN * 0.8]
		var rr2: Array = [R0 * 0.42, R0 * 0.3, R0 * 0.17, R0 * 0.08]
		_tube(st, rp, rr2, 10, 3.0, 0.33, rng2)
		col_box(Transform3D(axis_xf(rp[1], rp[2]).basis, (rp[1] + rp[2]) * 0.5), Vector3(R0 * 0.36, rp[1].distance_to(rp[2]), R0 * 0.36))
	# les branches maîtresses, au-dessus des plates-formes, qui portent la couronne
	var limbs: Array = []
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0 + rng2.randf_range(-0.3, 0.3)
		var y0: float = H * rng2.randf_range(0.6, 0.78)
		var start: Vector3 = base + Vector3.UP * y0
		var dir2 := Vector3(cos(a2), rng2.randf_range(0.35, 0.7), sin(a2)).normalized()
		var L: float = H * rng2.randf_range(0.22, 0.3)
		var lp: Array = [start, start + dir2 * L * 0.35 + Vector3.UP * 0.6, start + dir2 * L * 0.7 + Vector3.UP * 1.6, start + dir2 * L + Vector3.UP * 3.0]
		var lr: Array = [R0 * 0.32, R0 * 0.22, R0 * 0.13, R0 * 0.05]
		_tube(st, lp, lr, 9, 2.0, 0.33, rng2)
		limbs.append(lp)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Tronc_" + str(t["id"])
	mi.mesh = st.commit()
	mi.material_override = mat("ecorce")
	mi.visibility_range_end = 1200.0
	root.add_child(mi)
	col_cyl(base + Vector3.DOWN * 2.0, R0 * 0.98, H * 0.86)
	# la couronne : des cartes de feuillage au bout des branches et au sommet
	var leaf := SurfaceTool.new()
	leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crown_c: Vector3 = base + Vector3.UP * H * 0.86
	var crown_r: float = H * 0.34
	var budget: int = int(H * (14.0 if pc_quality else 8.0))
	for c in range(budget):
		var p: Vector3
		if c % 3 == 0 or limbs.is_empty():
			var d := Vector3(rng2.randf_range(-1, 1), rng2.randf_range(-0.35, 0.7), rng2.randf_range(-1, 1)).normalized()
			p = crown_c + Vector3(d.x * crown_r, d.y * crown_r * 0.55, d.z * crown_r) * rng2.randf_range(0.55, 1.0)
		else:
			var lp2: Array = limbs[c % limbs.size()]
			var tt: float = rng2.randf_range(0.45, 1.0)
			var seg: float = tt * 3.0
			var i0: int = mini(int(seg), 2)
			var bp: Vector3 = (lp2[i0] as Vector3).lerp(lp2[i0 + 1], seg - i0)
			p = bp + Vector3(rng2.randf_range(-1, 1), rng2.randf_range(-0.5, 1.2), rng2.randf_range(-1, 1)) * rng2.randf_range(1.5, 4.5)
		Flora._card(leaf, p, rng2.randf_range(2.6, 4.2), Flora._random_basis(rng2), crown_c, crown_r, 0.15)
	var lm := MeshInstance3D.new()
	lm.name = "Couronne_" + str(t["id"])
	var mesh := ArrayMesh.new()
	leaf.commit(mesh)
	mesh.surface_set_material(0, Flora.leaf_material())
	lm.mesh = mesh
	lm.visibility_range_end = 1400.0
	root.add_child(lm)


var pc_quality: bool = true
const Relief = preload("res://scripts/ramure_relief_v62.gd")


## Un tube lisse le long d'un chemin (anneaux de `sides` côtés), UV : u autour (u_tiles fois),
## v le long (v_scale par mètre). Un peu de bosses pour casser le cylindre.
func _tube(st: SurfaceTool, path: Array, radii: Array, sides: int, u_tiles: float, v_scale: float, r: RandomNumberGenerator) -> void:
	var rings: Array = []
	var vacc: float = 0.0
	for i in range(path.size()):
		var p: Vector3 = path[i]
		var fwd: Vector3
		if i == 0:
			fwd = (path[1] - path[0]).normalized()
		elif i == path.size() - 1:
			fwd = (path[i] - path[i - 1]).normalized()
		else:
			fwd = (path[i + 1] - path[i - 1]).normalized()
		var ref: Vector3 = Vector3.UP if absf(fwd.y) < 0.9 else Vector3.RIGHT
		var side: Vector3 = fwd.cross(ref).normalized()
		var up: Vector3 = side.cross(fwd).normalized()
		if i > 0:
			vacc += (path[i] as Vector3).distance_to(path[i - 1])
		var ring: Array = []
		for s in range(sides + 1):
			var a: float = TAU * s / sides
			var bump: float = 1.0 + 0.06 * sin(a * 5.0 + i * 1.3) + 0.04 * sin(a * 11.0 - i * 0.7)
			var off: Vector3 = (side * cos(a) + up * sin(a)) * float(radii[i]) * bump
			ring.append([p + off, Vector2(u_tiles * float(s) / sides, vacc * v_scale)])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a0: Array = rings[i][s]
			var a1: Array = rings[i][s + 1]
			var b0: Array = rings[i + 1][s]
			var b1: Array = rings[i + 1][s + 1]
			for v in [a0, b1, b0, a0, a1, b1]:
				st.set_uv(v[1])
				st.add_vertex(v[0])


# =================================================================== plates-formes

## Une plate-forme autour du tronc : 24 secteurs de 15°. ri : rayon intérieur (le tronc),
## ro : rayon extérieur. stair_open : [a0, a1] (°) où la cage d'escalier perce le plancher
## (on y garde seulement la bande extérieure, au-delà de stair_band). gaps : angles (°) sans
## garde-corps (ponts, ascenseur, tyrolienne), avec leur demi-largeur en mètres.
func deck(c: Vector3, ri: float, ro: float, stair_open: Array, stair_band: float, gaps: Array) -> void:
	var th: float = 0.28
	var uv := func(p: Vector3) -> Vector2: return Vector2(p.x, p.z) * 0.42
	var dn := Vector3.DOWN * th
	for k in range(24):
		var a0: float = k * 15.0
		var a1: float = a0 + 15.0
		var am: float = a0 + 7.5
		var bas := Basis(Vector3.UP, -deg_to_rad(am))      # X local -> radial
		# le secteur, coupé exactement là où la cage d'escalier perce le plancher
		var parts: Array = [[a0, a1, ri]]
		var near_stair: bool = false
		if not stair_open.is_empty():
			var o0: float = float(stair_open[0])
			var o1: float = float(stair_open[1])
			var om: float = am + wrapf((o0 + o1) * 0.5 - am, -180.0, 180.0)
			var half: float = (o1 - o0) * 0.5
			var b0: float = om - half
			var b1: float = om + half
			near_stair = _arc_hits(a0, a1, b0 - 50.0, b1)
			if b1 > a0 and b0 < a1:
				var s0: float = clampf(b0, a0, a1)
				var s1: float = clampf(b1, a0, a1)
				parts = []
				if s0 - a0 > 0.01:
					parts.append([a0, s0, ri])
				parts.append([s0, s1, ri + stair_band])
				if a1 - s1 > 0.01:
					parts.append([s1, a1, ri])
		for pt in parts:
			var pa0: float = float(pt[0])
			var pa1: float = float(pt[1])
			var inner: float = float(pt[2])
			var p00: Vector3 = ring_pt(c, inner, pa0, c.y)
			var p01: Vector3 = ring_pt(c, ro, pa0, c.y)
			var p11: Vector3 = ring_pt(c, ro, pa1, c.y)
			var p10: Vector3 = ring_pt(c, inner, pa1, c.y)
			quad4("planches_r", p00, p01, p11, p10, Vector3.UP, uv.call(p00), uv.call(p01), uv.call(p11), uv.call(p10))
			quad4("planches_r_sombre", p00 + dn, p10 + dn, p11 + dn, p01 + dn, Vector3.DOWN, uv.call(p00), uv.call(p10), uv.call(p11), uv.call(p01))
			var pm: float = (pa0 + pa1) * 0.5
			if inner > ri + 0.01:
				var inn: Vector3 = -ring_pt(Vector3.ZERO, 1.0, pm, 0.0)
				quad4("poutre", p00 + dn, p10 + dn, p10, p00, inn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2))
			# la collision du morceau : une boîte droite déborde de son secteur vers le tronc ; près
			# du tronc (là où passe l'escalier), on la découpe en tranches étroites
			var half_p: float = deg_to_rad((pa1 - pa0) * 0.5)
			var bas_p := Basis(Vector3.UP, -deg_to_rad(pm))
			var r_split: float = ri + stair_band + 0.05
			var r_from: float = inner
			if inner < r_split - 0.01:
				for q in range(4):
					var r0q: float = lerpf(inner, r_split, q / 4.0)
					var r1q: float = lerpf(inner, r_split, (q + 1) / 4.0)
					col_box(Transform3D(bas_p, ring_pt(c, (r0q + r1q) * 0.5, pm, c.y - th * 0.5)), Vector3(r1q - r0q, th, 2.0 * r1q * sin(half_p) + 0.04))
				r_from = r_split
			col_box(Transform3D(bas_p, ring_pt(c, (r_from + ro) * 0.5, pm, c.y - th * 0.5)), Vector3(ro - r_from, th, 2.0 * ro * sin(half_p) + 0.08))
		# autour de la trémie de l'escalier, un garde-corps (on ne tombe pas dans le trou) : le
		# long du bord extérieur du trou, et en travers à son début ; la sortie reste ouverte
		if not stair_open.is_empty():
			var o0b: float = float(stair_open[0])
			var o1b: float = float(stair_open[1])
			var omb: float = am + wrapf((o0b + o1b) * 0.5 - am, -180.0, 180.0)
			var hb: float = (o1b - o0b) * 0.5
			var g0: float = maxf(omb - hb, a0)
			var g1: float = minf(omb + hb - 14.0, a1)
			if g1 > g0 + 0.3:
				var rr: float = ri + stair_band + 0.05
				var e0: Vector3 = ring_pt(c, rr, g0, c.y)
				var e1: Vector3 = ring_pt(c, rr, g1, c.y)
				beam(e0 + Vector3.UP * 1.0, e1 + Vector3.UP * 1.0, 0.08, "poutre")
				beam(e0 + Vector3.UP * 0.5, e1 + Vector3.UP * 0.5, 0.05, "poutre")
				box(Transform3D(Basis(Vector3.UP, -deg_to_rad(g0)), e0 + Vector3.UP * 0.5), Vector3(0.09, 1.0, 0.09), "poutre", 1.0)
				var gm: float = (g0 + g1) * 0.5
				col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(gm)), ring_pt(c, rr, gm, c.y + 0.6)), Vector3(0.1, 1.2, 2.0 * rr * sin(deg_to_rad((g1 - g0) * 0.5)) + 0.04))
			if omb - hb >= a0 and omb - hb < a1:
				var s0: Vector3 = ring_pt(c, ri, omb - hb, c.y)
				var s1: Vector3 = ring_pt(c, ri + stair_band + 0.05, omb - hb, c.y)
				beam(s0 + Vector3.UP * 1.0, s1 + Vector3.UP * 1.0, 0.08, "poutre")
				col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(omb - hb)), (s0 + s1) * 0.5 + Vector3.UP * 0.6), Vector3(stair_band + 0.1, 1.2, 0.1))
		var p01b: Vector3 = ring_pt(c, ro, a0, c.y)
		var p11b: Vector3 = ring_pt(c, ro, a1, c.y)
		var tw: float = 2.0 * ro * sin(deg_to_rad(7.5)) + 0.08
		# la poutre de rive
		var rn: Vector3 = ring_pt(Vector3.ZERO, 1.0, am, 0.0)
		quad4("poutre", p01b + dn * 1.6, p11b + dn * 1.6, p11b + Vector3.UP * 0.04, p01b + Vector3.UP * 0.04, rn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.35), Vector2(0, 0.35))
		# les jambes de force (une sur deux), du tronc au bord, sous le plancher (pas au-dessus
		# de l'escalier qui arrive)
		if k % 2 == 0 and not near_stair:
			beam(ring_pt(c, ri + 0.2, am, c.y - 3.6), ring_pt(c, ro - 0.5, am, c.y - th * 1.2), 0.22, "poutre")
		# le garde-corps (sauf devant les ponts)
		var open: bool = false
		for g in gaps:
			var ga: float = float(g[0])
			var half_deg: float = rad_to_deg(float(g[1]) / ro)
			if _arc_hits(a0, a1, ga - half_deg, ga + half_deg):
				open = true
		if not open:
			var q0: Vector3 = ring_pt(c, ro - 0.12, a0, c.y)
			var q1: Vector3 = ring_pt(c, ro - 0.12, a1, c.y)
			beam(q0 + Vector3.UP * 1.0, q1 + Vector3.UP * 1.0, 0.09, "poutre")
			beam(q0 + Vector3.UP * 0.55, q1 + Vector3.UP * 0.55, 0.06, "poutre")
			for q in [q0, (q0 + q1) * 0.5]:
				box(Transform3D(bas, (q as Vector3) + Vector3.UP * 0.5), Vector3(0.1, 1.0, 0.1), "poutre", 1.0)
			col_box(Transform3D(bas, ring_pt(c, ro - 0.12, am, c.y + 0.6)), Vector3(0.14, 1.2, tw))


## Les arcs [a0, a1] et [b0, b1] (en degrés, n'importe quel tour) se recouvrent-ils ?
static func _arc_hits(a0: float, a1: float, b0: float, b1: float) -> bool:
	var am: float = (a0 + a1) * 0.5
	var bm: float = (b0 + b1) * 0.5
	var d: float = absf(wrapf(am - bm, -180.0, 180.0))
	return d < (a1 - a0) * 0.5 + (b1 - b0) * 0.5


# =================================================================== l'escalier en colimaçon

## Un escalier autour du tronc, de y0 à y1 (monde), en partant de l'angle a0 (°), en tournant
## dans le sens des angles croissants. Renvoie [angle d'arrivée (°), points pour les gens].
## t : l'arbre (pour le rayon du tronc), base : le pied.
func spiral(t: Dictionary, base: Vector3, y0: float, y1: float, a0: float) -> Array:
	var rise: float = y1 - y0
	var r_mid0: float = Relief.trunk_r(t, y0 - base.y) + 0.9
	var span_deg: float = rad_to_deg(rise / 0.55 / r_mid0)
	var n: int = int(ceil(rise / 0.21))
	var pts: Array = []
	for i in range(n):
		var u: float = (i + 0.5) / n
		var a: float = a0 + span_deg * u
		var y: float = y0 + rise * (i + 1.0) / n
		var ri: float = Relief.trunk_r(t, y - base.y) + 0.12
		var ro: float = ri + 1.5
		var rm: float = (ri + ro) * 0.5
		var step_len: float = deg_to_rad(span_deg / n) * rm * 1.25
		var bas := Basis(Vector3.UP, -deg_to_rad(a))
		box(Transform3D(bas, ring_pt(base, rm, a, y - 0.04)), Vector3(1.5, 0.08, step_len), "planches_r", 1.0)
		if i % 5 == 0:
			beam(ring_pt(base, ri - 0.1, a, y - 0.9), ring_pt(base, ro - 0.2, a, y - 0.1), 0.12, "poutre")
	# la rampe (collision), le garde-corps, les points du chemin
	var seg_deg: float = 12.0
	var ns: int = int(ceil(span_deg / seg_deg))
	var prev_top: Vector3 = Vector3.ZERO
	for j in range(ns + 1):
		var u2: float = float(j) / ns
		var a2: float = a0 + span_deg * u2
		var y2: float = y0 + rise * u2
		var rm2: float = Relief.trunk_r(t, y2 - base.y) + 0.9
		var top: Vector3 = ring_pt(base, rm2, a2, y2)
		if j % 1 == 0:
			pts.append(top)
		if j > 0:
			var a_prev: float = a0 + span_deg * float(j - 1) / ns
			var y_prev: float = y0 + rise * float(j - 1) / ns
			var f: Vector3 = top - prev_top
			var L: float = f.length()
			var fd: Vector3 = f / L
			var radial: Vector3 = ring_pt(Vector3.ZERO, 1.0, (a2 + a_prev) * 0.5, 0.0)
			var up: Vector3 = fd.cross(radial).normalized()
			if up.y < 0.0:
				up = -up
			var side: Vector3 = fd.cross(up).normalized()
			col_box(Transform3D(Basis(side, up, -fd), (top + prev_top) * 0.5 - up * 0.16), Vector3(1.5, 0.3, L * 1.04))
			# le garde-corps extérieur
			var ro_a: float = Relief.trunk_r(t, y_prev - base.y) + 1.6
			var ro_b: float = Relief.trunk_r(t, y2 - base.y) + 1.6
			var ga: Vector3 = ring_pt(base, ro_a, a_prev, y_prev)
			var gb: Vector3 = ring_pt(base, ro_b, a2, y2)
			beam(ga + Vector3.UP * 1.0, gb + Vector3.UP * 1.0, 0.07, "poutre")
			rope(ga + Vector3.UP * 0.55, gb + Vector3.UP * 0.55, 0.02)
			box(Transform3D(Basis(Vector3.UP, -deg_to_rad(a_prev)), ga + Vector3.UP * 0.5), Vector3(0.08, 1.0, 0.08), "poutre", 1.0)
			var wall_c: Vector3 = (ga + gb) * 0.5 + Vector3.UP * 0.75
			col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad((a_prev + a2) * 0.5)), wall_c), Vector3(0.12, absf(gb.y - ga.y) + 1.5, ga.distance_to(gb) * 1.02))
		prev_top = top
	return [a0 + span_deg, pts]


# =================================================================== ponts de corde

## Un pont de corde de a à b (planchers, monde), qui pend de `sag` mètres au milieu.
## Renvoie les points du chemin (pour les gens), tous les 3 m environ.
func rope_bridge(a: Vector3, b: Vector3, sag: float) -> Array:
	var flat: Vector3 = (b - a) * Vector3(1, 0, 1)
	var L: float = flat.length()
	var f: Vector3 = flat / L
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	var curve := func(t: float, s: float) -> Vector3: return a.lerp(b, t) + Vector3.DOWN * s * sin(t * PI)
	# les planches (avec de petits jours), sur deux longerons de corde
	var n: int = int(L / 0.38)
	for i in range(n + 1):
		var t: float = float(i) / n
		var p: Vector3 = curve.call(t, sag)
		var p2: Vector3 = curve.call(clampf(t + 0.01, 0.0, 1.0), sag)
		var p1: Vector3 = curve.call(clampf(t - 0.01, 0.0, 1.0), sag)
		var tan: Vector3 = (p2 - p1).normalized()
		var up: Vector3 = side.cross(tan).normalized()
		if up.y < 0.0:
			up = -up
		var jitter: float = sin(i * 2.3) * 0.03
		box(Transform3D(Basis(side, up, -tan).rotated(up, jitter), p + Vector3.DOWN * 0.03), Vector3(1.5, 0.05, 0.3), "planches_r", 1.0)
	# les cordes : deux longerons sous les planches, deux mains courantes, des suspentes
	var m: int = 16
	for i2 in range(m):
		var ta: float = float(i2) / m
		var tb: float = float(i2 + 1) / m
		for sd in [-0.7, 0.7]:
			rope(curve.call(ta, sag) + side * sd + Vector3.DOWN * 0.08, curve.call(tb, sag) + side * sd + Vector3.DOWN * 0.08, 0.035)
			var ha: Vector3 = curve.call(ta, sag * 0.7) + side * (sd * 1.22) + Vector3.UP * 1.05
			var hb: Vector3 = curve.call(tb, sag * 0.7) + side * (sd * 1.22) + Vector3.UP * 1.05
			rope(ha, hb, 0.035)
			rope(ha, curve.call(ta, sag) + side * sd, 0.015)
	# collision : le tablier et deux parois (on ne tombe pas du pont)
	var cs: int = 10
	var pts: Array = []
	for j in range(cs):
		var ta2: float = float(j) / cs
		var tb2: float = float(j + 1) / cs
		var pa: Vector3 = curve.call(ta2, sag)
		var pb: Vector3 = curve.call(tb2, sag)
		var fd: Vector3 = (pb - pa).normalized()
		var up2: Vector3 = side.cross(fd).normalized()
		if up2.y < 0.0:
			up2 = -up2
		var sd2: Vector3 = fd.cross(up2).normalized()
		col_box(Transform3D(Basis(sd2, up2, -fd), (pa + pb) * 0.5 - up2 * 0.14), Vector3(1.6, 0.28, pa.distance_to(pb) * 1.04))
		for s3 in [-0.95, 0.95]:
			col_box(Transform3D(Basis(sd2, up2, -fd), (pa + pb) * 0.5 + side * s3 + up2 * 0.6), Vector3(0.12, 1.3, pa.distance_to(pb) * 1.04))
	var np: int = maxi(2, int(L / 3.0))
	for k in range(np + 1):
		pts.append(curve.call(float(k) / np, sag))
	return pts


## Où accrocher une lanterne le long d'un pont (sur la main courante).
static func bridge_rail_point(a: Vector3, b: Vector3, sag: float, t: float, sd: float) -> Vector3:
	var flat: Vector3 = (b - a) * Vector3(1, 0, 1)
	var side: Vector3 = flat.normalized().cross(Vector3.UP).normalized()
	return a.lerp(b, t) + Vector3.DOWN * sag * 0.7 * sin(t * PI) + side * (sd * 1.22) + Vector3.UP * 1.05


# =================================================================== cabanes

## Une cabane ronde en rondins (c : le centre du plancher), toit conique de chaume. La porte
## regarde `door_dir` (horizontal). Renvoie le point devant la porte.
func round_hut(c: Vector3, r: float, h: float, door_dir: Vector3, opts: Dictionary = {}) -> Vector3:
	var dd: Vector3 = (door_dir * Vector3(1, 0, 1)).normalized()
	cyl(Transform3D(Basis(), c), r, r, h, "rondins", 18, false, 1.2)
	disc(Transform3D(Basis(), c + Vector3.UP * 0.02), r - 0.05, "planches_r", 18)
	col_cyl(c, r, h + 0.3)
	var roof_h: float = float(opts.get("toit_h", r * 1.15))
	var over: float = 0.55
	cyl(Transform3D(Basis(), c + Vector3.UP * h), r + over, 0.06, roof_h, "chaume_r", 18, false, 1.0)
	cyl(Transform3D(Basis(), c + Vector3.UP * (h - 0.05)), r + over, r + over, 0.1, "poutre", 18, false)
	# un épi de bois au sommet
	cyl(Transform3D(Basis(), c + Vector3.UP * (h + roof_h - 0.2)), 0.08, 0.04, 0.7, "poutre", 6)
	# la porte (cadre et battant), deux fenêtres rondes qui s'éclairent le soir
	var yaw: float = atan2(dd.x, dd.z)
	var dxf := Transform3D(Basis(Vector3.UP, yaw), c + dd * (r + 0.02) + Vector3.UP * 0.95)
	box(dxf, Vector3(0.9, 1.9, 0.06), "porte_r", 1.0)
	box(dxf * Transform3D(Basis(), Vector3(0, 1.0, 0.03)), Vector3(1.1, 0.14, 0.12), "poutre", 1.0)
	for sx in [-0.6, 0.6]:
		box(dxf * Transform3D(Basis(), Vector3(sx, 0.0, 0.03)), Vector3(0.12, 2.0, 0.12), "poutre", 1.0)
	for side_a in [70.0, -70.0]:
		var wd: Vector3 = dd.rotated(Vector3.UP, deg_to_rad(side_a))
		var wxf := Transform3D(Basis(Vector3.UP, atan2(wd.x, wd.z)) * Basis(Vector3.RIGHT, PI * 0.5), c + wd * (r + 0.03) + Vector3.UP * 1.45)
		cyl(wxf, 0.32, 0.32, 0.04, "fenetre_r", 12)
		cyl(wxf, 0.38, 0.38, 0.02, "poutre", 12, false)
	if opts.has("noren"):
		var nxf := Transform3D(Basis(Vector3.UP, yaw + PI), c + dd * (r + 0.12) + Vector3.UP * 1.62)
		quad(nxf, 1.15, 1.15, str(opts["noren"]), Vector2(0, 0), Vector2(1, 1), true)
	if bool(opts.get("lanterne", true)):
		paper_lantern(c + dd * (r + 0.35) + dd.cross(Vector3.UP) * 0.9 + Vector3.UP * 2.25, 0.85, "papier_rouge")
	return c + dd * (r + 0.7)


# =================================================================== lanternes

## Une lanterne de papier ronde (pos : son centre), suspendue à une petite corde.
func paper_lantern(pos: Vector3, s: float = 1.0, key: String = "papier") -> void:
	var xf := Transform3D(Basis().scaled(Vector3(1.0, 1.25, 1.0) * s), pos)
	var mesh_r: float = 0.22
	# une sphère en 8 fuseaux (le papier), deux couvercles de bois laqué
	var seg: int = 8
	var rings: int = 6
	for i in range(rings):
		var v0: float = PI * i / rings
		var v1: float = PI * (i + 1) / rings
		for j in range(seg):
			var u0: float = TAU * j / seg
			var u1: float = TAU * (j + 1) / seg
			var P := func(u: float, v: float) -> Vector3: return xf * (Vector3(cos(u) * sin(v), cos(v), sin(u) * sin(v)) * mesh_r)
			var N := func(u: float, v: float) -> Vector3: return Vector3(cos(u) * sin(v), cos(v), sin(u) * sin(v))
			var nn: Vector3 = N.call((u0 + u1) * 0.5, (v0 + v1) * 0.5)
			quad4(key, P.call(u0, v0), P.call(u1, v0), P.call(u1, v1), P.call(u0, v1), nn,
				Vector2(float(j) / seg, float(i) / rings), Vector2(float(j + 1) / seg, float(i) / rings), Vector2(float(j + 1) / seg, float(i + 1) / rings), Vector2(float(j) / seg, float(i + 1) / rings))
	cyl(Transform3D(Basis(), pos + Vector3.UP * (mesh_r * 1.2 * s)), 0.09 * s, 0.09 * s, 0.05 * s, "laque_noire", 8)
	cyl(Transform3D(Basis(), pos + Vector3.DOWN * (mesh_r * 1.25 * s + 0.04 * s)), 0.08 * s, 0.08 * s, 0.05 * s, "laque_noire", 8)
	rope(pos + Vector3.UP * (mesh_r * 1.25 * s + 0.02), pos + Vector3.UP * (mesh_r * 1.25 * s + 0.35), 0.01)


## Une guirlande de lanternes le long d'une corde (a -> b), qui pend.
func lantern_string(a: Vector3, b: Vector3, sag: float, count: int, keys: Array) -> void:
	var prev: Vector3 = a
	var m: int = 10
	for i in range(1, m + 1):
		var t: float = float(i) / m
		var p: Vector3 = a.lerp(b, t) + Vector3.DOWN * sag * sin(t * PI)
		rope(prev, p, 0.012)
		prev = p
	for k in range(count):
		var t2: float = (k + 1.0) / (count + 1.0)
		var p2: Vector3 = a.lerp(b, t2) + Vector3.DOWN * (sag * sin(t2 * PI) + 0.4)
		paper_lantern(p2, 0.7, str(keys[k % keys.size()]))


## Un poteau de bambou avec une lanterne pendue à une potence (le long des allées).
func lantern_post(base: Vector3, yaw: float, key: String = "papier") -> void:
	cyl(Transform3D(Basis(), base), 0.07, 0.06, 2.6, "bambou", 6)
	var arm: Vector3 = Vector3(sin(yaw), 0, cos(yaw)) * 0.7
	beam(base + Vector3.UP * 2.5, base + Vector3.UP * 2.5 + arm, 0.05, "bambou")
	paper_lantern(base + Vector3.UP * 2.05 + arm, 0.8, key)


# =================================================================== mobilier du village

## Un banc de rondin (fendu), posé sur deux souches.
func log_bench(xf: Transform3D, w: float = 2.0) -> void:
	# le rondin couché (le dessus à 46 cm), calé sur deux billots bas
	cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(w * 0.5, 0.25, 0)), 0.21, 0.21, w, "rondins", 10, true, 1.0)
	for sx in [-w * 0.35, w * 0.35]:
		cyl(xf * Transform3D(Basis(), Vector3(sx, 0.0, 0)), 0.2, 0.22, 0.1, "poutre", 8)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.23, 0)), Vector3(w, 0.46, 0.42))


## Un tambour de festival (taiko) sur son support.
func taiko(xf: Transform3D, r: float = 0.55) -> void:
	var dxf: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.95, -r * 0.75))
	cyl(dxf, r, r, r * 1.5, "laque_rouge", 18, false)
	for yy in [-0.02, r * 1.5 - 0.02]:
		cyl(dxf * Transform3D(Basis(), Vector3(0, yy, 0)), r + 0.03, r + 0.03, 0.04, "peau_tambour", 18)
	for sx in [-0.45, 0.45]:
		beam(xf * Vector3(sx, 0, -0.3), xf * Vector3(sx * 0.6, 0.75, 0.0), 0.08, "laque_noire")
		beam(xf * Vector3(sx, 0, 0.3), xf * Vector3(sx * 0.6, 0.75, 0.0), 0.08, "laque_noire")
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.8, 0)), Vector3(1.2, 1.6, 1.2))


## Une arche de la Grande Course : deux poteaux laqués rouges, deux traverses (un torii de
## forêt), des lanternes, un numéro.
func race_arch(c: Vector3, yaw: float, w: float = 4.6) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), c)
	for sx in [-w * 0.5, w * 0.5]:
		cyl(xf * Transform3D(Basis(), Vector3(sx, -0.4, 0)), 0.16, 0.18, 4.6, "laque_rouge", 10)
		col_cyl(xf * Vector3(sx, -0.4, 0), 0.18, 4.6)
	box(xf * Transform3D(Basis(), Vector3(0, 3.9, 0)), Vector3(w + 1.4, 0.24, 0.32), "laque_noire", 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 3.35, 0)), Vector3(w + 0.4, 0.18, 0.22), "laque_rouge", 1.0)
	for k in range(3):
		paper_lantern(xf * Vector3(-w * 0.32 + k * w * 0.32, 2.85, 0.0), 0.75, "papier" if k != 1 else "papier_rouge")


## Un feu de camp entouré de pierres (c : centre au sol). Renvoie le point des flammes.
func bonfire(c: Vector3) -> Vector3:
	for k in range(12):
		var a: float = TAU * k / 12.0
		var p: Vector3 = c + Vector3(cos(a) * 1.15, 0.05, sin(a) * 1.15)
		cyl(Transform3D(Basis(Vector3.UP, a), p), 0.22, 0.26, 0.28, "pierre", 6)
	disc(Transform3D(Basis(), c + Vector3.UP * 0.04), 1.0, "cendre", 14)
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0
		beam(c + Vector3(cos(a2) * 0.9, 0.1, sin(a2) * 0.9), c + Vector3(0, 1.1, 0), 0.14, "poutre")
	col_cyl(c, 1.35, 0.4)
	return c + Vector3.UP * 0.5


## Un rang de carottes (le jardin des lapins).
func carrot_row(a: Vector3, b: Vector3) -> void:
	var L: float = a.distance_to(b)
	var f: Vector3 = (b - a) / L
	var side: Vector3 = f.cross(Vector3.UP).normalized()
	box(Transform3D(Basis(side, Vector3.UP, -f), (a + b) * 0.5 + Vector3.UP * 0.08), Vector3(0.7, 0.16, L), "terreau", 1.0)
	var n: int = int(L / 0.35)
	for i in range(n):
		var p: Vector3 = a + f * (i + 0.5) * 0.35 + Vector3.UP * 0.16
		cyl(Transform3D(Basis(), p + Vector3.DOWN * 0.05), 0.04, 0.01, 0.1, "carotte", 5)
		for k in range(3):
			var leaf: Vector3 = Vector3(cos(k * 2.1 + i), 2.2, sin(k * 2.1 + i)).normalized() * 0.28
			beam(p + Vector3.UP * 0.05, p + Vector3.UP * 0.05 + leaf, 0.03, "fanes")


## Un champignon géant de la forêt (décor ; les « lune » brillent la nuit).
func big_mushroom(c: Vector3, h: float, r: float, lune: bool) -> void:
	cyl(Transform3D(Basis(), c), r * 0.22, r * 0.3, h, "champi_pied", 10)
	var cap := Transform3D(Basis().scaled(Vector3(1.0, 0.45, 1.0)), c + Vector3.UP * h)
	var key: String = "champi_lune" if lune else "champi_rouge"
	var seg: int = 12
	for i in range(4):
		var v0: float = PI * 0.5 * i / 4
		var v1: float = PI * 0.5 * (i + 1) / 4
		for j in range(seg):
			var u0: float = TAU * j / seg
			var u1: float = TAU * (j + 1) / seg
			var P := func(u: float, v: float) -> Vector3: return cap * (Vector3(cos(u) * sin(PI * 0.5 - v), cos(PI * 0.5 - v), sin(u) * sin(PI * 0.5 - v)) * r)
			var nn := Vector3(cos((u0 + u1) * 0.5), 1.0, sin((u0 + u1) * 0.5)).normalized()
			quad4(key, P.call(u0, v0), P.call(u1, v0), P.call(u1, v1), P.call(u0, v1), nn, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	disc(Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3.UP * (h + 0.01)), r, "champi_pied", seg)

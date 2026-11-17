extends Node3D
## V163 : le décor de la teuf de la plage, autour du mur de son, des platines et de la piste.
##  - le portique : deux tours de structure alu (des treillis carrés de 29 cm, leurs diagonales, leurs
##    platines au sol), la poutre au-dessus du mur de son ; les quatre lyres qui y pendent (la lyre, la
##    tête, la lentille qui s'allume au rythme du kick avec son projecteur) et, la nuit, leurs faisceaux
##    qui balaient la piste ;
##  - les guirlandes guinguette : des mâts de bois flotté autour de la piste, des fils qui pendent entre
##    eux et vers le portique, des ampoules rondes tous les 85 cm (allumées la nuit), et des fanions de
##    toile de toutes les couleurs ;
##  - des flambeaux de bambou (la flamme danse, la nuit) ;
##  - la banderole « DJ MISTRAL » nouée devant la table de mixage ;
##  - des câbles qui serpentent sur le sable, des flight-cases (les cornières d'alu, les coins boules,
##    les fermetures papillon), un coin pour souffler : des canapés de palettes et leurs coussins.
## Construit par teuf_v57.setup ; les lentilles et les faisceaux suivent les projecteurs (suivre()).

const MetalKit = preload("res://scripts/metal_kit_v160.gd")
const Sculpt = preload("res://scripts/statue_naine_v159.gd")
const B := "res://assets/textures/beau163/"
const B161 := "res://assets/textures/beau161/"

var main: Node
var teuf: Node3D
var _acc: Dictionary = {}
var _mats: Dictionary = {}
var _body: StaticBody3D
var _rng := RandomNumberGenerator.new()
var lentilles: Array = []          # une matière par lyre (suit son projecteur)
var faisceaux: Array = []          # un ShaderMaterial par lyre
var nb_ampoules: int = 0
var nb_fanions: int = 0
var nb_flambeaux: int = 0
var nb_mats: int = 0
var y_poutre: float = 8.0
var ampoules_mat: StandardMaterial3D
var flamme_mat: ShaderMaterial


func build(t: Node3D, m: Node) -> void:
	teuf = t
	main = m
	name = "Decor_teuf_v163"
	_rng.seed = 16301
	_body = StaticBody3D.new()
	_body.name = "Decor_teuf_collisions"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	var W: Vector3 = teuf.WALL
	y_poutre = _sol(W.x, W.z) + 8.0
	_portique(W)
	_guirlandes(W)
	_flambeaux()
	_banderole()
	_cables(W)
	_flight_cases(W)
	_coin_palettes()
	_commit()


# =================================================================== matières

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.8
	match key:
		"alu":
			m.albedo_color = Color(0.78, 0.79, 0.8)
			m.metallic = 0.9
			m.roughness = 0.32
			MetalKit.habille(m, "brosse", 1.4)
		"acier":
			m.albedo_color = Color(0.32, 0.33, 0.34)
			m.metallic = 0.85
			m.roughness = 0.5
			MetalKit.habille(m, "fer", 0.8)
		"chrome":
			m.albedo_color = Color(0.86, 0.87, 0.88)
			m.metallic = 1.0
			m.roughness = 0.14
		"noir":
			m.albedo_color = Color(0.07, 0.07, 0.075)
			m.metallic = 0.4
			m.roughness = 0.45
		"cable":
			m.albedo_color = Color(0.05, 0.05, 0.055)
			m.roughness = 0.55
			_tex(m, B161 + "caoutchouc", 3.0)
		"flight":
			m.albedo_color = Color(1, 1, 1)
			m.roughness = 0.7
			_tex(m, B + "flight", 0.9)
		"bois_flotte":
			_tex(m, B + "bois_flotte", 0.7)
			m.roughness = 0.9
		"bambou":
			_tex(m, B + "bambou", 0.0)
			m.roughness = 0.55
		"palette":
			_tex(m, B + "palette", 0.8)
			m.roughness = 0.92
		"coussin":
			_tex(m, B161 + "toile_lin", 1.6)
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.95
		"fanion":
			_tex(m, B161 + "toile_lin", 4.0)
			m.vertex_color_use_as_albedo = true
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.backlight_enabled = true
			m.backlight = Color(0.45, 0.45, 0.45)
			m.roughness = 0.95
		"douille":
			m.albedo_color = Color(0.08, 0.08, 0.08)
			m.roughness = 0.5
		_:
			m.albedo_color = Color(1, 0, 1)
	_mats[key] = m
	return m


func _tex(m: StandardMaterial3D, base: String, triplanar: float) -> void:
	if ResourceLoader.exists(base + ".png"):
		m.albedo_texture = load(base + ".png")
	if ResourceLoader.exists(base + "_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_n.png")
	if ResourceLoader.exists(base + "_r.png"):
		m.roughness_texture = load(base + "_r.png")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	if triplanar > 0.0:
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * triplanar


func _st(key: String) -> SurfaceTool:
	if not _acc.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_acc[key] = st
	return _acc[key]


func _commit() -> void:
	for key in _acc:
		var st: SurfaceTool = _acc[key]
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.name = "Teuf_" + str(key)
		mi.mesh = st.commit()
		mi.material_override = _mat(str(key))
		if key == "fanion" or key == "cable":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_acc.clear()


func _sol(x: float, z: float) -> float:
	return float(main._height_at(x, z))


# =================================================================== formes

## Une barre (un cylindre de a à b, rayon r, n côtés), normales lisses, UV en mètres.
func _barre(key: String, a: Vector3, b: Vector3, r: float, n: int = 6, r2: float = -1.0) -> void:
	var st: SurfaceTool = _st(key)
	var d: Vector3 = b - a
	var L: float = d.length()
	if L < 0.0001:
		return
	var ax: Vector3 = d / L
	var u: Vector3 = ax.cross(Vector3.UP if absf(ax.y) < 0.95 else Vector3.RIGHT).normalized()
	var v: Vector3 = ax.cross(u).normalized()
	var rb: float = r if r2 < 0.0 else r2
	for j in range(n):
		var a0: float = TAU * float(j) / n
		var a1: float = TAU * float(j + 1) / n
		var n0: Vector3 = u * cos(a0) + v * sin(a0)
		var n1: Vector3 = u * cos(a1) + v * sin(a1)
		var p00: Vector3 = a + n0 * r
		var p01: Vector3 = a + n1 * r
		var p10: Vector3 = b + n0 * rb
		var p11: Vector3 = b + n1 * rb
		var u0: float = float(j) / n * TAU * r
		var u1: float = float(j + 1) / n * TAU * r
		_tri(st, [p00, p10, p01], [n0, n0, n1], [Vector2(u0, 0), Vector2(u0, L), Vector2(u1, 0)], (n0 + n1) * 0.5)
		_tri(st, [p01, p10, p11], [n1, n0, n1], [Vector2(u1, 0), Vector2(u0, L), Vector2(u1, L)], (n0 + n1) * 0.5)


## Un triangle tourné vers « dehors » (Godot : sens des aiguilles d'une montre vu de devant).
func _tri(st: SurfaceTool, p: Array, nn: Array, uv: Array, dehors: Vector3) -> void:
	var o: Array = [0, 1, 2]
	if ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3)).dot(dehors) > 0.0:
		o = [0, 2, 1]
	for i in o:
		st.set_normal(nn[i])
		st.set_uv(uv[i])
		st.add_vertex(p[i])


func _boite(key: String, xf: Transform3D, s: Vector3) -> void:
	var bm := BoxMesh.new()
	bm.size = s
	_ajoute(key, bm.get_mesh_arrays(), xf)


func _boule(key: String, c: Vector3, r: float) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	_ajoute(key, sm.get_mesh_arrays(), Transform3D(Basis(), c))


## Verse un maillage (ses tableaux) dans la matière, triangle par triangle (pas d'indices : tout le
## SurfaceTool reste « à plat », comme les barres).
func _ajoute(key: String, arr: Array, xf: Transform3D) -> void:
	var st: SurfaceTool = _st(key)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb: Basis = xf.basis.inverse().transposed()
	if idx.is_empty():
		for i in range(vs.size()):
			idx.append(i)
	for q in idx:
		st.set_normal((nb * ns[q]).normalized())
		st.set_uv(uvs[q] if q < uvs.size() else Vector2.ZERO)
		st.add_vertex(xf * vs[q])


func _col_boite(xf: Transform3D, s: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = s
	cs.shape = sh
	cs.transform = xf
	_body.add_child(cs)


# =================================================================== le portique et les lyres

## Une tour de treillis carré (29 cm), de bas en haut, ses diagonales en zigzag sur chaque face.
func _treillis(a: Vector3, b: Vector3, cote: float = 0.29) -> void:
	var d: Vector3 = b - a
	var L: float = d.length()
	var ax: Vector3 = d / L
	var u: Vector3 = ax.cross(Vector3.UP if absf(ax.y) < 0.95 else Vector3.FORWARD).normalized()
	var v: Vector3 = ax.cross(u).normalized()
	var h: float = cote * 0.5
	var coins: Array = [u * h + v * h, -u * h + v * h, -u * h - v * h, u * h - v * h]
	for c in coins:
		_barre("alu", a + c, b + c, 0.024, 8)
	var n: int = maxi(1, int(round(L / 0.5)))
	for k in range(n):
		var t0: float = float(k) / n * L
		var t1: float = float(k + 1) / n * L
		for f in range(4):
			var c0: Vector3 = coins[f]
			var c1: Vector3 = coins[(f + 1) % 4]
			var p0: Vector3 = a + ax * t0 + (c0 if k % 2 == 0 else c1)
			var p1: Vector3 = a + ax * t1 + (c1 if k % 2 == 0 else c0)
			_barre("alu", p0, p1, 0.009, 5)
		# une entretoise tous les deux pas
		if k % 2 == 0:
			for f2 in range(4):
				_barre("alu", a + ax * t0 + coins[f2], a + ax * t0 + coins[(f2 + 1) % 4], 0.009, 5)


func _portique(W: Vector3) -> void:
	var z: float = W.z - 3.1
	var xs: Array = [W.x - 6.4, W.x + 6.4]
	for x in xs:
		var g: float = _sol(x, z)
		# la platine au sol, ses boulons, et la tour
		_boite("acier", Transform3D(Basis(), Vector3(x, g + 0.012, z)), Vector3(0.8, 0.024, 0.8))
		for sx in [-0.32, 0.32]:
			for sz in [-0.32, 0.32]:
				_boule("chrome", Vector3(x + sx, g + 0.03, z + sz), 0.022)
		_treillis(Vector3(x, g + 0.024, z), Vector3(x, y_poutre + 0.145, z))
		# le manchon d'angle en haut
		_boite("alu", Transform3D(Basis(), Vector3(x, y_poutre, z)), Vector3(0.34, 0.34, 0.34))
		_col_boite(Transform3D(Basis(), Vector3(x, (g + y_poutre) * 0.5, z)), Vector3(0.32, y_poutre - g, 0.32))
	_treillis(Vector3(xs[0] + 0.17, y_poutre, z), Vector3(xs[1] - 0.17, y_poutre, z))
	# les lyres, sous la poutre, à l'aplomb des quatre projecteurs
	var cols: Array = [Color(1.0, 0.15, 0.7), Color(0.1, 0.8, 1.0), Color(0.3, 1.0, 0.3), Color(1.0, 0.65, 0.1)]
	var cible := Vector3(teuf.PISTE.x, _sol(teuf.PISTE.x, teuf.PISTE.y), teuf.PISTE.y)
	for i in range(4):
		var x2: float = W.x - 4.5 + i * 3.0
		_lyre(Vector3(x2, y_poutre - 0.145, z), cible + Vector3((i - 1.5) * 2.2, 0.0, (i % 2) * 2.5 - 1.0), cols[i], i)


func _lyre(haut: Vector3, cible: Vector3, col: Color, i: int) -> void:
	# le crochet sur la poutre, la base (le moteur), la lyre en U, la tête qui vise la piste
	_boite("noir", Transform3D(Basis(), haut + Vector3(0, -0.04, 0)), Vector3(0.08, 0.08, 0.2))
	var base := haut + Vector3(0, -0.2, 0)
	_boite("noir", Transform3D(Basis(), base), Vector3(0.36, 0.16, 0.3))
	var dir: Vector3 = (cible - (base + Vector3(0, -0.42, 0))).normalized()
	var yaw: float = atan2(dir.x, dir.z)
	var by := Basis(Vector3.UP, yaw)
	var bras_y: float = base.y - 0.1
	for s in [-1.0, 1.0]:
		var bx: Vector3 = by * Vector3(s * 0.2, 0, 0)
		_boite("noir", Transform3D(by, Vector3(base.x, bras_y - 0.2, base.z) + bx), Vector3(0.04, 0.4, 0.1))
	var centre := Vector3(base.x, bras_y - 0.36, base.z)
	# la tête : un tambour noir, ses ailettes, la lentille au bout
	var t0: Vector3 = centre - dir * 0.16
	var t1: Vector3 = centre + dir * 0.22
	_barre("noir", t0, t1, 0.15, 14)
	_barre("noir", t0 - dir * 0.05, t0, 0.11, 12, 0.15)
	for k in range(5):
		_barre("noir", t0 + dir * (0.03 + k * 0.05), t0 + dir * (0.045 + k * 0.05), 0.162, 14)
	_barre("chrome", t1, t1 + dir * 0.012, 0.152, 16)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.05, 0.05, 0.06)
	lm.metallic_specular = 0.9
	lm.roughness = 0.06
	lm.emission_enabled = true
	lm.emission = col
	lm.emission_energy_multiplier = 0.0
	var disc := MeshInstance3D.new()
	disc.name = "Lentille_lyre_%d" % i
	var cm := CylinderMesh.new()
	cm.top_radius = 0.125
	cm.bottom_radius = 0.125
	cm.height = 0.01
	cm.radial_segments = 20
	disc.mesh = cm
	disc.material_override = lm
	disc.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), t1 + dir * 0.016)
	add_child(disc)
	lentilles.append(lm)
	# le faisceau : un cône doux de la lentille à la piste (la nuit seulement)
	var L: float = (cible - t1).length()
	var fm := ShaderMaterial.new()
	fm.shader = load("res://shaders/faisceau_v163.gdshader")
	fm.set_shader_parameter("couleur", Vector3(col.r, col.g, col.b))
	fm.set_shader_parameter("force", 0.0)
	var cone := MeshInstance3D.new()
	cone.name = "Faisceau_lyre_%d" % i
	cone.mesh = _cone(L, 0.12, 1.5)
	cone.material_override = fm
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cone.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), t1 + dir * 0.02)
	cone.visible = false
	add_child(cone)
	faisceaux.append([fm, cone])


## Un cône le long de +Y (de r0 en 0 à r1 en L), sans fonds ; v = 0 à la lentille, 1 au bout.
func _cone(L: float, r0: float, r1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 20
	for j in range(n):
		var a0: float = TAU * float(j) / n
		var a1: float = TAU * float(j + 1) / n
		var n0 := Vector3(cos(a0), 0, sin(a0))
		var n1 := Vector3(cos(a1), 0, sin(a1))
		var p00: Vector3 = n0 * r0
		var p01: Vector3 = n1 * r0
		var p10: Vector3 = n0 * r1 + Vector3.UP * L
		var p11: Vector3 = n1 * r1 + Vector3.UP * L
		_tri(st, [p00, p10, p01], [n0, n0, n1], [Vector2(0, 0), Vector2(0, 1), Vector2(1, 0)], n0 + n1)
		_tri(st, [p01, p10, p11], [n1, n0, n1], [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)], n0 + n1)
	return st.commit()


## Appelé par teuf_v57._process : les lentilles et les faisceaux suivent leurs projecteurs.
func suivre(lights: Array, nuit: bool) -> void:
	for i in range(mini(lights.size(), lentilles.size())):
		var e: float = (lights[i] as OmniLight3D).light_energy
		(lentilles[i] as StandardMaterial3D).emission_energy_multiplier = e * 1.6 + (0.4 if nuit else 0.0)
		var fa: Array = faisceaux[i]
		(fa[1] as MeshInstance3D).visible = nuit and e > 0.05
		if nuit:
			# le faisceau reste visible entre deux coups de grosse caisse, et flashe dessus
			(fa[0] as ShaderMaterial).set_shader_parameter("force", clampf(0.3 + e / 3.0, 0.0, 1.0))


# =================================================================== les guirlandes guinguette

func _mat_flotte(x: float, z: float, h: float) -> Vector3:
	# un mât de bois flotté (un peu de travers), son pied dans le sable
	var g: float = _sol(x, z)
	var pied := Vector3(x, g - 0.4, z)
	var tete := Vector3(x + _rng.randf_range(-0.12, 0.12), g + h, z + _rng.randf_range(-0.12, 0.12))
	var mi: Vector3 = (pied + tete) * 0.5 + Vector3(_rng.randf_range(-0.05, 0.05), 0, _rng.randf_range(-0.05, 0.05))
	_barre("bois_flotte", pied, mi, 0.075, 9, 0.065)
	_barre("bois_flotte", mi, tete, 0.065, 9, 0.05)
	_boule("bois_flotte", tete, 0.05)
	var cs := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = 0.08
	cy.height = h
	cs.shape = cy
	cs.position = Vector3(x, g + h * 0.5, z)
	_body.add_child(cs)
	nb_mats += 1
	return tete


## Un fil qui pend (une chaînette) de a à b ; rend ses points.
func _fil(a: Vector3, b: Vector3, fleche: float) -> Array:
	var pts: Array = []
	var n: int = maxi(6, int(a.distance_to(b) / 0.5))
	for k in range(n + 1):
		var t: float = float(k) / n
		var p: Vector3 = a.lerp(b, t)
		p.y -= fleche * 4.0 * t * (1.0 - t)
		pts.append(p)
	for k2 in range(n):
		_barre("cable", pts[k2], pts[k2 + 1], 0.006, 4)
	return pts


func _le_long(pts: Array, pas: float) -> Array:
	# des points tous les « pas » mètres le long du fil
	var out: Array = []
	var reste: float = pas * 0.5
	for k in range(pts.size() - 1):
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		var L: float = a.distance_to(b)
		var t: float = reste
		while t < L:
			out.append(a.lerp(b, t / L))
			t += pas
		reste = t - L
	return out


func _guirlandes(W: Vector3) -> void:
	var z: float = W.z - 3.1
	var tl := Vector3(W.x - 6.4, y_poutre - 1.2, z)
	var tr := Vector3(W.x + 6.4, y_poutre - 1.2, z)
	var P := Vector2(teuf.PISTE.x, teuf.PISTE.y)
	var pos: Array = [P + Vector2(-11.5, -4.5), P + Vector2(-7.5, -11.5), P + Vector2(0.0, -13.5), P + Vector2(7.5, -11.5), P + Vector2(11.5, -4.5)]
	var tetes: Array = []
	var bas: Array = []
	for p in pos:
		var t: Vector3 = _mat_flotte(p.x, p.y, 4.9)
		tetes.append(t)
		bas.append(t + Vector3(0, -0.8, 0))
	var lignes: Array = [[tl, tetes[0]], [tetes[0], tetes[1]], [tetes[1], tetes[2]], [tetes[2], tetes[3]], [tetes[3], tetes[4]], [tetes[4], tr],
		[tl, tetes[3]], [tr, tetes[1]], [tetes[2], (tl + tr) * 0.5 + Vector3(0, 0.2, 0)]]
	var mm_pts: Array = []
	for li in lignes:
		var a: Vector3 = li[0]
		var b: Vector3 = li[1]
		var pts: Array = _fil(a, b, 0.07 * a.distance_to(b))
		mm_pts.append_array(_le_long(pts, 0.85))
	# les fanions : sur le tour, un peu plus bas que les ampoules
	var tour: Array = [[tl + Vector3(0, -0.8, 0), bas[0]], [bas[0], bas[1]], [bas[1], bas[2]], [bas[2], bas[3]], [bas[3], bas[4]], [bas[4], tr + Vector3(0, -0.8, 0)]]
	var couleurs: Array = [Color(0.86, 0.2, 0.18), Color(0.98, 0.78, 0.2), Color(0.16, 0.5, 0.78), Color(0.2, 0.62, 0.36), Color(0.95, 0.5, 0.15), Color(0.92, 0.9, 0.86), Color(0.85, 0.38, 0.6)]
	for li2 in tour:
		var pts2: Array = _fil(li2[0], li2[1], 0.05 * (li2[0] as Vector3).distance_to(li2[1]))
		var pl: Array = _le_long(pts2, 0.34)
		for k in range(pl.size()):
			var c: Color = couleurs[(k + nb_fanions) % couleurs.size()]
			_fanion(pl[k], ((li2[1] as Vector3) - (li2[0] as Vector3)).normalized(), c)
		nb_fanions += pl.size()
	_ampoules(mm_pts)


func _fanion(p: Vector3, le_long: Vector3, c: Color) -> void:
	var st: SurfaceTool = _st("fanion")
	var cote: Vector3 = Vector3(le_long.x, 0, le_long.z).normalized()
	var vent: float = _rng.randf_range(-0.35, 0.35)
	var bas: Vector3 = (Vector3.DOWN + Vector3(-cote.z, 0, cote.x) * vent).normalized()
	var a: Vector3 = p - cote * 0.13
	var b: Vector3 = p + cote * 0.13
	var d: Vector3 = p + bas * 0.32
	var nrm: Vector3 = (b - a).cross(d - a).normalized()
	st.set_color(c)
	_tri(st, [a, b, d], [nrm, nrm, nrm], [Vector2(0, 0), Vector2(0.26, 0), Vector2(0.13, 0.32)], -nrm)


func _ampoules(pts: Array) -> void:
	ampoules_mat = StandardMaterial3D.new()
	ampoules_mat.albedo_color = Color(1.0, 0.88, 0.66, 0.85)
	ampoules_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ampoules_mat.roughness = 0.08
	ampoules_mat.metallic_specular = 0.9
	ampoules_mat.emission_enabled = true
	ampoules_mat.emission = Color(1.0, 0.6, 0.28)
	ampoules_mat.emission_energy_multiplier = 0.0
	var t: Node = main.get("temps_v56")
	if t != null and t.has_method("register_glow"):
		t.register_glow(ampoules_mat, 1.6, 0.0)
	var sm := SphereMesh.new()
	sm.radius = 0.042
	sm.height = 0.09
	sm.radial_segments = 10
	sm.rings = 6
	var dm := CylinderMesh.new()
	dm.top_radius = 0.013
	dm.bottom_radius = 0.016
	dm.height = 0.045
	dm.radial_segments = 8
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sm
	mm.instance_count = pts.size()
	var md := MultiMesh.new()
	md.transform_format = MultiMesh.TRANSFORM_3D
	md.mesh = dm
	md.instance_count = pts.size()
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		md.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.03, 0)))
		mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.085, 0)))
	var a := MultiMeshInstance3D.new()
	a.name = "Ampoules_guinguette"
	a.multimesh = mm
	a.material_override = ampoules_mat
	a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(a)
	var d := MultiMeshInstance3D.new()
	d.name = "Douilles_guinguette"
	d.multimesh = md
	d.material_override = _mat("douille")
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(d)
	nb_ampoules = pts.size()


# =================================================================== les flambeaux

func _flambeaux() -> void:
	var P := Vector2(teuf.PISTE.x, teuf.PISTE.y)
	flamme_mat = ShaderMaterial.new()
	flamme_mat.shader = load("res://shaders/flamme_v163.gdshader")
	flamme_mat.set_shader_parameter("glow", 0.0)
	var t: Node = main.get("temps_v56")
	if t != null and t.has_method("register_glow"):
		t.register_glow(flamme_mat, 1.0, 0.0)
	var fl := QuadMesh.new()
	fl.size = Vector2(0.3, 0.6)
	fl.center_offset = Vector3(0, 0.27, 0)
	for off in [Vector2(-9.0, 2.0), Vector2(-10.5, -9.0), Vector2(-3.8, -13.2), Vector2(3.8, -13.2), Vector2(10.5, -9.0), Vector2(9.5, 2.0)]:
		var p: Vector2 = P + off
		var g: float = _sol(p.x, p.y)
		var h: float = 1.9
		var pied := Vector3(p.x, g - 0.3, p.y)
		var tete := Vector3(p.x, g + h, p.y)
		_barre("bambou", pied, tete, 0.032, 10)
		# les nœuds du bambou
		var y: float = g + 0.25
		while y < g + h - 0.1:
			_barre("bambou", Vector3(p.x, y, p.y), Vector3(p.x, y + 0.03, p.y), 0.037, 10)
			y += _rng.randf_range(0.34, 0.46)
		# la coupelle de fer, la mèche
		var tmp := SurfaceTool.new()
		tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
		Sculpt._tour({"acier": tmp}, "acier", tete, [Vector2(0.03, 0.0), Vector2(0.075, 0.08), Vector2(0.085, 0.2), Vector2(0.07, 0.21)], Vector3.ONE, true)
		var cm: ArrayMesh = tmp.commit()
		if cm.get_surface_count() > 0:
			_ajoute("acier", cm.surface_get_arrays(0), Transform3D.IDENTITY)
		_barre("noir", tete + Vector3(0, 0.2, 0), tete + Vector3(0, 0.27, 0), 0.012, 6)
		# la flamme : deux plans croisés, qui dansent (flamme_v163.gdshader)
		for k in range(2):
			var f := MeshInstance3D.new()
			f.name = "Flamme_flambeau"
			f.mesh = fl
			f.material_override = flamme_mat
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			f.position = tete + Vector3(0, 0.25, 0)
			f.rotation.y = k * PI * 0.5 + _rng.randf() * 0.3
			add_child(f)
		nb_flambeaux += 1


# =================================================================== la banderole

func _banderole() -> void:
	var T: Vector3 = teuf.TABLE
	var g: float = _sol(T.x, T.z)
	var zf: float = T.z - 1.13
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(B + "banderole.png"):
		m.albedo_texture = load(B + "banderole.png")
	if ResourceLoader.exists(B161 + "toile_lin_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(B161 + "toile_lin_n.png")
		m.normal_scale = 0.6
	m.roughness = 0.92
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# une toile un peu gonflée par le vent (une grille de 24 × 6), nouée aux pieds de la table
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w: float = 4.2
	var h: float = 1.15
	var nx: int = 24
	var ny: int = 6
	var grille: Array = []
	for j in range(ny + 1):
		var row: Array = []
		for i in range(nx + 1):
			var u: float = float(i) / nx
			var v: float = float(j) / ny
			var x: float = T.x + w * 0.5 - u * w        # vue de la piste (vers +Z), la droite est -X
			var y: float = g + 1.62 - v * h - 0.05 * sin(u * PI) * v
			var zz: float = zf - 0.07 * sin(u * PI) * sin(v * PI) - 0.015 * sin(u * 23.0 + v * 3.0)
			row.append([Vector3(x, y, zz), Vector2(u, v)])
		grille.append(row)
	for j2 in range(ny):
		for i2 in range(nx):
			var a: Array = grille[j2][i2]
			var b: Array = grille[j2][i2 + 1]
			var c: Array = grille[j2 + 1][i2]
			var d: Array = grille[j2 + 1][i2 + 1]
			for tri in [[a, b, c], [b, d, c]]:
				var pa: Vector3 = tri[0][0]
				var nrm: Vector3 = ((tri[1][0] as Vector3) - pa).cross((tri[2][0] as Vector3) - pa).normalized()
				if nrm.z > 0.0:
					nrm = -nrm
				_tri(st, [tri[0][0], tri[1][0], tri[2][0]], [nrm, nrm, nrm], [tri[0][1], tri[1][1], tri[2][1]], nrm)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Banderole_Mistral"
	mi.mesh = st.commit()
	mi.material_override = m
	add_child(mi)
	# les cordelettes aux quatre coins
	for c2 in [Vector3(T.x - w * 0.5, g + 1.62, zf), Vector3(T.x + w * 0.5, g + 1.62, zf), Vector3(T.x - w * 0.5, g + 0.47, zf), Vector3(T.x + w * 0.5, g + 0.47, zf)]:
		var dx: float = -0.12 if c2.x < T.x else 0.12
		_barre("cable", c2, c2 + Vector3(dx, 0.04, 0.12), 0.006, 4)


# =================================================================== câbles, flight-cases, palettes

func _serpent(a: Vector2, b: Vector2, r: float, seed_k: int) -> void:
	var n: int = maxi(8, int(a.distance_to(b) / 0.3))
	var side: Vector2 = (b - a).normalized().orthogonal()
	var prev: Vector3
	for k in range(n + 1):
		var t: float = float(k) / n
		var p2: Vector2 = a.lerp(b, t) + side * (0.35 * sin(t * 7.0 + seed_k) + 0.12 * sin(t * 19.0 + seed_k * 2.0)) * sin(t * PI)
		var p := Vector3(p2.x, _sol(p2.x, p2.y) + r * 0.6, p2.y)
		if k > 0:
			_barre("cable", prev, p, r, 6)
		prev = p


func _cables(W: Vector3) -> void:
	var T: Vector3 = teuf.TABLE
	var z: float = W.z - 3.1
	# le multipaire de la table au mur, l'alimentation du distributeur, les tours du portique
	_serpent(Vector2(T.x - 1.6, T.z - 0.9), Vector2(W.x + 4.6, W.z - 2.4), 0.018, 1)
	_serpent(Vector2(T.x - 0.6, T.z - 0.95), Vector2(W.x + 5.2, W.z - 2.0), 0.011, 2)
	_serpent(Vector2(W.x - 8.4, W.z - 0.6), Vector2(W.x - 5.4, W.z - 2.2), 0.011, 3)
	for sx in [-1.0, 1.0]:
		var x: float = W.x + sx * 6.4
		_serpent(Vector2(x + sx * -0.14, z + 0.14), Vector2(W.x + sx * 5.3, W.z - 2.3), 0.012, 4 + int(sx))
		# le câble qui monte le long de la tour, attaché par des colliers
		var g: float = _sol(x, z)
		var c := Vector3(x - sx * 0.16, 0, z + 0.16)
		_barre("cable", Vector3(c.x, g + 0.02, c.z), Vector3(c.x, y_poutre - 0.1, c.z), 0.012, 6)
		var y: float = g + 0.6
		while y < y_poutre - 0.3:
			_barre("noir", Vector3(c.x, y, c.z), Vector3(c.x, y + 0.025, c.z), 0.017, 6)
			y += 0.9


func _flight_case(xf: Transform3D, s: Vector3) -> void:
	_boite("flight", xf, s - Vector3(0.01, 0.01, 0.01))
	var h: Vector3 = s * 0.5
	# les cornières d'alu sur les douze arêtes, les coins boules
	for ax in range(3):
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]:
				var c := Vector3.ZERO
				var sz := Vector3(0.03, 0.03, 0.03)
				match ax:
					0:
						c = Vector3(0, a * h.y, b * h.z)
						sz.x = s.x - 0.08
					1:
						c = Vector3(a * h.x, 0, b * h.z)
						sz.y = s.y - 0.08
					2:
						c = Vector3(a * h.x, b * h.y, 0)
						sz.z = s.z - 0.08
				_boite("alu", xf * Transform3D(Basis(), c), sz)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				_boule("chrome", xf * Vector3(x * h.x, y * h.y, z * h.z), 0.032)
	# le joint du couvercle, deux fermetures papillon, une poignée de chaque côté
	var yj: float = h.y - 0.16
	_boite("alu", xf * Transform3D(Basis(), Vector3(0, yj, 0)), Vector3(s.x + 0.012, 0.02, s.z + 0.012))
	for x2 in [-0.28, 0.28]:
		_boite("chrome", xf * Transform3D(Basis(), Vector3(x2 * s.x, yj, -h.z - 0.01)), Vector3(0.09, 0.1, 0.02))
	for sx in [-1.0, 1.0]:
		_boite("chrome", xf * Transform3D(Basis(), Vector3(sx * (h.x + 0.01), h.y * 0.25, 0)), Vector3(0.02, 0.06, 0.2))
	_col_boite(xf, s)


func _flight_cases(W: Vector3) -> void:
	var x: float = W.x - 7.1
	var z: float = W.z + 1.6
	var g: float = _sol(x, z)
	_flight_case(Transform3D(Basis(Vector3.UP, 0.08), Vector3(x, g + 0.36, z)), Vector3(1.2, 0.72, 0.8))
	_flight_case(Transform3D(Basis(Vector3.UP, -0.05), Vector3(x + 0.05, g + 0.72 + 0.27, z)), Vector3(0.9, 0.54, 0.62))
	_flight_case(Transform3D(Basis(Vector3.UP, 0.3), Vector3(x + 0.1, _sol(x, z + 1.1) + 0.3, z + 1.15)), Vector3(0.8, 0.6, 0.6))
	var T: Vector3 = teuf.TABLE
	_flight_case(Transform3D(Basis(Vector3.UP, -0.12), Vector3(T.x + 5.6, _sol(T.x + 5.6, T.z - 0.2) + 0.3, T.z - 0.2)), Vector3(0.8, 0.6, 0.6))


func _palette(xf: Transform3D) -> void:
	# une palette Europe (1,2 × 0,8 m) : trois planches de dessous, neuf dés, trois traverses, cinq planches
	for z in [-0.35, 0.0, 0.35]:
		_boite("palette", xf * Transform3D(Basis(), Vector3(0, 0.011, z)), Vector3(1.2, 0.022, 0.1))
	for x in [-0.55, 0.0, 0.55]:
		for z2 in [-0.35, 0.0, 0.35]:
			_boite("palette", xf * Transform3D(Basis(), Vector3(x, 0.06, z2)), Vector3(0.1, 0.078, 0.1 if absf(z2) > 0.1 else 0.145))
	for z3 in [-0.35, 0.0, 0.35]:
		_boite("palette", xf * Transform3D(Basis(), Vector3(0, 0.11, z3)), Vector3(1.2, 0.022, 0.1))
	for k in range(5):
		_boite("palette", xf * Transform3D(Basis(), Vector3(0, 0.133, -0.35 + k * 0.175)), Vector3(1.2, 0.022, 0.1 + (0.045 if k % 2 == 0 else 0.0)))


func _coussin(xf: Transform3D, s: Vector3, c: Color) -> void:
	# un coussin bombé (une boule écrasée en boîte arrondie)
	var st: SurfaceTool = _st("coussin")
	st.set_color(c)
	var bm := SphereMesh.new()
	bm.radius = 0.5
	bm.height = 1.0
	bm.radial_segments = 16
	bm.rings = 8
	var arr: Array = bm.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	# on « gonfle » la sphère vers une boîte (des coins arrondis), puis on l'étire
	for k in range(0, idx.size(), 3):
		for q in [idx[k], idx[k + 1], idx[k + 2]]:
			var p: Vector3 = vs[q] * 2.0
			var b: Vector3 = Vector3(signf(p.x) * pow(absf(p.x), 0.45), signf(p.y) * pow(absf(p.y), 0.8), signf(p.z) * pow(absf(p.z), 0.45))
			var nn: Vector3 = Vector3(ns[q].x / s.x, ns[q].y / s.y, ns[q].z / s.z).normalized()
			st.set_color(c)
			st.set_normal(xf.basis * nn)
			st.set_uv(uvs[q] * Vector2(2.0, 1.0))
			st.add_vertex(xf * (b * s * 0.5))


func _coin_palettes() -> void:
	var P := Vector2(teuf.PISTE.x, teuf.PISTE.y)
	var cols: Array = [[Color(0.86, 0.5, 0.2), Color(0.2, 0.45, 0.6)], [Color(0.78, 0.26, 0.3), Color(0.9, 0.82, 0.62)]]
	var k: int = 0
	for c in [P + Vector2(-15.5, 3.0), P + Vector2(-15.0, -3.2)]:
		var g: float = _sol(c.x, c.y)
		# le canapé regarde la piste (+X)
		var b := Basis(Vector3.UP, -PI * 0.5 + (0.25 if k == 0 else -0.2))
		var xf := Transform3D(b, Vector3(c.x, g - 0.02, c.y))
		_palette(xf)
		_palette(xf * Transform3D(Basis(), Vector3(0, 0.144, 0)))
		# le dossier : une palette debout contre l'arrière
		_palette(xf * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.22), Vector3(0, 0.29, 0.47)))
		var cc: Array = cols[k]
		_coussin(xf * Transform3D(Basis(), Vector3(-0.3, 0.36, -0.02)), Vector3(0.58, 0.14, 0.76), cc[0])
		_coussin(xf * Transform3D(Basis(), Vector3(0.3, 0.36, -0.02)), Vector3(0.58, 0.14, 0.76), cc[0])
		_coussin(xf * Transform3D(Basis(Vector3.RIGHT, 0.32), Vector3(-0.3, 0.62, 0.26)), Vector3(0.55, 0.42, 0.14), cc[1])
		_coussin(xf * Transform3D(Basis(Vector3.RIGHT, 0.28), Vector3(0.3, 0.62, 0.26)), Vector3(0.55, 0.42, 0.14), cc[1])
		_col_boite(xf * Transform3D(Basis(), Vector3(0, 0.22, 0.05)), Vector3(1.2, 0.44, 0.9))
		k += 1
	# une table basse : une palette posée sur une autre, une caisse de bois
	var ct: Vector2 = P + Vector2(-13.6, 0.0)
	var xt := Transform3D(Basis(Vector3.UP, 0.1), Vector3(ct.x, _sol(ct.x, ct.y) - 0.02, ct.y))
	_palette(xt)
	_palette(xt * Transform3D(Basis(), Vector3(0, 0.144, 0)))
	_palette(xt * Transform3D(Basis(), Vector3(0, 0.288, 0)))
	_col_boite(xt * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(1.2, 0.42, 0.8))

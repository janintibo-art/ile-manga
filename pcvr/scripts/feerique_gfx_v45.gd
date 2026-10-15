extends RefCounted
## V45 : un rendu plus réaliste pour le Royaume des Racines.
##  - parois, sols et plafonds en roche irrégulière (relief de bruit, ombre dans les creux),
##    avec le shader de roche du jeu (texture et relief projetés, mousse sur les dessus) ;
##  - racines en tubes continus, écorce texturée avec relief ;
##  - champignons tournés (chapeau bombé à bord recourbé, lamelles lumineuses dessous,
##    pied fibreux avec un anneau), textures peintes ici (dégradés, taches, fibres) ;
##  - cristaux hexagonaux à pointe, plus transparents et brillants.

const Rocks = preload("res://scripts/rocks_v26.gd")

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _flip: bool = false
var _tex: Dictionary = {}
var _mats: Dictionary = {}


func _init() -> void:
	_noise.seed = 4500
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise.frequency = 0.22
	_detail.seed = 4501
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.frequency = 0.9
	# Sens des faces : un petit triangle d'essai dit si l'ordre des sommets doit être inversé.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(Vector3(0, 0, 0))
	st.add_vertex(Vector3(1, 0, 0))
	st.add_vertex(Vector3(0, 0, 1))
	st.generate_normals()
	var arr: Array = st.commit_to_arrays()
	var n: Vector3 = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array)[0]
	# Avec cet ordre, la normale voulue est +Y (vers le haut) si la règle est « horaire ».
	_flip = n.y < 0.0


# =================================================================== matériaux

func rock(kind: String) -> Material:
	match kind:
		"mur":
			return Rocks.material(Color(0.66, 0.58, 0.62), 0.22, 0.24)
		"sol":
			return Rocks.material(Color(0.62, 0.62, 0.52), 0.92, 0.32)
		"plafond":
			return Rocks.material(Color(0.5, 0.45, 0.5), 0.0, 0.2)
	return Rocks.material()


func bark() -> StandardMaterial3D:
	if _mats.has("ecorce"):
		return _mats["ecorce"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/flora/bark.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/flora/bark_n.png")
	m.normal_scale = 1.6
	m.albedo_color = Color(0.82, 0.72, 0.62)
	m.roughness = 0.92
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	_mats["ecorce"] = m
	return m


func crystal_mat(c: Color) -> StandardMaterial3D:
	var key: String = "cristal_" + c.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r * 0.7, c.g * 0.7, c.b * 0.7, 0.62)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic = 0.15
	m.metallic_specular = 0.9
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.9
	m.rim_enabled = true
	m.rim = 0.8
	m.rim_tint = 0.6
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.05
	_mats[key] = m
	return m


## Chapeau de champignon : dessus en dégradé avec des taches, lamelles lumineuses dessous.
func cap_mat(c: Color, spots: bool, glow: float) -> StandardMaterial3D:
	var key: String = "chapeau_%s_%s_%.1f" % [c.to_html(), spots, glow]
	if _mats.has(key):
		return _mats[key]
	var w: int = 256
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emi := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = c.to_rgba32()
	var spot_list: Array = []
	if spots:
		for k in range(22):
			spot_list.append([rng.randf(), rng.randf_range(0.12, 0.62), rng.randf_range(0.025, 0.06)])
	var dark: Color = c.darkened(0.45)
	var light: Color = c.lightened(0.18)
	var gill: Color = c.lightened(0.55)
	for y in range(h):
		var v: float = float(y) / (h - 1)
		for x in range(w):
			var u: float = float(x) / w
			var col: Color
			var e := Color(0, 0, 0)
			if v < 0.72:
				var t: float = v / 0.72
				col = dark.lerp(light, smoothstep(0.0, 1.0, t))
				var n: float = _detail.get_noise_2d(u * 60.0, v * 30.0)
				col = col.lerp(col.darkened(0.25), clampf(n * 0.6 + 0.2, 0.0, 1.0) * 0.5)
				for sp in spot_list:
					var du: float = absf(wrapf(u - float(sp[0]), -0.5, 0.5)) * (0.4 + t) * 2.0
					var dv: float = absf(v - float(sp[1]))
					var dd: float = sqrt(du * du + dv * dv)
					if dd < float(sp[2]):
						col = col.lerp(Color(0.97, 0.94, 0.88), smoothstep(float(sp[2]), float(sp[2]) * 0.6, dd))
				# Liseré lumineux au bord
				e = c.lightened(0.3) * smoothstep(0.62, 0.72, v) * 0.35 * glow
			else:
				var stripe: float = 0.5 + 0.5 * sin(u * TAU * 64.0)
				col = gill.lerp(c, stripe * 0.4)
				e = c.lightened(0.45) * (0.55 + 0.45 * stripe) * glow
			img.set_pixel(x, y, col)
			emi.set_pixel(x, y, e)
	img.generate_mipmaps()
	emi.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.emission_enabled = true
	# Opérateur « ajouter » : émission = couleur + texture ; la couleur reste noire.
	m.emission = Color(0, 0, 0)
	m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
	m.emission_texture = ImageTexture.create_from_image(emi)
	m.emission_energy_multiplier = 2.2
	m.roughness = 0.55
	m.clearcoat_enabled = true
	m.clearcoat = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


## Pied de champignon : crème fibreuse, plus sombre au pied.
func stem_mat() -> StandardMaterial3D:
	if _mats.has("pied"):
		return _mats["pied"]
	var w: int = 128
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var v: float = float(y) / (h - 1)
		for x in range(w):
			var u: float = float(x) / w
			var fib: float = _detail.get_noise_2d(u * 140.0, v * 6.0) * 0.5 + 0.5
			var col := Color(0.93, 0.9, 0.84).lerp(Color(0.78, 0.72, 0.66), fib * 0.5)
			col = col.lerp(Color(0.55, 0.5, 0.45), smoothstep(0.75, 1.0, v) * 0.6)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats["pied"] = m
	return m


# =================================================================== maillages

## Paroi rocheuse : une grille posée sur la face intérieure (repère de la section), qui se
## bombe vers l'intérieur selon un bruit. Les bords marqués « taper » restent à plat (raccord
## avec les ouvertures). Couleur de sommet : plus sombre dans les creux.
func rock_face(center: Vector3, u: Vector3, v: Vector3, su: float, sv: float, inward: Vector3, amp: float, cell: float, taper: Array, ridged: bool = false, facing: Vector3 = Vector3.ZERO) -> ArrayMesh:
	if facing == Vector3.ZERO:
		facing = inward
	var nu: int = maxi(2, int(ceil(su / cell)) + 1)
	var nv: int = maxi(2, int(ceil(sv / cell)) + 1)
	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	for j in range(nv):
		var b: float = -sv * 0.5 + sv * j / (nv - 1)
		for i in range(nu):
			var a: float = -su * 0.5 + su * i / (nu - 1)
			var p: Vector3 = center + u * a + v * b
			var n: float = _noise.get_noise_3d(p.x, p.y, p.z) * 0.5 + 0.5
			if ridged:
				n = pow(1.0 - absf(_noise.get_noise_3d(p.x * 1.3, p.y * 1.3, p.z * 1.3)), 3.0) * 0.8 + n * 0.3
			n += _detail.get_noise_3d(p.x, p.y, p.z) * 0.08
			var k: float = 1.0
			var edge: float = 0.9
			if bool(taper[0]):
				k *= smoothstep(0.0, edge, a + su * 0.5)
			if bool(taper[1]):
				k *= smoothstep(0.0, edge, su * 0.5 - a)
			if bool(taper[2]):
				k *= smoothstep(0.0, edge, b + sv * 0.5)
			if bool(taper[3]):
				k *= smoothstep(0.0, edge, sv * 0.5 - b)
			var disp: float = amp * clampf(n, 0.0, 1.2) * k
			cols.append(Color(1, 1, 1) * lerpf(0.55, 1.08, clampf(n * k + (1.0 - k) * 0.7, 0.0, 1.0)))
			pts.append(p + inward * disp)
	for attempt in range(2):
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		for q in range(pts.size()):
			st2.set_color(cols[q])
			st2.add_vertex(pts[q])
		for j in range(nv - 1):
			for i in range(nu - 1):
				var i0: int = j * nu + i
				var i1: int = i0 + 1
				var i2: int = i0 + nu
				var i3: int = i2 + 1
				if attempt == 0:
					st2.add_index(i0); st2.add_index(i1); st2.add_index(i3)
					st2.add_index(i0); st2.add_index(i3); st2.add_index(i2)
				else:
					st2.add_index(i0); st2.add_index(i3); st2.add_index(i1)
					st2.add_index(i0); st2.add_index(i2); st2.add_index(i3)
		st2.generate_normals()
		var arr: Array = st2.commit_to_arrays()
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		# On garde l'ordre dont les normales regardent vers l'intérieur de la salle.
		if attempt == 1 or nn[nu + 1].dot(facing) > 0.0:
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			return mesh
	return null


## Racines : tubes continus le long de courbes de Bézier [a, ctrl, b, r0, r1, segments].
func roots_mesh(curves: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base: int = 0
	var sides: int = 9
	for c in curves:
		var a: Vector3 = c[0]
		var ctrl: Vector3 = c[1]
		var b: Vector3 = c[2]
		var r0: float = float(c[3])
		var r1: float = float(c[4])
		var segs: int = int(c[5]) * 2
		var pts: Array = []
		for k in range(segs + 1):
			var t: float = float(k) / segs
			pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
		var length: float = 0.0
		var prev_side := Vector3.ZERO
		for k in range(segs + 1):
			var t2: float = float(k) / segs
			var p: Vector3 = pts[k]
			var tan: Vector3 = ((pts[mini(k + 1, segs)] as Vector3) - (pts[maxi(k - 1, 0)] as Vector3)).normalized()
			var side: Vector3 = tan.cross(Vector3.UP if absf(tan.y) < 0.95 else Vector3.RIGHT).normalized()
			if prev_side != Vector3.ZERO and side.dot(prev_side) < 0.0:
				side = -side
			prev_side = side
			var up: Vector3 = side.cross(tan).normalized()
			if k > 0:
				length += p.distance_to(pts[k - 1])
			var r: float = lerpf(r0, r1, t2) * (1.0 + _detail.get_noise_3d(p.x * 2.0, p.y * 2.0, p.z * 2.0) * 0.15)
			if k == segs:
				r *= 0.4
			for sidx in range(sides + 1):
				var ang: float = TAU * sidx / sides
				var dir: Vector3 = side * cos(ang) + up * sin(ang)
				st.set_normal(dir)
				st.set_uv(Vector2(float(sidx) / sides * maxf(r * 4.0, 0.5), length * 0.7))
				st.set_color(Color(1, 1, 1) * lerpf(0.7, 1.0, t2))
				st.add_vertex(p + dir * r)
		for k in range(segs):
			for sidx in range(sides):
				var i0: int = base + k * (sides + 1) + sidx
				var i1: int = i0 + 1
				var i2: int = i0 + sides + 1
				var i3: int = i2 + 1
				st.add_index(i0); st.add_index(i2); st.add_index(i1)
				st.add_index(i1); st.add_index(i2); st.add_index(i3)
		base += (segs + 1) * (sides + 1)
	st.generate_tangents()
	return st.commit()


## Tour (révolution) d'un profil [rayon, hauteur, v], avec normales lissées.
func _lathe(profile: Array, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = profile.size()
	for k in range(n):
		var pr: Array = profile[k]
		var prv: Array = profile[maxi(k - 1, 0)]
		var nxt: Array = profile[mini(k + 1, n - 1)]
		var tang := Vector2(float(nxt[0]) - float(prv[0]), float(nxt[1]) - float(prv[1])).normalized()
		var nrm2 := Vector2(-tang.y, tang.x)
		for sidx in range(sides + 1):
			var ang: float = TAU * sidx / sides
			var dir := Vector3(cos(ang), 0, sin(ang))
			st.set_normal((dir * nrm2.x + Vector3.UP * nrm2.y).normalized())
			st.set_uv(Vector2(float(sidx) / sides, float(pr[2])))
			st.add_vertex(dir * float(pr[0]) + Vector3.UP * float(pr[1]))
	for k in range(n - 1):
		for sidx in range(sides):
			var i0: int = k * (sides + 1) + sidx
			var i1: int = i0 + 1
			var i2: int = i0 + sides + 1
			var i3: int = i2 + 1
			st.add_index(i0); st.add_index(i1); st.add_index(i2)
			st.add_index(i1); st.add_index(i3); st.add_index(i2)
	return st.commit()


## Chapeau : dôme, bord recourbé, dessous en lamelles. Origine au niveau du bord.
func cap_mesh(r: float, dome: float = 0.45) -> ArrayMesh:
	var prof: Array = []
	for k in range(9):
		var th: float = PI * 0.5 * float(k) / 8.0
		prof.append([r * sin(th), r * dome * cos(th) + r * 0.04, 0.72 * float(k) / 8.0])
	prof.append([r * 1.02, -r * 0.01, 0.73])
	prof.append([r * 0.96, -r * 0.07, 0.76])
	prof.append([r * 0.7, -r * 0.1, 0.85])
	prof.append([r * 0.3, -r * 0.13, 0.95])
	prof.append([0.001, -r * 0.14, 1.0])
	return _lathe(prof, 28)


## Pied : renflé à la base, un anneau (« jupe ») sous le chapeau.
func stem_mesh(r: float, h: float, skirt: bool = true) -> ArrayMesh:
	var prof: Array = [[r * 0.82, h * 1.0, 0.0], [r * 0.9, h * 0.8, 0.2]]
	if skirt:
		prof += [[r * 1.75, h * 0.7, 0.27], [r * 1.68, h * 0.68, 0.28], [r * 0.9, h * 0.66, 0.32]]
	prof += [[r * 0.9, h * 0.6, 0.4], [r * 0.95, h * 0.4, 0.6], [r * 1.0, h * 0.2, 0.8], [r * 1.15, h * 0.06, 0.94], [r * 1.35, 0.0, 1.0]]
	return _lathe(prof, 24 if r > 0.6 else 18)


## Cristal hexagonal à pointe (origine à la base).
func crystal_mesh(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body_h: float = h * 0.72
	var ring: Array = []
	for k in range(6):
		var a: float = TAU * k / 6.0
		ring.append(Vector3(cos(a) * r, 0, sin(a) * r))
	var tip := Vector3(0, h, 0)
	for k in range(6):
		var p0: Vector3 = ring[k]
		var p1: Vector3 = ring[(k + 1) % 6]
		var q0: Vector3 = p0 + Vector3.UP * body_h
		var q1: Vector3 = p1 + Vector3.UP * body_h
		for tri in [[p0, q0, p1], [p1, q0, q1], [q0, tip, q1]]:
			for v in (tri if _flip else [tri[0], tri[2], tri[1]]):
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()

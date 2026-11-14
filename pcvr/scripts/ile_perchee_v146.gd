extends Node3D
## V146 : l'Île Perchée, la grande île flottante du Far West (au sud-ouest de l'archipel, au sud de
## Hautefond, à 270 m au-dessus de la mer). Une prairie dorée posée sur une montagne renversée de
## grès rouge ; le bourg de Pile-ou-Face, ses saloons et ses tripots.
##  - le dessus (~230 m de rayon) : une prairie qui ondule, deux mesas de grès rouge à falaises
##    (le Vieux-Pic à l'ouest, la Mesa des Corbeaux au nord), deux aiguilles de roche ; le ruisseau
##    de l'Orpailleur, qui naît au pied du Vieux-Pic et tombe du bord (la Chute de l'Orpailleur) ;
##    l'Abreuvoir (une mare) ; le bourg de Pile-ou-Face au milieu (sa grand-rue, la rue du Pique, la
##    place de la Roue) ; le Quai des Nuées à l'est (le dirigeable) ; la Grande Chaîne au sud-est
##    (la cabine qui descend jusqu'à la mer) ;
##  - le dessous : une montagne renversée de grès rouge en strates, des racines qui pendent, et les
##    quatre Pierres-de-Ciel, d'énormes cristaux bleus pris dans des cages de fer, qui portent l'île.
## Le relief se calcule à la demande (top_local) ; le sol physique est un maillage (trimesh).
## Repère local : +X à l'est, +Z au sud ; l'origine est le centre de l'île.

const CENTER := Vector3(-820.0, 270.0, 2140.0)
const Y0: float = 270.0
const R0: float = 226.0
const NR: int = 112
const NS: int = 448
const SECTORS: int = 12
const DEPTH: float = 175.0
const T_MJ := "res://assets/textures/montjoie/"
const T_SO := "res://assets/textures/soleils/"
## Le bourg : la grand-rue (est-ouest), la rue du Pique (nord-sud), la place de la Roue.
const RUE_Z: float = 0.0
const RUE_X := Vector2(-40.0, 158.0)
const RUE_W: float = 15.0
const PIQUE_X: float = 60.0
const PIQUE_Z := Vector2(-96.0, 92.0)
const PLACE := Vector2(60.0, 0.0)
const PLACE_R: float = 20.0
const BOURG_R: float = 118.0            # le bourg est aplani dans ce rayon (autour de BOURG_C)
const BOURG_C := Vector2(58.0, 0.0)
## Les mesas : [centre, rayon, hauteur] ; les aiguilles aussi (petites et hautes).
const MESAS := [[Vector2(-138.0, -66.0), 40.0, 30.0], [Vector2(-34.0, -168.0), 23.0, 19.0]]
const AIGUILLES := [[Vector2(-172.0, 112.0), 9.0, 24.0], [Vector2(22.0, 176.0), 7.0, 17.0], [Vector2(-196.0, 60.0), 6.0, 13.0]]
## Le ruisseau de l'Orpailleur : de la source (au pied du Vieux-Pic) jusqu'au bord, à l'ouest.
const RUISSEAU := [Vector2(-92.0, -30.0), Vector2(-108.0, -4.0), Vector2(-132.0, 14.0), Vector2(-158.0, 22.0), Vector2(-184.0, 34.0), Vector2(-206.0, 44.0), Vector2(-226.0, 50.0)]
const ABREUVOIR := Vector2(-58.0, 66.0)
const ABREUVOIR_R: float = 15.0
const EAU_Y: float = -0.55              # le niveau de l'eau (local), dans la mare et le ruisseau
## Le Quai des Nuées (à l'est, au-delà du bord) et la Grande Chaîne (au sud-est).
const QUAI_ANGLE: float = 0.0           # radians (vers l'est)
const CHAINE_ANGLE: float = 0.86        # radians (au sud-est)

var pc: bool = true
var terrain_mat: ShaderMaterial
var biome: Image
var falls: Array = []                   # [lèvre (monde), pied (monde, sur la mer)]
var pierres: Array = []                 # les Pierres-de-Ciel (Node3D), sous l'île
var _coast := FastNoiseLite.new()
var _noise := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, Y0 + y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


func _setup_noise() -> void:
	_coast.seed = 14601
	_coast.frequency = 0.85
	_coast.fractal_octaves = 3
	_noise.seed = 14602
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4
	_under.seed = 14603
	_under.frequency = 0.03
	_under.fractal_octaves = 4


# =================================================================== la forme

func coast_radius(theta: float) -> float:
	var n: float = _coast.get_noise_2d(cos(theta) * 1.4, sin(theta) * 1.4)
	var r: float = R0 + n * 14.0 + sin(theta * 3.0 + 1.1) * 6.0 + sin(theta * 8.0 + 0.4) * 1.8
	# le cap du Quai des Nuées (à l'est) et celui de la Grande Chaîne (au sud-est)
	r += 10.0 * exp(-pow(wrapf(theta - QUAI_ANGLE, -PI, PI) / 0.12, 2.0))
	r += 8.0 * exp(-pow(wrapf(theta - CHAINE_ANGLE, -PI, PI) / 0.1, 2.0))
	return r


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## La distance au lit du ruisseau (et la place le long, de 0 à la source à 1 au bord).
func ruisseau_dist(p: Vector2) -> Vector2:
	var best: float = INF
	var at: float = 0.0
	var n: int = RUISSEAU.size()
	for i in range(n - 1):
		var a: Vector2 = RUISSEAU[i]
		var b: Vector2 = RUISSEAU[i + 1]
		var d: float = _seg_dist(p, a, b)
		if d < best:
			best = d
			var ab: Vector2 = b - a
			at = (float(i) + clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)) / float(n - 1)
	return Vector2(best, at)


## Un point est-il sur une rue du bourg (la grand-rue, la rue du Pique, la place) ?
func rue_w(p: Vector2) -> float:
	var g: float = 0.0
	if p.x > RUE_X.x - 6.0 and p.x < RUE_X.y + 60.0:
		g = 1.0 - smoothstep(RUE_W * 0.5 - 1.5, RUE_W * 0.5 + 1.5, absf(p.y - RUE_Z))
		g *= smoothstep(RUE_X.x - 5.0, RUE_X.x + 1.0, p.x)
	if p.y > PIQUE_Z.x - 4.0 and p.y < PIQUE_Z.y + 4.0:
		g = maxf(g, 1.0 - smoothstep(5.0, 8.0, absf(p.x - PIQUE_X)))
	g = maxf(g, 1.0 - smoothstep(PLACE_R - 2.0, PLACE_R + 1.0, p.distance_to(PLACE)))
	return g


## Les chemins de terre hors du bourg : vers la Grande Chaîne, vers l'Abreuvoir et le Vieux-Pic.
func chemin_w(p: Vector2) -> float:
	var ch: Vector2 = Vector2(cos(CHAINE_ANGLE), sin(CHAINE_ANGLE)) * (coast_radius(CHAINE_ANGLE) - 8.0)
	var d: float = _seg_dist(p, Vector2(PIQUE_X, PIQUE_Z.y), ch)
	d = minf(d, _seg_dist(p, Vector2(RUE_X.x, RUE_Z), ABREUVOIR + Vector2(18.0, -6.0)))
	d = minf(d, _seg_dist(p, Vector2(RUE_X.x, RUE_Z), Vector2(-92.0, -30.0)))
	return 1.0 - smoothstep(2.2, 3.6, d)


## La hauteur du dessus, en repère local (par rapport à Y0).
func top_local(lx: float, lz: float) -> float:
	var l := Vector2(lx, lz)
	var r: float = l.length()
	var rr: float = coast_radius(atan2(lz, lx))
	# la prairie qui ondule, plus vallonnée loin du bourg
	var roll: float = _noise.get_noise_2d(lx, lz) * 4.5 + _noise.get_noise_2d(lx * 2.3 + 40.0, lz * 2.3) * 1.0
	var bourg: float = 1.0 - smoothstep(BOURG_R * 0.75, BOURG_R, l.distance_to(BOURG_C))
	var h: float = roll * (1.0 - bourg * 0.9) + 0.6
	# les mesas : des falaises franches et un éboulis au pied
	for m in MESAS + AIGUILLES:
		var c: Vector2 = m[0]
		var mr: float = float(m[1])
		var mh: float = float(m[2])
		var d: float = l.distance_to(c)
		if d > mr + 26.0:
			continue
		var ang: float = atan2(l.y - c.y, l.x - c.x)
		var bord: float = mr + _coast.get_noise_2d(cos(ang) * 2.0 + c.x, sin(ang) * 2.0 + c.y) * mr * 0.16
		var falaise: float = 1.0 - smoothstep(bord - 1.2, bord + 2.4, d)
		var eboulis: float = (1.0 - smoothstep(bord, bord + 22.0, d)) * 0.16
		var dessus: float = _noise.get_noise_2d(lx * 3.0, lz * 3.0) * 0.8 * falaise
		h = maxf(h, h * (1.0 - falaise) + mh * maxf(falaise, eboulis) + dessus)
	# le lit du ruisseau, la mare
	var rd: Vector2 = ruisseau_dist(l)
	var lit: float = 1.0 - smoothstep(1.4, 4.0, rd.x)
	h = lerpf(h, minf(h, EAU_Y - 0.7), lit * (1.0 - smoothstep(0.92, 1.0, rd.y) * 0.0))
	var dm: float = l.distance_to(ABREUVOIR)
	h = lerpf(h, minf(h, EAU_Y - 1.4), 1.0 - smoothstep(ABREUVOIR_R - 3.0, ABREUVOIR_R + 4.0, dm))
	# les rues sont bien plates (un peu plus bas que les trottoirs de bois)
	h -= 0.12 * rue_w(l)
	# le bord : une lèvre de roche, puis l'île bascule dans le vide
	h += 1.2 * smoothstep(rr - 16.0, rr - 6.0, r) * (1.0 - smoothstep(rr - 4.0, rr, r))
	h -= 3.4 * pow(smoothstep(rr - 5.0, rr, r), 1.6)
	return h


## La hauteur du sol (monde), ou -INF hors de l'île.
func height(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	if l.length_squared() < 260.0 * 260.0 and l.length() <= coast_radius(atan2(l.y, l.x)):
		return Y0 + top_local(l.x, l.y)
	return -INF


## Au-dessus de l'île (ou dessous, dans sa roche), et à peu près à sa hauteur ?
func contains(p: Vector3) -> bool:
	return p.y > Y0 - DEPTH - 30.0 and p.y < Y0 + 300.0 and near_xz(p.x, p.z, 30.0)


func near_xz(wx: float, wz: float, margin: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < coast_radius(atan2(l.y, l.x)) + margin + 40.0


## Sur le dessus (on y marche) ?
func on_top(p: Vector3) -> bool:
	var h: float = height(p.x, p.z)
	return h > -INF and absf(p.y - h) < 8.0


## Dans l'eau (la mare, le ruisseau) ?
func in_water(wx: float, wz: float) -> bool:
	var l: Vector2 = L(wx, wz)
	if l.distance_to(ABREUVOIR) < ABREUVOIR_R - 2.5:
		return true
	return ruisseau_dist(l).x < 1.3


## [bas de la roche, dessus] au-dessus de (x, z), ou [] hors de l'île.
func rock_span(wx: float, wz: float) -> Array:
	var l: Vector2 = L(wx, wz)
	var r: float = l.length()
	var rr: float = coast_radius(atan2(l.y, l.x)) + 2.0
	if r >= rr:
		return []
	var t: float = 1.0 - pow(r / rr, 4.0 / 3.0)
	var top: float = height(wx, wz)
	if top < -1e6:
		top = Y0
	return [Y0 - 3.4 - (DEPTH - 3.4) * pow(t, 1.15) - 2.0, top]


# =================================================================== construction

func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	pc = high_quality
	_rng.seed = 14600
	_setup_noise()
	_bake_biome()
	_make_material()
	_build_top()
	_build_underside()
	_build_pierres()
	_build_eau()
	print("ILE_MANGA_V146: l'Île Perchée en ", Time.get_ticks_msec() - t0, " ms")


func _make_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/perchee_sol_v146.gdshader")
	var tex := {"prairie": T_MJ + "prairie", "chemin": T_MJ + "chemin", "terre_rouge": T_SO + "sable", "verdure": T_SO + "herbe",
		"gres": T_SO + "gres", "paves": T_MJ + "paves"}
	for k in tex:
		var t: String = str(tex[k]) + ".png"
		if ResourceLoader.exists(t):
			mat.set_shader_parameter(k + "_tex", load(t))
		var tn: String = str(tex[k]) + "_n.png"
		if ResourceLoader.exists(tn):
			mat.set_shader_parameter(k + "_n", load(tn))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - BIOME_HALF, CENTER.z - BIOME_HALF, BIOME_HALF * 2.0, BIOME_HALF * 2.0))
	mat.set_shader_parameter("y0", Y0)
	mat.set_shader_parameter("eau_y", Y0 + EAU_Y)
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("extra_detail", pc)
	terrain_mat = mat


# =================================================================== la carte des sols

const BIOME_RES: int = 288
const BIOME_HALF: float = 252.0


## R : la terre battue (les rues, les chemins) ; G : la terre rouge (autour des mesas, les
## terres sèches du sud) ; B : la verdure (le long du ruisseau, autour de la mare) ; A : la place
## pavée de la Roue.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = BIOME_HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var p := Vector2(-BIOME_HALF + (xi + 0.5) * px, -BIOME_HALF + (zi + 0.5) * px)
			var n: float = _noise.get_noise_2d(p.x * 3.0, p.y * 3.0)
			var dirt: float = maxf(rue_w(p) * (1.0 - (1.0 - smoothstep(PLACE_R - 3.0, PLACE_R, p.distance_to(PLACE)))), chemin_w(p))
			var red: float = 0.0
			for m in MESAS + AIGUILLES:
				red = maxf(red, 1.0 - smoothstep(float(m[1]) + 6.0, float(m[1]) + 30.0, p.distance_to(m[0]) + n * 10.0))
			red = maxf(red, smoothstep(0.25, 0.5, _noise.get_noise_2d(p.x * 0.7 + 300.0, p.y * 0.7) + n * 0.2) * 0.55)
			var rd: float = ruisseau_dist(p).x
			var vert: float = maxf(1.0 - smoothstep(6.0, 20.0, rd + n * 6.0), 1.0 - smoothstep(ABREUVOIR_R + 2.0, ABREUVOIR_R + 18.0, p.distance_to(ABREUVOIR) + n * 6.0))
			var place: float = 1.0 - smoothstep(PLACE_R - 3.0, PLACE_R - 1.0, p.distance_to(PLACE))
			biome.set_pixel(xi, zi, Color(dirt, red * (1.0 - vert) * (1.0 - dirt), vert * (1.0 - dirt), place))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


# =================================================================== le dessus

func _ring_point(i: int, j: int) -> Vector3:
	var theta: float = TAU * float(j) / NS
	var rr: float = coast_radius(theta)
	var r: float = rr * pow(float(i) / NR, 0.9)
	var lx: float = cos(theta) * r
	var lz: float = sin(theta) * r
	return Vector3(lx, top_local(lx, lz), lz)


func _build_top() -> void:
	var pts: Array = []
	for i in range(NR + 1):
		var row: Array = []
		for j in range(NS):
			row.append(_ring_point(i, j) if i > 0 else Vector3(0, top_local(0, 0), 0))
		pts.append(row)
	var per: int = NS / SECTORS
	for s in range(SECTORS):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var faces := PackedVector3Array()
		var j0: int = s * per
		var j1: int = NS if s == SECTORS - 1 else j0 + per
		for i in range(NR):
			for j in range(j0, j1):
				var jn: int = (j + 1) % NS
				var a: Vector3 = pts[i][j]
				var b: Vector3 = pts[i][jn]
				var c: Vector3 = pts[i + 1][j]
				var d: Vector3 = pts[i + 1][jn]
				if i == 0:
					_tri(st, faces, a, d, c)
				else:
					_tri(st, faces, a, b, d)
					_tri(st, faces, a, d, c)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "Perchee_dessus_%d" % s
		mi.mesh = st.commit()
		mi.material_override = terrain_mat
		add_child(mi)
		mi.position = Vector3(CENTER.x, Y0, CENTER.z)
		_trimesh(faces, "Perchee_sol_%d" % s, Vector3(CENTER.x, Y0, CENTER.z))


func _tri(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	for v in [a, c, b]:
		st.set_uv(Vector2(v.x, v.z) * 0.2)
		st.add_vertex(v)
		faces.append(v)


func _trimesh(faces: PackedVector3Array, nm: String, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = nm
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	body.position = at


# =================================================================== le dessous

## Une montagne renversée de grès rouge : le bord, un ventre qui rentre, puis la pointe ; les
## strates en corniches (des marches qui débordent), des ravines.
func _build_underside() -> void:
	var nu: int = 40 if pc else 26
	var ns: int = 200 if pc else 120
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	var tip := Vector3(-18.0, -DEPTH, 14.0)
	for k in range(nu + 1):
		var t: float = float(k) / nu
		var row: Array = []
		for j in range(ns):
			var th: float = TAU * float(j) / ns
			var rr: float = coast_radius(th) - 0.5
			var prof: float = pow(1.0 - t, 0.7) * (1.0 + 0.1 * sin(t * PI))
			var dir := Vector2(cos(th), sin(th))
			var base := Vector3(dir.x * rr * prof, lerpf(-3.6, tip.y, pow(t, 1.1)), dir.y * rr * prof)
			base = base.lerp(Vector3(tip.x, base.y, tip.z), t * t * 0.55)
			var n: float = _under.get_noise_3d(base.x * 0.5, base.y * 0.3, base.z * 0.5)
			# les corniches : le grès dur déborde, le tendre rentre
			var strate: float = pow(absf(sin(base.y * 0.42 + n * 1.2)), 3.0) * 3.2 - 1.2
			var ravine: float = -pow(maxf(_under.get_noise_2d(th * 9.0, 3.0), 0.0), 2.0) * 22.0
			var push: float = (n * 9.0 + strate + ravine) * (1.0 - t * 0.55) * minf(t * 7.0, 1.0)
			row.append(base + Vector3(dir.x, 0, dir.y) * push)
		rows.append(row)
	for k in range(nu):
		for j in range(ns):
			var jn: int = (j + 1) % ns
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][jn]
			var c: Vector3 = rows[k + 1][j]
			var d: Vector3 = rows[k + 1][jn]
			for v in [a, c, d, a, d, b]:
				st.set_uv(Vector2(v.x + v.z, v.y) * 0.1)
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Perchee_dessous"
	mi.mesh = st.commit()
	mi.material_override = terrain_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)
	_racines(rows, nu, ns)


## Des racines qui pendent sous le bord (les arbres du dessus cherchent l'eau des nuages).
func _racines(rows: Array, nu: int, ns: int) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.33, 0.24, 0.17)
	m.roughness = 0.95
	var n: int = 70 if pc else 30
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in range(n):
		var k: int = _rng.randi_range(1, int(nu * 0.35))
		var j: int = _rng.randi() % ns
		var p: Vector3 = rows[k][j]
		var lg: float = _rng.randf_range(4.0, 16.0)
		var pts: Array = [p]
		var d := Vector3(_rng.randf_range(-0.2, 0.2), -1.0, _rng.randf_range(-0.2, 0.2))
		for s in range(6):
			p += d.normalized() * lg / 6.0 + Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
			pts.append(p)
		var r0: float = _rng.randf_range(0.12, 0.3)
		for s in range(pts.size() - 1):
			var a: Vector3 = pts[s]
			var b: Vector3 = pts[s + 1]
			var ra: float = r0 * (1.0 - float(s) / 6.0)
			var rb: float = r0 * (1.0 - float(s + 1) / 6.0) + 0.01
			var ax: Vector3 = (b - a).normalized()
			var u: Vector3 = ax.cross(Vector3.RIGHT).normalized()
			var v: Vector3 = ax.cross(u)
			for e in range(5):
				var a0: float = TAU * e / 5.0
				var a1: float = TAU * (e + 1) / 5.0
				var o0: Vector3 = u * cos(a0) + v * sin(a0)
				var o1: Vector3 = u * cos(a1) + v * sin(a1)
				for vv in [a + o0 * ra, b + o0 * rb, b + o1 * rb, a + o0 * ra, b + o1 * rb, a + o1 * ra]:
					st.add_vertex(vv)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Perchee_racines"
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)


## Les quatre Pierres-de-Ciel : d'énormes cristaux bleus pris dans des cages de fer rivetées,
## accrochés sous l'île par des chaînes ; ils luisent et bourdonnent (ce sont eux qui la portent).
func _build_pierres() -> void:
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.45, 0.75, 1.0, 0.82)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.roughness = 0.08
	cristal.metallic_specular = 0.9
	cristal.emission_enabled = true
	cristal.emission = Color(0.25, 0.6, 1.0)
	cristal.emission_energy_multiplier = 1.6
	cristal.rim_enabled = true
	cristal.rim = 0.8
	var fer := StandardMaterial3D.new()
	fer.albedo_color = Color(0.2, 0.19, 0.18)
	fer.metallic = 0.85
	fer.roughness = 0.5
	var places := [[Vector2(70.0, -60.0), 62.0], [Vector2(-80.0, -40.0), 70.0], [Vector2(-40.0, 90.0), 66.0], [Vector2(90.0, 70.0), 58.0]]
	for i in range(places.size()):
		var c: Vector2 = places[i][0]
		var y: float = -float(places[i][1])
		var root := Node3D.new()
		root.name = "Pierre_de_ciel_%d" % i
		add_child(root)
		root.position = Vector3(CENTER.x + c.x, Y0 + y, CENTER.z + c.y)
		# le cristal : deux pointes (un octaèdre étiré)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 5.5
		cm.height = 9.0
		cm.radial_segments = 6
		cm.rings = 1
		for s in [1.0, -1.0]:
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = cristal
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
			mi.position = Vector3(0, 4.5 * s, 0)
			if s < 0.0:
				mi.rotation.x = PI
		# la cage : des montants courbes et deux cerclages
		for k in range(6):
			var a: float = TAU * k / 6.0 + PI / 6.0
			var bar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.45, 19.0, 0.45)
			bar.mesh = bm
			bar.material_override = fer
			root.add_child(bar)
			bar.position = Vector3(cos(a) * 3.6, 0, sin(a) * 3.6)
			bar.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35) * 0.6
		for y2 in [-3.0, 3.0]:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 5.0
			tm.outer_radius = 5.6
			tm.rings = 24
			tm.ring_segments = 6
			ring.mesh = tm
			ring.material_override = fer
			root.add_child(ring)
			ring.position.y = y2
		# les chaînes qui la tiennent à la roche
		var top_y: float = -3.4 - (DEPTH - 3.4) * pow(1.0 - pow(c.length() / coast_radius(atan2(c.y, c.x)), 4.0 / 3.0), 1.15)
		var chain_len: float = maxf(top_y - y - 9.0, 2.0)
		for k2 in range(3):
			var a2: float = TAU * k2 / 3.0
			var ch := MeshInstance3D.new()
			var chm := CylinderMesh.new()
			chm.top_radius = 0.25
			chm.bottom_radius = 0.25
			chm.height = chain_len + 6.0
			chm.radial_segments = 6
			ch.mesh = chm
			ch.material_override = fer
			root.add_child(ch)
			ch.position = Vector3(cos(a2) * 4.0, 9.0 + chain_len * 0.5, sin(a2) * 4.0)
		var l := OmniLight3D.new()
		l.light_color = Color(0.4, 0.7, 1.0)
		l.light_energy = 3.0
		l.omni_range = 34.0
		l.shadow_enabled = false
		root.add_child(l)
		pierres.append(root)


# =================================================================== l'eau : la mare, le ruisseau, la chute

func _build_eau() -> void:
	var sh: Shader = load("res://shaders/eau_douce_v69.gdshader")
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("deep", Color(0.08, 0.2, 0.2, 1.0))
	m.set_shader_parameter("shallow", Color(0.26, 0.42, 0.34, 1.0))
	m.set_shader_parameter("clarity", 1.6)
	if ResourceLoader.exists("res://assets/textures/water/water_n.png"):
		m.set_shader_parameter("ripple_n", load("res://assets/textures/water/water_n.png"))
	# la mare
	var disc := CylinderMesh.new()
	disc.top_radius = ABREUVOIR_R + 2.0
	disc.bottom_radius = ABREUVOIR_R + 2.0
	disc.height = 0.02
	disc.radial_segments = 40
	var mare := MeshInstance3D.new()
	mare.name = "Abreuvoir"
	mare.mesh = disc
	mare.material_override = m
	mare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mare)
	mare.position = W(ABREUVOIR.x, ABREUVOIR.y, EAU_Y)
	# le ruisseau : une bande d'eau qui suit son lit, qui coule (waterfall_v26)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for i in range(RUISSEAU.size() - 1):
		var a: Vector2 = RUISSEAU[i]
		var b: Vector2 = RUISSEAU[i + 1]
		for s in range(6):
			pts.append(a.lerp(b, s / 6.0))
	pts.append(RUISSEAU[RUISSEAU.size() - 1])
	var n: int = pts.size()
	var rows: Array = []
	for k in range(n):
		var p: Vector2 = pts[k]
		var tan: Vector2 = ((pts[mini(k + 1, n - 1)] as Vector2) - (pts[maxi(k - 1, 0)] as Vector2)).normalized()
		var side := Vector2(-tan.y, tan.x)
		var w: float = lerpf(1.6, 2.6, float(k) / (n - 1))
		var row: Array = []
		for a2 in [-1.0, 0.0, 1.0]:
			var q: Vector2 = p + side * w * a2
			var y: float = EAU_Y if k < n - 4 else minf(EAU_Y, top_local(q.x, q.y) + 0.25)
			row.append([W(q.x, q.y, y), Vector2((a2 + 1.0) * 0.5, float(k) / (n - 1) * 6.0)])
		rows.append(row)
	for k in range(n - 1):
		for i in range(2):
			for idx in [[k, i], [k, i + 1], [k + 1, i], [k, i + 1], [k + 1, i + 1], [k + 1, i]]:
				var v: Array = rows[idx[0]][idx[1]]
				st.set_normal(Vector3.UP)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	var brook := MeshInstance3D.new()
	brook.name = "Ruisseau_orpailleur"
	brook.mesh = st.commit()
	brook.material_override = m
	brook.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(brook)
	_chute()


## La Chute de l'Orpailleur : du bord ouest jusqu'à la mer (270 m de chute libre).
func _chute() -> void:
	var a: Vector2 = RUISSEAU[RUISSEAU.size() - 2]
	var b: Vector2 = RUISSEAU[RUISSEAU.size() - 1]
	var d2: Vector2 = (b - a).normalized()
	var th: float = atan2(b.y, b.x)
	var rim: Vector2 = Vector2(cos(th), sin(th)) * (coast_radius(th) - 1.0)
	var dir := Vector3(d2.x, 0, d2.y)
	var side := Vector3(-d2.y, 0, d2.x)
	var lip: Vector3 = W(rim.x, rim.y, top_local(rim.x * 0.98, rim.y * 0.98) + 0.2)
	var drop: float = lip.y + 0.4
	var rows: int = 48 if pc else 30
	var cols: int = 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid: Array = []
	for j in range(rows + 1):
		var t: float = float(j) / rows
		var out: float = 1.5 * sqrt(t * 3.0) + 9.0 * t
		var y: float = -drop * pow(t, 1.15)
		var width: float = lerpf(4.0, 20.0, pow(t, 0.8))
		var row: Array = []
		for i in range(cols + 1):
			var u: float = float(i) / cols
			var bulge: float = (1.0 - pow((u - 0.5) * 2.0, 2.0)) * (0.3 + 2.0 * t)
			row.append([lip + dir * (out + bulge) + side * (u - 0.5) * width + Vector3(0, y, 0), Vector2(u, t)])
		grid.append(row)
	for j in range(rows):
		for i in range(cols):
			for idx in [[j, i], [j + 1, i], [j, i + 1], [j, i + 1], [j + 1, i], [j + 1, i + 1]]:
				var v: Array = grid[idx[0]][idx[1]]
				st.set_normal(dir)
				st.set_uv(v[1])
				st.add_vertex(v[0])
	var fall := MeshInstance3D.new()
	fall.name = "Chute_orpailleur"
	fall.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/chute_ciel_v54.gdshader")
	m.set_shader_parameter("fall_length", drop)
	fall.material_override = m
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fall.extra_cull_margin = 30.0
	add_child(fall)
	var foot: Vector3 = lip + dir * 12.0
	foot.y = 0.0
	falls.append([lip, foot])
	_brume(foot + Vector3.UP * 3.0, Vector3(10, 2, 10), 60 if pc else 26, 7.0, 16.0, Color(0.93, 0.95, 0.97, 0.3), 2.5)
	_brume(lip + dir * 9.0 + Vector3.DOWN * drop * 0.5, Vector3(7, 24, 7), 36 if pc else 14, 6.0, 12.0, Color(0.95, 0.97, 1.0, 0.16), 1.0)


func _brume(at: Vector3, box: Vector3, amount: int, lifetime: float, size: float, color: Color, rise: float) -> void:
	var parts := GPUParticles3D.new()
	parts.amount = amount
	parts.lifetime = lifetime
	parts.preprocess = lifetime
	parts.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = rise * 0.5
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0.4, 0.15, 0)
	pm.damping_min = 0.2
	pm.damping_max = 0.5
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.25, color)
	fade.set_color(fade.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	parts.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load("res://assets/textures/ciel/nuage.png")
	mat.disable_receive_shadows = true
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(parts)
	parts.global_position = at

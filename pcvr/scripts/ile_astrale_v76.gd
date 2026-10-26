extends Node3D
## V76 : Astralys, l'île flottante des Lumens, à 380 m au-dessus de l'océan, au nord-ouest de
## l'archipel (entre Arcanelle et l'Île des Trois Soleils).
##  - Le dessus : un grand plateau (~190 m de rayon) presque plat, où la cité de cristal est posée ;
##    au centre, le dais de la Flèche de Cristal (4 m plus haut) ; à l'ouest, la cuvette des
##    Jardins suspendus ; une herbe argentée sur les bords ; le promontoire du sud-est porte le
##    Portail d'accueil, et, au-delà du bord, le belvédère du Rayon.
##  - Le dessous : une montagne renversée de roche sombre veinée de cristaux, de longues
##    stalactites de cristal, des îlots qui flottent tout autour.
##  - Deux îlots qu'on visite : l'Observatoire (au nord) et le Jardin des Apesanteurs (au
##    sud-ouest), reliés au plateau par des ponts de lumière (posés par la ville).
##  - Des chutes de lumière (de l'eau irisée) tombent des bords dans le vide.
##  - En bas, sur la mer : la Bouée d'accueil, d'où le Rayon d'accueil monte jusqu'au belvédère.
## Le relief se calcule à la demande (top_local) ; le sol physique est un maillage (trimesh).

const CENTER := Vector3(-820.0, 380.0, -760.0)
const Y0: float = 380.0
const R0: float = 192.0
const NR: int = 92
const NS: int = 420
const DEPTH: float = 190.0
const SECTORS: int = 10
const TEX := "res://assets/textures/astralys/"
## Le dais de la Flèche, la cuvette des jardins (repère local, +Z vers le sud).
const DAIS_R: float = 30.0
const DAIS_H: float = 4.0
const GARDENS := Vector2(-92.0, 58.0)
const PORTAIL := Vector2(130.0, 130.0)
## Le belvédère du Rayon (au-delà du bord) et, juste en dessous, sur la mer, la Bouée d'accueil.
const SPATIO_FLAT := Vector2(114.0, 60.0)
const RAYON := Vector2(156.0, 156.0)
const BUOY_Y: float = 0.0
## Les îlots qu'on visite : [nom, centre local, rayon, hauteur du dessus (local), profondeur].
const ISLETS := [["observatoire", Vector2(0.0, -236.0), 20.0, 6.0, 70.0], ["apesanteur", Vector2(-196.0, 138.0), 24.0, -2.0, 80.0]]
## La mer de la bouée (un cercle) et la voie de mer qui la relie à la mer de l'archipel.
const SEA_R: float = 90.0
const LANE_END := Vector2(-480.0, -330.0)
const LANE_W: float = 60.0

var pc: bool = true
var terrain_mat: ShaderMaterial
var falls: Array = []                    # [Vector3 haut, Vector3 bas] : les chutes de lumière
var crystals: Array = []                 # les cristaux du dessous (MeshInstance3D)
var islet_tops: Dictionary = {}          # nom -> Vector3 (monde, le milieu du dessus)
var _coast := FastNoiseLite.new()
var _noise := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, Y0 + y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func buoy_world() -> Vector3:
	return Vector3(CENTER.x + RAYON.x, BUOY_Y, CENTER.z + RAYON.y)


# =================================================================== la forme

func _setup_noise() -> void:
	_coast.seed = 7601
	_coast.frequency = 0.9
	_coast.fractal_octaves = 3
	_noise.seed = 7602
	_noise.frequency = 0.012
	_noise.fractal_octaves = 4
	_under.seed = 7603
	_under.frequency = 0.035
	_under.fractal_octaves = 4


func coast_radius(theta: float) -> float:
	var n: float = _coast.get_noise_2d(cos(theta) * 1.4, sin(theta) * 1.4)
	var r: float = R0 + n * 10.0 + sin(theta * 3.0 + 0.6) * 4.0 + sin(theta * 7.0 + 1.3) * 1.5
	# le promontoire du Portail (au sud-est)
	r += 16.0 * exp(-pow(wrapf(theta - PI * 0.25, -PI, PI) / 0.16, 2.0))
	return r


## La hauteur du dessus du plateau, en repère local (par rapport à Y0).
func top_local(lx: float, lz: float) -> float:
	var l := Vector2(lx, lz)
	var r: float = l.length()
	var rr: float = coast_radius(atan2(lz, lx))
	var wild: float = smoothstep(135.0, 165.0, r)
	# le Spatioport (ses aires d'envol) reste plat
	wild *= smoothstep(42.0, 58.0, l.distance_to(SPATIO_FLAT))
	var h: float = _noise.get_noise_2d(lx, lz) * 0.06 + (_noise.get_noise_2d(lx * 0.6 + 50.0, lz * 0.6) * 1.6 + 0.4) * wild
	# le dais de la Flèche de Cristal
	h += DAIS_H * (1.0 - smoothstep(DAIS_R, DAIS_R + 12.0, r))
	# la cuvette des Jardins suspendus
	var dg: float = l.distance_to(GARDENS)
	h -= 1.4 * (1.0 - smoothstep(18.0, 30.0, dg))
	# le bord arrondi : le plateau bascule dans le vide
	h -= 3.0 * pow(smoothstep(rr - 9.0, rr, r), 1.6)
	return h


## La hauteur du sol (monde) du plateau ou d'un îlot, ou -INF hors de l'île.
func height(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	if l.length_squared() < 230.0 * 230.0 and l.length() <= coast_radius(atan2(l.y, l.x)):
		return Y0 + top_local(l.x, l.y)
	for it in ISLETS:
		var d: float = l.distance_to(it[1])
		if d <= float(it[2]):
			return Y0 + float(it[3]) - 1.6 * pow(smoothstep(float(it[2]) - 4.0, float(it[2]), d), 1.6)
	return -INF


## Au-dessus de l'île (ou d'un îlot), et à peu près à sa hauteur ?
func contains(p: Vector3) -> bool:
	return p.y > Y0 - DEPTH - 30.0 and p.y < Y0 + 320.0 and near_xz(p.x, p.z, 30.0)


func near_xz(wx: float, wz: float, margin: float) -> bool:
	var l: Vector2 = L(wx, wz)
	if l.length() < coast_radius(atan2(l.y, l.x)) + margin + 16.0:
		return true
	for it in ISLETS:
		if l.distance_to(it[1]) < float(it[2]) + margin:
			return true
	return l.distance_to(RAYON) < 12.0 + margin


## Sur le dessus (on y marche), un peu en retrait du bord ?
func on_top(p: Vector3) -> bool:
	var h: float = height(p.x, p.z)
	return h > -INF and absf(p.y - h) < 6.0


## La mer de la bouée (un cercle) et sa voie vers la mer de l'archipel : on y navigue.
static func sea_contains(wx: float, wz: float) -> bool:
	var b: Vector3 = buoy_world()
	var p := Vector2(wx, wz)
	if p.distance_to(Vector2(b.x, b.z)) < SEA_R:
		return true
	return _seg_dist(p, Vector2(b.x, b.z), LANE_END) < LANE_W * 0.5


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func sea_clamp(wx: float, wz: float) -> Vector2:
	var b: Vector3 = buoy_world()
	var c := Vector2(b.x, b.z)
	var p := Vector2(wx, wz)
	var a: Vector2 = c + (p - c).limit_length(SEA_R - 0.5)
	var ab: Vector2 = LANE_END - c
	var t: float = clampf((p - c).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var q: Vector2 = c + ab * t
	var lane: Vector2 = q + (p - q).limit_length(LANE_W * 0.5 - 0.5)
	return a if p.distance_to(a) < p.distance_to(lane) else lane


# =================================================================== construction

func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	pc = high_quality
	_rng.seed = 7600
	_setup_noise()
	_bake_biome()
	_make_material()
	_build_top()
	_build_underside(Vector2.ZERO, 0.2, DEPTH, true)
	for it in ISLETS:
		_build_islet(it)
	_build_floaters()
	_build_falls()
	print("ILE_MANGA_V76: Astralys (île flottante) en ", Time.get_ticks_msec() - t0, " ms")


func _make_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/astralys_terrain_v76.gdshader")
	for k in ["herbe_lunaire", "nacre", "cristal_sol", "mousse_astrale", "sable_stellaire", "roche_astrale"]:
		var t: String = TEX + k + ".png"
		if ResourceLoader.exists(t):
			mat.set_shader_parameter(k + "_tex", load(t))
		var tn: String = TEX + k + "_n.png"
		if ResourceLoader.exists(tn):
			mat.set_shader_parameter(k + "_n", load(tn))
	mat.set_shader_parameter("center", Vector2(CENTER.x, CENTER.z))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - BIOME_HALF, CENTER.z - BIOME_HALF, BIOME_HALF * 2.0, BIOME_HALF * 2.0))
	mat.set_shader_parameter("y0", Y0)
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("extra_detail", pc)
	terrain_mat = mat


# =================================================================== la carte des sols

const BIOME_RES: int = 256
const BIOME_HALF: float = 260.0
## Les dalles de cristal : [centre local, rayon] (le dais de la Flèche, l'Agora, les aires du
## Spatioport, le belvédère du Portail).
const PLAZAS := [[Vector2(0.0, 0.0), 40.0], [Vector2(0.0, 44.0), 20.0], [Vector2(100.0, 60.0), 28.0], [Vector2(130.0, 130.0), 12.0]]
var biome: Image


## R : les dalles de nacre de la ville ; G : les dalles de cristal (les places) ; B : la mousse
## astrale (les jardins, l'îlot des apesanteurs) ; A : le sable stellaire des allées.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = BIOME_HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var p := Vector2(-BIOME_HALF + (xi + 0.5) * px, -BIOME_HALF + (zi + 0.5) * px)
			var n: float = _noise.get_noise_2d(p.x * 3.0, p.y * 3.0)
			var r: float = p.length()
			var city: float = 1.0 - smoothstep(128.0, 150.0, r + n * 14.0)
			var plaza: float = 0.0
			for pl in PLAZAS:
				plaza = maxf(plaza, 1.0 - smoothstep(float(pl[1]) - 3.0, float(pl[1]) + 1.0, p.distance_to(pl[0])))
			var moss: float = 1.0 - smoothstep(26.0, 40.0, p.distance_to(GARDENS) + n * 8.0)
			moss = maxf(moss, 1.0 - smoothstep(16.0, 26.0, p.distance_to(ISLETS[1][1])))
			var obs: float = 1.0 - smoothstep(16.0, 20.0, p.distance_to(ISLETS[0][1]))
			# les allées de sable : des rayons de la Flèche vers le bord, et un anneau
			var ang: float = atan2(p.y, p.x)
			var spoke: float = 1.0 - smoothstep(2.0, 3.6, absf(wrapf(ang * 8.0 / TAU, -0.5, 0.5)) * r * TAU / 8.0)
			var ring: float = 1.0 - smoothstep(2.0, 3.6, absf(r - 112.0))
			var sand: float = maxf(spoke * smoothstep(40.0, 50.0, r), ring) * city
			biome.set_pixel(xi, zi, Color(maxf(city * (1.0 - moss), obs), plaza, moss * (1.0 - plaza), sand * (1.0 - plaza) * (1.0 - moss)))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


func _ring_point(i: int, j: int) -> Vector3:
	var theta: float = TAU * float(j) / NS
	var rr: float = coast_radius(theta)
	var r: float = rr * pow(float(i) / NR, 0.85)
	var lx: float = cos(theta) * r
	var lz: float = sin(theta) * r
	return Vector3(lx, top_local(lx, lz), lz)


## Le dessus : des anneaux de la Flèche au bord, coupés en secteurs (un maillage et un sol par
## secteur).
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
		mi.name = "Astralys_dessus_%d" % s
		mi.mesh = st.commit()
		mi.material_override = terrain_mat
		add_child(mi)
		mi.position = Vector3(CENTER.x, Y0, CENTER.z)
		_trimesh(faces, "Astralys_sol_%d" % s, Vector3(CENTER.x, Y0, CENTER.z))


func _tri(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	# (l'ordre des sommets : la face avant regarde vers le haut)
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


## Le dessous : une montagne renversée (du bord jusqu'à la pointe), bosselée, rentrée, striée.
## main : le grand plateau (le bord suit la côte) ; sinon un îlot (centre, rayon, haut, profondeur).
func _build_underside(c: Vector2, top_y: float, depth: float, main: bool, radius: float = 0.0) -> void:
	var nu: int = 28 if main else 12
	var ns: int = 160 if main else 40
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	var tip := Vector3(c.x + (12.0 if main else 2.0), top_y - depth, c.y - (8.0 if main else 1.0))
	for k in range(nu + 1):
		var t: float = float(k) / nu
		var row: Array = []
		for j in range(ns):
			var th: float = TAU * float(j) / ns
			var rr: float = (coast_radius(th) - 1.0) if main else radius
			# le profil : le bord, un ventre qui rentre, puis la pointe (un cône bombé)
			var prof: float = pow(1.0 - t, 0.75) * (1.0 + 0.08 * sin(t * PI))
			var dir := Vector2(cos(th), sin(th))
			var base := Vector3(c.x + dir.x * rr * prof, lerpf(top_y - 3.2 if main else top_y - 1.6, tip.y, pow(t, 1.15)), c.y + dir.y * rr * prof)
			base = base.lerp(Vector3(tip.x, base.y, tip.z), t * t * 0.5)
			var n: float = _under.get_noise_3d(base.x * 0.6, base.y * 0.35, base.z * 0.6)
			var strata: float = sin(base.y * 0.9 + n * 3.0) * 0.6
			var push: float = (n * 7.0 + strata) * (1.0 - t * 0.6) * (1.0 if main else 0.35) * minf(t * 6.0, 1.0)
			row.append(base + Vector3(dir.x, 0, dir.y) * push)
		rows.append(row)
	for k in range(nu):
		for j in range(ns):
			var jn: int = (j + 1) % ns
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][jn]
			var cc: Vector3 = rows[k + 1][j]
			var d: Vector3 = rows[k + 1][jn]
			for v in [a, cc, d, a, d, b]:
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Astralys_dessous" if main else "Ilot_dessous"
	mi.mesh = st.commit()
	mi.material_override = load("res://scripts/astrale_mats_v76.gd").make("roche76")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)
	# les cristaux : des stalactites lumineuses qui pendent sous la roche
	var n_cr: int = (60 if pc else 26) if main else 8
	var Mats = load("res://scripts/astrale_mats_v76.gd")
	var cols := ["cristal76_bleu", "cristal76_violet", "cristal76_turquoise", "cristal76_rose"]
	for q in range(n_cr):
		var kk: int = _rng.randi_range(2, nu - 3)
		var jj: int = _rng.randi() % ns
		var p0: Vector3 = rows[kk][jj]
		var len: float = _rng.randf_range(4.0, 18.0) * (1.0 if main else 0.5)
		var cm := CylinderMesh.new()
		cm.top_radius = len * 0.12
		cm.bottom_radius = 0.0
		cm.height = len
		cm.radial_segments = 6
		cm.rings = 1
		var ci := MeshInstance3D.new()
		ci.mesh = cm
		ci.material_override = Mats.make(cols[q % cols.size()])
		ci.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ci)
		ci.position = Vector3(CENTER.x, Y0, CENTER.z) + p0 - Vector3(0, len * 0.45, 0)
		ci.rotation = Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf() * TAU, _rng.randf_range(-0.25, 0.25))
		crystals.append(ci)


## Un îlot qu'on visite : un dessus rond (un sol), un dessous.
func _build_islet(it: Array) -> void:
	var c: Vector2 = it[1]
	var r: float = float(it[2])
	var ty: float = float(it[3])
	var nr: int = 12
	var ns: int = 48
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var rows: Array = []
	for i in range(nr + 1):
		var row: Array = []
		for j in range(ns):
			var th: float = TAU * float(j) / ns
			var rr: float = r * float(i) / nr
			var d := Vector2(cos(th), sin(th)) * rr
			var y: float = ty - 1.6 * pow(smoothstep(r - 4.0, r, rr), 1.6)
			row.append(Vector3(c.x + d.x, y, c.y + d.y))
		rows.append(row)
	for i in range(nr):
		for j in range(ns):
			var jn: int = (j + 1) % ns
			_tri(st, faces, rows[i][j], rows[i][jn], rows[i + 1][jn])
			_tri(st, faces, rows[i][j], rows[i + 1][jn], rows[i + 1][j])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Ilot_" + str(it[0])
	mi.mesh = st.commit()
	mi.material_override = terrain_mat
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)
	_trimesh(faces, "Ilot_sol_" + str(it[0]), Vector3(CENTER.x, Y0, CENTER.z))
	_build_underside(c, ty, float(it[4]), false, r)
	islet_tops[str(it[0])] = W(c.x, c.y, ty)


## Des rochers qui flottent tout autour (sans sol), avec leurs cristaux.
func _build_floaters() -> void:
	var Mats = load("res://scripts/astrale_mats_v76.gd")
	var n: int = 18 if pc else 9
	for k in range(n):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(R0 + 30.0, R0 + 110.0)
		var size: float = _rng.randf_range(3.0, 11.0)
		var p := Vector3(cos(a) * d, _rng.randf_range(-80.0, 30.0), sin(a) * d)
		if Vector2(p.x, p.z).distance_to(RAYON) < 30.0:
			continue
		var sm := SphereMesh.new()
		sm.radius = size
		sm.height = size * 1.1
		sm.radial_segments = 14
		sm.rings = 8
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = Mats.make("roche76")
		add_child(mi)
		mi.position = Vector3(CENTER.x, Y0, CENTER.z) + p
		mi.scale = Vector3(1.0, 0.55, 1.0)
		mi.rotation.y = _rng.randf() * TAU
		mi.set_meta("float", [mi.position, _rng.randf() * TAU, _rng.randf_range(0.4, 1.2)])
		var cm := CylinderMesh.new()
		cm.top_radius = size * 0.35
		cm.bottom_radius = 0.0
		cm.height = size * 1.4
		cm.radial_segments = 6
		var ci := MeshInstance3D.new()
		ci.mesh = cm
		ci.material_override = Mats.make(["cristal76_bleu", "cristal76_violet", "cristal76_turquoise"][k % 3])
		mi.add_child(ci)
		ci.position = Vector3(0, -size * 1.2, 0)
		floaters.append(mi)


var floaters: Array = []


## Les chutes de lumière : de l'eau irisée qui file du bord et se perd dans le vide.
func _build_falls() -> void:
	var sh: Shader = load("res://shaders/chute_lumiere_v76.gdshader") if ResourceLoader.exists("res://shaders/chute_lumiere_v76.gdshader") else null
	for th_deg in [105.0, 200.0, 318.0]:
		var th: float = deg_to_rad(th_deg)
		var rr: float = coast_radius(th)
		var top := Vector3(cos(th) * (rr + 0.5), top_local(cos(th) * (rr - 6.0), sin(th) * (rr - 6.0)) - 2.6, sin(th) * (rr + 0.5))
		var len: float = 170.0
		var qm := QuadMesh.new()
		qm.size = Vector2(14.0, len)
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		if sh != null:
			var m := ShaderMaterial.new()
			m.shader = sh
			mi.material_override = m
		else:
			mi.material_override = load("res://scripts/astrale_mats_v76.gd").make("pont76_turquoise")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var wp: Vector3 = Vector3(CENTER.x, Y0, CENTER.z) + top + Vector3(0, -len * 0.5, 0) + Vector3(cos(th), 0, sin(th)) * 2.0
		mi.global_transform = Transform3D(Basis(Vector3.UP, -th + PI * 0.5), wp)
		falls.append([Vector3(CENTER.x, Y0, CENTER.z) + top, wp - Vector3(0, len * 0.5, 0)])


var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	for f in floaters:
		var meta: Array = f.get_meta("float")
		(f as Node3D).position = (meta[0] as Vector3) + Vector3(0, sin(_clock * 0.25 * float(meta[2]) + float(meta[1])) * 1.6, 0)

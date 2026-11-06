extends Node3D
## V113 : la Cité des Nuées, l'île flottante de Hautefond. À deux cents mètres au-dessus de la ville
## (un peu au nord-ouest de la Grande Colonne), un plateau rond d'environ deux cents mètres de large :
##  - le dessus : presque plat (la ville y est posée), une cuvette pour l'étang du Parc des Brumes et
##    son ruisseau ; le bord s'arrondit et bascule dans le vide (la Promenade du bord et sa balustrade
##    de verre le gardent) ;
##  - la ceinture : un anneau de béton blanc qui tient le bord, un liseré de lumière froide ;
##  - le dessous : une montagne renversée de roche grise, bosselée et striée, jusqu'à la pointe ;
##  - les quatre sustentateurs (de grandes nacelles blanches à anneau lumineux bleuté, avec leur
##    voile de sustentation) et le cinquième, sous la pointe ;
##  - des nuages, sous l'île, qui dérivent lentement autour ;
##  - la Cascade des Nuées : l'eau de l'étang sort d'un bec d'acier dans la ceinture et tombe dans le
##    vide ; elle se change en brume bien avant de toucher le sol.
## Le relief se calcule à la demande (top_local) ; le sol physique est un maillage (trimesh).
## Repère local : +X à l'est, +Z au sud (comme partout) ; l'origine est le centre du plateau.

const HF_CENTER := Vector3(-980.0, 0.0, 1420.0)  # le centre de Hautefond (la Grande Colonne)
const OFF := Vector2(-50.0, -50.0)                # le centre de l'île, par rapport à la Colonne
const CENTER := Vector3(-1030.0, 236.0, 1370.0)
const Y0: float = 236.0
const R0: float = 106.0
const DEPTH: float = 104.0
const NR: int = 64
const NS: int = 288
const SECTORS: int = 8
const TEX := "res://assets/textures/montjoie/"
const TEX113 := "res://assets/textures/nuees/"
## La Grande Colonne, en repère local ; la Ligne des Nuées part du Belvédère, à 22 m de l'axe, vers l'île.
const COL_L := Vector2(50.0, 50.0)
const TUBE_OFF: float = 22.0
## Les grands lieux (repère local)
const ESPLANADE_R: float = 24.0
const POND := Vector2(-54.0, -46.0)
const POND_R: float = 12.0
const POND_Y: float = -0.72
const CASCADE_DEG: float = -132.0
const PARC := Vector2(-58.0, -40.0)
const NAVETTE_R: float = 86.0
const NAVETTE_Y: float = 7.0
## Les quatre sustentateurs : angle (degrés), distance du centre ; et celui de la pointe.
const ENGINES := [[0.0, 56.0], [90.0, 56.0], [180.0, 56.0], [270.0, 56.0]]

var pc: bool = true
var terrain_mat: ShaderMaterial
var biome: Image
var engines: Array = []                  # [Node3D (la nacelle), anneau intérieur, voile, lumière]
var clouds: Array = []                   # [MeshInstance3D, angle, rayon, hauteur, vitesse]
var cascade_top := Vector3.ZERO
var rim_glow: StandardMaterial3D
var engine_glow: StandardMaterial3D
var _coast := FastNoiseLite.new()
var _noise := FastNoiseLite.new()
var _under := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _cloud_root: Node3D


static func W(x: float, z: float, y: float = 0.0) -> Vector3:
	return Vector3(CENTER.x + x, Y0 + y, CENTER.z + z)


static func L(wx: float, wz: float) -> Vector2:
	return Vector2(wx - CENTER.x, wz - CENTER.z)


static func polar(deg: float, r: float) -> Vector2:
	var a: float = deg_to_rad(deg)
	return Vector2(cos(a) * r, sin(a) * r)


## L'axe de la Ligne des Nuées (repère local) : du Belvédère vers l'île.
static func tube_l() -> Vector2:
	return COL_L + (-COL_L).normalized() * TUBE_OFF


static func tube_dir_to_column() -> Vector3:
	var d: Vector2 = (COL_L - tube_l()).normalized()
	return Vector3(d.x, 0, d.y)


# =================================================================== la forme

func _setup_noise() -> void:
	_coast.seed = 11301
	_coast.frequency = 0.8
	_coast.fractal_octaves = 3
	_noise.seed = 11302
	_noise.frequency = 0.02
	_noise.fractal_octaves = 3
	_under.seed = 11303
	_under.frequency = 0.04
	_under.fractal_octaves = 4


func coast_radius(theta: float) -> float:
	var n: float = _coast.get_noise_2d(cos(theta) * 1.3, sin(theta) * 1.3)
	var r: float = R0 + n * 6.0 + sin(theta * 3.0 + 0.4) * 2.0 + sin(theta * 5.0 + 2.1) * 1.0
	# le Port des Nuées (à l'ouest) avance un peu
	r += 6.0 * exp(-pow(wrapf(theta - PI, -PI, PI) / 0.22, 2.0))
	return r


func coast_deg(deg: float) -> float:
	return coast_radius(deg_to_rad(deg))


## La hauteur du dessus du plateau, en repère local (par rapport à Y0).
func top_local(lx: float, lz: float) -> float:
	var l := Vector2(lx, lz)
	var r: float = l.length()
	var rr: float = coast_radius(atan2(lz, lx))
	var h: float = _noise.get_noise_2d(lx, lz) * 0.08
	# le Parc des Brumes : de douces bosses de pelouse, la cuvette de l'étang
	var dp: float = l.distance_to(PARC)
	h += (0.5 + _noise.get_noise_2d(lx * 2.0 + 30.0, lz * 2.0) * 0.6) * (1.0 - smoothstep(18.0, 34.0, dp))
	var dq: float = l.distance_to(POND)
	h = lerpf(h, -1.4, 1.0 - smoothstep(POND_R - 3.0, POND_R + 1.0, dq))
	# le ruisseau, de l'étang jusqu'à la grille (avant la Promenade)
	var a: Vector2 = POND
	var b: Vector2 = polar(CASCADE_DEG, coast_deg(CASCADE_DEG) - 10.0)
	var ab: Vector2 = b - a
	var t: float = clampf((l - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var dd: float = l.distance_to(a + ab * t)
	if t > 0.0 and t < 1.0:
		h = minf(h, lerpf(h, -0.7, 1.0 - smoothstep(0.9, 1.6, dd)))
	# le bord arrondi : le plateau bascule dans le vide (au-delà de la balustrade)
	h -= 2.6 * pow(smoothstep(rr - 5.0, rr, r), 1.6)
	return h


## La hauteur du sol (monde) du plateau, ou -INF hors de l'île.
func height(wx: float, wz: float) -> float:
	var l: Vector2 = L(wx, wz)
	if l.length_squared() < 130.0 * 130.0 and l.length() <= coast_radius(atan2(l.y, l.x)):
		return Y0 + top_local(l.x, l.y)
	return -INF


## Le dessous de la roche (monde) à la distance r du centre (sans les bosses).
func under_y(r: float, rr: float) -> float:
	var q: float = clampf(r / rr, 0.0, 1.0)
	return Y0 - 3.2 - (DEPTH - 3.2) * pow(1.0 - pow(q, 1.6), 1.25)


## Au-dessus de l'île, ou dans sa roche, ou dessous à portée de nuage ?
func contains(p: Vector3) -> bool:
	return p.y > Y0 - DEPTH - 40.0 and p.y < Y0 + 160.0 and near_xz(p.x, p.z, 30.0)


func near_xz(wx: float, wz: float, margin: float) -> bool:
	var l: Vector2 = L(wx, wz)
	return l.length() < coast_radius(atan2(l.y, l.x)) + margin + 20.0


## Sur le dessus (on y marche) ?
func on_top(p: Vector3) -> bool:
	var h: float = height(p.x, p.z)
	return h > -INF and absf(p.y - h) < 6.0


## [bas de la roche, dessus] au-dessus de (x, z), ou [] hors de l'île (pour l'aéronef).
func rock_span(x: float, z: float) -> Array:
	var l: Vector2 = L(x, z)
	var r: float = l.length()
	if r > 130.0:
		return []
	var rr: float = coast_radius(atan2(l.y, l.x)) + 1.5
	if r >= rr:
		return []
	var top: float = height(x, z)
	if top < -1e6:
		top = Y0 - 2.0
	return [under_y(r, rr) - 14.0, top]


func solid(p: Vector3) -> bool:
	var sp: Array = rock_span(p.x, p.z)
	return not sp.is_empty() and p.y > float(sp[0]) and p.y < float(sp[1]) - 0.6


# =================================================================== construction

func build(high_quality: bool) -> void:
	var t0: int = Time.get_ticks_msec()
	pc = high_quality
	_rng.seed = 11300
	_setup_noise()
	_bake_biome()
	_make_material()
	_build_top()
	_build_rim()
	_build_underside()
	_build_engines()
	_build_clouds()
	_build_cascade()
	print("ILE_MANGA_V113: la Cité des Nuées (île flottante) en ", Time.get_ticks_msec() - t0, " ms")


# =================================================================== la carte des sols

const BIOME_RES: int = 256
const BIOME_HALF: float = 128.0
## Les dalles : [centre local, rayon] (l'Esplanade, le parvis de la Gare, le parvis de l'Institut, le
## Port, le parvis du Conseil, la terrasse du Café).
const PLAZAS := [[Vector2(0.0, 0.0), 26.0], [Vector2(36.0, 36.0), 14.0], [Vector2(0.0, -70.0), 16.0], [Vector2(-92.0, 0.0), 14.0],
	[Vector2(0.0, -36.0), 12.0], [Vector2(0.0, 32.0), 10.0], [Vector2(66.0, 0.0), 10.0], [Vector2(-50.0, 50.0), 12.0]]


## R : la terre des massifs ; G : rien ; B : le sous-bois (sous les arbres du parc) ; A : les dalles.
func _bake_biome() -> void:
	biome = Image.create(BIOME_RES, BIOME_RES, false, Image.FORMAT_RGBA8)
	var px: float = BIOME_HALF * 2.0 / BIOME_RES
	for zi in range(BIOME_RES):
		for xi in range(BIOME_RES):
			var p := Vector2(-BIOME_HALF + (xi + 0.5) * px, -BIOME_HALF + (zi + 0.5) * px)
			var n: float = _noise.get_noise_2d(p.x * 3.0, p.y * 3.0)
			var r: float = p.length()
			var rr: float = coast_radius(atan2(p.y, p.x))
			var pave: float = 0.0
			for pl in PLAZAS:
				pave = maxf(pave, 1.0 - smoothstep(float(pl[1]) - 1.5, float(pl[1]) + 0.5, p.distance_to(pl[0])))
			# les allées : huit rayons de l'Esplanade jusqu'au bord, l'anneau du boulevard, la Promenade
			var ang: float = atan2(p.y, p.x)
			var spoke: float = 1.0 - smoothstep(1.8, 2.6, absf(wrapf(ang * 8.0 / TAU, -0.5, 0.5)) * r * TAU / 8.0)
			var ring: float = 1.0 - smoothstep(2.2, 3.0, absf(r - 46.0))
			var prom: float = 1.0 - smoothstep(2.6, 3.4, absf(r - (rr - 8.5)))
			pave = maxf(pave, maxf(spoke * smoothstep(20.0, 26.0, r), maxf(ring, prom)))
			var wood: float = (1.0 - smoothstep(14.0, 26.0, p.distance_to(PARC) + n * 8.0)) * (1.0 - pave)
			var bed: float = 0.0
			if r > 30.0 and r < rr - 13.0 and pave < 0.2 and n > 0.42:
				bed = 0.8
			biome.set_pixel(xi, zi, Color(bed * (1.0 - wood), 0.0, wood, pave))


func biome_at(wx: float, wz: float) -> Color:
	var l: Vector2 = L(wx, wz)
	var xi: int = clampi(int((l.x + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	var zi: int = clampi(int((l.y + BIOME_HALF) / (BIOME_HALF * 2.0) * BIOME_RES), 0, BIOME_RES - 1)
	return biome.get_pixel(xi, zi) if biome != null else Color(0, 0, 0, 0)


func _make_material() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/montjoie_terrain_v71.gdshader")
	var texs := {"prairie": TEX + "prairie", "champ": TEX + "champ", "chemin": TEX + "chemin", "sous_bois": TEX + "sous_bois",
		"roche_crocs": TEX + "roche_crocs", "sable_lac": TEX + "sable_lac", "paves": TEX113 + "dalle_claire"}
	for k in texs:
		for suf in [["_tex", ".png"], ["_n", "_n.png"]]:
			var t: String = str(texs[k]) + str(suf[1])
			if ResourceLoader.exists(t):
				mat.set_shader_parameter(str(k) + str(suf[0]), load(t))
			elif str(k) == "paves" and ResourceLoader.exists(TEX + "paves" + str(suf[1])):
				mat.set_shader_parameter(str(k) + str(suf[0]), load(TEX + "paves" + str(suf[1])))
	mat.set_shader_parameter("biome", ImageTexture.create_from_image(biome))
	mat.set_shader_parameter("biome_rect", Vector4(CENTER.x - BIOME_HALF, CENTER.z - BIOME_HALF, BIOME_HALF * 2.0, BIOME_HALF * 2.0))
	mat.set_shader_parameter("lake", Vector4(CENTER.x + 5000.0, CENTER.z, 1.0, 1.0))
	mat.set_shader_parameter("lake_y", -100.0)
	mat.set_shader_parameter("town", Vector4(CENTER.x, CENTER.z, 140.0, 0.0))
	mat.set_shader_parameter("water_level", -100.0)
	mat.set_shader_parameter("extra_detail", pc)
	terrain_mat = mat


# =================================================================== le dessus

func _ring_point(i: int, j: int) -> Vector3:
	var theta: float = TAU * float(j) / NS
	var rr: float = coast_radius(theta)
	var r: float = rr * pow(float(i) / NR, 0.8)
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
		mi.name = "Nuees_dessus_%d" % s
		mi.mesh = st.commit()
		mi.material_override = terrain_mat
		add_child(mi)
		mi.position = Vector3(CENTER.x, Y0, CENTER.z)
		_trimesh(faces, "Nuees_sol_%d" % s, Vector3(CENTER.x, Y0, CENTER.z))


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


# =================================================================== la ceinture

## L'anneau de béton blanc qui tient le bord (de -0.4 à -3.6 m), un liseré de lumière froide.
func _build_rim() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lst := SurfaceTool.new()
	lst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 240
	for j in range(n):
		var t0: float = TAU * float(j) / n
		var t1: float = TAU * float(j + 1) / n
		var r0: float = coast_radius(t0) + 0.35
		var r1: float = coast_radius(t1) + 0.35
		var d0 := Vector3(cos(t0), 0, sin(t0))
		var d1 := Vector3(cos(t1), 0, sin(t1))
		var u0: float = float(j) * 2.8
		var u1: float = float(j + 1) * 2.8
		# la face extérieure (un léger fruit), le dessus, la sous-face
		var ya: float = -2.4
		var yb: float = -6.2
		_quad(st, d0 * r0 + Vector3.UP * ya, d1 * r1 + Vector3.UP * ya, d1 * (r1 - 0.6) + Vector3.UP * yb, d0 * (r0 - 0.6) + Vector3.UP * yb, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1.3), Vector2(u0, 1.3), (d0 + d1).normalized())
		_quad(st, d0 * (r0 - 3.2) + Vector3.UP * (ya + 0.25), d1 * (r1 - 3.2) + Vector3.UP * (ya + 0.25), d1 * r1 + Vector3.UP * ya, d0 * r0 + Vector3.UP * ya, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1), Vector3.UP)
		_quad(st, d0 * (r0 - 0.6) + Vector3.UP * yb, d1 * (r1 - 0.6) + Vector3.UP * yb, d1 * (r1 - 4.0) + Vector3.UP * (yb + 0.4), d0 * (r0 - 4.0) + Vector3.UP * (yb + 0.4), Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1), Vector3.DOWN)
		# le liseré de lumière (un ruban un peu en saillie)
		var yl: float = -4.1
		_quad(lst, d0 * (r0 + 0.04) + Vector3.UP * (yl + 0.12), d1 * (r1 + 0.04) + Vector3.UP * (yl + 0.12), d1 * (r1 - 0.04) + Vector3.UP * (yl - 0.12), d0 * (r0 - 0.04) + Vector3.UP * (yl - 0.12), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, (d0 + d1).normalized())
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Nuees_ceinture"
	mi.mesh = st.commit()
	mi.material_override = load("res://scripts/nuees_mats_v113.gd").make("beton113")
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)
	lst.generate_normals()
	var li := MeshInstance3D.new()
	li.name = "Nuees_lisere"
	li.mesh = lst.commit()
	rim_glow = StandardMaterial3D.new()
	rim_glow.albedo_color = Color(0.85, 0.95, 1.0)
	rim_glow.emission_enabled = true
	rim_glow.emission = Color(0.7, 0.88, 1.0)
	rim_glow.emission_energy_multiplier = 0.4
	rim_glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	li.material_override = rim_glow
	li.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(li)
	li.position = Vector3(CENTER.x, Y0, CENTER.z)


## Un quadrilatère (a, b, c, d dans l'ordre du tour) dont la face avant regarde du côté de want.
## (Godot : la face avant tourne dans le sens des aiguilles d'une montre vue de devant.)
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, want: Vector3) -> void:
	var nrm: Vector3 = (b - a).cross(c - a)
	var order: Array = [[a, ua], [c, uc], [b, ub], [a, ua], [d, ud], [c, uc]] if nrm.dot(want) > 0.0 else [[a, ua], [b, ub], [c, uc], [a, ua], [c, uc], [d, ud]]
	for e in order:
		st.set_uv(e[1])
		st.add_vertex(e[0])


# =================================================================== le dessous

func _build_underside() -> void:
	var nu: int = 34 if pc else 22
	var ns: int = 150 if pc else 90
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for k in range(nu + 1):
		var t: float = float(k) / nu
		var row: Array = []
		for j in range(ns):
			var th: float = TAU * float(j) / ns
			var rr: float = coast_radius(th) - 0.4
			var r: float = rr * (1.0 - t)
			var dir := Vector2(cos(th), sin(th))
			var y: float = under_y(r, rr) - Y0
			if k == 0:
				y = -5.8
			var base := Vector3(dir.x * r, y, dir.y * r)
			var nz: float = _under.get_noise_3d(base.x * 0.7, base.y * 0.4, base.z * 0.7)
			var big: float = _under.get_noise_3d(base.x * 0.18 + 40.0, base.y * 0.12, base.z * 0.18)
			var ridge: float = 1.0 - absf(_under.get_noise_2d(th * 9.0, base.y * 0.05))
			var strata: float = sin(base.y * 0.8 + nz * 3.0) * 0.7
			var k_in: float = minf(t * 5.0, 1.0) * (1.0 - t * 0.7)
			base += Vector3(dir.x, 0, dir.y) * (nz * 7.0 + strata + big * 10.0 + ridge * ridge * 4.0) * k_in
			base.y += (nz * 6.0 + big * 9.0) * minf(t * 4.0, 1.0)
			row.append(base)
		rows.append(row)
	var tip := Vector3(0, -DEPTH - 4.0, 0)
	for k in range(nu):
		for j in range(ns):
			var jn: int = (j + 1) % ns
			var a: Vector3 = rows[k][j]
			var b: Vector3 = rows[k][jn]
			var cc: Vector3 = rows[k + 1][j]
			var d: Vector3 = rows[k + 1][jn]
			for v in [a, cc, d, a, d, b]:
				st.set_uv(Vector2((v as Vector3).x + (v as Vector3).y, (v as Vector3).z - (v as Vector3).y) * 0.08)
				st.add_vertex(v)
	for j2 in range(ns):
		var jn2: int = (j2 + 1) % ns
		for v2 in [rows[nu][j2], tip, rows[nu][jn2]]:
			st.set_uv(Vector2((v2 as Vector3).x, (v2 as Vector3).z) * 0.08)
			st.add_vertex(v2)
	st.generate_normals()
	_stalactites(rows, nu, ns)
	var mi := MeshInstance3D.new()
	mi.name = "Nuees_dessous"
	mi.mesh = st.commit()
	mi.material_override = load("res://scripts/nuees_mats_v113.gd").make("roche113")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	mi.position = Vector3(CENTER.x, Y0, CENTER.z)


## Des pointes de roche qui pendent sous l'île (de la roche grise, comme le reste du dessous), et des
## racines claires qui dépassent du bord.
func _stalactites(rows: Array, nu: int, ns: int) -> void:
	var M = load("res://scripts/nuees_mats_v113.gd")
	var n: int = 46 if pc else 20
	var cm_cache: Array = []
	for v in range(4):
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 0.0
		cm.height = 1.0
		cm.radial_segments = 7
		cm.rings = 3
		cm_cache.append(cm)
	for q in range(n):
		var kk: int = _rng.randi_range(3, nu - 2)
		var jj: int = _rng.randi() % ns
		var p0: Vector3 = rows[kk][jj]
		var sz: float = _rng.randf_range(2.0, 5.5) * (1.2 - float(kk) / nu * 0.5)
		var len: float = sz * _rng.randf_range(3.0, 6.0)
		var ci := MeshInstance3D.new()
		ci.mesh = cm_cache[q % 4]
		ci.material_override = M.make("roche113")
		add_child(ci)
		ci.position = Vector3(CENTER.x, Y0, CENTER.z) + p0 - Vector3(0, len * 0.42, 0)
		ci.scale = Vector3(sz, len, sz * _rng.randf_range(0.7, 1.2))
		ci.rotation = Vector3(_rng.randf_range(-0.12, 0.12), _rng.randf() * TAU, _rng.randf_range(-0.12, 0.12))
		ci.visibility_range_end = 2600.0


# =================================================================== les sustentateurs

func _build_engines() -> void:
	var M = load("res://scripts/nuees_mats_v113.gd")
	engine_glow = M.make("anneau113") as StandardMaterial3D
	var list: Array = ENGINES.duplicate()
	list.append([0.0, 0.0])
	for e in list:
		var big: bool = float(e[1]) > 1.0
		var pl: Vector2 = polar(float(e[0]), float(e[1]))
		var rr: float = coast_radius(deg_to_rad(float(e[0])))
		var top_y: float = under_y(float(e[1]), rr) + (2.0 if big else -2.0)
		var s: float = 1.0 if big else 0.75
		var n := Node3D.new()
		n.name = "Sustentateur"
		add_child(n)
		n.position = Vector3(CENTER.x + pl.x, top_y, CENTER.z + pl.y)
		# la nacelle : un fût blanc, un bulbe, une collerette d'acier, l'anneau lumineux
		var body := _mesh_cyl(4.6 * s, 6.2 * s, 8.0 * s, "composite113", 32)
		n.add_child(body)
		body.position = Vector3(0, -4.0 * s, 0)
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 6.2 * s
		sm.height = 7.0 * s
		sm.radial_segments = 32
		sm.rings = 12
		bulb.mesh = sm
		bulb.material_override = M.make("composite113")
		n.add_child(bulb)
		bulb.position = Vector3(0, -8.0 * s, 0)
		var collar := _mesh_cyl(7.2 * s, 7.2 * s, 1.2 * s, "acier113", 40)
		n.add_child(collar)
		collar.position = Vector3(0, -7.6 * s, 0)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 7.4 * s
		tm.outer_radius = 8.3 * s
		tm.rings = 48
		tm.ring_segments = 10
		ring.mesh = tm
		ring.material_override = engine_glow
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(ring)
		ring.position = Vector3(0, -9.2 * s, 0)
		# l'anneau intérieur, qui tourne lentement (des ailettes d'acier)
		var inner := Node3D.new()
		n.add_child(inner)
		inner.position = Vector3(0, -10.6 * s, 0)
		for k in range(12):
			var a: float = TAU * k / 12.0
			var fin := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.35 * s, 1.6 * s, 3.6 * s)
			fin.mesh = bm
			fin.material_override = M.make("acier113")
			inner.add_child(fin)
			fin.position = Vector3(cos(a) * 4.0 * s, 0, sin(a) * 4.0 * s)
			fin.rotation = Vector3(0.4, -a, 0)
		var hub := _mesh_cyl(1.6 * s, 1.0 * s, 2.4 * s, "acier113", 16)
		inner.add_child(hub)
		hub.position = Vector3(0, -1.2 * s, 0)
		# le mât d'ancrage, qui entre loin dans la roche
		var mast := _mesh_cyl(2.6 * s, 3.4 * s, 18.0 * s, "acier113_sombre", 16)
		n.add_child(mast)
		mast.position = Vector3(0, 9.0 * s, 0)
		# les tirants qui l'accrochent à la roche
		for k2 in range(4):
			var a2: float = TAU * (k2 + 0.5) / 4.0
			var strut := _mesh_cyl(0.5 * s, 0.5 * s, 7.0 * s, "acier113", 8)
			n.add_child(strut)
			strut.position = Vector3(cos(a2) * 5.6 * s, -1.0 * s, sin(a2) * 5.6 * s)
			strut.rotation = Vector3(sin(a2) * 0.35, 0, -cos(a2) * 0.35)
		# le voile de sustentation : un cône de lumière très pâle sous la nacelle
		var veil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 7.0 * s
		cm.bottom_radius = 13.0 * s
		cm.height = 26.0 * s
		cm.radial_segments = 32
		cm.rings = 1
		cm.cap_top = false
		cm.cap_bottom = false
		veil.mesh = cm
		veil.material_override = M.make("voile113")
		veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(veil)
		veil.position = Vector3(0, -10.0 * s - 13.0 * s, 0)
		var lt := OmniLight3D.new()
		lt.light_color = Color(0.65, 0.85, 1.0)
		lt.light_energy = 1.0
		lt.omni_range = 26.0 * s
		lt.shadow_enabled = false
		lt.distance_fade_enabled = true
		lt.distance_fade_begin = 400.0
		lt.distance_fade_length = 60.0
		n.add_child(lt)
		lt.position = Vector3(0, -11.0 * s, 0)
		for c in n.get_children():
			if c is GeometryInstance3D:
				(c as GeometryInstance3D).visibility_range_end = 2600.0
		engines.append([n, inner, veil, lt])


func _mesh_cyl(r0: float, r1: float, h: float, key: String, seg: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r0
	cm.bottom_radius = r1
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = load("res://scripts/nuees_mats_v113.gd").make(key)
	return mi


# =================================================================== les nuages

## Des bancs de nuages sous l'île : de grands flocons doux, tournés vers la caméra, qui dérivent.
func _build_clouds() -> void:
	_cloud_root = Node3D.new()
	_cloud_root.name = "Nuages_des_Nuees"
	add_child(_cloud_root)
	var tex: Texture2D = load(TEX113 + "nuage.png") if ResourceLoader.exists(TEX113 + "nuage.png") else null
	var n: int = 30 if pc else 14
	var mats: Array = []
	for k in range(3):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = [Color(1.0, 1.0, 1.0, 0.62), Color(0.96, 0.97, 1.0, 0.5), Color(1.0, 0.98, 0.95, 0.42)][k]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m.disable_receive_shadows = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.proximity_fade_enabled = true
		m.proximity_fade_distance = 18.0
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 12.0
		m.distance_fade_max_distance = 40.0
		mats.append(m)
	for k2 in range(n):
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(70.0, 190.0)
		var y: float = _rng.randf_range(-78.0, -30.0)
		var w: float = _rng.randf_range(34.0, 64.0)
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(w, w * _rng.randf_range(0.38, 0.55))
		mi.mesh = qm
		mi.material_override = mats[k2 % 3]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 2400.0
		_cloud_root.add_child(mi)
		clouds.append([mi, a, r, Y0 + y, _rng.randf_range(0.004, 0.012)])
	_clouds_tick(0.0)


func _clouds_tick(_delta: float) -> void:
	for c in clouds:
		var a: float = float(c[1]) + _clock * float(c[4])
		(c[0] as Node3D).global_position = Vector3(CENTER.x + cos(a) * float(c[2]), float(c[3]) + sin(_clock * 0.05 + float(c[1])) * 1.5, CENTER.z + sin(a) * float(c[2]))


# =================================================================== la cascade

func _build_cascade() -> void:
	var th: float = deg_to_rad(CASCADE_DEG)
	var rr: float = coast_radius(th)
	var out := Vector3(cos(th), 0, sin(th))
	cascade_top = W(out.x * (rr + 0.6), out.z * (rr + 0.6), -3.2)
	var len: float = 150.0
	var pts: Array = []
	for k in range(20):
		var t: float = float(k) / 19.0
		pts.append(cascade_top + out * (0.6 + 6.0 * sqrt(t)) - Vector3.UP * len * t)
	var mi: MeshInstance3D = _ribbon("Cascade_des_Nuees", pts, 3.2)
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/chute_ciel_v54.gdshader")
	wm.set_shader_parameter("fall_length", len)
	wm.set_shader_parameter("water_color", Color(0.66, 0.8, 0.86))
	mi.material_override = wm
	mi.visibility_range_end = 2400.0


func _ribbon(label: String, pts: Array, wid: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for i in range(pts.size()):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var c: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t: Vector3 = (c - a).normalized()
		var side: Vector3 = Vector3(t.x, 0, t.z).cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.RIGHT
		var n: Vector3 = side.cross(t).normalized()
		var w: float = wid * lerpf(0.8, 1.6, float(i) / (pts.size() - 1))
		var p: Vector3 = pts[i]
		rows.append([p - side * w * 0.5, p + side * w * 0.5, n, float(i) / (pts.size() - 1)])
	for i in range(rows.size() - 1):
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var quad: Array = [[r0[0], Vector2(0, r0[3]), r0[2]], [r0[1], Vector2(1, r0[3]), r0[2]], [r1[1], Vector2(1, r1[3]), r1[2]], [r1[0], Vector2(0, r1[3]), r1[2]]]
		var face: Vector3 = ((quad[1][0] as Vector3) - (quad[0][0] as Vector3)).cross((quad[2][0] as Vector3) - (quad[0][0] as Vector3))
		var order: Array = [0, 2, 1, 0, 3, 2] if face.dot(r0[2]) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_uv(quad[k][1])
			st.set_normal(quad[k][2])
			st.add_vertex(quad[k][0])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


# =================================================================== la vie

## La nuit : la ceinture et les anneaux des sustentateurs luisent plus fort.
func set_night(k: float) -> void:
	if rim_glow != null:
		rim_glow.emission_energy_multiplier = lerpf(0.4, 3.0, k)
	if engine_glow != null:
		engine_glow.emission_energy_multiplier = lerpf(1.4, 4.5, k)
	for e in engines:
		(e[3] as OmniLight3D).light_energy = lerpf(0.6, 2.6, k)


func tick(delta: float, near: bool) -> void:
	_clock += delta
	_clouds_tick(delta)
	if not near:
		return
	for e in engines:
		(e[1] as Node3D).rotate_y(delta * 0.35)
		var v: MeshInstance3D = e[2]
		v.scale = Vector3.ONE * (1.0 + sin(_clock * 0.9 + (e[0] as Node3D).position.x) * 0.03)

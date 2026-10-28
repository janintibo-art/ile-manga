extends Node3D
## V70 : Pandémonia, la méga-cité des démons, bâtie en cercles sur l'Île de Braise
## (ile_braise_v70.gd donne le relief : la Citadelle, le Cercle de Feu, la Haute-Ville, la
## Basse-Ville, le rempart, la Rade de Cendre). Ici, tout ce qui est bâti :
##  - le Cercle de Feu : la lave entre ses deux murs, les quatre ponts, les escaliers de la
##    Citadelle, la braise qui monte la nuit ;
##  - la Haute-Ville : le boulevard du Cercle, la promenade des Remparts et son mur de
##    soutènement, quatre grands escaliers sur arches (la rue Basse passe dessous) ;
##  - la Basse-Ville : la rue Basse, la rue du Milieu, le chemin de ronde, le rempart, ses tours
##    et ses quatre portes ;
##  - des centaines de maisons gothiques, rangées le long des rues (pandemonia_v70 les place,
##    braise_kit_v70 les dessine) ; des réverbères ;
##  - les grands lieux (le Palais, la Cathédrale-Forge, l'Académie, la Grand-Place, le Marché,
##    l'Arène, les Thermes, le port…) : pandemonia_lieux_v70.gd ;
##  - le réseau des rues (points, liens) pour les habitants, leurs lieux (spots), leurs portes.
## Le repère : polaire autour du centre de la cité (R.CITY), en degrés (0 = est, 90 = sud).

const R = preload("res://scripts/ile_braise_v70.gd")
const Kit = preload("res://scripts/braise_kit_v70.gd")
const Lieux = preload("res://scripts/pandemonia_lieux_v70.gd")
const Basse = preload("res://scripts/pandemonia_basse_v70.gd")

## Les rues en anneau (le rayon du milieu de la chaussée) et leur hauteur.
const HI_R: float = 69.0                 # le boulevard du Cercle
const HO_R: float = 118.6                # la promenade des Remparts
const BI_R: float = 128.2                # la rue Basse (au pied du mur de la Haute-Ville)
const BM_R: float = 157.5                # la rue du Milieu
const BO_R: float = 184.5                # le chemin de ronde (au pied du rempart)
const HY: float = 24.0                   # la Haute-Ville
const BY: float = 12.0                   # la Basse-Ville
const WALL_R: float = 190.0              # le rempart
const KEEP_R0: float = 120.4             # le mur de la Haute-Ville (le dedans, le dehors)
const KEEP_R1: float = 124.8
const VIA_R1: float = 150.0              # le pied des grands escaliers
## Les grands lieux (pas de maisons) : [nom, angle min, angle max, r min, r max].
const RESERVED := [
	["place", -14.0, 14.0, 72.0, 114.5],
	["cathedrale", 77.0, 103.0, 72.0, 125.0],
	["bibliotheque", 167.0, 193.0, 72.0, 114.5],
	["academie", -106.0, -74.0, 72.0, 114.5],
	["marche", -29.0, -6.0, 131.0, 181.0],
	["arene", 56.0, 80.0, 131.0, 181.0],
	["thermes", 86.0, 106.0, 131.0, 181.0],
	["jardins", 107.5, 129.0, 131.0, 181.0],
	["artisans", 171.0, 189.0, 131.0, 160.0],
	["chenil", -172.0, -158.0, 160.0, 181.0],
	["caserne", -66.0, -54.0, 131.0, 155.0],
]
## Les rangées de maisons : [rayon de la façade, sens (-1 : la façade regarde le centre, +1 :
## dehors), profondeur, sol, étages min, étages max, rue (anneau des points), quartier].
const ROWS := [
	[74.6, -1, 12.0, 24.0, 3, 5, "hi", "haute"],
	[113.6, 1, 11.5, 24.0, 3, 5, "ho", "haute"],
	[132.0, -1, 10.0, 12.0, 3, 4, "bi", "basse"],
	[153.5, 1, 10.0, 12.0, 2, 4, "bm", "basse"],
	[161.8, -1, 9.6, 12.0, 2, 4, "bm", "basse"],
	[180.5, 1, 8.4, 12.0, 2, 3, "bo", "basse"],
]
## Où habitent les habitants : id -> [angle, rangée] (la maison la plus proche, libre).
## Ceux qui vivent dans un grand lieu ont leur porte posée par pandemonia_lieux_v70.
const HOMES := {
	"cendrin": [104.5, 1], "ferronde": [72.0, 1], "malachar": [-109.0, 0], "sulfura": [-70.0, 0],
	"pepin": [-34.0, 4], "zebuline": [-34.0, 4], "ortie": [-48.0, 3], "gorgoth": [52.0, 5],
	"hurla": [84.0, 4], "lumina": [17.0, 0], "ebene": [-17.0, 0], "calcine": [24.0, 1],
	"ombreline": [160.0, 0], "kraxx": [-31.0, 2], "vesperine": [-3.0, 2], "bobor": [-12.0, 3],
	"charbonnel": [-50.0, 5], "moloka": [-38.0, 5], "nox": [-140.0, 3], "brasille": [131.0, 3],
	"bulle": [100.0, 2], "tiburce": [192.0, 2], "zigomar": [168.0, 2], "grisette": [196.0, 4],
	"flammeche": [-156.0, 4], "pyrus": [-60.0, 0], "grumbald": [-44.0, 5], "brindille": [-24.0, 4],
}

var main: Node
var ile: Node3D
var kit
var pc: bool = true
var lieux                                # pandemonia_lieux_v70 (la Citadelle, la Haute-Ville)
var basse                                # pandemonia_basse_v70 (la Basse-Ville, le port)
var points: Dictionary = {}
var graph: Dictionary = {}
var spots: Dictionary = {}
var doors: Dictionary = {}
var objets: Dictionary = {}              # nom -> Vector3 (les comptoirs, les coffres, les invites)
var flora_avoid: Array = []
var fire_spots: Array = []               # [Vector3, taille]
var smoke_spots: Array = []
var tree_spots: Array = []               # Vector3 : les arbres de braise plantés dans la ville
var bm_lamps: Array = []                 # Vector3 : les réverbères de la rue du Milieu (Nox les allume)
var houses: Array = []                   # {deg, r, row, door, w}
var lanterns: Dictionary = {}            # les sept Grandes Lanternes : id -> {glass, light, flame, pos}
var districts: Dictionary = {}
var lava_ring: MeshInstance3D
var moat_lights: Array = []
var embers: CPUParticles3D
var _rng := RandomNumberGenerator.new()
var _store: Dictionary = {}              # quartier -> [maillages en cours, pièces répétées]
var _cur: String = ""


# =================================================================== repère polaire

func PW(deg: float, r: float, y: float) -> Vector3:
	return R.PW(deg, r, y)


## Un point au sol (la hauteur du relief).
func PG(deg: float, r: float, dy: float = 0.0) -> Vector3:
	var w: Vector3 = R.PW(deg, r, 0.0)
	w.y = ile.height(w.x, w.z) + dy
	return w


static func radial(deg: float) -> Vector3:
	return Vector3(cos(deg_to_rad(deg)), 0.0, sin(deg_to_rad(deg)))


static func tangent(deg: float) -> Vector3:
	return Vector3(-sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg)))


## Un repère au point polaire (deg, r, y) dont le +Z regarde « in » (le centre), « out »,
## « cw » (vers les angles croissants) ou « ccw ».
func PX(deg: float, r: float, y: float, facing: String) -> Transform3D:
	var f: Vector3
	match facing:
		"in":
			f = -radial(deg)
		"out":
			f = radial(deg)
		"cw":
			f = tangent(deg)
		_:
			f = -tangent(deg)
	return Transform3D(Basis.looking_at(-f, Vector3.UP), PW(deg, r, y))


## Un repère quelconque : au point p, le +Z regarde vers dir.
static func XD(p: Vector3, dir: Vector3) -> Transform3D:
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	return Transform3D(Basis.looking_at(-d, Vector3.UP), p)


static func in_arc(a: float, a0: float, a1: float) -> bool:
	if a1 - a0 >= 359.9:
		return true
	return wrapf(a - a0, 0.0, 360.0) <= wrapf(a1 - a0, 0.0, 360.0)


## Le grand lieu à cet endroit (polaire), ou "".
static func reserved(deg: float, r: float) -> String:
	for z in RESERVED:
		if r >= float(z[3]) and r <= float(z[4]) and in_arc(deg, float(z[1]), float(z[2])):
			return str(z[0])
	return ""


func _spot(name: String, pos: Vector3, face: Vector3, pose: String, node: String = "") -> void:
	spots[name] = {"pos": pos, "face": face, "pose": pose, "node": node}


func _link(a: String, b: String) -> void:
	if a == b or not points.has(a) or not points.has(b):
		return
	if not graph.has(a):
		graph[a] = []
	if not graph.has(b):
		graph[b] = []
	if not (graph[a] as Array).has(b):
		graph[a].append(b)
	if not (graph[b] as Array).has(a):
		graph[b].append(a)


func _chain(names: Array) -> void:
	for i in range(names.size() - 1):
		_link(str(names[i]), str(names[i + 1]))


func _pt(name: String, p: Vector3) -> String:
	points[name] = p
	return name


func _avoid(p: Vector3, r: float) -> void:
	flora_avoid.append([Vector2(p.x, p.z), r])


## On dessine dans un quartier (chaque quartier garde ses maillages en cours : on peut y
## revenir ; tout est assemblé à la fin, un maillage par matière et par quartier).
func _district(name: String) -> void:
	if _cur == name:
		return
	if _cur != "":
		_store[_cur] = [kit.batch, kit.inst]
	var n: Node3D = districts.get(name, null)
	if n == null:
		n = Node3D.new()
		n.name = "Quartier_" + name
		add_child(n)
		districts[name] = n
	kit.root = n
	var st: Variant = _store.get(name, null)
	if st == null:
		kit.batch = {}
		kit.inst = {}
	else:
		kit.batch = st[0]
		kit.inst = st[1]
	_cur = name


func _commit_all() -> void:
	if _cur != "":
		_store[_cur] = [kit.batch, kit.inst]
	for name in _store:
		kit.root = districts[name]
		kit.batch = _store[name][0]
		kit.inst = _store[name][1]
		kit.commit()
	_store.clear()
	_cur = ""


# =================================================================== construction

func build(main_node: Node, island: Node3D, high_quality: bool) -> void:
	main = main_node
	ile = island
	pc = high_quality
	var t0: int = Time.get_ticks_msec()
	_rng.seed = 7070
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56") if main != null else null)
	kit.main = main
	kit.pc = pc
	kit.rng.seed = 7071
	kit.light_every = 2
	lieux = Lieux.new()
	lieux.setup(self)
	basse = Basse.new()
	basse.setup(self)
	_district("cercle")
	_cercle_de_feu()
	_district("citadelle")
	lieux.palais()
	_district("remparts_haute")
	_mur_haute()
	_viaducs()
	_district("rempart")
	_rempart()
	_district("haute_e")
	lieux.grand_place()
	_district("haute_s")
	lieux.cathedrale()
	_district("haute_o")
	lieux.bibliotheque()
	_district("haute_n")
	lieux.academie()
	_district("basse_3")
	basse.marche()
	basse.caserne()
	_district("basse_5")
	basse.arene()
	_district("basse_6")
	basse.thermes()
	basse.jardins()
	_district("basse_7")
	basse.artisans()
	_district("basse_0")
	basse.chenil()
	_district("port")
	basse.port()
	# les maisons, quartier par quartier (un maillage par quartier : on ne dessine que ce qu'on voit)
	var t1: int = Time.get_ticks_msec()
	for i in range(ROWS.size()):
		_fill_row(i)
	var t2: int = Time.get_ticks_msec()
	_streets()
	_commit_all()
	_homes()
	_graph()
	for f in kit.fires70:
		fire_spots.append(f)
	for c in kit.chimneys70:
		if _rng.randf() < 0.35:
			smoke_spots.append(c)
	print("ILE_MANGA_V70: Pandémonia bâtie, %d maisons, %d lieux, %d points, %d pièces répétées, %d réverbères (%d lumières), en %d ms (maisons %d ms)" % [houses.size(), spots.size(), points.size(), kit.inst_count, kit.lamps70.size(), kit.lamps70.filter(func(l): return l != null).size(), Time.get_ticks_msec() - t0, t2 - t1])


# =================================================================== le Cercle de Feu

func _cercle_de_feu() -> void:
	var c: Vector3 = PW(0.0, 0.0, 0.0)
	var cx := Transform3D(Basis(), c)
	# le mur du dehors (la Haute-Ville), le mur du dedans (la Citadelle) : leurs faces sur la lave
	kit.ring(cx * kit.T(0, 17.6, 0), R.LAVA_R1, 68.4, HY - 17.6, "pgoth70_sombre", 96)
	kit.ring(cx * kit.T(0, 17.6, 0), 47.6, R.LAVA_R0, HY - 17.6, "pgoth70_sombre", 80)
	# un bandeau de pierre au bord, des consoles sous le parapet
	kit.ring(cx * kit.T(0, HY - 0.3, 0), R.LAVA_R1 - 0.25, R.LAVA_R1 + 0.02, 0.3, "pgoth70", 96)
	for k in range(96):
		var a: float = 360.0 * k / 96.0
		kit.box(Transform3D(Basis(Vector3.UP, -deg_to_rad(a)), PW(a, R.LAVA_R1 - 0.12, HY - 0.25)), Vector3(0.5, 0.7, 0.4), "pgoth70", 1.0)
	# les collisions des deux murs (le dessus se marche), par segments
	for k2 in range(48):
		var a0: float = 360.0 * k2 / 48.0
		var a1: float = 360.0 * (k2 + 1) / 48.0
		var am: float = (a0 + a1) * 0.5
		var len_o: float = deg_to_rad(a1 - a0) * 66.0 + 0.4
		kit.col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(am)), PW(am, 66.0, HY - 3.2)), Vector3(68.4 - R.LAVA_R1, 6.4, len_o))
		var len_i: float = deg_to_rad(a1 - a0) * 50.0 + 0.4
		kit.col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(am)), PW(am, 50.0, HY - 3.2)), Vector3(R.LAVA_R0 - 47.6, 6.4, len_i))
	# la lave
	lava_ring = _lava_annulus(c + Vector3.UP * R.MOAT_LAVA_Y, R.LAVA_R0 - 0.3, R.LAVA_R1 + 0.3, 128)
	# le parapet du boulevard, interrompu aux ponts
	for k3 in range(96):
		var a2: float = 360.0 * k3 / 96.0
		var a3: float = 360.0 * (k3 + 1) / 96.0
		if _near_avenue(a2, R.LAVA_R1, 4.0) or _near_avenue(a3, R.LAVA_R1, 4.0):
			continue
		kit.parapet70(PW(a2, R.LAVA_R1 + 0.5, HY), PW(a3, R.LAVA_R1 + 0.5, HY), 1.0, 0.5, "pgoth70")
	# les quatre ponts et les escaliers de la Citadelle
	for i in range(4):
		var av: float = float(R.AVENUES[i])
		kit.bridge70(PW(av, 69.0, HY), PW(av, R.STAIR_R.x, HY), 6.4, R.MOAT_FLOOR, "pgoth70", "paves70")
		kit.stair(PW(av, R.STAIR_R.x, HY), PW(av, R.STAIR_R.y, R.CIT_Y), 6.4, "pgoth70", "pgoth70_sombre", 0.9, 0.5)
		for s in [-1.0, 1.0]:
			kit.lamp70(PW(av, 67.6, HY) + tangent(av) * s * 3.9, 4.2, true, true, -deg_to_rad(av))
			kit.lamp70(PW(av, R.STAIR_R.x + 0.8, HY) + tangent(av) * s * 3.9, 3.9, true, false)
	# la braise qui monte du fossé, la lumière de la lave
	var n_l: int = 16 if pc else 8
	for k4 in range(n_l):
		var a4: float = 360.0 * (k4 + 0.5) / n_l
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.42, 0.12)
		l.light_energy = 2.6
		l.omni_range = 17.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 1.5
		l.distance_fade_enabled = true
		l.distance_fade_begin = 140.0
		l.distance_fade_length = 30.0
		kit.root.add_child(l)
		l.position = PW(a4, (R.LAVA_R0 + R.LAVA_R1) * 0.5, R.MOAT_LAVA_Y + 2.2)
		moat_lights.append(l)
	embers = _embers(c + Vector3.UP * (R.MOAT_LAVA_Y + 0.3), (R.LAVA_R0 + R.LAVA_R1) * 0.5, (R.LAVA_R1 - R.LAVA_R0) * 0.42)
	_avoid(c, 70.0)


## L'anneau de lave (un maillage à part : sa matière est le shader de lave ; u le long de
## l'anneau, v en travers, en mètres : la lave coule autour de la Citadelle).
func _lava_annulus(c: Vector3, r0: float, r1: float, seg: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var circ: float = TAU * (r0 + r1) * 0.5
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var u0: float = circ * float(i) / seg
		var u1: float = circ * float(i + 1) / seg
		var p00 := c + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p01 := c + Vector3(cos(a0) * r1, 0, sin(a0) * r1)
		var p10 := c + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var p11 := c + Vector3(cos(a1) * r1, 0, sin(a1) * r1)
		for v in [[p00, Vector2(u0, 0)], [p11, Vector2(u1, r1 - r0)], [p01, Vector2(u0, r1 - r0)], [p00, Vector2(u0, 0)], [p10, Vector2(u1, 0)], [p11, Vector2(u1, r1 - r0)]]:
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Lave_Cercle_de_Feu"
	mi.mesh = st.commit()
	mi.material_override = kit.mat("lave70")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	kit.root.add_child(mi)
	return mi


## Des braises qui s'envolent d'un anneau (le fossé) ou d'un disque.
func _embers(c: Vector3, ring_r: float, width: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Braises_qui_montent"
	p.amount = 160 if pc else 60
	p.lifetime = 4.5
	p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = ring_r + width
	p.emission_ring_inner_radius = maxf(ring_r - width, 0.0)
	p.emission_ring_height = 0.2
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.8
	p.gravity = Vector3(0.15, 0.35, 0.05)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	grad.set_color(1, Color(0.9, 0.15, 0.02, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	p.mesh = q
	p.visibility_aabb = AABB(Vector3(-ring_r - width - 4.0, -2.0, -ring_r - width - 4.0), Vector3((ring_r + width + 4.0) * 2.0, 14.0, (ring_r + width + 4.0) * 2.0))
	kit.root.add_child(p)
	p.position = c
	return p


## Ce point (polaire) est-il sur une avenue (à moins de hw mètres de son axe) ?
static func _near_avenue(deg: float, r: float, hw: float) -> bool:
	for a in R.AVENUES:
		if absf(R._adiff(deg, float(a))) * PI / 180.0 * r < hw:
			return true
	return false


# =================================================================== le mur de la Haute-Ville

func _mur_haute() -> void:
	var c: Vector3 = PW(0.0, 0.0, 0.0)
	var cx := Transform3D(Basis(), c)
	kit.ring(cx * kit.T(0, BY - 0.6, 0), KEEP_R0, KEEP_R1, HY - BY + 0.6, "pgoth70_sombre", 128)
	kit.ring(cx * kit.T(0, HY - 0.32, 0), KEEP_R1 - 0.02, KEEP_R1 + 0.25, 0.3, "pgoth70", 128)
	for k in range(64):
		var a0: float = 360.0 * k / 64.0
		var a1: float = 360.0 * (k + 1) / 64.0
		var am: float = (a0 + a1) * 0.5
		var len: float = deg_to_rad(a1 - a0) * KEEP_R1 + 0.4
		kit.col_box(Transform3D(Basis(Vector3.UP, -deg_to_rad(am)), PW(am, (KEEP_R0 + KEEP_R1) * 0.5, (HY + BY - 0.6) * 0.5)), Vector3(KEEP_R1 - KEEP_R0, HY - BY + 0.6, len))
	# des contreforts sur la face du mur, des gargouilles au sommet, des soupiraux à la base
	for k2 in range(64):
		var a: float = 360.0 * (k2 + 0.5) / 64.0
		if _near_avenue(a, KEEP_R1, 7.0):
			continue
		var bx: Transform3D = PX(a, KEEP_R1, BY, "out")
		kit.buttress(bx, HY - BY - 1.0, 1.4, 1.1, "pgoth70_sombre", false)
		if k2 % 4 == 1:
			kit.gargoyle(PX(a, KEEP_R1 - 0.1, HY - 0.2, "out"), 1.1, "pgoth70_sombre")
		if k2 % 2 == 0:
			var hx: Transform3D = PX(a + 2.8, KEEP_R1, BY, "out")
			kit.ogive_face(hx * kit.T(0, 0.1, 0.02), 1.6, 2.6, "fenetrenoire70", 4)
			kit.ogive_frame(hx, 1.6, 2.6, 0.22, 0.2, "pgoth70", 4)
	# le parapet de la promenade, interrompu en haut des grands escaliers
	for k3 in range(128):
		var a2: float = 360.0 * k3 / 128.0
		var a3: float = 360.0 * (k3 + 1) / 128.0
		if _near_avenue(a2, KEEP_R1, 5.4) or _near_avenue(a3, KEEP_R1, 5.4) or reserved((a2 + a3) * 0.5, KEEP_R1 - 1.0) == "cathedrale":
			continue
		kit.parapet70(PW(a2, KEEP_R1 - 0.45, HY), PW(a3, KEEP_R1 - 0.45, HY), 1.0, 0.5, "pgoth70")


## Les quatre grands escaliers sur arches : du haut du mur (la promenade) au pied, dans la
## Basse-Ville ; la rue Basse passe sous l'arche, les côtés sont des murs pleins.
func _viaducs() -> void:
	var span: float = 7.6
	var arch_h: float = 7.4
	for av in R.AVENUES:
		var a: float = float(av)
		var top: Vector3 = PW(a, KEEP_R1 - 0.3, HY)
		var foot: Vector3 = PW(a, VIA_R1, BY)
		_flight(foot, top, 8.0, "pgoth70", "pgoth70_sombre")
		var run: float = VIA_R1 - (KEEP_R1 - 0.3)
		var bs := Basis(Vector3.UP, atan2(radial(a).x, radial(a).z))
		# l'arche au-dessus de la rue Basse
		var axf := Transform3D(bs * Basis(Vector3.UP, -PI * 0.5), PW(a, BI_R, BY))
		kit.ogive_frame(axf, span, arch_h, 1.0, 9.2, "pgoth70_sombre", 6, true)
		# les deux murs de côté : pleins, sauf l'arche (leur bas suit l'extrados)
		var nsl: int = 30
		for s in [-1.0, 1.0]:
			var side: Vector3 = tangent(a) * s * 4.25
			for k in range(nsl):
				var r0: float = KEEP_R1 - 0.3 + k * run / nsl
				var r1: float = KEEP_R1 - 0.3 + (k + 1) * run / nsl
				var rm: float = (r0 + r1) * 0.5
				var deck: float = HY - (rm - (KEEP_R1 - 0.3)) / run * (HY - BY)
				var bottom: float = BY - 0.4
				var x: float = rm - BI_R
				if absf(x) < span * 0.5 + 1.0:
					bottom = BY + Kit.ogive_y(span + 2.0, arch_h + 1.0, x) - 0.08
				var hh: float = deck - bottom - 0.12
				if hh < 0.25:
					continue
				var p: Vector3 = PW(a, rm, bottom + hh * 0.5) + side
				kit.box(Transform3D(bs, p), Vector3(0.7, hh, r1 - r0 + 0.03), "pgoth70_sombre", 2.0)
				kit.col_box(Transform3D(bs, p), Vector3(0.7, hh, r1 - r0))
		# le plein sous l'escalier, au-delà de l'arche (on ne passe pas dessous)
		for k2 in range(5):
			var q0: float = BI_R + span * 0.5 + 0.6 + k2 * (VIA_R1 - BI_R - span * 0.5 - 0.6) / 5.0
			var q1: float = BI_R + span * 0.5 + 0.6 + (k2 + 1) * (VIA_R1 - BI_R - span * 0.5 - 0.6) / 5.0
			var qm: float = (q0 + q1) * 0.5
			var dk: float = HY - (qm - (KEEP_R1 - 0.3)) / run * (HY - BY)
			var h2: float = dk - BY - 0.3
			if h2 < 0.3:
				continue
			kit.col_box(Transform3D(bs, PW(a, qm, BY + h2 * 0.5)), Vector3(8.0, h2, q1 - q0))
		for s2 in [-1.0, 1.0]:
			kit.lamp70(PW(a, KEEP_R1 - 1.6, HY) + tangent(a) * s2 * 5.0, 4.2, true, true, -deg_to_rad(a))
			kit.lamp70(PW(a, VIA_R1 + 1.4, BY) + tangent(a) * s2 * 5.0, 4.2, true, true, -deg_to_rad(a))
			kit.pinnacle(PW(a, KEEP_R1 - 0.6, HY) + tangent(a) * s2 * 4.6, 1.1, "pgoth70")


## Une volée de marches portée (le dessous en gradins : on voit les marches d'en bas), sa rampe
## de collision, ses deux garde-corps de pierre. a : le bas, b : le haut.
func _flight(a: Vector3, b: Vector3, w: float, key: String, rail_key: String) -> void:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var run: float = flat.length()
	var rise: float = b.y - a.y
	var dir: Vector3 = flat / run
	var bs := Basis(Vector3.UP, atan2(dir.x, dir.z))
	var n: int = maxi(int(round(rise / 0.24)), 1)
	for i in range(n):
		var t0: float = float(i) / n
		var p: Vector3 = a + dir * run * (t0 + 0.5 / n)
		var top: float = a.y + rise * float(i + 1) / n
		kit.box(Transform3D(bs, Vector3(p.x, top - 0.4, p.z)), Vector3(w, 0.8, run / n + 0.02), key, 1.6)
	var slope: float = atan2(rise, run)
	var len3: float = sqrt(run * run + rise * rise)
	var cb: Basis = bs * Basis(Vector3.RIGHT, -slope)
	var mid: Vector3 = (a + b) * 0.5
	kit.col_box(Transform3D(cb, mid + cb * Vector3(0, -0.1, 0)), Vector3(w, 0.2, len3 + 0.25))
	for s in [-1.0, 1.0]:
		var off: Vector3 = bs * Vector3(s * (w * 0.5 + 0.3), 0, 0)
		kit.box(Transform3D(cb, mid + off + cb * Vector3(0, 0.5, 0)), Vector3(0.6, 1.0, len3 + 0.1), rail_key, 1.6)
		kit.col_box(Transform3D(cb, mid + off + cb * Vector3(0, 0.5, 0)), Vector3(0.6, 1.0, len3 + 0.1))


# =================================================================== le rempart

func _rempart() -> void:
	var nseg: int = 96
	for k in range(nseg):
		var a0: float = 360.0 * k / nseg
		var a1: float = 360.0 * (k + 1) / nseg
		if _near_avenue(a0, WALL_R, 7.5) or _near_avenue(a1, WALL_R, 7.5):
			continue
		var g0: Vector3 = PG(a0, WALL_R + 2.6)
		var g1: Vector3 = PG(a1, WALL_R + 2.6)
		var y0: float = minf(minf(g0.y, g1.y), BY) - 0.6
		kit.wall_line(PW(a0, WALL_R, y0), PW(a1, WALL_R, y0), BY + 9.0 - y0, 3.0, "pgoth70", true, 1.0)
	# les tours, tous les 15°
	for k2 in range(24):
		var a: float = 360.0 * k2 / 24.0 + 7.5
		if _near_avenue(a, WALL_R, 12.0):
			continue
		var gy: float = minf(PG(a, WALL_R + 5.0).y, BY)
		kit.tower70(PW(a, WALL_R + 1.0, gy - 0.5), 4.3, BY + 14.0 - gy, {"roof": "cone", "roof_h": 9.0, "windows": [BY + 5.0 - gy, BY + 9.5 - gy], "nwin": 3, "lit": 0.4})
		_avoid(PW(a, WALL_R + 1.0, 0.0), 6.0)
	# les quatre portes de la ville : un porche en arc brisé entre deux grosses tours
	for av in R.AVENUES:
		var a2: float = float(av)
		var gx: Transform3D = PX(a2, WALL_R, BY, "out")
		kit.arch_gate(gx, 6.4, 7.0, 4.2, 12.0, "pgoth70")
		kit.crenels(gx * Vector3(-5.6, 12.0, 1.6), gx * Vector3(5.6, 12.0, 1.6), 0.5, "pgoth70")
		kit.banner70(gx * kit.T(0, 11.6, 2.1), 1.4, 3.4)
		for s in [-1.0, 1.0]:
			var tp: Vector3 = gx * Vector3(s * 7.4, 0, 0.4)
			var gy2: float = minf(PG(a2, WALL_R + 5.0).y, BY)
			kit.tower70(Vector3(tp.x, gy2 - 0.5, tp.z), 4.6, BY + 17.0 - gy2, {"roof": "cone", "roof_h": 11.0, "windows": [BY + 6.0 - gy2, BY + 11.0 - gy2], "nwin": 4, "lit": 0.5})
			kit.lamp70(gx * Vector3(s * 4.2, 0, -3.0), 4.4, true, true, -deg_to_rad(a2))
		_avoid(PW(a2, WALL_R, 0.0), 14.0)


# =================================================================== les maisons

## Les rues rayonnantes d'un quartier : [angle, demi-largeur], triées.
func _radials(zone: String) -> Array:
	var out: Array = []
	if zone == "haute":
		for k in range(16):
			var a: float = -180.0 + 22.5 * k
			var hw: float = 2.8
			if _is_avenue(a):
				hw = 6.6
			elif int(round(a)) % 90 == 0:
				hw = 4.0
			out.append([a, hw])
	else:
		for k2 in range(32):
			var a2: float = -180.0 + 11.25 * k2
			var hw2: float = 2.1
			if _is_avenue(a2):
				hw2 = 6.6
			elif k2 % 2 == 0:
				hw2 = 3.2
			out.append([a2, hw2])
	return out


static func _is_avenue(a: float) -> bool:
	for av in R.AVENUES:
		if absf(R._adiff(a, float(av))) < 0.5:
			return true
	return false


func _fill_row(ri: int) -> void:
	var row: Array = ROWS[ri]
	var r: float = float(row[0])
	var sens: int = int(row[1])
	var depth: float = float(row[2])
	var zone: String = str(row[7])
	var rads: Array = _radials(zone)
	var n: int = rads.size()
	var haute: bool = zone == "haute"
	for i in range(n):
		var a0: float = float(rads[i][0])
		var a1: float = float(rads[(i + 1) % n][0])
		if a1 <= a0:
			a1 += 360.0
		var start: float = a0 + rad_to_deg((float(rads[i][1]) + 0.5) / r)
		var stop: float = a1 - rad_to_deg((float(rads[(i + 1) % n][1]) + 0.5) / r)
		var dname: String = _district_of(zone, (a0 + a1) * 0.5)
		_district(dname)
		var cur: float = start
		var since: int = 0
		var limit: int = 0
		while cur < stop and limit < 40:
			limit += 1
			var w: float = _rng.randf_range(7.0, 10.0) if haute else _rng.randf_range(5.8, 8.8)
			var aw: float = rad_to_deg(w / r)
			if cur + aw > stop:
				var rem: float = deg_to_rad(stop - cur) * r
				if rem < 5.0:
					break
				w = rem
				aw = stop - cur
			var mid: float = cur + aw * 0.5
			if not _footprint_free(mid, r, w, depth, sens):
				cur += rad_to_deg(1.5 / r)
				continue
			_house(ri, mid, r, w, depth, sens, since)
			since += 1
			var gap: float = _rng.randf_range(0.0, 0.25)
			# une ruelle tous les trois à six maisons
			if since >= 3 and _rng.randf() < 0.3:
				gap = _rng.randf_range(1.6, 2.6)
				since = 0
			cur += aw + rad_to_deg(gap / r)


func _district_of(zone: String, deg: float) -> String:
	var a: float = wrapf(deg, -180.0, 180.0)
	if zone == "haute":
		if absf(a) <= 45.0:
			return "haute_e"
		if a > 45.0 and a <= 135.0:
			return "haute_s"
		if a < -45.0 and a >= -135.0:
			return "haute_n"
		return "haute_o"
	var oct: int = int(floor((a + 180.0) / 45.0)) % 8
	return "basse_%d" % oct


## Aucun coin de la maison ne mord sur un grand lieu ?
func _footprint_free(mid: float, r: float, w: float, depth: float, sens: int) -> bool:
	var half: float = rad_to_deg(w * 0.5 / r)
	var rb: float = r - sens * depth
	for p in [[mid - half, r], [mid + half, r], [mid - half, rb], [mid + half, rb], [mid, (r + rb) * 0.5]]:
		if reserved(float(p[0]), float(p[1])) != "":
			return false
	return true


const WALLS_H := ["erouge70", "erouge70", "pgoth70", "bnoire70", "mrouge70", "erouge70_sombre", "pgoth70_chaud", "bnoire70_rouge"]
const WALLS_B := ["erouge70", "erouge70", "bnoire70", "bnoire70", "pgoth70", "erouge70_sombre", "bnoire70_rouge", "erouge70_pourpre"]


func _house(ri: int, deg: float, r: float, w: float, depth: float, sens: int, nth: int) -> void:
	var row: Array = ROWS[ri]
	var y: float = float(row[3])
	var haute: bool = str(row[7]) == "haute"
	var xf: Transform3D = PX(deg, r, y, "in" if sens < 0 else "out")
	var floors: int = _rng.randi_range(int(row[4]), int(row[5]))
	var walls: Array = WALLS_H if haute else WALLS_B
	var roofs: Array = ["ardoise70", "ardoise70", "ardoise70", "tuile70", "tuile70", "ardoise70_pourpre", "cuivre70"] if haute else ["ardoise70", "ardoise70", "tuile70", "tuile70", "tuile70_sombre"]
	var dx: float = _rng.randf_range(-w * 0.22, w * 0.22)
	var opts := {
		"floors": floors, "wall": walls[_rng.randi() % walls.size()], "roof": roofs[_rng.randi() % roofs.size()],
		"pitch": _rng.randf_range(52.0, 62.0), "jet": _rng.randf_range(0.15, 0.45), "lit": 0.6 if haute else 0.5,
		"door_x": dx, "gable": _rng.randf() < 0.72, "banner": haute and _rng.randf() < 0.12,
		"balcony": 2 if _rng.randf() < (0.22 if haute else 0.1) else 0,
		"turret": (1 if _rng.randf() < 0.5 else -1) if (floors >= 3 and _rng.randf() < (0.16 if haute else 0.07)) else 0,
		"base": "pgoth70_sombre" if _rng.randf() < 0.7 else "basalte70",
		"gf": 3.8 if haute else 3.5, "uf": 3.2 if haute else 3.0, "v81": true,
	}
	var door: Vector3 = kit.house70(xf, w, depth, opts)
	door.y = y + 0.05
	houses.append({"deg": deg, "r": r, "row": ri, "door": door, "w": w, "street": str(row[6])})
	_avoid(xf * Vector3(0, 0, -depth * 0.5), maxf(w, depth) * 0.6)


## Les portes des habitants : la maison libre la plus proche de l'angle voulu, dans la rangée
## voulue (Zébuline et son fils Pépin habitent la même maison).
func _homes() -> void:
	var taken: Dictionary = {}
	for id in HOMES:
		if str(id) == "zebuline" and doors.has("porte_pepin"):
			doors["porte_zebuline"] = _pt("porte_zebuline", points["porte_pepin"])
			continue
		var want: Array = HOMES[id]
		var best: int = -1
		var bd: float = INF
		for i in range(houses.size()):
			var h: Dictionary = houses[i]
			if int(h["row"]) != int(want[1]) or taken.has(i):
				continue
			var d: float = absf(R._adiff(float(h["deg"]), float(want[0])))
			if d < bd:
				bd = d
				best = i
		if best < 0:
			continue
		taken[best] = true
		var hh: Dictionary = houses[best]
		doors["porte_" + str(id)] = _pt("porte_" + str(id), hh["door"])
		hh["owner"] = str(id)


# =================================================================== les rues

func _streets() -> void:
	# le boulevard du Cercle : des réverbères doubles, des bancs, des arbres de braise
	_district("haute_e")
	for k in range(48):
		var a: float = 360.0 * (k + 0.5) / 48.0
		if _near_avenue(a, HI_R, 5.0):
			continue
		_district(_district_of("haute", a))
		kit.lamp70(PW(a, R.LAVA_R1 + 1.6, HY), 4.2, true, k % 2 == 0, -deg_to_rad(a))
		if k % 3 == 1 and reserved(a, 72.5) == "":
			kit.bench70(PX(a + 1.6, 71.6, HY, "in"))
			tree_spots.append(PW(a - 1.9, 71.8, HY))
	# la promenade des Remparts
	for k2 in range(64):
		var a2: float = 360.0 * (k2 + 0.5) / 64.0
		if _near_avenue(a2, HO_R, 6.0) or reserved(a2, HO_R + 2.0) != "":
			continue
		_district(_district_of("haute", a2))
		kit.lamp70(PW(a2, KEEP_R1 - 1.5, HY), 3.9, true, false)
		if k2 % 4 == 2:
			kit.bench70(PX(a2 + 1.2, KEEP_R1 - 1.4, HY, "out"))
	# la rue Basse : des lanternes accrochées au mur de la Haute-Ville
	for k3 in range(72):
		var a3: float = 360.0 * (k3 + 0.5) / 72.0
		if _near_avenue(a3, KEEP_R1, 7.0):
			continue
		_district(_district_of("basse", a3))
		kit.wall_lamp70(PX(a3, KEEP_R1, BY + 3.6, "out"), true)
	# la rue du Milieu : des réverbères de chaque côté, en quinconce
	for k4 in range(72):
		var a4: float = 360.0 * (k4 + 0.5) / 72.0
		var rr: float = BM_R + (3.3 if k4 % 2 == 0 else -3.3)
		if _near_avenue(a4, BM_R, 7.0) or reserved(a4, rr) != "":
			continue
		_district(_district_of("basse", a4))
		kit.lamp70(PW(a4, rr, BY), 3.9, true, false)
		bm_lamps.append(PW(a4, rr, BY))
	# le chemin de ronde : des lanternes au rempart
	for k5 in range(72):
		var a5: float = 360.0 * (k5 + 0.5) / 72.0
		if _near_avenue(a5, WALL_R, 9.0):
			continue
		_district(_district_of("basse", a5))
		kit.wall_lamp70(PX(a5, WALL_R - 1.5, BY + 3.4, "in"), true)
	# les avenues, au sol, de la rue du Milieu aux portes
	for av in R.AVENUES:
		var a6: float = float(av)
		_district(_district_of("basse", a6))
		for rr2 in [166.0, 176.0]:
			for s in [-1.0, 1.0]:
				kit.lamp70(PW(a6, rr2, BY) + tangent(a6) * s * 5.6, 4.2, true, true, -deg_to_rad(a6))
	# dans les cours entre les rangées de la Haute-Ville : des arbres
	for k6 in range(32):
		var a7: float = 360.0 * (k6 + 0.5) / 32.0
		if reserved(a7, 94.0) == "" and not _near_avenue(a7, 94.0, 8.0):
			tree_spots.append(PW(a7, 94.0, HY))


# =================================================================== le réseau des rues

const RINGS := {"hi": [HI_R, HY + 0.05, 16], "ho": [HO_R, HY + 0.05, 16], "bi": [BI_R, BY + 0.05, 32], "bm": [BM_R, BY + 0.05, 32], "bo": [BO_R, BY + 0.05, 32]}


func ring_node(ring: String, k: int) -> String:
	return "%s_%d" % [ring, k]


func ring_angle(ring: String, k: int) -> float:
	var n: int = int(RINGS[ring][2])
	return -180.0 + 360.0 * k / n


## Le point d'un anneau le plus proche d'un angle (un nom de point, ou "").
func nearest_ring(ring: String, deg: float) -> String:
	var n: int = int(RINGS[ring][2])
	var best: String = ""
	var bd: float = INF
	for k in range(n):
		var nm: String = ring_node(ring, k)
		if not points.has(nm):
			continue
		var d: float = absf(R._adiff(ring_angle(ring, k), deg))
		if d < bd:
			bd = d
			best = nm
	return best


func _graph() -> void:
	# les anneaux (un point tous les 22,5° en haut, tous les 11,25° en bas), sauf dans les grands lieux
	for ring in RINGS:
		var spec: Array = RINGS[ring]
		var n: int = int(spec[2])
		for k in range(n):
			var a: float = ring_angle(ring, k)
			if reserved(a, float(spec[0])) != "":
				continue
			_pt(ring_node(ring, k), PW(a, float(spec[0]), float(spec[1])))
		for k2 in range(n):
			var a0: float = ring_angle(ring, k2)
			if reserved(a0 + 180.0 / n, float(spec[0])) != "":
				continue
			_link(ring_node(ring, k2), ring_node(ring, (k2 + 1) % n))
	# les rues rayonnantes de la Haute-Ville (hors des grands lieux)
	for k3 in range(16):
		var a3: float = ring_angle("hi", k3)
		if reserved(a3, 94.0) == "":
			_link(ring_node("hi", k3), ring_node("ho", k3))
	# celles de la Basse-Ville
	for k4 in range(32):
		var a4: float = ring_angle("bi", k4)
		if _is_avenue(a4):
			continue
		if reserved(a4, 142.0) == "":
			_link(ring_node("bi", k4), ring_node("bm", k4))
		if reserved(a4, 171.0) == "":
			_link(ring_node("bm", k4), ring_node("bo", k4))
	# les avenues : les ponts et les escaliers de la Citadelle, les grands escaliers, les portes
	for av in R.AVENUES:
		var a5: float = float(av)
		var nm: String = "av%d" % int(a5)
		_pt(nm + "_pont", PW(a5, 58.0, HY + 0.1))
		_pt(nm + "_cit", PW(a5, R.STAIR_R.y - 1.0, R.CIT_Y + 0.05))
		_pt(nm + "_haut", PW(a5, KEEP_R1 - 1.2, HY + 0.05))
		_pt(nm + "_via", PW(a5, (KEEP_R1 + VIA_R1) * 0.5, (HY + BY) * 0.5 + 0.1))
		_pt(nm + "_pied", PW(a5, VIA_R1 + 1.2, BY + 0.05))
		_pt(nm + "_porte", PW(a5, WALL_R, BY + 0.05))
		var hi: String = nearest_ring("hi", a5)
		var ho: String = nearest_ring("ho", a5)
		var bm: String = nearest_ring("bm", a5)
		var bo: String = nearest_ring("bo", a5)
		_chain([nm + "_cit", nm + "_pont", hi])
		_chain([hi, ho, nm + "_haut", nm + "_via", nm + "_pied", bm, bo, nm + "_porte"])
	# les grands lieux et leurs lieux (pandemonia_lieux_v70 a posé ses points et ses liens)
	lieux.link_graph()
	basse.link_graph()
	_street_spots()
	_dehors()
	# les portes : au point de leur rue le plus proche
	for d in doors:
		var p: Vector3 = points[doors[d]]
		var cp: Vector2 = R.city_polar(R.L(p.x, p.z).x, R.L(p.x, p.z).y)
		var best: String = ""
		var street: String = ""
		for h in houses:
			if (h["door"] as Vector3).distance_to(p) < 0.2:
				street = str(h["street"])
		if street != "":
			best = nearest_ring(street, cp.x)
		if best == "" or (points[best] as Vector3).distance_to(p) > 30.0:
			best = _nearest_point(p, "porte")
		_link(str(doors[d]), best)


## Les lieux des rues : des coins où l'on bavarde, les réverbères qu'allume Nox.
func _street_spots() -> void:
	var rues := [["rue_1", "bm", -33.75, 2.6, "debout"], ["rue_2", "bi", 33.75, -2.2, "bras_croises"], ["rue_3", "bo", 146.25, -2.4, "debout"],
		["rue_4", "hi", -22.5, -3.0, "observer"], ["rue_5", "ho", 112.5, 3.4, "observer"], ["rue_6", "bm", -146.25, -2.6, "debout"]]
	for rr in rues:
		var node: String = nearest_ring(str(rr[1]), float(rr[2]))
		var p: Vector3 = points[node]
		var cp: Vector2 = R.city_polar(R.L(p.x, p.z).x, R.L(p.x, p.z).y)
		var off: Vector3 = radial(cp.x) * float(rr[3])
		var face: Vector3 = -off if str(rr[4]) != "observer" else off
		_spot(str(rr[0]), p + off, face, str(rr[4]), node)
	var wants := [-101.0, -150.0, 160.0, 28.0]
	for i in range(wants.size()):
		var best := Vector3.ZERO
		var bd: float = INF
		for lp in bm_lamps:
			var la: float = R.city_polar(R.L(lp.x, lp.z).x, R.L(lp.x, lp.z).y).x
			var d: float = absf(R._adiff(la, float(wants[i])))
			if d < bd:
				bd = d
				best = lp
		var lc: Vector2 = R.city_polar(R.L(best.x, best.z).x, R.L(best.x, best.z).y)
		var to_street: Vector3 = radial(lc.x) * (1.0 if lc.y < BM_R else -1.0)
		_spot("reverbere_%d" % (i + 1), best + to_street * 0.9 + Vector3.UP * 0.05, -to_street, "lancer_sort", nearest_ring("bm", lc.x))


## Dehors : les chemins qui partent des portes de la ville (le Bois de Cendre, le volcan, les
## sources, le champ de lave, les Ruines, les plages), pour ceux qui vont cueillir ou se promener.
func _dehors() -> void:
	for av in R.AVENUES:
		var a: float = float(av)
		if a == -45.0:
			continue
		var nm: String = "av%d" % int(a)
		_pt(nm + "_dehors", PG(a, WALL_R + 12.0, 0.05))
		_link(nm + "_porte", nm + "_dehors")
	var starts := {"bois": "av45_dehors", "volcan": "av135_dehors", "ruines": "av-135_dehors", "plage_ouest": "av-135_dehors", "sources": "", "champ": "", "plage_sud": ""}
	for k in ile.paths_world:
		var pts: Array = ile.paths_world[k]
		if pts.size() < 2:
			continue
		var prev: String = ""
		var acc: float = 0.0
		for i in range(pts.size()):
			if i > 0:
				acc += (pts[i] as Vector3).distance_to(pts[i - 1])
			if i == 0 or i == pts.size() - 1 or acc > 11.0:
				acc = 0.0
				var near: String = _nearest_point(pts[i] as Vector3, "porte") if prev == "" else ""
				var nm2: String = _pt("ch_%s_%d" % [str(k), i], (pts[i] as Vector3) + Vector3.UP * 0.05)
				if prev != "":
					_link(prev, nm2)
				elif str(starts.get(k, "")) != "":
					_link(str(starts[k]), nm2)
				else:
					_link(near, nm2)
				prev = nm2
	# la clairière du Bois de Cendre : on y cueille des champignons qui luisent
	var cl: Vector3 = ile.pads_world["clairiere"]
	_pt("bois_clairiere", cl + Vector3(2.0, 0.05, 1.0))
	_link("bois_clairiere", _nearest_point(cl + Vector3(2.0, 0.0, 1.0), "bois_"))
	_spot("bois_cueillette", cl + Vector3(-1.5, 0.05, 2.5), Vector3(-0.5, 0, 1), "jardiner", "bois_clairiere")


## Le point le plus proche (sauf ceux qui commencent par « exclu »).
func _nearest_point(p: Vector3, exclu: String = "") -> String:
	var best: String = ""
	var bd: float = INF
	for k in points:
		if exclu != "" and str(k).begins_with(exclu):
			continue
		var q: Vector3 = points[k]
		var d: float = q.distance_to(p) + absf(q.y - p.y) * 3.0
		if d < bd:
			bd = d
			best = str(k)
	return best


# =================================================================== où est-on ?

func on_structure(p: Vector3) -> bool:
	for wb in kit.walk_boxes:
		var l: Vector3 = (wb[0] as Transform3D) * p
		var h: Vector3 = wb[1]
		if absf(l.x) < h.x and l.y > -1.5 and l.y < h.y and absf(l.z) < h.z:
			return true
	return false


## Le quartier de la cité (pour la musique, les ambiances, le carnet), ou "".
func zone_at(p: Vector3) -> String:
	var l: Vector2 = R.L(p.x, p.z)
	var cp: Vector2 = R.city_polar(l.x, l.y)
	var lz: String = lieux.zone_at(p, cp) if lieux != null else ""
	if lz != "":
		return lz
	var bz: String = basse.zone_at(p, cp) if basse != null else ""
	if bz != "":
		return bz
	if cp.y < R.CIT_R + 2.0 and p.y > R.CIT_Y - 6.0:
		return "braise_palais"
	if cp.y < KEEP_R1 + 0.5:
		return "braise_haute" if p.y > HY - 6.0 else "braise_cercle"
	if cp.y < WALL_R + 2.0:
		return "braise_basse"
	return ""

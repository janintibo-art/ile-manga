extends Node3D
## V41 : la quête de Lyra et l'île des elfes (le Bois-Doré).
##  - Au cœur de l'île du village, une clairière cachée : l'Arbre sacré (un rejeton de
##    l'Arbre-Mère) se meurt, et Lyra Sylvanel, une elfe, veille sur lui.
##  - Sa quête : une fleur de lune (au sommet du petit piton de la jungle, face à la baie),
##    l'eau de la source (puisée avec sa fiole dans le bassin de la grande chute, au nord-est)
##    et une graine d'or (Barnabé l'a trouvée sur une plage il y a vingt ans).
##  - L'Arbre soigné, Lyra confie sa boussole elfique et rentre chez elle.
##  - Sans la boussole, la brume du Bois-Doré repousse le bateau. Avec elle, on accoste au
##    ponton de l'île des elfes : un sentier de lanternes mène au village, au pied de
##    l'Arbre-Mère, entouré de cinq arbres géants qui portent chacun une plate-forme et une
##    maison ronde, reliées par des passerelles ; on y monte par des rampes qui tournent
##    autour des troncs. (V42 : les habitants, le marché et la vie du village : village_elfe_v42.gd.)

const IleScript = preload("res://scripts/ile_elfes_v41.gd")
const FloraScript = preload("res://scripts/jungle_flora_v30.gd")
const LyraData = preload("res://scripts/pnj/lyra_v41.gd")
const Falls = preload("res://scripts/scenery_v13.gd")
const Rocks = preload("res://scripts/rocks_v26.gd")
const MIST_R: float = 190.0
const PLATFORM_H: float = 9.0
const VILLAGE_R: float = 21.0

var main: Node
var ile: Node3D
var flora: Node3D
var pc: bool = true
var state := {"fleur": false, "arbre": false, "visite": false}
var lyra: Node3D
var glade: Vector3 = Vector3.INF               # clairière de l'Arbre sacré (île du village)
var tree_spots: Array = []                    # arbres du village elfe {pos, angle}
var _home_points: Dictionary = {}
var _home_graph: Dictionary = {}
var _glade_points: Dictionary = {}
var _glade_graph: Dictionary = {}
var _lyra_away: bool = false
var _sacred_leaves: ShaderMaterial
var _sacred_light: OmniLight3D
var _sacred_fx: CPUParticles3D
var _flower: Node3D
var _flower_pos: Vector3 = Vector3.INF
var _fog: FogVolume
var _mist_clock: float = 0.0
var _mats: Dictionary = {}
var _body: StaticBody3D
var village: Node3D                           # V42 : la vie du village (habitants, marché…)


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_body = StaticBody3D.new()
	_body.name = "Elfes_collision_v41"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)


# =================================================================== 1) l'île (au chargement du monde)

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_elfes_v41"
	add_child(ile)
	ile.build(pc)
	flora = FloraScript.new()
	flora.name = "Bois_Dore_v41"
	add_child(flora)
	var g: Vector2 = ile.GLADE
	flora.clearings.append([g, VILLAGE_R + 11.0])
	# Le sentier du ponton au village reste dégagé.
	var d0: Vector3 = ile.dock_start - ile.CENTER
	for k in range(14):
		var t: float = float(k) / 13.0
		var pt: Vector2 = Vector2(d0.x, d0.z).lerp(g, t)
		flora.clearings.append([pt, 4.5])
	flora.build_elfes(ile, pc)
	_build_village()
	_build_mist()


func dock() -> Array:
	return [ile.dock_start, ile.dock_end]


# =================================================================== matériaux et formes

func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.8
	match key:
		"bois":
			m.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.9, 0.9, 0.9)
			m.albedo_color = Color(0.92, 0.82, 0.66)
		"pierre":
			m.albedo_texture = load("res://assets/textures/temple/temple_floor.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.25, 0.25, 0.25)
			m.albedo_color = Color(1.0, 0.98, 0.94)
		"mur":
			m.albedo_texture = load("res://assets/textures/temple/temple_wall.png")
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.6, 0.6, 0.6)
			m.albedo_color = Color(1.0, 0.97, 0.9)
			m.roughness = 0.9
		"toit":
			m.albedo_color = Color(0.36, 0.56, 0.42)
			m.metallic = 0.45
			m.roughness = 0.45
		"or":
			m.albedo_color = Color(0.92, 0.76, 0.4)
			m.metallic = 0.8
			m.roughness = 0.3
		"corde":
			m.albedo_color = Color(0.72, 0.62, 0.45)
			m.roughness = 0.95
		"lanterne":
			m.albedo_color = Color(1.0, 0.86, 0.55)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.45)
			m.emission_energy_multiplier = 3.0
		"cristal":
			m.albedo_color = Color(0.7, 1.0, 0.85, 0.85)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(0.55, 1.0, 0.8)
			m.emission_energy_multiplier = 2.5
			m.roughness = 0.1
		"eau":
			m.albedo_color = Color(0.2, 0.45, 0.5, 0.75)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
			m.metallic = 0.2
		"fenetre":
			m.albedo_color = Color(1.0, 0.85, 0.55)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.75, 0.4)
			m.emission_energy_multiplier = 1.6
	_mats[key] = m
	return m


func _flower_mat(c: Color) -> StandardMaterial3D:
	var key: String = "fleur_" + c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.6
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.25
		_mats[key] = m
	return _mats[key]


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(r_top: float, r_bot: float, h: float, segs: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	return c


func _sphere(r: float, segs: int = 14) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 4)
	return s


## Boîte visible + collision (repère monde).
func _solid(size: Vector3, xf: Transform3D, mat: Material, visible_box: bool = true) -> void:
	if visible_box:
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh(size)
		mi.material_override = mat
		add_child(mi)
		mi.global_transform = xf
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	_body.add_child(cs)
	cs.global_transform = xf


func _cyl_collision(pos: Vector3, radius: float, height: float) -> void:
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	cs.shape = s
	_body.add_child(cs)
	cs.global_position = pos + Vector3.UP * height * 0.5


func _lantern(pos: Vector3, with_light: bool, energy: float = 1.3) -> void:
	_mesh(self, _cyl(0.0, 0.16, 0.16, 8), _mat("or"), pos + Vector3.UP * 0.32)
	_mesh(self, _sphere(0.13), _mat("lanterne"), pos + Vector3.UP * 0.12)
	_mesh(self, _cyl(0.1, 0.1, 0.04, 8), _mat("or"), pos + Vector3.DOWN * 0.03)
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.5)
		l.light_energy = energy
		l.omni_range = 9.0
		l.omni_attenuation = 1.3
		add_child(l)
		l.global_position = pos + Vector3.UP * 0.1


# =================================================================== le village elfe

func _build_village() -> void:
	var G: Vector3 = ile.glade_world()
	# L'Arbre-Mère au centre de la place, feuillage doré qui luit doucement.
	var mother := MeshInstance3D.new()
	mother.name = "Arbre_Mere"
	mother.mesh = flora.giant_mesh(1, pc)
	mother.scale = Vector3.ONE * 2.4
	mother.rotation.y = 0.7
	add_child(mother)
	mother.global_position = G + Vector3.DOWN * 0.6
	var gold: ShaderMaterial = (flora.canopy_mat() as ShaderMaterial).duplicate()
	gold.set_shader_parameter("tint", Color(1.25, 1.12, 0.55))
	mother.set_surface_override_material(1, gold)
	_cyl_collision(G, 1.45 * 2.4, 60.0)
	var halo := OmniLight3D.new()
	halo.light_color = Color(1.0, 0.86, 0.5)
	halo.light_energy = 2.4
	halo.omni_range = 40.0
	halo.omni_attenuation = 0.8
	add_child(halo)
	halo.global_position = G + Vector3.UP * 30.0
	var motes := CPUParticles3D.new()
	motes.amount = 90
	motes.lifetime = 7.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(16, 10, 16)
	motes.direction = Vector3.DOWN
	motes.spread = 40.0
	motes.gravity = Vector3(0, -0.15, 0)
	motes.initial_velocity_min = 0.1
	motes.initial_velocity_max = 0.3
	var mq := QuadMesh.new()
	mq.size = Vector2(0.09, 0.09)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mm.albedo_color = Color(1.0, 0.85, 0.45, 0.8)
	mm.albedo_texture = main._soft_dot_v24()
	mq.material = mm
	motes.mesh = mq
	add_child(motes)
	motes.global_position = G + Vector3.UP * 12.0
	# La place : un anneau de pierre blanche autour de l'Arbre-Mère, des bancs, des massifs de fleurs.
	var plaza := MeshInstance3D.new()
	plaza.mesh = _cyl(10.5, 10.5, 0.12, 48)
	plaza.material_override = _mat("pierre")
	add_child(plaza)
	plaza.global_position = G + Vector3.UP * 0.02
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.5
		var bp: Vector3 = G + Vector3(cos(a) * 8.6, 0, sin(a) * 8.6)
		var bench := Node3D.new()
		add_child(bench)
		bench.global_position = bp
		bench.rotation.y = -a + PI * 0.5
		_mesh(bench, _box_mesh(Vector3(2.0, 0.1, 0.5)), _mat("bois"), Vector3(0, 0.45, 0))
		for sx in [-0.8, 0.8]:
			_mesh(bench, _box_mesh(Vector3(0.12, 0.45, 0.45)), _mat("pierre"), Vector3(sx, 0.22, 0))
		_flower_bed(G + Vector3(cos(a + 0.52) * 9.4, 0, sin(a + 0.52) * 9.4), 1.1, 3000 + k)
	# La Fontaine de lune, juste à côté de la place
	var fpos: Vector3 = G + Vector3(0, 0, 13.5)
	_mesh(self, _cyl(2.2, 2.4, 0.6, 32), _mat("pierre"), fpos + Vector3.UP * 0.3)
	_mesh(self, _cyl(1.95, 1.95, 0.05, 32), _mat("eau"), fpos + Vector3.UP * 0.55)
	_mesh(self, _cyl(0.3, 0.4, 1.8, 12), _mat("pierre"), fpos + Vector3.UP * 1.2)
	_mesh(self, _cyl(0.0, 0.32, 0.8, 6), _mat("cristal"), fpos + Vector3.UP * 2.5)
	_cyl_collision(fpos, 2.4, 0.6)
	var fl := OmniLight3D.new()
	fl.light_color = Color(0.6, 1.0, 0.85)
	fl.light_energy = 1.5
	fl.omni_range = 9.0
	add_child(fl)
	fl.global_position = fpos + Vector3.UP * 2.8
	# Les cinq arbres-maisons autour de la place
	for i in range(5):
		var a2: float = TAU * i / 5.0 + 0.31
		var p: Vector3 = G + Vector3(cos(a2) * VILLAGE_R, 0, sin(a2) * VILLAGE_R)
		p.y = ile.height(p.x, p.z)
		tree_spots.append({"pos": p, "angle": a2})
	for i in range(5):
		_house_tree(i)
	for i in range(5):
		_bridge(tree_spots[i], tree_spots[(i + 1) % 5])
	# Le sentier de lanternes et de pierres plates, du ponton à la place
	var start: Vector3 = ile.dock_start
	var to_g: Vector3 = (G - start) * Vector3(1, 0, 1)
	var length: float = to_g.length() - 11.0
	var dir: Vector3 = to_g.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var stones := MultiMesh.new()
	stones.transform_format = MultiMesh.TRANSFORM_3D
	stones.mesh = Rocks.shape(4170, Vector3(0.9, 0.18, 0.7), 0.5, 0.05)
	var n_st: int = int(length / 1.1)
	stones.instance_count = n_st
	var rng := RandomNumberGenerator.new()
	rng.seed = 4171
	for k in range(n_st):
		var q: Vector3 = start + dir * (1.0 + k * 1.1) + side * rng.randf_range(-0.35, 0.35)
		q.y = ile.height(q.x, q.z) + 0.02
		stones.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), q))
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = stones
	smi.material_override = _mat("pierre")
	add_child(smi)
	var posts: int = int(length / 13.0)
	for k in range(1, posts + 1):
		for sgn in [-1.0, 1.0]:
			if (k + int(sgn > 0.0)) % 2 == 0:
				continue
			var q2: Vector3 = start + dir * (k * 13.0) + side * sgn * 1.6
			q2.y = ile.height(q2.x, q2.z)
			_mesh(self, _cyl(0.06, 0.08, 2.4, 8), _mat("bois"), q2 + Vector3.UP * 1.2)
			_mesh(self, _box_mesh(Vector3(0.5, 0.06, 0.06)), _mat("bois"), q2 + Vector3(0, 2.35, 0) - side * sgn * 0.2, Vector3(0, atan2(side.x, side.z) + PI * 0.5, 0))
			_lantern(q2 + Vector3(0, 2.15, 0) - side * sgn * 0.4, true, 1.1)
	# Une arche de bienvenue au bout du ponton
	var arch_p: Vector3 = start + dir * 3.0
	arch_p.y = ile.height(arch_p.x, arch_p.z)
	for sgn in [-1.0, 1.0]:
		_mesh(self, _cyl(0.12, 0.16, 4.2, 10), _mat("bois"), arch_p + side * sgn * 1.7 + Vector3.UP * 2.1)
	var arc := Node3D.new()
	add_child(arc)
	arc.global_position = arch_p + Vector3.UP * 4.1
	arc.rotation.y = atan2(side.x, side.z)
	var tm := TorusMesh.new()
	tm.inner_radius = 1.55
	tm.outer_radius = 1.8
	tm.rings = 24
	_mesh(arc, tm, _mat("bois"), Vector3.ZERO, Vector3(PI * 0.5, PI * 0.5, 0), Vector3(1.0, 1.0, 0.45))
	_mesh(arc, _cyl(0.0, 0.2, 0.3, 6), _mat("cristal"), Vector3(0, 0.55, 0))


func _flower_bed(c: Vector3, radius: float, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var cols := [Color(0.95, 0.85, 0.95), Color(0.75, 0.6, 0.95), Color(1.0, 0.92, 0.55), Color(0.95, 0.55, 0.6), Color(0.65, 0.85, 1.0)]
	for k in range(18):
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * radius
		var p: Vector3 = c + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = main._height_at(p.x, p.z)
		_mesh(self, _cyl(0.006, 0.008, 0.3, 4), _flower_mat(Color(0.3, 0.55, 0.3)), p + Vector3.UP * 0.15)
		_mesh(self, _sphere(0.06, 8), _flower_mat(cols[rng.randi() % cols.size()]), p + Vector3.UP * 0.32, Vector3.ZERO, Vector3(1.0, 0.55, 1.0))


## Un arbre-maison : géant, plate-forme circulaire à 9 m, maison ronde, rambarde,
## lanternes, et une rampe qui tourne autour du tronc jusqu'à la plate-forme.
func _house_tree(i: int) -> void:
	var t: Dictionary = tree_spots[i]
	var p: Vector3 = t["pos"]
	var a_out: float = float(t["angle"])
	var a_in: float = a_out + PI                     # vers la place
	var tree := MeshInstance3D.new()
	tree.mesh = flora.giant_mesh((i + 2) % 4, pc)
	tree.scale = Vector3.ONE * 1.5
	tree.rotation.y = 0.9 * i
	add_child(tree)
	tree.global_position = p + Vector3.DOWN * 0.4
	_cyl_collision(p, 1.45 * 1.5, 40.0)
	var H: float = p.y + PLATFORM_H
	# Plate-forme : 20 lames de bois en couronne (r 2,0 → 6,6)
	for k in range(20):
		var a: float = TAU * k / 20.0
		var c: Vector3 = Vector3(p.x + cos(a) * 4.3, H - 0.15, p.z + sin(a) * 4.3)
		_solid(Vector3(2.2, 0.3, 4.6), Transform3D(Basis(Vector3.UP, -a + PI * 0.5), c), _mat("bois"))
	# Rambarde extérieure, ouverte vers la rampe et vers les deux passerelles
	var gaps: Array = [a_in]
	var prev: Vector3 = (tree_spots[(i + 4) % 5] as Dictionary)["pos"]
	var nxt: Vector3 = (tree_spots[(i + 1) % 5] as Dictionary)["pos"]
	gaps.append(atan2(prev.z - p.z, prev.x - p.x))
	gaps.append(atan2(nxt.z - p.z, nxt.x - p.x))
	for k in range(36):
		var a3: float = TAU * (k + 0.5) / 36.0
		var open: bool = false
		for gpa in gaps:
			if absf(wrapf(a3 - float(gpa), -PI, PI)) < 0.2:
				open = true
		if open:
			continue
		var rp := Vector3(p.x + cos(a3) * 6.45, H + 0.5, p.z + sin(a3) * 6.45)
		_solid(Vector3(1.16, 1.0, 0.08), Transform3D(Basis(Vector3.UP, -a3 + PI * 0.5), rp), _mat("bois"), false)
		_mesh(self, _box_mesh(Vector3(1.16, 0.07, 0.09)), _mat("bois"), rp + Vector3.UP * 0.5, Vector3(0, -a3 + PI * 0.5, 0))
		_mesh(self, _cyl(0.04, 0.05, 1.0, 6), _mat("bois"), Vector3(p.x + cos(a3 - 0.087) * 6.45, H + 0.5, p.z + sin(a3 - 0.087) * 6.45))
	# La maison ronde, du côté opposé à la place
	var hc := Vector3(p.x + cos(a_out) * 4.7, H, p.z + sin(a_out) * 4.7)
	var house := Node3D.new()
	add_child(house)
	house.global_position = hc
	house.rotation.y = -a_out + PI * 0.5
	_mesh(house, _cyl(1.65, 1.7, 2.6, 24), _mat("mur"), Vector3(0, 1.3, 0))
	_mesh(house, _cyl(0.9, 2.15, 1.3, 24), _mat("toit"), Vector3(0, 3.2, 0))
	_mesh(house, _cyl(0.0, 0.95, 1.6, 24), _mat("toit"), Vector3(0, 4.6, 0))
	_mesh(house, _sphere(0.12), _mat("or"), Vector3(0, 5.45, 0))
	_mesh(house, _box_mesh(Vector3(0.85, 1.85, 0.08)), _mat("bois"), Vector3(1.66, 0.95, 0), Vector3(0, PI * 0.5, 0))
	_mesh(house, _cyl(0.43, 0.43, 0.08, 16), _mat("bois"), Vector3(1.66, 1.87, 0), Vector3(0, 0, PI * 0.5))
	for wa in [0.9, -0.9, 2.4]:
		_mesh(house, _sphere(0.24, 12), _mat("fenetre"), Vector3(cos(wa) * 1.66, 1.55, sin(wa) * 1.66), Vector3.ZERO, Vector3(0.25, 1.0, 1.0) if absf(cos(wa)) > 0.5 else Vector3(1.0, 1.0, 0.25))
	_cyl_collision(hc, 1.7, 2.8)
	# Lanternes
	for la in [a_in + 0.55, a_in - 0.55]:
		_lantern(Vector3(p.x + cos(la) * 6.3, H + 1.4, p.z + sin(la) * 6.3), true, 1.2)
	# La rampe en spirale (r 8,3) et son palier d'arrivée
	# 0,6 tour, pente qui s'accentue vers le haut : en passant sous la passerelle voisine,
	# la rampe est encore 3 m plus bas (on ne s'y cogne pas la tête).
	var R: float = 8.3
	var turns: float = 0.6
	var expo: float = 1.5
	var a_end: float = a_in
	var a0: float = a_end - turns * TAU
	var steps: int = int(turns * 40.0)
	for k in range(steps):
		var f0: float = float(k) / steps
		var f1: float = float(k + 1) / steps
		var am: float = a0 + (k + 0.5) * (a_end - a0) / steps
		var y0: float = PLATFORM_H * pow(f0, expo)
		var y1: float = PLATFORM_H * pow(f1, expo)
		var y: float = p.y + (y0 + y1) * 0.5
		var pitch: float = atan((y1 - y0) / (R * TAU * turns / steps))
		var c2 := Vector3(p.x + cos(am) * R, y, p.z + sin(am) * R)
		var tang := Vector3(-sin(am), 0, cos(am))
		var yaw: float = atan2(tang.x, tang.z)
		var seg: float = R * TAU * turns / steps / cos(pitch) + 0.15
		var b := Basis.from_euler(Vector3(-pitch, yaw, 0))
		_solid(Vector3(1.9, 0.25, seg), Transform3D(b, c2 + Vector3.DOWN * 0.13), _mat("bois"))
		for sgn in [-1.0, 1.0]:
			# Pas de garde-corps intérieur tout en haut : on y passe sur le palier.
			if sgn < 0.0 and k >= steps - 3:
				continue
			var rr: float = R + sgn * 1.0
			var cp := Vector3(p.x + cos(am) * rr, y + 0.45, p.z + sin(am) * rr)
			_solid(Vector3(0.08, 0.9, seg), Transform3D(b, cp), _mat("bois"), false)
			if k % 3 == 0:
				_mesh(self, _cyl(0.04, 0.05, 1.0, 6), _mat("bois"), cp + Vector3.DOWN * 0.0)
			_mesh(self, _box_mesh(Vector3(0.06, 0.06, seg)), _mat("corde"), Vector3.ZERO).global_transform = Transform3D(b, cp + Vector3.UP * 0.45)
		# Pieux qui soutiennent la rampe
		if k % 6 == 3:
			var g_y: float = ile.height(c2.x, c2.z)
			if y - g_y > 1.0:
				_mesh(self, _cyl(0.1, 0.12, y - g_y, 6), _mat("bois"), Vector3(c2.x, (y + g_y) * 0.5, c2.z))
	var land := Vector3(p.x + cos(a_end) * 7.3, H - 0.13, p.z + sin(a_end) * 7.3)
	_solid(Vector3(2.0, 0.26, 2.6), Transform3D(Basis(Vector3.UP, -a_end + PI * 0.5), land), _mat("bois"))
	# Le pied de la rampe : quelques pierres plates
	var foot := Vector3(p.x + cos(a0) * R, p.y, p.z + sin(a0) * R)
	_mesh(self, Rocks.shape(4180 + i, Vector3(1.6, 0.25, 1.2), 0.5, 0.05), _mat("pierre"), foot + Vector3.UP * 0.05)


## Passerelle de cordes entre deux plates-formes (planches qui fléchissent, garde-corps).
func _bridge(ta: Dictionary, tb: Dictionary) -> void:
	var pa: Vector3 = ta["pos"]
	var pb: Vector3 = tb["pos"]
	var flat: Vector3 = (pb - pa) * Vector3(1, 0, 1)
	var dir: Vector3 = flat.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var a: Vector3 = Vector3(pa.x, pa.y + PLATFORM_H, pa.z) + dir * 6.3
	var b: Vector3 = Vector3(pb.x, pb.y + PLATFORM_H, pb.z) - dir * 6.3
	var length: float = (b - a).length()
	var n: int = int(length / 0.55)
	var sag: float = 0.7
	var prev_top: Array = []
	for k in range(n):
		var t0: float = float(k) / n
		var t1: float = float(k + 1) / n
		var q0: Vector3 = a.lerp(b, t0) + Vector3.DOWN * sag * sin(PI * t0)
		var q1: Vector3 = a.lerp(b, t1) + Vector3.DOWN * sag * sin(PI * t1)
		var mid: Vector3 = (q0 + q1) * 0.5
		var seg: Vector3 = q1 - q0
		var pitch: float = atan2(-seg.y, Vector2(seg.x, seg.z).length())
		var b2 := Basis.from_euler(Vector3(pitch, atan2(dir.x, dir.z), 0))
		_solid(Vector3(1.5, 0.12, seg.length() * 0.92), Transform3D(b2, mid + Vector3.DOWN * 0.06), _mat("bois"))
		for sgn in [-1.0, 1.0]:
			var rail: Vector3 = mid + side * sgn * 0.8 + Vector3.UP * 0.5
			_solid(Vector3(0.06, 1.0, seg.length()), Transform3D(b2, rail), _mat("corde"), false)
			_mesh(self, _box_mesh(Vector3(0.04, 0.04, seg.length() + 0.02)), _mat("corde"), Vector3.ZERO).global_transform = Transform3D(b2, rail + Vector3.UP * 0.5)
			if k % 4 == 0:
				_mesh(self, _cyl(0.02, 0.02, 1.0, 4), _mat("corde"), mid + side * sgn * 0.8 + Vector3.UP * 0.5)
	for end in [a, b]:
		for sgn in [-1.0, 1.0]:
			_mesh(self, _cyl(0.07, 0.09, 1.6, 8), _mat("bois"), end + side * sgn * 0.85 + Vector3.UP * 0.8)


# =================================================================== la brume du Bois-Doré

func _build_mist() -> void:
	if not pc:
		return
	_fog = FogVolume.new()
	_fog.name = "Brume_du_Bois_Dore"
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(MIST_R * 2.1, 90.0, MIST_R * 2.1)
	var m := FogMaterial.new()
	m.density = 0.09
	m.albedo = Color(0.95, 0.95, 0.92)
	m.edge_fade = 0.25
	_fog.material = m
	add_child(_fog)
	_fog.global_position = ile.CENTER + Vector3.UP * 10.0


func allowed() -> bool:
	return bool(state["arbre"]) or (main.inventory_v28 != null and main.inventory_v28.count("boussole_elfique") > 0)


# =================================================================== 2) la quête (une fois les habitants installés)

func build_quest() -> void:
	glade = _find_glade()
	if glade != Vector3.INF:
		_build_glade()
		_spawn_lyra()
	_build_flower()
	_build_spring()
	village = preload("res://scripts/village_elfe_v42.gd").new()
	village.name = "Village_elfe_v42"
	add_child(village)
	village.build(self)
	print("ILE_MANGA_V41: clairière de Lyra à ", glade, ", fleur de lune à ", _flower_pos, ", île des elfes à ", ile.CENTER)


## Une clairière plate et libre, au cœur de l'île du village, plutôt vers le sud-est.
func _find_glade() -> Vector3:
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var target := Vector2(26.0, 16.0)
	var best := Vector3.INF
	var best_score: float = INF
	for ai in range(48):
		var a: float = TAU * ai / 48.0
		for r in [20.0, 24.0, 28.0, 32.0, 36.0, 40.0]:
			var p := Vector2(cos(a) * r, sin(a) * r)
			var h: float = main._height_at(p.x, p.y)
			if h < 1.5 or h > 16.0:
				continue
			if Falls.near_pool(p.x, p.y):
				continue
			var lo: float = INF
			var hi: float = -INF
			for k in range(12):
				for rr in [2.5, 5.0]:
					var q: float = main._height_at(p.x + cos(k * PI / 6.0) * rr, p.y + sin(k * PI / 6.0) * rr)
					lo = minf(lo, q)
					hi = maxf(hi, q)
			if hi - lo > 1.6:
				continue
			var far_ok: bool = true
			for room in main.ROOMS_V27:
				if Vector2((room[0] + room[1]) * 0.5 - p.x, (room[2] + room[3]) * 0.5 - p.y).length() < 13.0:
					far_ok = false
			# Pas sous l'île céleste qui flotte au-dessus du village.
			if Vector2(p.x - 20.0, p.y + 15.0).length() < 30.0:
				far_ok = false
			if main.donjon_v35 != null and main.donjon_v35.village_trap != Vector3.INF:
				var vt: Vector3 = main.donjon_v35.village_trap
				if Vector2(vt.x - p.x, vt.z - p.y).length() < 15.0:
					far_ok = false
			if not far_ok:
				continue
			var qs := PhysicsShapeQueryParameters3D.new()
			var sph := SphereShape3D.new()
			sph.radius = 5.5
			qs.shape = sph
			qs.collision_mask = 1
			qs.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, h + 6.2, p.y))
			if not space.intersect_shape(qs, 1).is_empty():
				continue
			var score: float = (hi - lo) + p.distance_to(target) * 0.05
			if score < best_score:
				best_score = score
				best = Vector3(p.x, h, p.y)
	return best


func _build_glade() -> void:
	# L'Arbre sacré, mourant : feuillage roussi, sans éclat.
	var tree := MeshInstance3D.new()
	tree.name = "Arbre_sacre"
	tree.mesh = main.flora_v30.canopy_tree_mesh(1, pc) if main.flora_v30 != null else flora.canopy_tree_mesh(1, pc)
	tree.scale = Vector3.ONE * 0.85
	add_child(tree)
	tree.global_position = glade + Vector3.DOWN * 0.15
	_sacred_leaves = (flora.canopy_mat() as ShaderMaterial).duplicate()
	tree.set_surface_override_material(1, _sacred_leaves)
	_cyl_collision(glade, 0.55, 8.0)
	_sacred_light = OmniLight3D.new()
	_sacred_light.light_color = Color(1.0, 0.88, 0.55)
	_sacred_light.omni_range = 14.0
	add_child(_sacred_light)
	_sacred_light.global_position = glade + Vector3.UP * 5.0
	_sacred_fx = CPUParticles3D.new()
	_sacred_fx.amount = 40
	_sacred_fx.lifetime = 5.0
	_sacred_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sacred_fx.emission_sphere_radius = 5.0
	_sacred_fx.gravity = Vector3(0, 0.12, 0)
	_sacred_fx.direction = Vector3.UP
	_sacred_fx.initial_velocity_min = 0.05
	_sacred_fx.initial_velocity_max = 0.2
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.albedo_color = Color(1.0, 0.9, 0.5, 0.85)
	fm.albedo_texture = main._soft_dot_v24()
	q.material = fm
	_sacred_fx.mesh = q
	add_child(_sacred_fx)
	_sacred_fx.global_position = glade + Vector3.UP * 4.0
	# Un cercle de pierres blanches et de champignons, et des fleurs.
	for k in range(14):
		var a: float = TAU * k / 14.0
		var p: Vector3 = glade + Vector3(cos(a) * 7.5, 0, sin(a) * 7.5)
		p.y = main._height_at(p.x, p.z)
		_mesh(self, Rocks.shape(4190 + k, Vector3(0.6, 0.45, 0.5), 0.5, 0.06), _mat("pierre"), p + Vector3.UP * 0.12)
		if k % 2 == 0:
			_mesh(self, _cyl(0.04, 0.05, 0.2, 6), _flower_mat(Color(0.95, 0.92, 0.85)), p + Vector3(0.6, 0.1, 0.3))
			_mesh(self, _sphere(0.11, 10), _flower_mat(Color(0.85, 0.3, 0.25)), p + Vector3(0.6, 0.22, 0.3), Vector3.ZERO, Vector3(1.0, 0.5, 1.0))
	for k in range(4):
		var a2: float = TAU * k / 4.0 + 0.4
		_flower_bed(glade + Vector3(cos(a2) * 4.5, 0, sin(a2) * 4.5), 1.2, 4200 + k)
	_apply_tree()


func _apply_tree() -> void:
	if _sacred_leaves == null:
		return
	var healed: bool = bool(state["arbre"])
	_sacred_leaves.set_shader_parameter("tint", Color(1.05, 1.15, 0.62) if healed else Color(0.78, 0.55, 0.32))
	_sacred_light.light_energy = 1.6 if healed else 0.0
	_sacred_fx.emitting = healed


func _spawn_lyra() -> void:
	var side := Vector3(1, 0, 0)
	var front := Vector3(0, 0, 1)
	_home_points = {"arbre": glade + front * 2.6, "fleurs": glade + side * 4.2 + front * 1.5, "pierre": glade - side * 4.0 + front * 2.0}
	_home_graph = {"arbre": ["fleurs", "pierre"], "fleurs": ["arbre"], "pierre": ["arbre"]}
	var G: Vector3 = ile.glade_world()
	_glade_points = {"place": G + Vector3(0, 0, 9.0), "fontaine": G + Vector3(2.6, 0, 12.0), "banc": G + Vector3(-6.0, 0, 6.5), "arbre": G + Vector3(4.5, 0, 4.0)}
	_glade_graph = {"place": ["fontaine", "banc", "arbre"], "fontaine": ["place"], "banc": ["place"], "arbre": ["place"]}
	lyra = preload("res://scripts/pnj/pnj_v31.gd").new()
	main.add_child(lyra)
	lyra.setup(main, LyraData.DATA, _home_points.duplicate(), _home_graph.duplicate(), "arbre")
	var saved: Variant = main.pending_pnj_v31.get("lyra", {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		lyra.load_data(saved)
	main.npcs_v31.append(lyra)


func _move_lyra(home: bool) -> void:
	if lyra == null:
		return
	var pts: Dictionary = _home_points if home else _glade_points
	var graph: Dictionary = _home_graph if home else _glade_graph
	lyra.points = pts.duplicate()
	lyra.links = graph.duplicate()
	lyra.at_point = "arbre" if home else "place"
	lyra.route = []
	lyra.state = "repos"
	lyra.global_position = pts[lyra.at_point]
	lyra._snap_to_floor()
	_lyra_away = not home


## La fleur de lune, au sommet du petit piton de la jungle qui regarde la baie.
func _build_flower() -> void:
	var j: Node3D = main.jungle_v29
	if j == null:
		return
	var tw: Array = j.TOWERS[4]
	var c: Vector2 = tw[0]
	var x: float = j.CENTER.x + c.x
	var z: float = j.CENTER.z + c.y
	_flower_pos = Vector3(x, j.height(x, z), z)
	_flower = Node3D.new()
	_flower.name = "Fleur_de_lune"
	add_child(_flower)
	_flower.global_position = _flower_pos
	var petal := StandardMaterial3D.new()
	petal.albedo_color = Color(0.92, 0.96, 1.0)
	petal.emission_enabled = true
	petal.emission = Color(0.7, 0.85, 1.0)
	petal.emission_energy_multiplier = 1.8
	_mesh(_flower, _cyl(0.012, 0.016, 0.45, 6), _flower_mat(Color(0.3, 0.55, 0.32)), Vector3(0, 0.22, 0))
	for k in range(7):
		var a: float = TAU * k / 7.0
		_mesh(_flower, _sphere(0.08, 10), petal, Vector3(cos(a) * 0.09, 0.47, sin(a) * 0.09), Vector3(0.35, 0.0, 0.0), Vector3(1.0, 0.35, 1.6)).rotation.y = -a
	_mesh(_flower, _sphere(0.045, 10), _flower_mat(Color(0.75, 0.9, 1.0)), Vector3(0, 0.5, 0))
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.85, 1.0)
	l.light_energy = 1.2
	l.omni_range = 5.0
	l.position = Vector3(0, 0.8, 0)
	_flower.add_child(l)
	main.donjon_v35._interactions.append({"id": "fleur_lune", "pos": _flower_pos, "radius": 1.8,
		"text": "E : cueillir la fleur de lune", "vr": "Gâchette : cueillir la fleur", "call": _pick_flower,
		"when": func(): return not bool(state["fleur"])})


func _pick_flower() -> void:
	var got: int = main.inventory_v28.add("fleur_lune", 1)
	if got <= 0:
		main.donjon_v35._say("Ton sac est plein ! Fais de la place pour la fleur.", 3.0)
		return
	state["fleur"] = true
	_flower.visible = false
	if main.combat_v28 != null:
		main.combat_v28.puff(_flower_pos + Vector3.UP * 0.5, Color(0.8, 0.9, 1.0))
	main.donjon_v35._say("La fleur de lune ! Ses pétales brillent doucement entre tes doigts, comme un morceau de nuit.", 5.0)


## Le bassin de la grande chute (nord-est) : on y remplit la fiole de Lyra.
func _build_spring() -> void:
	var site: Vector2 = Falls.SITES[0][0]
	var pc2: Vector2 = Falls.pool_center(site)
	var to_c: Vector2 = (-pc2).normalized()
	var edge: Vector2 = pc2 + to_c * (Falls.POOL_RADIUS + 0.6)
	var pos := Vector3(edge.x, main._height_at(edge.x, edge.y), edge.y)
	main.donjon_v35._interactions.append({"id": "source_fiole", "pos": pos, "radius": 2.8,
		"text": "E : remplir la fiole à la source", "vr": "Gâchette : remplir la fiole", "call": _fill_flask,
		"when": func(): return main.inventory_v28.count("fiole_vide") > 0})


func _fill_flask() -> void:
	main.inventory_v28.remove("fiole_vide", 1)
	main.inventory_v28.add("eau_source", 1)
	main.donjon_v35._say("Tu plonges la fiole de cristal dans le bassin. L'eau de la source y scintille, comme pleine d'étoiles.", 5.0)


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or not main.game_started or ile == null:
		return
	_mist_clock = maxf(_mist_clock - delta, 0.0)
	var ok: bool = allowed()
	if _fog != null:
		_fog.visible = not ok
	# La brume repousse le bateau tant qu'on n'a pas la boussole.
	var boat: Node = main.boat_v29
	if boat != null and boat.driving and not ok:
		var h: Vector3 = boat.hull.global_position
		var off := Vector2(h.x - ile.CENTER.x, h.z - ile.CENTER.z)
		if off.length() < MIST_R:
			var out: Vector2 = off.normalized()
			boat.hull.global_position = Vector3(ile.CENTER.x + out.x * (MIST_R + 0.5), h.y, ile.CENTER.z + out.y * (MIST_R + 0.5))
			boat.yaw = atan2(-out.x, -out.y) + PI
			boat.speed = 1.5
			if _mist_clock <= 0.0:
				_mist_clock = 5.0
				main.donjon_v35._say("Une brume épaisse, dorée… Le bateau tourne en rond et ressort d'où il est venu. Il faudrait un guide pour la traverser.", 5.0)
	# Première arrivée au Bois-Doré
	var p: Vector3 = main._player_pos_v27()
	if not bool(state["visite"]) and Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() < 110.0 and ile.height(p.x, p.z) > -0.2 and (boat == null or not boat.driving):
		state["visite"] = true
		main.donjon_v35._say("Le Bois-Doré. Des arbres si grands que leurs cimes se perdent dans une lumière d'or… Un sentier de lanternes s'enfonce vers le village des elfes.", 7.0)
	# La quête de Lyra : l'Arbre est soigné dès qu'elle a reçu les trois offrandes.
	if lyra != null and not bool(state["arbre"]) and str(lyra.brain.memoire["quete"]) == "finie":
		state["arbre"] = true
		_heal()
	# Elle rentre chez elle quand on s'éloigne (après la guérison).
	if lyra != null and bool(state["arbre"]) and not _lyra_away:
		var talking: bool = main.dialogue_v31 != null and main.dialogue_v31.opened
		if not talking and p.distance_to(lyra.global_position) > 16.0:
			_move_lyra(false)


func _heal() -> void:
	if _sacred_leaves == null:
		return
	var tw := create_tween()
	tw.tween_method(func(k: float): _sacred_leaves.set_shader_parameter("tint", Color(0.78, 0.55, 0.32).lerp(Color(1.05, 1.15, 0.62), k)), 0.0, 1.0, 4.0)
	create_tween().tween_property(_sacred_light, "light_energy", 1.6, 4.0)
	_sacred_fx.emitting = true
	if main.combat_v28 != null:
		for k in range(4):
			main.combat_v28.puff(glade + Vector3(0, 2.0 + k * 1.5, 0), Color(1.0, 0.9, 0.5))


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"fleur": false, "arbre": false, "visite": false}
	for k in state:
		if d.has(k):
			state[k] = bool(d[k])
	if _flower != null:
		_flower.visible = not bool(state["fleur"])
	_apply_tree()
	if lyra != null:
		_move_lyra(not bool(state["arbre"]))

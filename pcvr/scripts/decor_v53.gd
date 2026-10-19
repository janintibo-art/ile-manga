extends Node3D
## V53 : finitions graphiques du village (check-up).
##  - Matériaux réalistes partagés (bois, planches, pierre, fer forgé, terre, terre cuite),
##    texture projetée dans le monde : pas d'étirement, même sur les objets mis à l'échelle.
##  - Chemins en dalles de pierre irrégulières (au lieu de disques beiges qui se chevauchent).
##  - Lanternes de village : poteau de bois, potence de fer, lanterne vitrée qui pend.
##  - Panneau d'accueil en planches (le texte ne flotte plus dans le vide).
##  - Fumée du feu de camp : volutes claires qui montent et s'élargissent.

const Rocks = preload("res://scripts/rocks_v26.gd")
const TEX := "res://assets/textures/"

static var _mats: Dictionary = {}

var main: Node
var pc: bool = true


# =================================================================== matériaux

static func _tex_mat(key: String, albedo: String, normal: String, tint: Color, scale: float, rough: float) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(TEX + albedo)
	m.albedo_color = tint
	if normal != "":
		m.normal_enabled = true
		m.normal_texture = load(TEX + normal)
		m.normal_scale = 0.8
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


## Bois brut (poteaux, lisses, tonneaux). tint : teinte multipliée.
static func wood(tint: Color = Color(0.78, 0.66, 0.54)) -> StandardMaterial3D:
	return _tex_mat("bois_%s" % tint.to_html(), "doors/wood_plain.png", "", tint, 1.4, 0.82)


## Planches assemblées (caisses, jardinières, panneaux).
static func planks(tint: Color = Color(0.85, 0.74, 0.62)) -> StandardMaterial3D:
	# (wood_plain : des planches ; door_wood est une porte, avec ses pentures et son anneau)
	return _tex_mat("planches_%s" % tint.to_html(), "doors/wood_plain.png", "", tint, 1.1, 0.8)


static func stone(tint: Color = Color(0.82, 0.8, 0.76)) -> StandardMaterial3D:
	return _tex_mat("pierre_%s" % tint.to_html(), "terrain/stone.jpg", "terrain/stone_n.png", tint, 0.7, 0.9)


static func soil() -> StandardMaterial3D:
	return _tex_mat("terre", "jungle/jungle_soil.png", "jungle/jungle_soil_n.png", Color(0.62, 0.5, 0.4), 1.8, 0.95)


static func iron() -> StandardMaterial3D:
	if _mats.has("fer"):
		return _mats["fer"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.15, 0.14)
	m.metallic = 0.75
	m.roughness = 0.5
	_mats["fer"] = m
	return m


static func terracotta() -> StandardMaterial3D:
	return _tex_mat("terre_cuite", "terrain/stone.jpg", "", Color(0.86, 0.5, 0.33), 1.2, 0.92)


## Verre chaud d'une lanterne (lumineux, sans éblouir).
static func lantern_glass() -> StandardMaterial3D:
	if _mats.has("verre_lanterne"):
		return _mats["verre_lanterne"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.82, 0.55, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(1.0, 0.62, 0.25)
	m.emission_energy_multiplier = 1.1
	m.roughness = 0.15
	_mats["verre_lanterne"] = m
	return m


static func flame_core() -> StandardMaterial3D:
	if _mats.has("flamme"):
		return _mats["flamme"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.5)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.3)
	m.emission_energy_multiplier = 2.5
	_mats["flamme"] = m
	return m


# =================================================================== petites briques

static func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, sides: int = 10, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Lanterne en fer et verre (origine : l'anneau d'accroche, la lanterne pend dessous).
static func lantern(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> Node3D:
	var l := Node3D.new()
	l.name = "Lanterne_v53_%d" % parent.get_child_count()
	l.position = pos
	l.scale = Vector3.ONE * scale_f
	parent.add_child(l)
	var fe: Material = iron()
	cyl(l, 0.012, 0.012, 0.12, Vector3(0, -0.06, 0), fe, 6)
	# toit pyramidal, plaque du bas
	var roof: MeshInstance3D = cyl(l, 0.02, 0.15, 0.1, Vector3(0, -0.17, 0), fe, 4)
	roof.rotation.y = PI * 0.25
	box(l, Vector3(0.2, 0.025, 0.2), Vector3(0, -0.5, 0), fe)
	# montants
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(l, Vector3(0.018, 0.3, 0.018), Vector3(sx * 0.09, -0.35, sz * 0.09), fe)
	var glass: MeshInstance3D = box(l, Vector3(0.16, 0.27, 0.16), Vector3(0, -0.35, 0), lantern_glass(), Vector3.ZERO, false)
	glass.name = "Verre"
	var flame := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.08
	flame.mesh = sm
	flame.material_override = flame_core()
	flame.position = Vector3(0, -0.4, 0)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l.add_child(flame)
	return l


## Tonneau galbé : douelles de bois (profil bombé), deux ou trois cerclages de fer.
static func barrel(parent: Node3D, pos: Vector3, radius: float = 0.42, height: float = 1.05, rot_y: float = 0.0) -> Node3D:
	var b := Node3D.new()
	b.name = "Tonneau_v53_%d" % parent.get_child_count()
	b.position = pos
	b.rotation.y = rot_y
	parent.add_child(b)
	var key := "tonneau_%d_%d" % [int(radius * 100), int(height * 100)]
	var mesh: ArrayMesh = _mats.get(key)
	if mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segs: int = 20
		var rows: int = 8
		var prof: Array = []
		for j in range(rows + 1):
			var t: float = float(j) / float(rows)
			prof.append([radius * (0.86 + 0.14 * sin(PI * t)), height * t])
		for j in range(rows):
			for i in range(segs):
				var a0: float = TAU * float(i) / segs
				var a1: float = TAU * float(i + 1) / segs
				var r0: float = prof[j][0]
				var r1: float = prof[j + 1][0]
				var y0: float = prof[j][1]
				var y1: float = prof[j + 1][1]
				var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
				var p10 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
				var p01 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
				var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
				# douelles : un léger creux entre deux planches
				var n0 := Vector3(cos(a0), 0.0, sin(a0))
				var n1 := Vector3(cos(a1), 0.0, sin(a1))
				for v in [[p00, n0], [p10, n1], [p01, n0], [p10, n1], [p11, n1], [p01, n0]]:
					st.set_normal(v[1])
					st.add_vertex(v[0])
		# fonds
		for yy in [0.0, height]:
			var rr: float = radius * 0.86
			for i in range(segs):
				var a0b: float = TAU * float(i) / segs
				var a1b: float = TAU * float(i + 1) / segs
				var c := Vector3(0, yy, 0)
				var q0 := Vector3(cos(a0b) * rr, yy, sin(a0b) * rr)
				var q1 := Vector3(cos(a1b) * rr, yy, sin(a1b) * rr)
				var up: bool = yy > 0.0
				st.set_normal(Vector3.UP if up else Vector3.DOWN)
				for v2 in ([c, q0, q1] if up else [c, q1, q0]):
					st.add_vertex(v2)
		mesh = st.commit()
		_mats[key] = mesh
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = planks(Color(0.72, 0.56, 0.42))
	b.add_child(mi)
	for t in [0.1, 0.5, 0.9]:
		var rr2: float = radius * (0.86 + 0.14 * sin(PI * t)) + 0.012
		var hoop: MeshInstance3D = cyl(b, rr2, rr2, 0.05, Vector3(0, height * t, 0), iron(), 20)
		hoop.name = "Cerclage"
	return b


## Caisse de planches à cadre renforcé.
static func crate(parent: Node3D, size: Vector3, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var c := Node3D.new()
	c.name = "Caisse_v53_%d" % parent.get_child_count()
	c.position = pos
	c.rotation.y = rot_y
	parent.add_child(c)
	box(c, size, Vector3(0, size.y * 0.5, 0), planks(Color(0.8, 0.66, 0.5)))
	var e: float = 0.07
	var fr: Material = wood(Color(0.5, 0.38, 0.28))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box(c, Vector3(e, size.y + 0.01, e), Vector3(sx * (size.x * 0.5 - e * 0.4), size.y * 0.5, sz * (size.z * 0.5 - e * 0.4)), fr)
	for sy in [0.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			box(c, Vector3(size.x + 0.01, e, e), Vector3(0, sy * size.y + (e * 0.4 if sy == 0.0 else -e * 0.4), sz2 * (size.z * 0.5 - e * 0.4)), fr)
		for sx2 in [-1.0, 1.0]:
			box(c, Vector3(e, e, size.z + 0.01), Vector3(sx2 * (size.x * 0.5 - e * 0.4), sy * size.y + (e * 0.4 if sy == 0.0 else -e * 0.4), 0), fr)
	return c


## Brasero de fer forgé : vasque à rebord sur trois pieds, charbons et braises.
static func brazier(parent: Node3D, pos: Vector3, ember: Material) -> Node3D:
	var b := Node3D.new()
	b.name = "Brasero_v53_%d" % parent.get_child_count()
	b.position = pos
	parent.add_child(b)
	var fe: Material = forged_iron()
	for k in range(3):
		var a: float = TAU * float(k) / 3.0
		var leg: MeshInstance3D = cyl(b, 0.035, 0.05, 1.25, Vector3(cos(a) * 0.32, 0.6, sin(a) * 0.32), fe, 6)
		leg.rotation = Vector3(sin(a) * -0.22, 0, cos(a) * 0.22)
		box(b, Vector3(0.14, 0.04, 0.14), Vector3(cos(a) * 0.45, 0.02, sin(a) * 0.45), fe)
	cyl(b, 0.04, 0.04, 0.03, Vector3(0, 0.55, 0), fe, 6)
	var ring: MeshInstance3D = cyl(b, 0.36, 0.36, 0.04, Vector3(0, 0.55, 0), fe, 16)
	ring.name = "Anneau"
	cyl(b, 0.56, 0.3, 0.36, Vector3(0, 1.32, 0), fe, 18)
	cyl(b, 0.6, 0.6, 0.05, Vector3(0, 1.5, 0), fe, 18)
	var coal := StandardMaterial3D.new()
	coal.albedo_color = Color(0.07, 0.06, 0.06)
	coal.roughness = 0.95
	for k in range(9):
		var a2: float = TAU * float(k) / 9.0 + 0.3
		var rr: float = 0.18 + 0.18 * float(k % 3) / 2.0
		var lump := MeshInstance3D.new()
		lump.mesh = Rocks.pebble(5350 + k)
		lump.material_override = coal if k % 3 != 0 else ember
		lump.scale = Vector3.ONE * 0.38
		lump.position = Vector3(cos(a2) * rr, 1.47, sin(a2) * rr)
		b.add_child(lump)
	var glow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.2
	glow.mesh = sm
	glow.material_override = ember
	glow.position = Vector3(0, 1.43, 0)
	b.add_child(glow)
	return b


## Fer forgé : métal sombre au grain martelé (pas un aplat lisse).
static func forged_iron() -> StandardMaterial3D:
	var m: StandardMaterial3D = _tex_mat("fer_forge", "terrain/rock.jpg", "terrain/rock_n.png", Color(0.3, 0.29, 0.29), 1.6, 0.55)
	m.metallic = 0.7
	return m


# =================================================================== le village

func build(main_node: Node, high_quality: bool) -> void:
	main = main_node
	pc = high_quality
	_build_paths()
	for coord in [Vector2(4.0, 8.0), Vector2(-6.0, 7.0), Vector2(6.0, -1.0), Vector2(-4.0, -3.0)]:
		_lamp_post(coord)
	_welcome_sign(Vector2(-2.8, 7.2))
	print("ILE_MANGA_V53: chemins dallés, lanternes, panneau d'accueil")


func _h(x: float, z: float) -> float:
	return float(main._height_at(x, z))


## Chemins du feu de camp vers les deux maisons : dalles plates irrégulières, jointes d'herbe.
func _build_paths() -> void:
	var routes: Array = []
	var a: Array = []
	for j in range(15):
		var t: float = float(j) / 14.0
		a.append(Vector2(lerpf(1.2, 6.4, t), 4.0 + 0.4 * sin(t * PI)))
	routes.append(a)
	var b: Array = []
	for j in range(26):
		var t2: float = float(j) / 25.0
		var p := Vector2(lerpf(-1.0, -11.0, t2) + sin(t2 * TAU) * 0.8, lerpf(4.3, 9.0, t2))
		if p.distance_to(Vector2(-11.0, 9.0)) < 3.6:
			break
		b.append(p)
	routes.append(b)
	var rng := RandomNumberGenerator.new()
	rng.seed = 530530
	var variants: Array = []
	for v in range(4):
		variants.append([])
	for route in routes:
		var acc: float = 0.0
		for i in range(route.size() - 1):
			var p0: Vector2 = route[i]
			var p1: Vector2 = route[i + 1]
			var seg: Vector2 = p1 - p0
			var n := Vector2(-seg.y, seg.x).normalized()
			var steps: int = maxi(1, int(seg.length() / 0.62))
			for s in range(steps):
				var c: Vector2 = p0 + seg * (float(s) / float(steps))
				acc += 1.0
				var k: int = 2 if rng.randf() < 0.75 else (1 if rng.randf() < 0.5 else 3)
				for m in range(k):
					var off: float = (float(m) - float(k - 1) * 0.5) * 0.62 + rng.randf_range(-0.08, 0.08)
					var q: Vector2 = c + n * off + seg.normalized() * rng.randf_range(-0.1, 0.1)
					var sc := Vector3(rng.randf_range(1.0, 1.45), rng.randf_range(0.7, 1.0), rng.randf_range(0.95, 1.35))
					var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(sc)
					var y: float = _h(q.x, q.y) - 0.025
					variants[rng.randi() % 4].append(Transform3D(basis, Vector3(q.x, y, q.y)))
	var mat: Material = Rocks.material(Color(0.86, 0.83, 0.77), 0.12, 0.9)
	for v in range(4):
		var list: Array = variants[v]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = Rocks.shape(5300 + v * 7, Vector3(0.5, 0.12, 0.46), 0.55, 0.14, 0.3, 12)
		mm.instance_count = list.size()
		for i in range(list.size()):
			mm.set_instance_transform(i, list[i])
		var inst := MultiMeshInstance3D.new()
		inst.name = "Dalles_chemin_v53_%d" % v
		inst.multimesh = mm
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		inst.visibility_range_end = 120.0 if pc else 70.0
		add_child(inst)


func _lamp_post(coord: Vector2) -> void:
	var h: float = _h(coord.x, coord.y)
	var root := Node3D.new()
	root.name = "Lanterne_village_v53_%d" % get_child_count()
	root.position = Vector3(coord.x, h, coord.y)
	root.rotation.y = atan2(-coord.x, -(coord.y - 4.0))     # la potence regarde le feu de camp
	add_child(root)
	var w: Material = wood(Color(0.62, 0.5, 0.4))
	# pied de pierres, poteau légèrement conique, potence
	var base := MeshInstance3D.new()
	base.mesh = Rocks.shape(5311, Vector3(0.55, 0.3, 0.55), 0.7, 0.2, 0.4, 12)
	base.material_override = Rocks.material(Color(0.75, 0.72, 0.68), 0.35, 0.6)
	base.position = Vector3(0, 0.08, 0)
	root.add_child(base)
	cyl(root, 0.065, 0.085, 2.45, Vector3(0, 1.22, 0), w, 7)
	box(root, Vector3(0.07, 0.07, 0.62), Vector3(0, 2.32, 0.26), w)
	box(root, Vector3(0.05, 0.05, 0.42), Vector3(0, 2.12, 0.14), w, Vector3(deg_to_rad(-38), 0, 0))
	cyl(root, 0.012, 0.012, 0.06, Vector3(0, 2.26, 0.5), iron(), 6)
	lantern(root, Vector3(0, 2.25, 0.5), 1.15)
	main._add_obstacle_cylinder_v11("Lanterne_collision_v53", root.position + Vector3.UP * 1.2, 0.16, 2.4)
	if pc:      # comme avant : en VR, la lanterne brille sans lumière dynamique (budget)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.7, 0.4)
		light.light_energy = 0.45
		light.omni_range = 6.0
		light.shadow_enabled = false
		light.position = Vector3(0, 1.8, 0.5)
		root.add_child(light)


func _welcome_sign(at: Vector2) -> void:
	var y: float = _h(at.x, at.y)
	var root := Node3D.new()
	root.name = "Panneau_accueil_v53"
	root.position = Vector3(at.x, y, at.y)
	root.rotation.y = deg_to_rad(48.0)          # lisible depuis le point de départ du joueur
	add_child(root)
	var w: Material = wood(Color(0.6, 0.48, 0.38))
	for sx in [-0.72, 0.72]:
		cyl(root, 0.055, 0.065, 1.75, Vector3(sx, 0.86, 0), w, 7)
	var board: Material = planks(Color(1.0, 0.88, 0.7))
	box(root, Vector3(1.75, 0.62, 0.06), Vector3(0, 1.4, 0.04), board)
	box(root, Vector3(1.85, 0.06, 0.1), Vector3(0, 1.74, 0.04), w)
	var txt := Label3D.new()
	txt.name = "Texte"
	txt.text = "Bienvenue\nsur l'Île Manga"
	txt.font_size = 72
	txt.pixel_size = 0.0021
	txt.outline_size = 0
	txt.modulate = Color(0.16, 0.08, 0.03)
	txt.position = Vector3(0, 1.4, 0.075)
	txt.double_sided = false
	txt.shaded = true
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(txt)
	var back := txt.duplicate() as Label3D
	back.position = Vector3(0, 1.4, 0.005)
	back.rotation.y = PI
	root.add_child(back)
	main._add_obstacle_cylinder_v11("Panneau_collision_v53", root.position + Vector3.UP * 0.9, 0.5, 1.8)


## Fumée du feu de camp : volutes claires, éclairées par le soleil, qui montent et s'étalent.
static func smoke(parent: Node3D, at: Vector3, amount: int = 34, rise: float = 1.2, size: float = 0.9) -> GPUParticles3D:
	var parts := GPUParticles3D.new()
	parts.name = "Fumee_v53_%d" % parent.get_child_count()
	parts.amount = amount
	parts.lifetime = 6.5
	parts.position = at
	parts.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 14, 12))
	parts.preprocess = 6.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.direction = Vector3.UP
	pm.spread = 10.0
	pm.initial_velocity_min = rise * 0.8
	pm.initial_velocity_max = rise * 1.3
	pm.gravity = Vector3(0.18, 0.05, 0.06)      # légère brise
	pm.damping_min = 0.05
	pm.damping_max = 0.15
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -12.0
	pm.angular_velocity_max = 12.0
	pm.scale_min = 0.8
	pm.scale_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.25))
	curve.add_point(Vector2(0.4, 0.9))
	curve.add_point(Vector2(1.0, 2.2))
	curve.max_value = 2.5
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.53, 0.5, 0.0))
	g.add_point(0.12, Color(0.6, 0.58, 0.55, 0.22))
	g.add_point(0.55, Color(0.78, 0.77, 0.76, 0.12))
	g.set_color(g.get_point_count() - 1, Color(0.85, 0.85, 0.86, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.9
	pm.turbulence_noise_scale = 3.0
	parts.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _puff_texture()
	mat.roughness = 1.0
	mat.disable_receive_shadows = true
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = 0.6
	quad.material = mat
	parts.draw_pass_1 = quad
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(parts)
	return parts


## Bouffée de fumée : bord irrégulier (bruit), cœur doux.
static func _puff_texture() -> Texture2D:
	if _mats.has("tex_bouffee"):
		return _mats["tex_bouffee"]
	var n := FastNoiseLite.new()
	n.seed = 53
	n.frequency = 0.08
	n.fractal_octaves = 4
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d: float = Vector2(x - 31.5, y - 31.5).length() / 31.5
			var v: float = n.get_noise_2d(x, y) * 0.5 + 0.5
			var a: float = clampf(1.0 - smoothstep(0.35, 1.0, d + (0.5 - v) * 0.5), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * (0.7 + 0.3 * v)))
	var tex := ImageTexture.create_from_image(img)
	_mats["tex_bouffee"] = tex
	return tex

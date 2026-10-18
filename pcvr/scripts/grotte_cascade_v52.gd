extends Node3D
## V52 : une petite grotte cachée derrière la cascade de l'ouest du village.
## On entre dans le bassin, on passe derrière le rideau d'eau : une ouverture s'ouvre dans la
## falaise. Une rampe de roche sort de l'eau et mène à une petite salle aux cristaux, où
## attend un vieux coffre (50 pièces, 2 rubis, 3 perles).
## La falaise est vraiment percée : les triangles du bloc central (affichage et collision)
## sont retirés à l'endroit de l'ouverture, et une coque de roche tournée vers l'intérieur
## forme le couloir et la salle. Ouvert ou non : donjon_v35.state["grotte_cascade"].

const Rocks = preload("res://scripts/rocks_v26.gd")
const SITE: int = 1                 # la cascade de l'ouest (face à l'île de la jungle)
const REWARD := [["piece", 50], ["rubis", 2], ["perle", 3]]

var main: Node
var site: Dictionary = {}
var origin := Vector3.ZERO          # c3 du site
var right := Vector3.RIGHT          # r : axe x local
var front := Vector3.BACK           # f : axe z local (vers le bassin)
var water_y: float = 0.0
var face_z: float = 5.5             # face avant de la falaise à hauteur d'eau (z local)
var floor_y: float = 0.0            # sol sec de la salle
var chest_pos := Vector3.ZERO
var entry_pos := Vector3.ZERO       # au fond de la salle, devant le coffre (pour les tests)
var mouth_pos := Vector3.ZERO       # dans l'ouverture, au ras de l'eau
var behind_fall := Vector3.ZERO     # dans le bassin, derrière le rideau d'eau
var removed_tris: int = 0
var _hinge: Node3D
var _opened_shown: bool = false
var _found: bool = false
var _tick: float = 0.0


func build(main_node: Node) -> void:
	main = main_node
	var scen: Node = main.get_node_or_null("Falaises_cascades_v13")
	if scen == null or scen.sites_info.size() <= SITE:
		return
	site = scen.sites_info[SITE]
	origin = site["c3"]
	right = site["r"]
	front = site["f"]
	water_y = float(site["water_y"])
	face_z = _find_face(water_y + 0.4)
	_carve_mouth()
	_build_shell()
	_build_rim()
	_build_chest()
	_build_lights()
	print("ILE_MANGA_V52: grotte derrière la cascade (face z=%.2f, sol %.2f, eau %.2f, %d triangles retirés)" % [face_z, floor_y - water_y, water_y, removed_tris])


## Repère local du site -> monde (y absolu).
func L(x: float, y: float, z: float) -> Vector3:
	return Vector3(origin.x, 0.0, origin.z) + right * x + front * z + Vector3(0.0, y, 0.0)


func to_local_site(p: Vector3) -> Vector3:
	var d := Vector3(p.x - origin.x, 0.0, p.z - origin.z)
	return Vector3(d.dot(right), p.y, d.dot(front))


# =================================================================== la falaise percée

## z local de la face avant du bloc central à la hauteur y (rayon lancé depuis le bassin).
func _find_face(y: float) -> float:
	var mi: MeshInstance3D = site["mesh"]
	var xf: Transform3D = mi.global_transform
	var faces: PackedVector3Array = mi.mesh.get_faces()
	var o: Vector3 = L(0.0, y, 14.0)
	var dir: Vector3 = -front
	var best: float = -INF
	for i in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(o, dir, xf * faces[i], xf * faces[i + 1], xf * faces[i + 2])
		if hit != null:
			best = maxf(best, to_local_site(hit).z)
	return best if best > -INF else 5.5


## Ouverture : on retire les triangles du bloc central qui tombent dans l'arche de l'entrée.
func _in_mouth(p_world: Vector3) -> bool:
	var q: Vector3 = to_local_site(p_world)
	if q.z < face_z - 2.6:
		return false
	var bottom: float = water_y - 1.6
	var e: float = pow(q.x / 1.2, 2.0) + pow(maxf(q.y - bottom, 0.0) / 2.85, 2.0)
	return e < 1.0 and q.y > bottom - 1.0


func _carve_mouth() -> void:
	var mi: MeshInstance3D = site["mesh"]
	var cs: CollisionShape3D = site["shape"]
	var xf: Transform3D = mi.global_transform
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		for i in range(verts.size()):
			idx.append(i)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col_faces := PackedVector3Array()
	var basis_only := Basis(xf.basis)
	for t in range(0, idx.size(), 3):
		var tri: Array = [[verts[idx[t]], norms[idx[t]]], [verts[idx[t + 1]], norms[idx[t + 1]]], [verts[idx[t + 2]], norms[idx[t + 2]]]]
		# Près de l'ouverture, on redécoupe finement (64 petits triangles) pour un bord net.
		var parts: Array = [tri]
		if _near_mouth(xf, tri):
			for depth in range(3):
				var nxt: Array = []
				for q in parts:
					nxt.append_array(_split(q))
				parts = nxt
		for q in parts:
			var c: Vector3 = xf * ((q[0][0] + q[1][0] + q[2][0]) / 3.0)
			if parts.size() > 1 and _in_mouth(c):
				removed_tris += 1
				continue
			for v in q:
				st.set_normal(v[1])
				st.add_vertex(v[0])
				col_faces.append(basis_only * v[0])
	mi.mesh = st.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(col_faces)
	shape.backface_collision = true
	cs.shape = shape


func _near_mouth(xf: Transform3D, tri: Array) -> bool:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for v in tri:
		var q: Vector3 = to_local_site(xf * (v[0] as Vector3))
		lo = lo.min(q)
		hi = hi.max(q)
	var bottom: float = water_y - 2.6
	return hi.z > face_z - 3.0 and lo.x < 2.2 and hi.x > -2.2 and hi.y > bottom and lo.y < water_y + 2.4


func _split(t: Array) -> Array:
	var m01: Array = [(t[0][0] + t[1][0]) * 0.5, ((t[0][1] + t[1][1]) * 0.5).normalized()]
	var m12: Array = [(t[1][0] + t[2][0]) * 0.5, ((t[1][1] + t[2][1]) * 0.5).normalized()]
	var m20: Array = [(t[2][0] + t[0][0]) * 0.5, ((t[2][1] + t[0][1]) * 0.5).normalized()]
	return [[t[0], m01, m20], [m01, t[1], m12], [m20, m12, t[2]], [m01, m12, m20]]


# =================================================================== le couloir et la salle

## Sections du souterrain : [z (depuis la face), sol (depuis l'eau), demi-largeur, hauteur].
## Le sol suit au moins le relief caché sous la falaise (talus du bassin), et ne redescend
## jamais une fois sorti de l'eau : une rampe régulière mène à la salle.
func _rings() -> Array:
	var plan: Array = [
		[1.0, -1.45, 2.0, 3.7],      # évasement devant la face (cache le bord de l'ouverture)
		[0.0, -1.4, 1.6, 3.4],
		[-1.0, -0.75, 1.4, 3.1],
		[-2.0, -0.1, 1.35, 2.9],
		[-3.0, 0.3, 1.45, 2.8],
		[-3.8, 0.3, 1.8, 2.9],
		[-4.8, 0.3, 2.3, 3.3],
		[-6.0, 0.3, 2.45, 3.5],
		[-7.2, 0.3, 2.3, 3.2],
		[-8.2, 0.3, 1.7, 2.5],
		[-8.8, 0.3, 0.9, 1.6],
		[-9.1, 0.3, 0.25, 0.6],
	]
	var out: Array = []
	var prev: float = -INF
	for i in range(plan.size()):
		var rg: Array = plan[i].duplicate()
		var hw: float = float(rg[2])
		var top: float = -INF
		for xx in [-hw * 0.9, -hw * 0.45, 0.0, hw * 0.45, hw * 0.9]:
			var p: Vector3 = L(xx, 0.0, face_z + float(rg[0]))
			top = maxf(top, float(main._height_at(p.x, p.z)) - water_y + 0.08)
		var fl: float = maxf(float(rg[1]), top)
		if i >= 2:
			fl = maxf(fl, prev)
		rg[1] = fl
		prev = fl
		out.append(rg)
	# toute la salle au même niveau (le plus haut des sols de la salle)
	var dry: float = 0.3
	for i in range(4, out.size()):
		dry = maxf(dry, float(out[i][1]))
	for i in range(4, out.size()):
		out[i][1] = dry
	floor_y = water_y + dry
	return out


func _build_shell() -> void:
	var rings: Array = _rings()
	var noise := FastNoiseLite.new()
	noise.seed = 5252
	noise.frequency = 0.55
	var n_arch: int = 16
	var n_floor: int = 6
	var loops: Array = []
	for rg in rings:
		var z: float = face_z + float(rg[0])
		var fy: float = water_y + float(rg[1])
		var hw: float = float(rg[2])
		var h: float = float(rg[3])
		var loop: Array = []
		for k in range(n_arch + 1):
			var th: float = PI * float(k) / float(n_arch)
			var x: float = hw * cos(th)
			var y: float = fy + h * pow(sin(th), 0.8)
			var p: Vector3 = L(x, y, z)
			# rugosité de la roche (vers l'extérieur/intérieur), pas sur le sol
			var n_out := (right * x + Vector3.UP * (y - fy) * 0.6).normalized()
			p += n_out * noise.get_noise_3dv(p) * 0.28 * clampf(sin(th) * 3.0, 0.3, 1.0)
			loop.append(p)
		for k in range(1, n_floor):
			var x2: float = -hw + 2.0 * hw * float(k) / float(n_floor)
			var p2: Vector3 = L(x2, fy + noise.get_noise_2d(x2 * 3.0, z * 3.0) * 0.04, z)
			loop.append(p2)
		loops.append(loop)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in range(loops.size() - 1):
		var r0: Array = loops[i]
		var r1: Array = loops[i + 1]
		var n: int = r0.size()
		for k in range(n):
			var a: Vector3 = r0[k]
			var b: Vector3 = r0[(k + 1) % n]
			var c: Vector3 = r1[k]
			var d: Vector3 = r1[(k + 1) % n]
			# ordre (a, c, b) : la face visible regarde vers l'intérieur du couloir
			for v in [a, c, b, b, c, d]:
				st.add_vertex(v)
				faces.append(v)
	# fond de la salle : on referme le dernier anneau
	var last: Array = loops[loops.size() - 1]
	var center := Vector3.ZERO
	for v in last:
		center += v
	center /= float(last.size())
	center += -front * 0.2
	for k in range(last.size()):
		var a2: Vector3 = last[k]
		var b2: Vector3 = last[(k + 1) % last.size()]
		for v in [a2, center, b2]:
			st.add_vertex(v)
			faces.append(v)
	st.generate_normals()
	var shell := MeshInstance3D.new()
	shell.name = "Grotte_parois_v52"
	shell.mesh = st.commit()
	var mat: ShaderMaterial = Rocks.material(Color(0.5, 0.5, 0.5), 0.15, 0.3).duplicate()
	mat.set_shader_parameter("wet_zone", Vector4(L(0, 0, face_z).x, water_y, L(0, 0, face_z).z, 5.0))
	shell.material_override = mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(shell)
	var body := StaticBody3D.new()
	body.name = "Falaise_grotte_collision_v52"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	mouth_pos = L(0.0, water_y - 1.3, face_z - 0.3)
	behind_fall = L(0.0, water_y - 1.3, face_z + 1.4)
	chest_pos = L(0.0, floor_y, face_z - 7.6)
	entry_pos = L(0.0, floor_y, face_z - 5.6)
	# Des cristaux sortent des parois et du sol.
	var crystal := StandardMaterial3D.new()
	crystal.albedo_color = Color(0.45, 0.85, 1.0, 0.85)
	crystal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal.emission_enabled = true
	crystal.emission = Color(0.25, 0.75, 1.0)
	crystal.emission_energy_multiplier = 1.6
	crystal.roughness = 0.1
	crystal.metallic_specular = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = 5253
	var spots := [[-1.9, 0.2, -5.0], [2.0, 0.3, -5.6], [-1.6, 0.0, -7.4], [1.7, 0.0, -7.6], [-2.1, 1.4, -6.2], [2.0, 1.6, -4.6], [0.9, 0.0, -8.3], [-0.9, 0.0, -8.4]]
	for sp in spots:
		var cluster := Node3D.new()
		cluster.position = L(float(sp[0]), floor_y + float(sp[1]), face_z + float(sp[2]))
		cluster.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		add_child(cluster)
		for j in range(rng.randi_range(3, 5)):
			var m := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			var hgt: float = rng.randf_range(0.25, 0.7)
			cm.top_radius = 0.0
			cm.bottom_radius = rng.randf_range(0.05, 0.11)
			cm.height = hgt
			cm.radial_segments = 6
			cm.rings = 1
			m.mesh = cm
			m.material_override = crystal
			m.position = Vector3(rng.randf_range(-0.15, 0.15), hgt * 0.4, rng.randf_range(-0.15, 0.15))
			m.rotation = Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cluster.add_child(m)


## Un cadre de blocs de roche autour de l'ouverture : bord naturel, irrégulier.
func _build_rim() -> void:
	var mat: Material = site["rock_mat"]
	var body := StaticBody3D.new()
	body.name = "Falaise_grotte_bord_v52"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5254
	var bottom: float = water_y - 1.6
	var n: int = 13
	for i in range(n):
		var th: float = lerpf(0.05, PI - 0.05, float(i) / float(n - 1))
		var x: float = 1.55 * cos(th)
		var y: float = bottom + 3.15 * sin(th)
		if y < water_y - 0.9:
			continue
		var sz: float = rng.randf_range(0.75, 1.15)
		var size := Vector3(sz * rng.randf_range(1.0, 1.4), sz, sz * rng.randf_range(0.8, 1.1))
		var mesh: ArrayMesh = Rocks.shape(5260 + i, size, 0.7, 0.25, 2.0, 20)
		var mi := MeshInstance3D.new()
		mi.name = "Bord_grotte_%d" % i
		mi.mesh = mesh
		mi.material_override = mat
		var pos: Vector3 = L(x, y, face_z + rng.randf_range(-0.05, 0.2))
		var yaw: float = rng.randf() * TAU
		mi.position = pos
		mi.rotation = Vector3(rng.randf_range(-0.4, 0.4), yaw, rng.randf_range(-0.4, 0.4))
		add_child(mi)
		var cs: CollisionShape3D = Rocks.collision_for(mesh, Transform3D(Basis.from_euler(mi.rotation), pos))
		body.add_child(cs)


# =================================================================== le coffre

func _build_chest() -> void:
	var root := Node3D.new()
	root.name = "Coffre_grotte_v52"
	add_child(root)
	root.global_position = chest_pos
	root.look_at(chest_pos + front, Vector3.UP)
	root.rotate_object_local(Vector3.UP, PI)     # le devant du coffre regarde l'entrée
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png")
	wood.uv1_triplanar = true
	wood.albedo_color = Color(0.62, 0.48, 0.36)
	wood.roughness = 0.8
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.32, 0.3, 0.28)
	iron.metallic = 0.85
	iron.roughness = 0.45
	_box(root, Vector3(1.0, 0.55, 0.65), Vector3(0, 0.275, 0), wood)
	for x in [-0.38, 0.0, 0.38]:
		_box(root, Vector3(0.06, 0.57, 0.67), Vector3(x, 0.275, 0), iron)
	_hinge = Node3D.new()
	_hinge.name = "Charniere"
	_hinge.position = Vector3(0, 0.55, -0.32)
	root.add_child(_hinge)
	var lid := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.33
	cyl.bottom_radius = 0.33
	cyl.height = 1.0
	cyl.radial_segments = 16
	lid.mesh = cyl
	lid.material_override = wood
	lid.rotation = Vector3(0, 0, PI * 0.5)
	lid.scale = Vector3(1.0, 1.0, 0.98)
	lid.position = Vector3(0, -0.05, 0.32)
	_hinge.add_child(lid)
	var lock := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.12, 0.14, 0.05)
	lock.mesh = lm
	lock.material_override = iron
	lock.position = Vector3(0, 0.5, 0.34)
	root.add_child(lock)
	var col := StaticBody3D.new()
	col.name = "Coffre_grotte_collision"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.0, 0.85, 0.65)
	cs.shape = bs
	cs.position = Vector3(0, 0.42, 0)
	col.add_child(cs)
	root.add_child(col)
	var d: Node = main.get("donjon_v35")
	if d != null:
		d._interactions.append({"id": "coffre_grotte_cascade", "pos": chest_pos, "radius": 1.9,
			"text": "E : ouvrir le vieux coffre", "vr": "Gâchette : ouvrir le coffre", "call": open_chest,
			"when": func(): return not opened()})


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _build_lights() -> void:
	var glow := OmniLight3D.new()
	glow.name = "Lueur_cristaux_v52"
	glow.light_color = Color(0.55, 0.85, 1.0)
	glow.light_energy = 1.6
	glow.omni_range = 7.5
	glow.omni_attenuation = 1.2
	glow.shadow_enabled = false
	glow.position = L(0.0, floor_y + 2.2, face_z - 6.2)
	add_child(glow)
	var warm := OmniLight3D.new()
	warm.name = "Lueur_coffre_v52"
	warm.light_color = Color(1.0, 0.78, 0.45)
	warm.light_energy = 0.9
	warm.omni_range = 3.2
	warm.position = chest_pos + Vector3.UP * 1.1 + front * 0.6
	add_child(warm)
	# la lumière du jour, bleutée, qui traverse le rideau d'eau
	var curtain := OmniLight3D.new()
	curtain.name = "Lumiere_rideau_v52"
	curtain.light_color = Color(0.7, 0.85, 1.0)
	curtain.light_energy = 1.0
	curtain.omni_range = 6.0
	curtain.position = L(0.0, water_y + 1.2, face_z + 0.4)
	add_child(curtain)


func opened() -> bool:
	var d: Node = main.get("donjon_v35")
	return d != null and bool(d.state.get("grotte_cascade", false))


func open_chest() -> void:
	var inv: Node = main.inventory_v28
	if not inv.can_accept(REWARD):
		main.donjon_v35._say("Ton sac est plein ! Fais de la place avant d'ouvrir le coffre : son contenu t'attendra.", 4.5)
		return
	main.donjon_v35.state["grotte_cascade"] = true
	_opened_shown = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.play("coffre", chest_pos + Vector3.UP * 0.5)
	main.jingle("decouverte")
	create_tween().tween_property(_hinge, "rotation:x", -1.8, 0.8).set_trans(Tween.TRANS_BACK)
	var got: Array = []
	for it in REWARD:
		got.append(inv.add(str(it[0]), int(it[1])))
	main.donjon_v35._say("Le vieux coffre de la cascade : %d pièces d'or, %d rubis et %d perles ! Quelqu'un avait trouvé la cachette bien avant toi…" % [got[0], got[1], got[2]], 6.5)
	if main.combat_v28 != null:
		main.combat_v28.puff(chest_pos + Vector3.UP * 0.8, Color(0.6, 0.9, 1.0))


func _process(delta: float) -> void:
	if main == null or _hinge == null:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.3
	# Couvercle selon la sauvegarde (chargement d'une partie).
	var o: bool = opened()
	if o != _opened_shown:
		_opened_shown = o
		_hinge.rotation.x = -1.8 if o else 0.0
	# Première fois dans la grotte (dans cette session) : un petit mot.
	if not _found and bool(main.game_started):
		var p: Vector3 = main._player_pos_v27()
		var q: Vector3 = to_local_site(p)
		if absf(q.x) < 2.6 and q.z < face_z - 2.5 and q.z > face_z - 9.5 and absf(p.y - floor_y) < 2.5:
			_found = true
			if not o:
				main.donjon_v35._say("Une grotte cachée derrière la cascade ! Des cristaux luisent dans la pénombre… et là, au fond, un vieux coffre.", 5.5)

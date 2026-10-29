extends RefCounted
## V87 : les Moaïs, sculptés ici (un maillage calculé, pas un modèle importé). Le corps est une
## suite d'anneaux empilés (une section aux coins arrondis qui s'élargit aux épaules, se resserre
## au cou, s'avance pour la tête), puis on sculpte la face avant : l'arcade lourde, les orbites
## creuses, le long nez droit et ses narines, les lèvres serrées, le menton en avant ; les
## longues oreilles sur les côtés ; les bras gravés le long du corps et les longues mains qui se
## rejoignent sur le ventre. Trois variantes (élancé, trapu, ancien et usé). Une unité = la
## hauteur de la statue (on l'agrandit à la pose). Pierre : le tuf (textures/moai/pierre_moai),
## le chignon de pierre rouge (pukao) : la scorie (textures/moai/pukao).
## Les maillages sont calculés une fois par variante et partagés.

const TEX := "res://assets/textures/moai/"
const NA: int = 64          # sommets autour
const NY: int = 120         # anneaux du bas en haut

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


## Les proportions d'une variante : [demi-largeur épaules, demi-profondeur, demi-largeur tête,
## hauteur des mains, carré des sections, usure]
## (variante + 10 : un Moaï habité, les mains plus haut pour laisser la place à la porte)
static func _var(v: int) -> Array:
	var P: Array
	match v % 10:
		1:
			P = [0.205, 0.125, 0.165, 0.24, 4.0, 0.0]       # trapu
		2:
			P = [0.18, 0.11, 0.15, 0.22, 3.4, 1.0]          # ancien, usé
		_:
			P = [0.17, 0.112, 0.145, 0.24, 4.2, 0.0]        # élancé
	if v >= 10:
		P[3] = 0.34
	return P


## La forme sans les détails : demi-largeur, demi-profondeur et avancée du centre à la hauteur y.
static func _section(y: float, P: Array) -> Vector3:
	var sw: float = float(P[0])
	var sd: float = float(P[1])
	var hw: float = float(P[2])
	var w: float
	var d: float
	var zc: float = 0.0
	if y < 0.5:
		# le torse : s'élargit un peu jusqu'aux épaules
		w = lerpf(sw * 0.94, sw, smoothstep(0.0, 0.48, y))
		d = sd * (1.0 + 0.06 * exp(-pow((y - 0.2) / 0.12, 2.0)))
	elif y < 0.6:
		# les épaules s'arrondissent, le cou
		var t: float = smoothstep(0.5, 0.6, y)
		w = lerpf(sw, hw * 0.98, t)
		d = lerpf(sd, sd * 1.12, t)
		zc = 0.018 * t
	else:
		# la tête : haute, un peu plus profonde, qui s'avance ; le dessus plat, incliné vers l'arrière
		var t2: float = smoothstep(0.6, 1.0, y)
		w = hw * (1.0 - 0.06 * t2)
		d = sd * (1.12 + 0.08 * t2)
		zc = 0.018 + 0.012 * t2
		if y > 0.965:
			var k: float = smoothstep(0.965, 1.0, y)
			w *= 1.0 - 0.18 * k
			d *= 1.0 - 0.22 * k
	return Vector3(w, d, zc)


## Ce que le sculpteur creuse ou laisse en relief sur la face avant (x en unités, y de 0 à 1) :
## renvoie l'avancée (en unités) à ajouter vers l'avant.
static func _face(x: float, y: float, P: Array) -> float:
	var ax: float = absf(x)
	var f: float = 0.0
	# l'arcade : un gros bourrelet en travers
	f += 0.03 * exp(-pow((y - 0.858) / 0.016, 2.0)) * (1.0 - smoothstep(0.1, 0.14, ax))
	# les orbites : deux creux sous l'arcade
	f -= 0.028 * exp(-(pow((ax - 0.062) / 0.036, 2.0) + pow((y - 0.815) / 0.028, 2.0)))
	# le nez : droit, long, qui s'avance de plus en plus jusqu'au bout
	if y > 0.645 and y < 0.85:
		var t: float = clampf((0.85 - y) / 0.19, 0.0, 1.0)
		var pw: float = 0.018 + 0.04 * t
		var prot: float = 0.014 + 0.105 * pow(t, 1.2)
		var bottom: float = smoothstep(0.645, 0.668, y)
		f += prot * pow(maxf(0.0, 1.0 - pow(ax / pw, 2.0)), 1.4) * bottom
	# les narines : deux petites boules au bas du nez
	f += 0.03 * exp(-(pow((ax - 0.04) / 0.015, 2.0) + pow((y - 0.668) / 0.012, 2.0)))
	# la bouche : la lèvre du haut, la fente, la lèvre du bas, serrées
	var mouth: float = 1.0 - smoothstep(0.05, 0.075, ax)
	f += mouth * (0.024 * exp(-pow((y - 0.633) / 0.008, 2.0)) - 0.012 * exp(-pow((y - 0.623) / 0.004, 2.0)) + 0.016 * exp(-pow((y - 0.612) / 0.007, 2.0)))
	# le menton, en avant
	f += 0.03 * exp(-pow((y - 0.585) / 0.016, 2.0)) * (1.0 - smoothstep(0.06, 0.11, ax))
	# les joues pleines
	f += 0.008 * exp(-(pow((ax - 0.08) / 0.03, 2.0) + pow((y - 0.72) / 0.05, 2.0)))
	# les mains : de longs doigts couchés sur le ventre, jusqu'au nombril
	var hy: float = float(P[3])
	if ax > 0.025 and ax < 0.17:
		var fingers: float = 0.5 + 0.5 * cos((y - hy) * TAU / 0.011)
		f += 0.014 * fingers * exp(-pow((y - hy) / 0.022, 2.0)) * smoothstep(0.025, 0.045, ax)
	f += 0.008 * exp(-(pow(ax / 0.012, 2.0) + pow((y - (hy - 0.05)) / 0.01, 2.0)))
	return f


## Les longues oreilles (sur les côtés) : l'avancée vers l'extérieur.
static func _ears(zf: float, y: float) -> float:
	if y < 0.68 or y > 0.95:
		return 0.0
	var t: float = smoothstep(0.68, 0.72, y) * (1.0 - smoothstep(0.91, 0.95, y))
	# l'oreille est sur le côté, un peu en arrière du milieu ; un ourlet et un creux
	var on: float = exp(-pow((zf + 0.15) / 0.45, 2.0))
	var groove: float = 0.5 + 0.5 * cos(clampf((zf + 0.15) / 0.3, -1.0, 1.0) * PI)
	return t * on * (0.016 - 0.008 * groove * smoothstep(0.74, 0.8, y))


## Le corps sculpté d'une variante (une unité de haut), avec ses normales et ses UV.
static func body_mesh(v: int) -> ArrayMesh:
	if _meshes.has(v):
		return _meshes[v]
	var P: Array = _var(v)
	var e: float = float(P[4])
	var wear: float = float(P[5])
	var noise := FastNoiseLite.new()
	noise.seed = 870 + v
	noise.frequency = 6.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for j in range(NY + 1):
		var y: float = float(j) / NY
		var s: Vector3 = _section(y, P)
		var ring: Array = []
		for i in range(NA):
			var a: float = TAU * float(i) / NA
			var sa: float = sin(a)
			var ca: float = cos(a)
			var x: float = s.x * signf(sa) * pow(absf(sa), 2.0 / e)
			var z: float = s.y * signf(ca) * pow(absf(ca), 2.0 / e) + s.z
			# la face avant (et les bras sur les côtés du torse)
			var front: float = pow(maxf(0.0, ca), 1.6)
			z += _face(x, y, P) * front
			var side: float = absf(sa)
			if y < 0.52:
				# les bras : un bandeau en relief le long du corps, de l'épaule à la hanche
				var arm: float = exp(-pow((ca - 0.12) / 0.16, 2.0)) * smoothstep(0.12, 0.2, y) * (1.0 - smoothstep(0.46, 0.52, y))
				x += signf(sa) * 0.02 * arm
			x += signf(sa) * _ears(ca, y) * pow(side, 3.0)
			# l'usure de la pierre (la variante ancienne est plus grêlée)
			var n: float = noise.get_noise_3d(x * 3.0, y * 3.0, z * 3.0)
			var r: float = 1.0 + n * (0.008 + 0.02 * wear)
			ring.append(Vector3(x * r, y, z * r))
		rings.append(ring)
	for j in range(NY):
		for i in range(NA):
			var i2: int = (i + 1) % NA
			var a0: Vector3 = rings[j][i]
			var a1: Vector3 = rings[j][i2]
			var b0: Vector3 = rings[j + 1][i]
			var b1: Vector3 = rings[j + 1][i2]
			var u0: float = float(i) / NA * 2.0
			var u1: float = float(i + 1) / NA * 2.0
			var v0: float = float(j) / NY * 3.0
			var v1: float = float(j + 1) / NY * 3.0
			st.set_uv(Vector2(u0, v0)); st.add_vertex(a0)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(b1)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(a1)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(a0)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(b0)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(b1)
	# le dessus de la tête : plat
	var top: Array = rings[NY]
	var c := Vector3.ZERO
	for p in top:
		c += p
	c /= float(top.size())
	for i in range(NA):
		st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(c)
		st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(top[(i + 1) % NA])
		st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(top[i])
	st.generate_normals()
	var m: ArrayMesh = st.commit()
	_meshes[v] = m
	return m


static func stone_mat(key: String = "pierre_moai", tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	var id: String = key + str(tint)
	if _mats.has(id):
		return _mats[id]
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(TEX + key + ".png"):
		m.albedo_texture = load(TEX + key + ".png")
	if ResourceLoader.exists(TEX + key + "_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(TEX + key + "_n.png")
		m.normal_scale = 1.1
	m.albedo_color = tint
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3.ONE * (0.7 if key == "pierre_moai" else 0.9)
	_mats[id] = m
	return m


## Un Moaï debout : sa base à « at », il regarde vers « face » (horizontal).
## opts : {"h": hauteur (m), "v": variante, "pukao": bool, "yeux": bool, "porte": bool, "enfoui": m}
## Renvoie le nœud ; ses métadonnées gardent la hauteur, le pied de la porte, etc.
static func make(parent: Node3D, at: Vector3, face: Vector3, opts: Dictionary) -> Node3D:
	var h: float = float(opts.get("h", 8.0))
	var v: int = int(opts.get("v", 0)) % 10 + (10 if bool(opts.get("porte", false)) else 0)
	var P: Array = _var(v)
	var root := Node3D.new()
	root.name = str(opts.get("nom", "Moai"))
	parent.add_child(root)
	var f := Vector3(face.x, 0.0, face.z)
	f = f.normalized() if f.length() > 0.01 else Vector3(0, 0, 1)
	var buried: float = float(opts.get("enfoui", 0.0))
	root.global_transform = Transform3D(Basis(Vector3.UP, atan2(f.x, f.z)), at + Vector3.DOWN * buried)
	var tint: Color = opts.get("teinte", Color(1, 1, 1))
	var body := MeshInstance3D.new()
	body.name = "Corps"
	body.mesh = body_mesh(v)
	body.material_override = stone_mat("pierre_moai", tint * Color(0.8, 0.76, 0.7))
	body.scale = Vector3.ONE * h
	root.add_child(body)
	# le chignon de pierre rouge
	if bool(opts.get("pukao", false)):
		var pk := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = float(P[2]) * 0.86 * h
		cm.bottom_radius = float(P[2]) * 0.78 * h
		cm.height = 0.13 * h
		cm.radial_segments = 28
		pk.mesh = cm
		pk.material_override = stone_mat("pukao")
		root.add_child(pk)
		pk.position = Vector3(0, h * (0.995 + 0.065), -0.01 * h)
		var knob := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = float(P[2]) * 0.4 * h
		cm2.bottom_radius = float(P[2]) * 0.5 * h
		cm2.height = 0.03 * h
		cm2.radial_segments = 20
		knob.mesh = cm2
		knob.material_override = stone_mat("pukao")
		root.add_child(knob)
		knob.position = Vector3(0, h * 1.14, -0.01 * h)
	# les yeux de corail blanc et de pierre noire (les Moaïs « réveillés »)
	if bool(opts.get("yeux", false)):
		for sx in [-1.0, 1.0]:
			var eye := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.03 * h
			sm.height = 0.04 * h
			eye.mesh = sm
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.95, 0.93, 0.88)
			em.roughness = 0.35
			eye.material_override = em
			root.add_child(eye)
			var ez: float = _front_z(sx * 0.062, 0.815, P) - 0.012
			eye.position = Vector3(sx * 0.062 * h, 0.815 * h, ez * h)
			eye.scale = Vector3(1.25, 0.8, 0.6)
			var pup := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.013 * h
			sp.height = 0.02 * h
			pup.mesh = sp
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.04, 0.04, 0.05)
			pm.roughness = 0.2
			pup.material_override = pm
			root.add_child(pup)
			pup.position = Vector3(sx * 0.062 * h, 0.812 * h, (ez + 0.012) * h)
	# la collision : le torse et la tête
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	root.add_child(sb)
	var c1 := CollisionShape3D.new()
	var b1 := BoxShape3D.new()
	b1.size = Vector3(float(P[0]) * 2.0 * h, 0.6 * h, float(P[1]) * 2.0 * h)
	c1.shape = b1
	c1.position = Vector3(0, 0.3 * h, 0)
	sb.add_child(c1)
	var c2 := CollisionShape3D.new()
	var b2 := BoxShape3D.new()
	b2.size = Vector3(float(P[2]) * 2.0 * h, 0.42 * h, float(P[1]) * 2.5 * h)
	c2.shape = b2
	c2.position = Vector3(0, 0.79 * h, 0.03 * h)
	sb.add_child(c2)
	root.set_meta("h", h)
	root.set_meta("front", _front_z(0.0, 0.08, P) * h)
	if bool(opts.get("porte", false)):
		_door(root, h, P, opts)
	return root


## Où est la face avant (z) en x, y (unités) ?
static func _front_z(x: float, y: float, P: Array) -> float:
	var s: Vector3 = _section(y, P)
	return s.y + s.z + _face(x, y, P)


## La porte d'un Moaï habité : une porte ronde de bois clair dans le ventre de pierre, son seuil,
## son petit auvent de palmes, une lanterne, un paillasson. (Le pied de la porte, devant, est
## gardé en métadonnée « porte » pour maisons_v81.)
static func _door(root: Node3D, h: float, P: Array, opts: Dictionary) -> void:
	var fz: float = _front_z(0.0, 0.1, P) * h
	var dw: float = 1.15
	var dh: float = 2.05
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/textures/doors/wood_plain.png") if ResourceLoader.exists("res://assets/textures/doors/wood_plain.png") else null
	wood.albedo_color = Color(0.72, 0.52, 0.32) if not opts.has("bois") else opts["bois"]
	wood.roughness = 0.8
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.08, 0.07)
	dark.roughness = 0.9
	# l'embrasure : un creux sombre (on dirait qu'on a creusé dans la pierre), le cadre de pierre
	var hole := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(dw + 0.3, dh + 0.25, 0.12)
	hole.mesh = bm
	hole.material_override = dark
	root.add_child(hole)
	hole.position = Vector3(0, (dh + 0.25) * 0.5, fz - 0.02)
	var arch := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = (dw + 0.3) * 0.5
	cyl.bottom_radius = (dw + 0.3) * 0.5
	cyl.height = 0.12
	cyl.radial_segments = 24
	arch.mesh = cyl
	arch.material_override = dark
	root.add_child(arch)
	arch.rotation = Vector3(PI * 0.5, 0, 0)
	arch.position = Vector3(0, dh + 0.25, fz - 0.02)
	# la porte (le haut arrondi), ses planches, sa poignée
	var leaf := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(dw, dh, 0.07)
	leaf.mesh = lb
	leaf.material_override = wood
	root.add_child(leaf)
	leaf.position = Vector3(0, dh * 0.5, fz + 0.03)
	var top := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = dw * 0.5
	tc.bottom_radius = dw * 0.5
	tc.height = 0.07
	tc.radial_segments = 24
	top.mesh = tc
	top.material_override = wood
	root.add_child(top)
	top.rotation = Vector3(PI * 0.5, 0, 0)
	top.position = Vector3(0, dh, fz + 0.03)
	for k in range(3):
		var band := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.025, dh + dw * 0.4, 0.02)
		band.mesh = bb
		band.material_override = dark
		root.add_child(band)
		band.position = Vector3(-dw * 0.25 + k * dw * 0.25, (dh + dw * 0.4) * 0.5, fz + 0.07)
	var knob := MeshInstance3D.new()
	var ks := SphereMesh.new()
	ks.radius = 0.05
	ks.height = 0.1
	knob.mesh = ks
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.85, 0.65, 0.3)
	brass.metallic = 0.8
	brass.roughness = 0.3
	knob.material_override = brass
	root.add_child(knob)
	knob.position = Vector3(dw * 0.32, 1.0, fz + 0.09)
	# le seuil de pierre et le paillasson tressé
	var step := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(dw + 0.6, 0.18, 0.6)
	step.mesh = sbm
	step.material_override = stone_mat("ahu")
	root.add_child(step)
	step.position = Vector3(0, 0.09, fz + 0.3)
	var mat_m := MeshInstance3D.new()
	var mbm := BoxMesh.new()
	mbm.size = Vector3(0.9, 0.02, 0.5)
	mat_m.mesh = mbm
	var straw := StandardMaterial3D.new()
	straw.albedo_color = Color(0.78, 0.62, 0.36)
	straw.roughness = 1.0
	mat_m.material_override = straw
	root.add_child(mat_m)
	mat_m.position = Vector3(0, 0.02, fz + 0.95)
	# la lanterne de coquillage, accrochée à côté de la porte
	var lan := MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.12
	ls.height = 0.26
	lan.mesh = ls
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.8, 0.5)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.7, 0.35)
	glow.emission_energy_multiplier = 1.6
	lan.material_override = glow
	root.add_child(lan)
	lan.position = Vector3(dw * 0.5 + 0.35, dh + 0.1, fz + 0.12)
	root.set_meta("porte", Vector3(0, 0.05, fz + 0.5))
	root.set_meta("lanterne", lan)

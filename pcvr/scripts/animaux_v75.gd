extends RefCounted
## V75 : les modèles des animaux de Port-Boucan (chien, chat, rat, pigeon, mouette), partagés
## par la faune de la ville (faune_v75.gd) et par Sardine, le chien compagnon (chien_v75.gd).
## Tout est fait de « fuseaux » (anneaux elliptiques le long d'un chemin) aux couleurs de pelage
## peintes dans les sommets (taches, ventre clair, museau…) : un seul matériau « fourrure » pour
## tous les animaux, des maillages partagés entre les animaux d'une même allure.
##
##   var a: Node3D = Animaux.build("chien", {"taille": 1.0, "base": Color(...), ...})
##   Animaux.animate(a, clock, vitesse_m_s, pose, delta)    # pose : "", "assis", "couche", "renifle",
##                                                          # "aboie", "vol", "picore", "plane"
## Le rig (les articulations) est rangé dans la méta « rig » du nœud renvoyé.

const VIS_END: float = 75.0          # au-delà, l'animal n'est plus dessiné

static var _mesh: Dictionary = {}
static var _mat: Dictionary = {}
static var _noise: FastNoiseLite


# =================================================================== outils de maillage

static func _n3(p: Vector3, seed_i: int) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.frequency = 1.0
		_noise.fractal_octaves = 2
	return _noise.get_noise_3d(p.x + seed_i * 17.31, p.y - seed_i * 5.7, p.z + seed_i * 3.13)


## Un fuseau : pts (centres), rx (demi-largeur), ry (demi-hauteur) ; un rayon nul ferme le bout.
## colf : Callable(p: Vector3, u: float, a: float) -> Color (couleur du pelage en ce point).
## wob : poil hirsute (le contour ondule) ; up : « le haut » des anneaux (pour un chemin vertical).
static func loft(pts_in: Array, rx_in: Array, ry_in: Array, seg: int = 14, colf: Callable = Callable(), wob: float = 0.0, up: Vector3 = Vector3.UP, wseed: int = 0, sub: int = 3) -> ArrayMesh:
	# des anneaux intermédiaires (Catmull-Rom) : des silhouettes lisses
	var pts: Array = []
	var rx: Array = []
	var ry: Array = []
	var n0: int = pts_in.size()
	for i in range(n0):
		if i == n0 - 1 or sub <= 1:
			pts.append(pts_in[i])
			rx.append(float(rx_in[i]))
			ry.append(float(ry_in[i]))
			continue
		var i0: int = maxi(i - 1, 0)
		var i3: int = mini(i + 2, n0 - 1)
		for k in range(sub):
			var t: float = float(k) / float(sub)
			pts.append(_cr3(pts_in[i0], pts_in[i], pts_in[i + 1], pts_in[i3], t))
			var a0: float = float(rx_in[i])
			var a1: float = float(rx_in[i + 1])
			var b0: float = float(ry_in[i])
			var b1: float = float(ry_in[i + 1])
			if k == 0:
				rx.append(a0)
				ry.append(b0)
			elif a0 == 0.0 or a1 == 0.0:
				# vers un bout fermé : un dôme (quart d'ellipse), pas une pointe
				var tt: float = t if a1 == 0.0 else 1.0 - t
				var dome: float = sqrt(maxf(1.0 - tt * tt, 0.0))
				rx.append(maxf(a0, a1) * dome)
				ry.append(maxf(b0, b1) * dome)
			else:
				rx.append(maxf(_cr1(float(rx_in[i0]), a0, a1, float(rx_in[i3]), t), 0.0))
				ry.append(maxf(_cr1(float(ry_in[i0]), b0, b1, float(ry_in[i3]), t), 0.0))
	var n: int = pts.size()
	var rows: Array = []
	var ctr: Array = []
	var tans: Array = []
	var prev_side := Vector3.ZERO
	for i in range(n):
		var c: Vector3 = pts[i]
		var t: Vector3 = ((pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var side: Vector3
		if prev_side == Vector3.ZERO:
			var u0: Vector3 = up
			if absf(t.dot(u0)) > 0.97:
				u0 = Vector3.FORWARD if absf(t.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
			side = u0.cross(t).normalized()
		else:
			# repère transporté le long du chemin : pas de torsion quand la courbe se redresse
			side = prev_side - t * t.dot(prev_side)
			if side.length() < 1e-4:
				side = prev_side
			side = side.normalized()
		prev_side = side
		var up2: Vector3 = t.cross(side).normalized()
		var ring := PackedVector3Array()
		for j in range(seg):
			var a: float = TAU * float(j) / float(seg)
			var k: float = 1.0
			if wob > 0.0:
				var pp: Vector3 = c + side * cos(a) * float(rx[i]) + up2 * sin(a) * float(ry[i])
				k = 1.0 + wob * _n3(pp * 38.0, wseed)
			ring.append(c + side * cos(a) * float(rx[i]) * k + up2 * sin(a) * float(ry[i]) * k)
		rows.append(ring)
		ctr.append(c)
		tans.append(t)
	var norms: Array = []
	for i in range(n):
		var nr := PackedVector3Array()
		var row: PackedVector3Array = rows[i]
		var r_up: PackedVector3Array = rows[mini(i + 1, n - 1)]
		var r_dn: PackedVector3Array = rows[maxi(i - 1, 0)]
		for j in range(seg):
			var du: Vector3 = row[(j + 1) % seg] - row[(j - 1 + seg) % seg]
			var dv: Vector3 = r_up[j] - r_dn[j]
			var nn: Vector3 = du.cross(dv)
			var out: Vector3 = row[j] - (ctr[i] as Vector3)
			if nn.length() < 1e-10 or out.length() < 1e-6:
				nn = -(tans[i] as Vector3) if i == 0 else (tans[i] as Vector3)
				if i != 0 and i != n - 1:
					nn = out if out.length() > 1e-6 else Vector3.UP
				out = nn
			nn = nn.normalized()
			if nn.dot(out) < 0.0:
				nn = -nn
			nr.append(nn)
		norms.append(nr)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_c: bool = colf.is_valid()
	var cols: Array = []
	if has_c:
		for i in range(n):
			var cr := PackedColorArray()
			for j in range(seg):
				cr.append(colf.call((rows[i] as PackedVector3Array)[j], float(i) / float(n - 1), TAU * float(j) / float(seg)))
			cols.append(cr)
	for i in range(n - 1):
		for j in range(seg):
			var j2: int = (j + 1) % seg
			var q: Array = [[i, j], [i, j2], [i + 1, j2], [i + 1, j]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Array = q[tri[0]]
				var b: Array = q[tri[1]]
				var cc: Array = q[tri[2]]
				var pa: Vector3 = rows[a[0]][a[1]]
				var pb: Vector3 = rows[b[0]][b[1]]
				var pc: Vector3 = rows[cc[0]][cc[1]]
				var g: Vector3 = (pb - pa).cross(pc - pa)
				if g.length() < 1e-14:
					continue
				var ns: Vector3 = norms[a[0]][a[1]] + norms[b[0]][b[1]] + norms[cc[0]][cc[1]]
				var order: Array = [a, b, cc] if g.dot(ns) < 0.0 else [a, cc, b]
				for v in order:
					st.set_normal(norms[v[0]][v[1]])
					st.set_uv(Vector2(float(v[1]) / float(seg), float(v[0]) / float(n - 1)))
					if has_c:
						st.set_color((cols[v[0]] as PackedColorArray)[v[1]])
					else:
						st.set_color(Color(1, 1, 1))
					st.add_vertex(rows[v[0]][v[1]])
	return st.commit()


static func _cr1(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


static func _cr3(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## Un fuseau le long d'une courbe lissée (queue, pattes) : rayons r0 → r1, rond.
static func tube(ctrl: Array, r0: float, r1: float, n: int, seg: int, colf: Callable = Callable(), up: Vector3 = Vector3.UP, tip: float = 0.0) -> ArrayMesh:
	var pts: Array = []
	var curve := Curve3D.new()
	for p in ctrl:
		curve.add_point(p)
	# tangentes douces (Catmull-Rom)
	for i in range(curve.point_count):
		var prev: Vector3 = curve.get_point_position(maxi(i - 1, 0))
		var nxt: Vector3 = curve.get_point_position(mini(i + 1, curve.point_count - 1))
		var tg: Vector3 = (nxt - prev) / 6.0
		curve.set_point_in(i, -tg)
		curve.set_point_out(i, tg)
	var L: float = curve.get_baked_length()
	var rx: Array = []
	for i in range(n):
		var f: float = float(i) / float(n - 1)
		pts.append(curve.sample_baked(f * L, true))
		var r: float = lerpf(r0, r1, f)
		if i == 0 and tip >= 0.0 and tip < 0.5:
			r = r * 0.55
		rx.append(r)
	# bouts arrondis
	var d0: Vector3 = ((pts[1] as Vector3) - (pts[0] as Vector3)).normalized()
	var d1: Vector3 = ((pts[n - 1] as Vector3) - (pts[n - 2] as Vector3)).normalized()
	pts.insert(0, (pts[0] as Vector3) - d0 * r0 * 0.4)
	rx.insert(0, 0.0)
	pts.append((pts[pts.size() - 1] as Vector3) + d1 * maxf(r1, 0.002) * 0.6)
	rx.append(0.0)
	return loft(pts, rx, rx, seg, colf, 0.0, up, 0, 1)


## Une boîte aux arêtes arrondies (pour les colliers, les médailles, les caisses…).
static func rbox(size: Vector3, r: float, seg_c: int = 3) -> ArrayMesh:
	var key: String = "rbox_%s_%.3f" % [str(size), r]
	if _mesh.has(key):
		return _mesh[key]
	var hx: float = size.x * 0.5 - r
	var hy: float = size.y * 0.5 - r
	var hz: float = size.z * 0.5 - r
	# profil vertical (anneaux de rectangles arrondis)
	var prof: Array = []
	for k in range(seg_c + 1):
		var a: float = -PI * 0.5 + PI * 0.5 * float(k) / float(seg_c)
		prof.append([-hy + sin(a) * r, cos(a) * r])
	for k2 in range(seg_c + 1):
		var a2: float = PI * 0.5 * float(k2) / float(seg_c)
		prof.append([hy + sin(a2) * r, cos(a2) * r])
	var pts: Array = []
	var rows: Array = []
	for pr in prof:
		var y: float = float(pr[0])
		var rr: float = float(pr[1])
		var ring := PackedVector3Array()
		for corner in range(4):
			var cx: float = hx if corner == 0 or corner == 3 else -hx
			var cz: float = hz if corner < 2 else -hz
			var a0: float = PI * 0.5 * float(corner)
			for k3 in range(seg_c + 1):
				var a3: float = a0 + PI * 0.5 * float(k3) / float(seg_c)
				ring.append(Vector3(cx + cos(a3) * rr, y, cz + sin(a3) * rr))
		rows.append(ring)
		pts.append(Vector3(0, y, 0))
	var mesh: ArrayMesh = _grid(rows, pts)
	_mesh[key] = mesh
	return mesh


## Grille d'anneaux → maillage (normales lissées, faces vers l'extérieur).
static func _grid(rows: Array, ctr: Array) -> ArrayMesh:
	var nr: int = rows.size()
	var n: int = (rows[0] as PackedVector3Array).size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var norms: Array = []
	for i in range(nr):
		var ring := PackedVector3Array()
		var row: PackedVector3Array = rows[i]
		for j in range(n):
			var du: Vector3 = row[(j + 1) % n] - row[(j - 1 + n) % n]
			var dv: Vector3 = (rows[mini(i + 1, nr - 1)] as PackedVector3Array)[j] - (rows[maxi(i - 1, 0)] as PackedVector3Array)[j]
			var nn: Vector3 = du.cross(dv)
			var out: Vector3 = row[j] - (ctr[i] as Vector3)
			if nn.length() < 1e-10:
				nn = Vector3.UP if i == nr - 1 else Vector3.DOWN
				out = nn
			nn = nn.normalized()
			if nn.dot(out) < 0.0:
				nn = -nn
			ring.append(nn)
		norms.append(ring)
	for i in range(nr - 1):
		for j in range(n):
			var j2: int = (j + 1) % n
			var q: Array = [[i, j], [i, j2], [i + 1, j2], [i + 1, j]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Array = q[tri[0]]
				var b: Array = q[tri[1]]
				var c: Array = q[tri[2]]
				var pa: Vector3 = rows[a[0]][a[1]]
				var pb: Vector3 = rows[b[0]][b[1]]
				var pc: Vector3 = rows[c[0]][c[1]]
				var g: Vector3 = (pb - pa).cross(pc - pa)
				if g.length() < 1e-14:
					continue
				var ns: Vector3 = norms[a[0]][a[1]] + norms[b[0]][b[1]] + norms[c[0]][c[1]]
				var order: Array = [a, b, c] if g.dot(ns) < 0.0 else [a, c, b]
				for v in order:
					st.set_normal(norms[v[0]][v[1]])
					var p: Vector3 = rows[v[0]][v[1]]
					st.set_uv(Vector2(p.x + p.z, p.y))
					st.add_vertex(p)
	# les couvercles (haut et bas) : un éventail
	for cap in [0, nr - 1]:
		var row2: PackedVector3Array = rows[cap]
		var cc: Vector3 = ctr[cap]
		var nrm: Vector3 = Vector3.UP if cap == nr - 1 else Vector3.DOWN
		for j in range(n):
			var p1: Vector3 = row2[j]
			var p2: Vector3 = row2[(j + 1) % n]
			var g2: Vector3 = (p1 - cc).cross(p2 - cc)
			if g2.length() < 1e-14:
				continue
			var ordr: Array = [cc, p1, p2] if g2.dot(nrm) < 0.0 else [cc, p2, p1]
			for v2 in ordr:
				st.set_normal(nrm)
				st.set_uv(Vector2((v2 as Vector3).x, (v2 as Vector3).z))
				st.add_vertex(v2)
	return st.commit()


static func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, shadow: bool = true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	m.scale = scl
	m.visibility_range_end = VIS_END
	if not shadow:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m


static func _node(parent: Node3D, nm: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = pos
	parent.add_child(n)
	return n


static func _sph(r: float, seg: int = 12) -> SphereMesh:
	var key: String = "sph_%.4f_%d" % [r, seg]
	if _mesh.has(key):
		return _mesh[key]
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = maxi(seg / 2, 4)
	_mesh[key] = s
	return s


# =================================================================== matériaux partagés

static func _noise_tex(key: String, seed_i: int, freq: float, stretch: Vector2, normal: bool, lo: float = 0.75, hi: float = 1.0) -> Texture2D:
	var k: String = "tex_" + key + ("_n" if normal else "")
	if _mat.has(k):
		return _mat[k]
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.seed = seed_i
	fn.frequency = freq
	fn.fractal_octaves = 3
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX
	nt.noise = fn
	if normal:
		nt.as_normal_map = true
		nt.bump_strength = 6.0
	else:
		var g := Gradient.new()
		g.set_color(0, Color(lo, lo, lo))
		g.set_color(1, Color(hi, hi, hi))
		nt.color_ramp = g
	_mat[k] = nt
	return nt


## La fourrure : couleur des sommets × un grain de poils, reflets doux sur les bords.
static func fur_mat() -> StandardMaterial3D:
	if _mat.has("fur"):
		return _mat["fur"]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _noise_tex("poil", 75, 0.09, Vector2.ONE, false, 0.72, 1.0)
	m.normal_enabled = true
	m.normal_texture = _noise_tex("poil", 76, 0.14, Vector2.ONE, true)
	m.normal_scale = 0.4
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(9.0, 26.0, 9.0)
	m.roughness = 0.95
	m.metallic_specular = 0.2
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.65
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat["fur"] = m
	return m


## Les plumes : comme la fourrure, en plus lisse.
static func feather_mat() -> StandardMaterial3D:
	if _mat.has("plume"):
		return _mat["plume"]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _noise_tex("plume", 81, 0.06, Vector2.ONE, false, 0.85, 1.0)
	m.normal_enabled = true
	m.normal_texture = _noise_tex("plume", 82, 0.08, Vector2.ONE, true)
	m.normal_scale = 0.35
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(14.0, 14.0, 30.0)
	m.roughness = 0.62
	m.rim_enabled = true
	m.rim = 0.2
	m.rim_tint = 0.5
	_mat["plume"] = m
	return m


static func plain_mat(key: String, c: Color, rough: float, clearcoat: float = 0.0, emit: float = 0.0, two_sided: bool = false) -> StandardMaterial3D:
	if _mat.has(key):
		return _mat[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if clearcoat > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = clearcoat
		m.clearcoat_roughness = 0.08
		m.metallic_specular = 0.8
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	if two_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat[key] = m
	return m


## Le tissu du bandana (une couleur par bandana) : un petit motif de cachemire en bruit.
static func cloth_mat(c: Color) -> StandardMaterial3D:
	var key: String = "tissu_" + c.to_html(false)
	if _mat.has(key):
		return _mat[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = _noise_tex("tissu", 91, 0.25, Vector2.ONE, false, 0.78, 1.0)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * 20.0
	m.roughness = 0.92
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat[key] = m
	return m


# =================================================================== pelages

## La couleur d'un pelage en un point (repère de l'animal, en mètres « taille 1 »).
static func _coat(v: Dictionary, p: Vector3, belly_y: float, part: String) -> Color:
	var base: Color = v.get("base", Color(0.55, 0.4, 0.26))
	var spot: Color = v.get("tache", Color(0.95, 0.93, 0.9))
	var belly: Color = v.get("ventre", base.lightened(0.35))
	var seed_i: int = int(v.get("seed", 1))
	var cover: float = float(v.get("taches", 0.0))
	var c: Color = base
	# le dos un peu plus sombre (la « selle »), le ventre et le poitrail plus clairs
	var dark: float = clampf((p.y - belly_y) * 6.0, 0.0, 1.0)
	c = c.darkened(0.12 * dark)
	var bl: float = clampf((belly_y - p.y) * 9.0 + 0.5, 0.0, 1.0)
	if part == "corps" or part == "cou":
		c = c.lerp(belly, bl * float(v.get("ventre_k", 0.8)))
	if part == "museau":
		c = c.lerp(v.get("museau_c", belly), clampf(float(v.get("museau_k", 0.6)), 0.0, 1.0))
	if part == "patte_bas" and bool(v.get("chaussettes", false)):
		c = c.lerp(spot, 0.9)
	# les taches
	if cover > 0.0:
		var nz: float = _n3(p * float(v.get("taches_f", 7.0)), seed_i) * 0.5 + 0.5
		var th: float = 1.0 - cover
		var k: float = smoothstep(th - 0.03, th + 0.03, nz)
		c = c.lerp(spot, k)
	# tigré (chats) : des rayures sur le dos et les flancs
	if float(v.get("tigre", 0.0)) > 0.0 and part != "museau":
		var s: float = sin(p.z * 70.0 + _n3(p * 9.0, seed_i + 3) * 4.0 + p.y * 18.0)
		var kk: float = smoothstep(0.35, 0.8, s) * float(v.get("tigre", 0.0)) * clampf(dark + 0.3, 0.0, 1.0)
		c = c.lerp(v.get("rayure", base.darkened(0.45)), kk)
	# un grain de couleur poil par poil
	var g: float = _n3(p * 60.0, seed_i + 11) * 0.05
	return Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g * 0.8, 0, 1))


# =================================================================== l'entrée

## Construit un animal : espece = chien, chat, rat, pigeon, mouette. Variante : voir chaque
## constructeur. La racine est au sol, l'animal regarde vers +Z.
static func build(espece: String, v: Dictionary = {}) -> Node3D:
	match espece:
		"chien":
			return build_dog(v)
		"chat":
			return build_cat(v)
		"rat":
			return build_rat(v)
		"pigeon":
			return build_bird(v, false)
		"mouette":
			return build_bird(v, true)
	return build_dog(v)


static func _vkey(v: Dictionary) -> String:
	var keys: Array = v.keys()
	keys.sort()
	var s: String = ""
	for k in keys:
		var x: Variant = v[k]
		s += str(k) + "=" + (x.to_html() if x is Color else str(x)) + ";"
	return s


# =================================================================== le chien

## Variante du chien :
##   taille (1 = un chien moyen, 55 cm au garrot), base, tache, taches (0..1), taches_f (fréquence),
##   ventre, museau_c, museau_k, oreilles ("dresse", "tombante", "mixte"), queue ("courbe", "droite",
##   "enroulee"), hirsute (0..1), museau (longueur, 1), pattes (longueur, 1), corpulence (1),
##   bandana (Color, ou absent), chaussettes (bool), seed.
static func build_dog(v: Dictionary) -> Node3D:
	var s: float = float(v.get("taille", 1.0))
	var root := Node3D.new()
	root.name = "Chien"
	var key: String = "chien_" + _vkey(v)
	var parts: Dictionary
	if _mesh.has(key):
		parts = _mesh[key]
	else:
		parts = _dog_meshes(v)
		_mesh[key] = parts
	var fur: Material = fur_mat()
	var legk: float = float(v.get("pattes", 1.0))
	var rig := {"espece": "chien", "taille": s, "legs": [], "tail": null, "head": null, "jaw": null, "ears": [], "tongue": null}
	var scl := Node3D.new()
	scl.name = "Echelle"
	scl.scale = Vector3.ONE * s
	root.add_child(scl)
	# le pivot : à la hanche (s'asseoir = basculer autour des hanches)
	var hip_y: float = 0.45 * legk
	var pivot := _node(scl, "Pivot", Vector3(0, hip_y, -0.24))
	var body := _node(pivot, "Corps", Vector3(0, -hip_y, 0.24))
	rig["pivot"] = pivot
	rig["pivot_y"] = hip_y
	rig["body"] = body
	_mi(body, parts["torse"], fur)
	_mi(body, parts["cou"], fur)
	var head := _node(body, "Tete", Vector3(0, 0.03 + 0.70 * (0.85 + 0.15 * legk), 0.40))
	rig["head"] = head
	rig["head_rest"] = head.position
	_mi(head, parts["tete"], fur)
	var jaw := _node(head, "Machoire", Vector3(0, -0.035, 0.05))
	_mi(jaw, parts["machoire"], fur)
	var tongue := _mi(jaw, parts["langue"], plain_mat("langue", Color(0.86, 0.36, 0.42), 0.35, 0.6), Vector3(0, -0.004, 0.0), Vector3.ZERO, Vector3.ONE, false)
	tongue.visible = false
	rig["jaw"] = jaw
	rig["tongue"] = tongue
	var ml: float = float(v.get("museau", 1.0))
	var nose_m: Material = plain_mat("truffe", Color(0.05, 0.04, 0.04), 0.25, 0.9)
	_mi(head, _sph(0.019), nose_m, Vector3(0, -0.012, 0.11 + 0.085 * ml), Vector3.ZERO, Vector3(1.15, 0.85, 0.9), false)
	var eye_m: Material = plain_mat("oeil_chien", Color(0.13, 0.07, 0.03), 0.05, 1.0)
	for sx in [-1.0, 1.0]:
		_mi(head, _sph(0.0135, 10), eye_m, Vector3(sx * 0.039, 0.022, 0.068), Vector3(0, sx * 0.5, 0), Vector3(1, 0.9, 0.8), false)
	# les oreilles
	var ears: String = str(v.get("oreilles", "tombante"))
	for k in range(2):
		var sx2: float = -1.0 if k == 0 else 1.0
		var floppy: bool = ears == "tombante" or (ears == "mixte" and k == 1)
		var ear := _node(head, "Oreille%d" % k, Vector3(sx2 * (0.05 if not floppy else 0.058), 0.06 if not floppy else 0.05, -0.02))
		_mi(ear, parts["oreille_tombante" if floppy else "oreille_dresse"], fur, Vector3.ZERO, Vector3.ZERO, Vector3(sx2, 1, 1))
		rig["ears"].append([ear, sx2, floppy])
	# la queue
	var tail := _node(body, "Queue", Vector3(0, 0.53, -0.36))
	_mi(tail, parts["queue"], fur)
	rig["tail"] = tail
	# les pattes : [hanche, genou, jarret, côté, avant]
	for fr in [true, false]:
		for sx3 in [-1.0, 1.0]:
			var hip := _node(body, "Patte", Vector3(sx3 * (0.07 if fr else 0.075) * float(v.get("corpulence", 1.0)), (0.42 if fr else 0.45) * legk, 0.21 if fr else -0.25))
			var knee: Node3D
			var hock: Node3D = null
			if fr:
				_mi(hip, parts["avant_haut"], fur)
				knee = _node(hip, "Coude", Vector3(0, -0.2 * legk, -0.02))
				_mi(knee, parts["avant_bas"], fur)
			else:
				_mi(hip, parts["cuisse"], fur)
				knee = _node(hip, "Genou", Vector3(0, -0.17 * legk, 0.05))
				_mi(knee, parts["tibia"], fur)
				hock = _node(knee, "Jarret", Vector3(0, -0.12 * legk, -0.075))
				_mi(hock, parts["canon"], fur)
			rig["legs"].append([hip, knee, hock, sx3, fr])
	# le bandana (les chiens de punks !)
	if v.has("bandana") and v["bandana"] is Color:
		var cm: Material = cloth_mat(v["bandana"])
		var neck := _node(body, "Bandana", Vector3(0, 0.575 * (0.85 + 0.15 * legk), 0.31))
		neck.rotation.x = 0.8
		_mi(neck, parts["collier"], cm)
		_mi(neck, parts["foulard"], cm)
	root.set_meta("rig", rig)
	return root


static func _dog_meshes(v: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var legk: float = float(v.get("pattes", 1.0))
	var ck: float = float(v.get("corpulence", 1.0))
	var hw: float = float(v.get("hirsute", 0.0)) * 0.09
	var sd: int = int(v.get("seed", 1))
	var by: float = 0.5 * legk - 0.06
	var colb := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p, by, "corps")
	# le torse : de la croupe au poitrail (le ventre remonte vers les hanches)
	var ty: float = 0.5 * legk
	var tz: Array = [-0.41, -0.385, -0.34, -0.24, -0.1, 0.04, 0.16, 0.25, 0.31, 0.345]
	var tyy: Array = [0.0, 0.0, 0.0, 0.0, 0.025, 0.0, -0.015, 0.0, 0.03, 0.05]
	var trx: Array = [0.0, 0.07, 0.11, 0.125, 0.115, 0.125, 0.135, 0.125, 0.09, 0.0]
	var trr: Array = [0.0, 0.08, 0.12, 0.135, 0.11, 0.145, 0.17, 0.16, 0.11, 0.0]
	var pts: Array = []
	var rx: Array = []
	var ry: Array = []
	for i in range(tz.size()):
		pts.append(Vector3(0, ty + float(tyy[i]), float(tz[i])))
		rx.append(float(trx[i]) * ck)
		ry.append(float(trr[i]))
	out["torse"] = loft(pts, rx, ry, 18, colb, hw, Vector3.UP, sd)
	# le cou
	var hy: float = 0.70 * (0.85 + 0.15 * legk)
	var colc := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p, hy - 0.08, "cou")
	out["cou"] = loft([Vector3(0, ty + 0.0, 0.2), Vector3(0, ty + 0.05, 0.27), Vector3(0, hy - 0.06, 0.35), Vector3(0, hy - 0.0, 0.39), Vector3(0, hy + 0.02, 0.41)],
		[0.095 * ck, 0.09 * ck, 0.068, 0.058, 0.0], [0.12, 0.11, 0.075, 0.06, 0.0], 14, colc, hw, Vector3.UP, sd + 1)
	# la tête : crâne, stop, museau (repère de la tête)
	var ml: float = float(v.get("museau", 1.0))
	var head_y: float = hy + 0.03
	var colh := func(p: Vector3, _u: float, _a: float) -> Color:
		var pw: Vector3 = p + Vector3(0, head_y, 0.4)
		if p.z > 0.075:
			return _coat(v, pw, head_y - 0.035, "museau")
		return _coat(v, pw, head_y - 0.06, "tete")
	var hz: Array = [-0.085, -0.07, -0.035, 0.0, 0.035, 0.065, 0.085, 0.11, 0.14, 0.175, 0.19]
	var hyy: Array = [0.005, 0.01, 0.015, 0.012, 0.005, -0.004, -0.012, -0.016, -0.018, -0.02, -0.02]
	var hrx: Array = [0.0, 0.045, 0.07, 0.078, 0.073, 0.058, 0.044, 0.037, 0.033, 0.026, 0.0]
	var hry: Array = [0.0, 0.05, 0.068, 0.072, 0.066, 0.05, 0.04, 0.034, 0.03, 0.023, 0.0]
	var hp: Array = []
	var hrxa: Array = []
	var hrya: Array = []
	for i2 in range(hz.size()):
		var z: float = float(hz[i2])
		if z > 0.07:
			z = 0.07 + (z - 0.07) * ml
		hp.append(Vector3(0, float(hyy[i2]), z))
		hrxa.append(float(hrx[i2]))
		hrya.append(float(hry[i2]))
	out["tete"] = loft(hp, hrxa, hrya, 16, colh, hw * 0.6, Vector3.UP, sd + 2)
	var colj := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p + Vector3(0, head_y - 0.035, 0.45), head_y + 0.2, "museau")
	out["machoire"] = loft([Vector3(0, 0, -0.01), Vector3(0, -0.003, 0.02), Vector3(0, -0.006, 0.07 * ml), Vector3(0, -0.004, 0.105 * ml), Vector3(0, -0.002, 0.118 * ml)],
		[0.0, 0.032, 0.028, 0.02, 0.0], [0.0, 0.016, 0.013, 0.01, 0.0], 10, colj)
	out["langue"] = loft([Vector3(0, 0.004, 0.02), Vector3(0, 0.0, 0.07 * ml), Vector3(0, -0.02, 0.11 * ml), Vector3(0, -0.045, 0.13 * ml), Vector3(0, -0.06, 0.135 * ml)],
		[0.0, 0.017, 0.019, 0.017, 0.0], [0.0, 0.004, 0.004, 0.004, 0.0], 8)
	# les oreilles : une feuille épaisse (repère de l'oreille, côté +X)
	var cole := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p * 0.5 + Vector3(0.06, head_y + 0.06, 0.4), head_y - 0.2, "oreille").darkened(0.08)
	out["oreille_dresse"] = loft([Vector3(0, -0.005, 0), Vector3(0.004, 0.025, -0.004), Vector3(0.01, 0.055, -0.01), Vector3(0.015, 0.08, -0.016), Vector3(0.017, 0.092, -0.018)],
		[0.0, 0.03, 0.022, 0.011, 0.0], [0.0, 0.009, 0.007, 0.004, 0.0], 8, cole, 0.0, Vector3.BACK)
	out["oreille_tombante"] = loft([Vector3(0, 0.01, 0), Vector3(0.022, 0.012, 0.0), Vector3(0.04, -0.015, 0.012), Vector3(0.048, -0.055, 0.018), Vector3(0.048, -0.085, 0.02), Vector3(0.046, -0.095, 0.02)],
		[0.0, 0.03, 0.034, 0.03, 0.02, 0.0], [0.0, 0.008, 0.008, 0.007, 0.006, 0.0], 8, cole, 0.0, Vector3.RIGHT)
	# la queue (repère de la queue)
	var colq := func(p: Vector3, u: float, _a: float) -> Color:
		var c: Color = _coat(v, p + Vector3(0, 0.53, -0.36), 0.4, "queue")
		if bool(v.get("bout_blanc", false)) and u > 0.75:
			c = c.lerp(v.get("tache", Color(0.95, 0.93, 0.9)), 0.9)
		return c
	match str(v.get("queue", "courbe")):
		"droite":
			out["queue"] = tube([Vector3.ZERO, Vector3(0, 0.02, -0.08), Vector3(0, -0.02, -0.18), Vector3(0, -0.07, -0.26), Vector3(0, -0.12, -0.31)], 0.032 + hw * 0.2, 0.012, 12, 8, colq)
		"enroulee":
			out["queue"] = tube([Vector3.ZERO, Vector3(0, 0.08, -0.04), Vector3(0, 0.15, 0.0), Vector3(0.03, 0.15, 0.07), Vector3(0.05, 0.1, 0.06)], 0.034, 0.018, 12, 8, colq)
		_:
			out["queue"] = tube([Vector3.ZERO, Vector3(0, 0.06, -0.08), Vector3(0, 0.13, -0.15), Vector3(0, 0.2, -0.17), Vector3(0, 0.26, -0.15)], 0.032 + hw * 0.25, 0.013, 12, 8, colq)
	# les pattes (repère de chaque articulation)
	var colp := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p + Vector3(0.09, 0.3, 0.2), 0.2, "patte")
	var colpb := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p + Vector3(0.09, 0.12, 0.2), 0.0, "patte_bas")
	out["avant_haut"] = loft([Vector3(0, 0.1, -0.03), Vector3(0, 0.05, -0.02), Vector3(0, -0.02, -0.005), Vector3(0, -0.1 * legk, -0.01), Vector3(0, -0.17 * legk, -0.018), Vector3(0, -0.215 * legk, -0.02)],
		[0.0, 0.045 * ck, 0.043 * ck, 0.034, 0.029, 0.0], [0.0, 0.075, 0.062, 0.042, 0.032, 0.0], 12, colp, hw * 0.5, Vector3.FORWARD, sd + 4)
	out["avant_bas"] = _paw_leg(0.2 * legk, 0.027, 0.022, colpb, 0.01)
	out["cuisse"] = loft([Vector3(0, 0.11, -0.04), Vector3(0, 0.06, -0.025), Vector3(0, -0.02, 0.0), Vector3(0, -0.09 * legk, 0.025), Vector3(0, -0.15 * legk, 0.045), Vector3(0, -0.19 * legk, 0.05)],
		[0.0, 0.05 * ck, 0.056 * ck, 0.045, 0.03, 0.0], [0.0, 0.085, 0.1, 0.07, 0.04, 0.0], 12, colp, hw * 0.5, Vector3.FORWARD, sd + 5)
	out["tibia"] = loft([Vector3(0, 0.02, 0.005), Vector3(0, -0.01, 0.0), Vector3(0, -0.06 * legk, -0.035), Vector3(0, -0.12 * legk, -0.075), Vector3(0, -0.135 * legk, -0.082)],
		[0.0, 0.034, 0.028, 0.022, 0.0], [0.0, 0.04, 0.032, 0.024, 0.0], 10, colp, 0.0, Vector3.FORWARD)
	out["canon"] = _paw_leg(0.15 * legk, 0.022, 0.02, colpb, 0.0)
	# le bandana : un collier de tissu et la pointe triangulaire (repère du cou)
	out["collier"] = loft([Vector3(0, -0.022, 0), Vector3(0, -0.014, 0), Vector3(0, 0.014, 0), Vector3(0, 0.022, 0)],
		[0.084 * ck, 0.092 * ck, 0.092 * ck, 0.084 * ck], [0.095, 0.104, 0.104, 0.095], 20, Callable(), 0.0, Vector3.BACK, 0, 1)
	out["foulard"] = _bandana_flap()
	return out


## Une patte de bas (avant-bras ou canon) avec son pied : [haut → bas], le pied vers +Z.
static func _paw_leg(l: float, r0: float, r1: float, colf: Callable, lean: float) -> ArrayMesh:
	var pts: Array = [Vector3(0, 0.02, 0), Vector3(0, 0.0, 0), Vector3(0, -l * 0.5, lean * 0.5), Vector3(0, -l * 0.86, lean), Vector3(0, -l * 0.94, lean + 0.012),
		Vector3(0, -l - 0.004, lean + 0.03), Vector3(0, -l - 0.006, lean + 0.05), Vector3(0, -l - 0.004, lean + 0.058)]
	var rx: Array = [0.0, r0, r0 * 0.88, r1, r1 * 1.25, r1 * 1.35, r1 * 1.1, 0.0]
	var ry: Array = [0.0, r0 * 1.1, r0 * 0.95, r1, r1 * 1.0, r1 * 0.75, r1 * 0.5, 0.0]
	return loft(pts, rx, ry, 10, colf, 0.0, Vector3.FORWARD)


static func _bandana_flap() -> ArrayMesh:
	if _mesh.has("bandana_flap"):
		return _mesh["bandana_flap"]
	# un triangle de tissu qui tombe sur le poitrail, avec un pli au milieu
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_l := Vector3(-0.075, 0.016, 0.075)
	var top_r := Vector3(0.075, 0.016, 0.075)
	var tip := Vector3(0.0, -0.01, 0.215)
	var mid := Vector3(0.0, 0.004, 0.125)
	var cols: Array = [[top_l, mid, tip], [mid, top_r, tip]]
	for tri in cols:
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		var nrm: Vector3 = (b - a).cross(c - a).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		for p in [a, c, b]:
			st.set_normal(nrm)
			st.set_uv(Vector2((p as Vector3).x, (p as Vector3).z))
			st.add_vertex(p)
	var m: ArrayMesh = st.commit()
	_mesh["bandana_flap"] = m
	return m


# =================================================================== le chat

## Variante du chat : taille (1 = un chat adulte, 25 cm au garrot), base, tache, taches, ventre,
## tigre (0..1, rayures), rayure, chaussettes, bout_blanc, oeil (Color), seed.
static func build_cat(v: Dictionary) -> Node3D:
	var s: float = float(v.get("taille", 1.0))
	var root := Node3D.new()
	root.name = "Chat"
	var key: String = "chat_" + _vkey(v)
	var parts: Dictionary
	if _mesh.has(key):
		parts = _mesh[key]
	else:
		parts = _cat_meshes(v)
		_mesh[key] = parts
	var fur: Material = fur_mat()
	var rig := {"espece": "chat", "taille": s, "legs": [], "tail": null, "head": null, "jaw": null, "ears": [], "tongue": null}
	var scl := Node3D.new()
	scl.name = "Echelle"
	scl.scale = Vector3.ONE * s
	root.add_child(scl)
	var hip_y: float = 0.22
	var pivot := _node(scl, "Pivot", Vector3(0, hip_y, -0.16))
	var body := _node(pivot, "Corps", Vector3(0, -hip_y, 0.16))
	rig["pivot"] = pivot
	rig["pivot_y"] = hip_y
	rig["body"] = body
	_mi(body, parts["torse"], fur)
	var head := _node(body, "Tete", Vector3(0, 0.31, 0.2))
	rig["head"] = head
	rig["head_rest"] = head.position
	_mi(head, parts["tete"], fur)
	var eye_c: Color = v.get("oeil", Color(0.55, 0.75, 0.2))
	var eye_m: Material = plain_mat("oeil_chat_" + eye_c.to_html(false), eye_c, 0.05, 1.0, 0.25)
	var pup: Material = plain_mat("pupille", Color(0.02, 0.02, 0.02), 0.05, 1.0)
	for sx in [-1.0, 1.0]:
		_mi(head, _sph(0.0105, 10), eye_m, Vector3(sx * 0.021, 0.012, 0.047), Vector3(0, sx * 0.4, 0), Vector3(1, 0.85, 0.75), false)
		_mi(head, _sph(0.0106, 8), pup, Vector3(sx * 0.0213, 0.012, 0.0485), Vector3(0, sx * 0.4, 0), Vector3(0.3, 0.84, 0.75), false)
		var ear := _node(head, "Oreille", Vector3(sx * 0.026, 0.03, -0.004))
		_mi(ear, parts["oreille"], fur, Vector3.ZERO, Vector3(0, 0, -sx * 0.25), Vector3(sx, 1, 1))
		rig["ears"].append([ear, sx, false])
	_mi(head, _sph(0.0065, 8), plain_mat("truffe_chat", Color(0.85, 0.5, 0.52), 0.3, 0.6), Vector3(0, -0.004, 0.066), Vector3.ZERO, Vector3(1.2, 0.8, 0.8), false)
	# les moustaches
	var wm: Material = plain_mat("moustache", Color(0.95, 0.95, 0.92), 0.4, 0.0, 0.0, true)
	_mi(head, parts["moustaches"], wm, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	var tail := _node(body, "Queue", Vector3(0, 0.23, -0.22))
	_mi(tail, parts["queue"], fur)
	rig["tail"] = tail
	for fr in [true, false]:
		for sx3 in [-1.0, 1.0]:
			var hip := _node(body, "Patte", Vector3(sx3 * 0.042, 0.2 if fr else 0.215, 0.13 if fr else -0.15))
			var knee: Node3D
			var hock: Node3D = null
			if fr:
				_mi(hip, parts["avant_haut"], fur)
				knee = _node(hip, "Coude", Vector3(0, -0.1, -0.012))
				_mi(knee, parts["avant_bas"], fur)
			else:
				_mi(hip, parts["cuisse"], fur)
				knee = _node(hip, "Genou", Vector3(0, -0.085, 0.03))
				_mi(knee, parts["tibia"], fur)
				hock = _node(knee, "Jarret", Vector3(0, -0.06, -0.045))
				_mi(hock, parts["canon"], fur)
			rig["legs"].append([hip, knee, hock, sx3, fr])
	root.set_meta("rig", rig)
	return root


static func _cat_meshes(v: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var sd: int = int(v.get("seed", 2))
	var colb := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p, 0.2, "corps")
	out["torse"] = loft([Vector3(0, 0.22, -0.25), Vector3(0, 0.22, -0.235), Vector3(0, 0.222, -0.2), Vector3(0, 0.225, -0.13), Vector3(0, 0.228, -0.04), Vector3(0, 0.226, 0.06), Vector3(0, 0.235, 0.14), Vector3(0, 0.26, 0.19), Vector3(0, 0.29, 0.215), Vector3(0, 0.31, 0.225)],
		[0.0, 0.045, 0.068, 0.072, 0.066, 0.068, 0.06, 0.045, 0.036, 0.0], [0.0, 0.05, 0.07, 0.075, 0.07, 0.078, 0.07, 0.055, 0.04, 0.0], 16, colb, 0.02, Vector3.UP, sd)
	var colh := func(p: Vector3, _u: float, _a: float) -> Color:
		var pw: Vector3 = p + Vector3(0, 0.31, 0.2)
		if p.z > 0.045 and p.y < 0.0:
			return _coat(v, pw, 0.31, "museau")
		return _coat(v, pw, 0.28, "tete")
	out["tete"] = loft([Vector3(0, 0.005, -0.05), Vector3(0, 0.008, -0.042), Vector3(0, 0.01, -0.02), Vector3(0, 0.008, 0.005), Vector3(0, 0.002, 0.03), Vector3(0, -0.006, 0.05), Vector3(0, -0.009, 0.062), Vector3(0, -0.01, 0.068)],
		[0.0, 0.035, 0.05, 0.054, 0.05, 0.034, 0.022, 0.0], [0.0, 0.035, 0.045, 0.046, 0.04, 0.026, 0.018, 0.0], 16, colh, 0.0, Vector3.UP, sd + 2)
	var cole := func(p: Vector3, _u: float, _a: float) -> Color:
		var c: Color = _coat(v, p + Vector3(0.03, 0.35, 0.2), 0.0, "oreille")
		return c.lerp(Color(0.85, 0.6, 0.58), 0.25) if p.z > 0.001 else c
	out["oreille"] = loft([Vector3(0, -0.004, 0), Vector3(0.002, 0.012, 0.0), Vector3(0.004, 0.028, -0.002), Vector3(0.005, 0.04, -0.003), Vector3(0.005, 0.045, -0.003)],
		[0.0, 0.019, 0.013, 0.005, 0.0], [0.0, 0.008, 0.006, 0.003, 0.0], 8, cole, 0.0, Vector3.BACK)
	var colq := func(p: Vector3, u: float, _a: float) -> Color:
		var c: Color = _coat(v, p + Vector3(0, 0.23, -0.22), 0.1, "queue")
		if bool(v.get("bout_blanc", false)) and u > 0.85:
			c = c.lerp(v.get("tache", Color(0.95, 0.93, 0.9)), 0.9)
		return c
	out["queue"] = tube([Vector3.ZERO, Vector3(0, 0.0, -0.08), Vector3(0, 0.05, -0.17), Vector3(0, 0.15, -0.21), Vector3(0, 0.24, -0.2), Vector3(0, 0.29, -0.16)], 0.02, 0.014, 16, 8, colq)
	var colp := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p + Vector3(0.04, 0.15, 0.1), 0.12, "patte")
	var colpb := func(p: Vector3, _u: float, _a: float) -> Color: return _coat(v, p + Vector3(0.04, 0.05, 0.1), 0.0, "patte_bas")
	out["avant_haut"] = loft([Vector3(0, 0.03, -0.005), Vector3(0, 0.0, 0.0), Vector3(0, -0.05, -0.005), Vector3(0, -0.105, -0.012), Vector3(0, -0.112, -0.013)],
		[0.0, 0.03, 0.025, 0.019, 0.0], [0.0, 0.04, 0.03, 0.02, 0.0], 10, colp, 0.0, Vector3.FORWARD)
	out["avant_bas"] = _paw_leg(0.1, 0.017, 0.015, colpb, 0.004)
	out["cuisse"] = loft([Vector3(0, 0.04, -0.02), Vector3(0, 0.01, 0.0), Vector3(0, -0.04, 0.015), Vector3(0, -0.08, 0.028), Vector3(0, -0.092, 0.03)],
		[0.0, 0.038, 0.034, 0.022, 0.0], [0.0, 0.056, 0.046, 0.024, 0.0], 10, colp, 0.0, Vector3.FORWARD)
	out["tibia"] = loft([Vector3(0, 0.01, 0.003), Vector3(0, -0.005, 0.0), Vector3(0, -0.03, -0.022), Vector3(0, -0.06, -0.045), Vector3(0, -0.066, -0.049)],
		[0.0, 0.02, 0.017, 0.014, 0.0], [0.0, 0.024, 0.019, 0.015, 0.0], 8, colp, 0.0, Vector3.FORWARD)
	out["canon"] = _paw_leg(0.07, 0.014, 0.013, colpb, 0.0)
	# les moustaches : de fins traits blancs (des triangles très minces, deux faces)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-1.0, 1.0]:
		for k in range(3):
			var a := Vector3(sx * 0.016, -0.008 + k * 0.003, 0.058)
			var b := Vector3(sx * 0.085, -0.012 + k * 0.012, 0.045 - k * 0.006)
			var w := Vector3(0, 0.0012, 0)
			for p in [a - w, b, a + w]:
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
	out["moustaches"] = st.commit()
	return out


# =================================================================== le rat (apprivoisé)

## Variante du rat : base, tache (capuchon), taches, ventre, capuche (bool : tête et épaules
## de couleur « tache »), seed. Taille 1 = un rat adulte (24 cm sans la queue).
static func build_rat(v: Dictionary) -> Node3D:
	var s: float = float(v.get("taille", 1.0))
	var root := Node3D.new()
	root.name = "Rat"
	var key: String = "rat_" + _vkey(v)
	var parts: Dictionary
	if _mesh.has(key):
		parts = _mesh[key]
	else:
		parts = _rat_meshes(v)
		_mesh[key] = parts
	var fur: Material = fur_mat()
	var skin: Material = plain_mat("peau_rat", Color(0.93, 0.68, 0.66), 0.55)
	var rig := {"espece": "rat", "taille": s, "legs": [], "tail": null, "head": null, "ears": []}
	var scl := Node3D.new()
	scl.name = "Echelle"
	scl.scale = Vector3.ONE * s
	root.add_child(scl)
	var pivot := _node(scl, "Pivot", Vector3(0, 0.04, -0.06))
	var body := _node(pivot, "Corps", Vector3(0, -0.04, 0.06))
	rig["pivot"] = pivot
	rig["pivot_y"] = 0.04
	rig["body"] = body
	_mi(body, parts["corps"], fur)
	var head := _node(body, "Tete", Vector3(0, 0.055, 0.075))
	rig["head"] = head
	rig["head_rest"] = head.position
	_mi(head, parts["tete"], fur)
	var eye_m: Material = plain_mat("oeil_rat", Color(0.05, 0.02, 0.02), 0.04, 1.0) if not bool(v.get("albinos", false)) else plain_mat("oeil_rat_rouge", Color(0.6, 0.05, 0.08), 0.04, 1.0)
	for sx in [-1.0, 1.0]:
		_mi(head, _sph(0.0055, 8), eye_m, Vector3(sx * 0.014, 0.012, 0.018), Vector3.ZERO, Vector3.ONE, false)
		var ear := _node(head, "Oreille", Vector3(sx * 0.016, 0.02, 0.0))
		_mi(ear, _sph(0.011, 10), skin, Vector3.ZERO, Vector3(0.3, sx * 0.6, 0), Vector3(1.0, 1.0, 0.25), false)
		rig["ears"].append([ear, sx, false])
	_mi(head, _sph(0.004, 8), skin, Vector3(0, 0.0, 0.054), Vector3.ZERO, Vector3.ONE, false)
	var tail := _node(body, "Queue", Vector3(0, 0.035, -0.07))
	_mi(tail, parts["queue"], skin)
	rig["tail"] = tail
	for fr in [true, false]:
		for sx2 in [-1.0, 1.0]:
			var hip := _node(body, "Patte", Vector3(sx2 * 0.022, 0.025, 0.045 if fr else -0.04))
			_mi(hip, parts["patte"], skin)
			rig["legs"].append([hip, null, null, sx2, fr])
	root.set_meta("rig", rig)
	return root


static func _rat_meshes(v: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var hood: bool = bool(v.get("capuche", false))
	var colb := func(p: Vector3, _u: float, _a: float) -> Color:
		var c: Color = _coat(v, p, 0.03, "corps")
		if hood and p.z > 0.035:
			c = c.lerp(v.get("tache", Color(0.3, 0.25, 0.22)), smoothstep(0.035, 0.05, p.z))
		elif hood and p.y > 0.06 and absf(p.x) < 0.012:
			c = c.lerp(v.get("tache", Color(0.3, 0.25, 0.22)), 0.85)
		return c
	out["corps"] = loft([Vector3(0, 0.04, -0.085), Vector3(0, 0.042, -0.078), Vector3(0, 0.046, -0.055), Vector3(0, 0.046, -0.015), Vector3(0, 0.045, 0.025), Vector3(0, 0.048, 0.055), Vector3(0, 0.052, 0.075), Vector3(0, 0.054, 0.082)],
		[0.0, 0.022, 0.038, 0.042, 0.036, 0.026, 0.018, 0.0], [0.0, 0.022, 0.036, 0.04, 0.034, 0.026, 0.018, 0.0], 14, colb, 0.03, Vector3.UP, int(v.get("seed", 3)))
	var colh := func(p: Vector3, _u: float, _a: float) -> Color:
		var c2: Color = _coat(v, p + Vector3(0, 0.055, 0.075), 0.05, "tete")
		if hood:
			c2 = c2.lerp(v.get("tache", Color(0.3, 0.25, 0.22)), 0.85)
		return c2
	out["tete"] = loft([Vector3(0, 0.004, -0.012), Vector3(0, 0.006, -0.006), Vector3(0, 0.006, 0.01), Vector3(0, 0.003, 0.028), Vector3(0, 0.0, 0.042), Vector3(0, -0.001, 0.052), Vector3(0, -0.001, 0.056)],
		[0.0, 0.016, 0.022, 0.018, 0.011, 0.006, 0.0], [0.0, 0.016, 0.02, 0.016, 0.01, 0.006, 0.0], 12, colh)
	out["queue"] = tube([Vector3.ZERO, Vector3(0, -0.01, -0.06), Vector3(0.02, -0.03, -0.12), Vector3(0.05, -0.035, -0.18), Vector3(0.06, -0.035, -0.24)], 0.008, 0.0025, 14, 6)
	out["patte"] = loft([Vector3(0, 0.005, 0), Vector3(0, -0.01, 0.002), Vector3(0, -0.022, 0.006), Vector3(0, -0.025, 0.014), Vector3(0, -0.025, 0.018)],
		[0.0, 0.006, 0.005, 0.006, 0.0], [0.0, 0.006, 0.004, 0.002, 0.0], 6, Callable(), 0.0, Vector3.FORWARD)
	return out


# =================================================================== les oiseaux

## Pigeon (gull = false) ou mouette (gull = true). Variante : base, aile, cou (reflets), tete,
## seed. Les ailes : [épaule (battement, axe Z), pli (Y), maillage].
static func build_bird(v: Dictionary, gull: bool) -> Node3D:
	var s: float = float(v.get("taille", 1.0))
	var root := Node3D.new()
	root.name = "Mouette" if gull else "Pigeon"
	var key: String = ("mouette_" if gull else "pigeon_") + _vkey(v)
	var parts: Dictionary
	if _mesh.has(key):
		parts = _mesh[key]
	else:
		parts = _bird_meshes(v, gull)
		_mesh[key] = parts
	var fm: Material = feather_mat()
	var k: float = 1.75 if gull else 1.0
	var rig := {"espece": "mouette" if gull else "pigeon", "taille": s, "wings": [], "legs": [], "head": null, "tail": null}
	var scl := Node3D.new()
	scl.name = "Echelle"
	scl.scale = Vector3.ONE * s * k
	root.add_child(scl)
	var body := _node(scl, "Corps", Vector3(0, 0.0, 0))
	rig["body"] = body
	_mi(body, parts["corps"], fm)
	var head := _node(body, "Tete", Vector3(0, 0.155, 0.075))
	rig["head"] = head
	rig["head_rest"] = head.position
	_mi(head, parts["tete"], fm)
	var beak_c: Color = Color(0.95, 0.78, 0.15) if gull else Color(0.2, 0.18, 0.18)
	_mi(head, parts["bec"], plain_mat("bec_m" if gull else "bec_p", beak_c, 0.35, 0.5), Vector3(0, -0.002, 0.024), Vector3.ZERO, Vector3.ONE, false)
	if gull:
		_mi(head, _sph(0.0035, 6), plain_mat("bec_point", Color(0.85, 0.12, 0.08), 0.4), Vector3(0, -0.009, 0.05), Vector3.ZERO, Vector3.ONE, false)
	else:
		_mi(head, _sph(0.006, 8), plain_mat("cere", Color(0.92, 0.9, 0.86), 0.7), Vector3(0, 0.004, 0.027), Vector3.ZERO, Vector3(1.0, 0.7, 1.0), false)
	var eye_m: Material = plain_mat("oeil_pigeon", Color(0.95, 0.45, 0.08), 0.05, 1.0) if not gull else plain_mat("oeil_mouette", Color(0.9, 0.85, 0.5), 0.05, 1.0)
	var pup: Material = plain_mat("pupille", Color(0.02, 0.02, 0.02), 0.05, 1.0)
	for sx in [-1.0, 1.0]:
		_mi(head, _sph(0.0055, 8), eye_m, Vector3(sx * 0.0145, 0.008, 0.008), Vector3.ZERO, Vector3(0.6, 1, 1), false)
		_mi(head, _sph(0.0028, 6), pup, Vector3(sx * 0.0178, 0.008, 0.008), Vector3.ZERO, Vector3.ONE, false)
	var tail := _node(body, "Queue", Vector3(0, 0.095, -0.1))
	_mi(tail, parts["queue"], fm)
	rig["tail"] = tail
	for sx2 in [-1.0, 1.0]:
		var sh := _node(body, "Epaule", Vector3(sx2 * 0.036, 0.12, 0.04))
		var fold := _node(sh, "Pli", Vector3.ZERO)
		_mi(fold, parts["aile"], fm, Vector3.ZERO, Vector3.ZERO, Vector3(sx2, 1, 1))
		rig["wings"].append([sh, fold, sx2])
	var leg_m: Material = plain_mat("patte_oiseau", Color(0.85, 0.42, 0.45) if not gull else Color(0.9, 0.62, 0.55), 0.6)
	for sx3 in [-1.0, 1.0]:
		var lg := _node(body, "Patte", Vector3(sx3 * 0.018, 0.065, 0.01))
		_mi(lg, parts["patte"], leg_m, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
		rig["legs"].append([lg, null, null, sx3, true])
	root.set_meta("rig", rig)
	return root


static func _bird_meshes(v: Dictionary, gull: bool) -> Dictionary:
	var out: Dictionary = {}
	var base: Color = v.get("base", Color(0.92, 0.93, 0.94) if gull else Color(0.42, 0.45, 0.52))
	var wing_c: Color = v.get("aile", Color(0.6, 0.64, 0.7) if gull else Color(0.56, 0.58, 0.64))
	var neck_c: Color = v.get("cou", Color(0.32, 0.55, 0.42))
	var head_c: Color = v.get("tete", base if gull else Color(0.4, 0.43, 0.52))
	var sd: int = int(v.get("seed", 5))
	var colb := func(p: Vector3, _u: float, _a: float) -> Color:
		var c: Color = base
		if not gull:
			# le cou irisé (vert et violet) et le jabot
			var nk: float = smoothstep(0.1, 0.15, p.y) * smoothstep(0.0, 0.05, p.z)
			var irid: Color = neck_c.lerp(Color(0.5, 0.3, 0.55), clampf(0.5 + p.x * 15.0, 0.0, 1.0))
			c = c.lerp(irid, nk * 0.85)
			c = c.lerp(head_c, smoothstep(0.15, 0.17, p.y) * 0.8)
			c = c.darkened(clampf((-p.z - 0.06) * 6.0, 0.0, 0.35))
		var g: float = _n3(p * 50.0, sd) * 0.04
		return Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g, 0, 1))
	out["corps"] = loft([Vector3(0, 0.085, -0.115), Vector3(0, 0.088, -0.1), Vector3(0, 0.095, -0.06), Vector3(0, 0.1, -0.01), Vector3(0, 0.108, 0.03), Vector3(0, 0.125, 0.06), Vector3(0, 0.15, 0.075), Vector3(0, 0.168, 0.077)],
		[0.0, 0.02, 0.04, 0.05, 0.048, 0.034, 0.022, 0.0], [0.0, 0.018, 0.04, 0.052, 0.052, 0.036, 0.022, 0.0], 14, colb)
	var colh := func(p: Vector3, _u: float, _a: float) -> Color:
		var c: Color = head_c
		if gull:
			c = base.lerp(Color(0.97, 0.97, 0.97), 0.5)
		var g2: float = _n3(p * 70.0, sd + 1) * 0.03
		return Color(clampf(c.r + g2, 0, 1), clampf(c.g + g2, 0, 1), clampf(c.b + g2, 0, 1))
	out["tete"] = loft([Vector3(0, 0.0, -0.022), Vector3(0, 0.004, -0.018), Vector3(0, 0.007, -0.005), Vector3(0, 0.006, 0.01), Vector3(0, 0.002, 0.022), Vector3(0, 0.0, 0.027)],
		[0.0, 0.015, 0.02, 0.018, 0.011, 0.0], [0.0, 0.016, 0.021, 0.019, 0.012, 0.0], 12, colh)
	var bl: float = 0.034 if gull else 0.018
	out["bec"] = loft([Vector3(0, 0.0, -0.002), Vector3(0, 0.0, 0.0), Vector3(0, -0.001, bl * 0.5), Vector3(0, -0.003 if gull else -0.002, bl), Vector3(0, -0.006 if gull else -0.003, bl + 0.004)],
		[0.0, 0.0075 if gull else 0.006, 0.0055 if gull else 0.004, 0.004 if gull else 0.0018, 0.0], [0.0, 0.0085 if gull else 0.0055, 0.007 if gull else 0.0038, 0.005 if gull else 0.0015, 0.0], 8)
	# l'aile : une feuille épaisse qui part de l'épaule vers l'arrière (repliée), côté +X
	var colw := func(p: Vector3, u: float, _a: float) -> Color:
		var c3: Color = wing_c
		if gull:
			c3 = c3.lerp(Color(0.08, 0.08, 0.09), smoothstep(0.72, 0.8, u))
			if u > 0.86 and _n3(p * 120.0, sd + 4) > 0.2:
				c3 = Color(0.95, 0.95, 0.95)
		else:
			# les deux barres noires de l'aile du pigeon, et les rémiges sombres
			var bar: float = smoothstep(0.03, 0.0, absf(u - 0.4)) + smoothstep(0.03, 0.0, absf(u - 0.55))
			c3 = c3.lerp(Color(0.12, 0.12, 0.14), clampf(bar, 0.0, 1.0) * 0.9)
			c3 = c3.lerp(Color(0.25, 0.26, 0.3), smoothstep(0.75, 0.9, u))
		var g3: float = _n3(p * 80.0, sd + 2) * 0.03
		return Color(clampf(c3.r + g3, 0, 1), clampf(c3.g + g3, 0, 1), clampf(c3.b + g3, 0, 1))
	out["aile"] = loft([Vector3(0, 0.0, 0.012), Vector3(0.006, -0.002, 0.0), Vector3(0.012, -0.008, -0.04), Vector3(0.013, -0.014, -0.09), Vector3(0.01, -0.02, -0.14), Vector3(0.005, -0.026, -0.18), Vector3(0.002, -0.028, -0.2)],
		[0.0, 0.012, 0.028, 0.032, 0.026, 0.014, 0.0], [0.0, 0.007, 0.008, 0.006, 0.0045, 0.003, 0.0], 10, colw, 0.0, Vector3.RIGHT)
	var colt := func(p: Vector3, u: float, _a: float) -> Color:
		var c4: Color = wing_c.darkened(0.15) if not gull else base
		if not gull:
			c4 = c4.lerp(Color(0.1, 0.1, 0.12), smoothstep(0.75, 0.9, u))
		return c4
	out["queue"] = loft([Vector3(0, 0.0, 0.0), Vector3(0, -0.002, -0.03), Vector3(0, -0.006, -0.07), Vector3(0, -0.008, -0.085)],
		[0.012, 0.024, 0.03, 0.0], [0.006, 0.006, 0.004, 0.0], 10, colt)
	out["patte"] = loft([Vector3(0, 0.0, 0), Vector3(0, -0.03, 0.004), Vector3(0, -0.058, 0.006), Vector3(0, -0.064, 0.016), Vector3(0, -0.064, 0.026)],
		[0.0, 0.004, 0.003, 0.004, 0.0], [0.0, 0.004, 0.003, 0.002, 0.0], 6, Callable(), 0.0, Vector3.FORWARD)
	return out


# =================================================================== l'animation

## Anime un animal : clock (temps propre), speed (m/s au sol), pose ("", "assis", "couche",
## "renifle", "aboie", "remue", "vol", "plane", "picore"), wag (0..1 : la queue qui frétille).
static func animate(a: Node3D, clock: float, speed: float, pose: String = "", wag: float = 0.0, delta: float = 0.016) -> void:
	var rig: Dictionary = a.get_meta("rig", {})
	if rig.is_empty():
		return
	var esp: String = str(rig.get("espece", ""))
	if esp == "pigeon" or esp == "mouette":
		_anim_bird(rig, clock, speed, pose, delta)
	else:
		_anim_quad(rig, clock, speed, pose, wag, delta)


static func _anim_quad(rig: Dictionary, clock: float, speed: float, pose: String, wag: float, delta: float) -> void:
	var s: float = float(rig.get("taille", 1.0))
	var esp: String = str(rig.get("espece", "chien"))
	var cat: bool = esp == "chat"
	var rat: bool = esp == "rat"
	var leg_len: float = (0.45 if not cat else 0.22) * s
	if rat:
		leg_len = 0.03 * s
	# allure : longueur de foulée ~ 1,1 × hauteur de patte
	var stride: float = leg_len * (2.2 if not rat else 5.0)
	var freq: float = speed / maxf(stride, 0.01)
	var ph: float = clock * TAU * freq if speed > 0.05 else 0.0
	var run: bool = speed > 2.6 * s and not rat
	var amp: float = clampf(speed / (1.4 * s if not rat else 0.3), 0.0, 1.0) * (0.55 if not run else 0.75)
	var k: float = clampf(delta * 8.0, 0.0, 1.0)
	var pivot: Node3D = rig.get("pivot")
	var body: Node3D = rig.get("body")
	var py: float = float(rig.get("pivot_y", 0.4))
	var sit: bool = pose == "assis"
	var lie: bool = pose == "couche"
	var piv_rot: float = 0.0
	var piv_drop: float = 0.0
	if sit:
		piv_rot = -0.7 if not cat else -0.62
		piv_drop = py * (0.65 if not cat else 0.75)
	elif lie:
		piv_rot = 0.04
		piv_drop = py * 0.62
	if pivot != null:
		pivot.rotation.x = lerpf(pivot.rotation.x, piv_rot, k)
		var bob: float = absf(sin(ph * (2.0 if not run else 1.0))) * 0.02 * amp
		pivot.position.y = lerpf(pivot.position.y, py - piv_drop + bob, k)
		if run:
			pivot.rotation.x += sin(ph) * 0.06
	# les pattes
	for l in rig.get("legs", []):
		var hip: Node3D = l[0]
		var knee: Node3D = l[1]
		var hock: Node3D = l[2]
		var side: float = float(l[3])
		var front: bool = bool(l[4])
		var lp: float = ph
		if run:
			# galop : les deux avant ensemble (un peu décalés), puis les deux arrière
			lp += (0.0 if front else PI) + (0.0 if side > 0.0 else 0.35)
		else:
			# trot / pas : en diagonale
			lp += (0.0 if (front == (side > 0.0)) else PI)
		var swing: float = -sin(lp) * amp
		var lift: float = maxf(0.0, cos(lp)) * amp
		var h_goal: float = swing
		var k_goal: float = 0.0
		var j_goal: float = 0.0
		if front:
			k_goal = lift * 1.3
		else:
			k_goal = -lift * 0.9
			j_goal = lift * 1.1
		if sit:
			if front:
				h_goal = -piv_rot
				k_goal = 0.0
			else:
				h_goal = -0.55 if not cat else -0.68
				k_goal = 1.42 if not cat else 1.49
				j_goal = -1.62 if not cat else -1.69
		elif lie:
			if front:
				h_goal = -1.35
				k_goal = 0.0
			else:
				h_goal = -1.3
				k_goal = 0.75
				j_goal = -0.95
		elif pose == "aboie" and front:
			h_goal = -0.15
		if rat:
			hip.rotation.x = lerpf(hip.rotation.x, swing * 1.4, clampf(delta * 14.0, 0.0, 1.0))
			continue
		hip.rotation.x = lerpf(hip.rotation.x, h_goal, k if (sit or lie) else 1.0)
		if knee != null:
			knee.rotation.x = lerpf(knee.rotation.x, k_goal, k if (sit or lie) else 1.0)
		if hock != null:
			hock.rotation.x = lerpf(hock.rotation.x, j_goal, k if (sit or lie) else 1.0)
	# la tête
	var head: Node3D = rig.get("head")
	if head != null:
		var hr: Vector3 = rig.get("head_rest", head.position)
		var look_x: float = 0.0
		var look_y: float = sin(clock * 0.37) * 0.25 + sin(clock * 0.91) * 0.12
		var hpos: Vector3 = hr
		match pose:
			"renifle":
				look_x = 0.75
				hpos = hr + Vector3(0, -0.12, 0.04) * (1.0 if not cat else 0.5)
				look_y = sin(clock * 3.1) * 0.35
			"aboie":
				look_x = -0.25 + sin(clock * 9.0) * 0.08
				look_y = 0.0
			"assis":
				look_x = 0.35 if not cat else 0.6
			"couche":
				look_x = 0.4
				hpos = hr + Vector3(0, -0.06, 0.0)
		if speed > 0.2:
			look_y *= 0.3
			look_x = 0.1 + sin(ph * 2.0) * 0.05
		if rat:
			look_x = 0.2 + sin(clock * 11.0) * 0.06
		head.rotation.x = lerpf(head.rotation.x, look_x, k)
		head.rotation.y = lerpf(head.rotation.y, look_y, k)
		head.position = head.position.lerp(hpos, k)
	# la mâchoire : aboie, halète
	var jaw: Node3D = rig.get("jaw")
	var tongue: Node3D = rig.get("tongue")
	var pant: bool = (speed > 1.5 or wag > 0.6) and not cat
	if jaw != null:
		var open: float = 0.0
		if pose == "aboie":
			open = maxf(0.0, sin(clock * 18.0)) * 0.45
		elif pant:
			open = 0.22 + sin(clock * 14.0) * 0.05
		jaw.rotation.x = lerpf(jaw.rotation.x, open, clampf(delta * 18.0, 0.0, 1.0))
	if tongue != null:
		tongue.visible = pant and pose != "aboie"
	# la queue
	var tail: Node3D = rig.get("tail")
	if tail != null:
		var wf: float = 11.0 + wag * 6.0
		var wa: float = 0.15 + wag * 0.55
		if cat:
			wf = 1.6
			wa = 0.25
		if rat:
			wf = 2.0
			wa = 0.3
		tail.rotation.y = sin(clock * wf) * wa
		var up: float = 0.0
		if not cat and not rat:
			up = -0.25 * wag + (0.3 if sit else 0.0)
		tail.rotation.x = lerpf(tail.rotation.x, up, k)
	# les oreilles : petits frémissements
	for e in rig.get("ears", []):
		var ear: Node3D = e[0]
		var side2: float = float(e[1])
		var floppy: bool = bool(e[2])
		var tw: float = maxf(0.0, sin(clock * 0.7 + side2 * 2.0) - 0.92) * 6.0
		if floppy:
			ear.rotation.x = sin(ph * 2.0) * 0.25 * amp + tw * 0.2
		else:
			ear.rotation.z = -side2 * tw * 0.3


static func _anim_bird(rig: Dictionary, clock: float, speed: float, pose: String, delta: float) -> void:
	var body: Node3D = rig.get("body")
	var head: Node3D = rig.get("head")
	var hr: Vector3 = rig.get("head_rest", Vector3.ZERO)
	var gull: bool = str(rig.get("espece", "")) == "mouette"
	var k: float = clampf(delta * 10.0, 0.0, 1.0)
	var flying: bool = pose == "vol" or pose == "plane"
	for w in rig.get("wings", []):
		var sh: Node3D = w[0]
		var fold: Node3D = w[1]
		var sx: float = float(w[2])
		if flying:
			# aile déployée (pointée sur le côté), battements
			fold.rotation.y = lerpf(fold.rotation.y, sx * 1.45, clampf(delta * 12.0, 0.0, 1.0))
			var beat: float = 0.0
			if pose == "vol":
				beat = sin(clock * (11.0 if not gull else 6.5)) * (0.75 if not gull else 0.6)
			else:
				beat = sin(clock * 1.3) * 0.05 + 0.08
			sh.rotation.z = -sx * beat
		else:
			fold.rotation.y = lerpf(fold.rotation.y, sx * 0.04, clampf(delta * 12.0, 0.0, 1.0))
			sh.rotation.z = lerpf(sh.rotation.z, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	if body != null:
		if flying:
			body.rotation.x = lerpf(body.rotation.x, 0.45, k)
			body.position.y = lerpf(body.position.y, -0.07, k)
		else:
			body.rotation.x = lerpf(body.rotation.x, 0.0 if pose != "picore" else 0.25, k)
			body.position.y = lerpf(body.position.y, 0.0, k)
			body.rotation.z = sin(clock * 9.0) * 0.06 * clampf(speed / 0.5, 0.0, 1.0)
	if head != null:
		var hp: Vector3 = hr
		var hx: float = 0.0
		if pose == "picore":
			var pk: float = maxf(0.0, sin(clock * 6.0))
			hp = hr + Vector3(0, -0.07, 0.03) * pk
			hx = 1.1 * pk
		elif not flying and speed > 0.05:
			# le hochement du pigeon qui marche (la tête avance et recule)
			hp = hr + Vector3(0, 0, 0.02 * sin(clock * TAU * speed * 6.0))
		elif flying:
			hx = -0.4
		head.position = head.position.lerp(hp, clampf(delta * 16.0, 0.0, 1.0))
		head.rotation.x = lerpf(head.rotation.x, hx, clampf(delta * 16.0, 0.0, 1.0))
		head.rotation.y = sin(clock * 1.7) * 0.4 if not flying else 0.0
	for l in rig.get("legs", []):
		var lg: Node3D = l[0]
		var sx2: float = float(l[3])
		if flying:
			lg.rotation.x = lerpf(lg.rotation.x, 1.2, k)
		else:
			lg.rotation.x = sin(clock * TAU * speed * 6.0 + (0.0 if sx2 > 0 else PI)) * 0.45 * clampf(speed / 0.3, 0.0, 1.0)
	var tail: Node3D = rig.get("tail")
	if tail != null:
		tail.rotation.x = lerpf(tail.rotation.x, -0.2 if flying else 0.0, k)

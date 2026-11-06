extends "res://scripts/nuees_kit_v113.gd"
## V115 : la boîte à outils du Dôme d'Azur (futuriste, au fond de la mer). Tout ce que savent faire
## les kits d'avant (les immeubles de verre et de béton blanc de la Cité des Nuées, ses garde-corps de
## verre, ses lampadaires, ses bancs…), et ce qui fait le Dôme :
##  - geodome() : une coupole géodésique (un icosaèdre découpé, sa moitié haute, aplatie) : les vitres
##    (le verre de la mer profonde, verre_abysse_v115 : un maillage à part, pour que les verres se trient
##    bien), la résille de titane blanc, ses nœuds ; et sa collision ;
##  - drum115() : le tambour vitré qui la porte (piliers de titane, grandes vitres, un socle et une
##    ceinture de nacre), ouvert là où passent les galeries et le tube ;
##  - glass_tube() : un tube de verre (une galerie, le tube du Funiculaire) : ses anneaux de titane, sa
##    quille, son plancher ;
##  - floor_disc() : le sol rond d'un dôme (terrazzo), percé au besoin (le puits des bathyscaphes) ;
##  - bubble_house() : une maison-bulle (une sphère de nacre posée au sol, ses hublots, son vestibule) ;
##  - shell_tower() : une tour-coquillage (torsadée, des balcons en spirale, une couronne en conque) ;
##  - lamp115(), bench115(), sign115(), totem115(), porthole115() ; coral115() (un corail qui luit),
##    hydro_tower115() (une tour de culture), algae_tube115() (un tube d'algues), tank115() (une cuve
##    d'aquarium).
## Repères : une façade « xf » regarde +Z local (comme les autres kits).

const Mats115 = preload("res://scripts/dome_mats_v115.gd")

var glass_nodes: Array = []              # MeshInstance3D : les verres de la mer (un par dôme, par tube)
var glows115: Array = []                 # [Vector3, Color, énergie, portée] : des lampes qui méritent une vraie lumière


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	# la façade des tours (le mur-rideau des Nuées) : une copie à nous, plus douce le soir (sous la
	# coupole, on la voit de près) ; dome_mats_v115.night() la règle
	if key == "facade113":
		var base: Material = super.mat(key)
		if base is StandardMaterial3D:
			var cp: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
			Mats115.facade = cp
			mats[key] = cp
			return cp
		return base
	var m: Material = Mats115.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


## Un maillage à part (un seul matériau) : tris = [[a, b, c, normale], …] (repère monde).
func own_mesh(name: String, key: String, tris: Array, shadow: bool = false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		_tri(st, t[0], t[1], t[2], t[3])
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = st.commit()
	mi.material_override = mat(key)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi


## Une tige (un cylindre ou un cône) de a à b.
func rod(a: Vector3, b: Vector3, r0: float, r1: float, key: String, seg: int = 6) -> void:
	if a.distance_to(b) < 0.01:
		return
	cyl(axis_xf(a, b), r0, r1, a.distance_to(b), key, seg, false, 1.0)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) < 0.0:
		var t: Vector3 = b
		b = c
		c = t
	for p in [a, b, c]:
		st.set_normal(n)
		st.set_uv(Vector2(p.x, p.z) * 0.05)
		st.add_vertex(p)


func _trimesh(faces: Array) -> void:
	var pf := PackedVector3Array()
	for p in faces:
		pf.append(p)
	var cs := CollisionShape3D.new()
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(pf)
	sh.backface_collision = true
	cs.shape = sh
	body.add_child(cs)


# =================================================================== la coupole géodésique

## Les triangles d'une demi-sphère géodésique (rayon 1, pôle en haut), fréquence freq (paire) :
## [sommets (Array de Vector3), triangles (Array de [i, j, k])].
static func geo_hemisphere(freq: int) -> Array:
	var t: float = (1.0 + sqrt(5.0)) / 2.0
	var v0: Array = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
		Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var f0: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	# le sommet 5 en haut (le pôle) : alors les milieux de la ceinture sont pile sur l'équateur
	var up: Vector3 = (v0[5] as Vector3).normalized()
	var axis: Vector3 = up.cross(Vector3.UP).normalized()
	var rot := Basis(axis, up.angle_to(Vector3.UP))
	var ico: Array = []
	for p in v0:
		ico.append((rot * (p as Vector3)).normalized())
	var verts: Array = []
	var index: Dictionary = {}
	var tris: Array = []
	var key := func(p: Vector3) -> Vector3i:
		return Vector3i(roundi(p.x * 20000.0), roundi(p.y * 20000.0), roundi(p.z * 20000.0))
	var idx := func(p: Vector3) -> int:
		var kk: Vector3i = key.call(p)
		if index.has(kk):
			return index[kk]
		index[kk] = verts.size()
		verts.append(p)
		return verts.size() - 1
	for f in f0:
		var a: Vector3 = ico[f[0]]
		var b: Vector3 = ico[f[1]]
		var c: Vector3 = ico[f[2]]
		var grid: Dictionary = {}
		for i in range(freq + 1):
			for j in range(freq + 1 - i):
				var k: int = freq - i - j
				var p: Vector3 = (a * float(i) + b * float(j) + c * float(k)) / float(freq)
				p = p.normalized()
				if absf(p.y) < 0.00005:
					p.y = 0.0
				grid[Vector2i(i, j)] = p
		for i in range(freq):
			for j in range(freq - i):
				var tri_a: Array = [grid[Vector2i(i, j)], grid[Vector2i(i + 1, j)], grid[Vector2i(i, j + 1)]]
				var all_up: bool = (tri_a[0] as Vector3).y >= -0.0001 and (tri_a[1] as Vector3).y >= -0.0001 and (tri_a[2] as Vector3).y >= -0.0001
				if all_up:
					tris.append([idx.call(tri_a[0]), idx.call(tri_a[1]), idx.call(tri_a[2])])
				if i + j + 1 < freq:
					var tri_b: Array = [grid[Vector2i(i + 1, j)], grid[Vector2i(i + 1, j + 1)], grid[Vector2i(i, j + 1)]]
					if (tri_b[0] as Vector3).y >= -0.0001 and (tri_b[1] as Vector3).y >= -0.0001 and (tri_b[2] as Vector3).y >= -0.0001:
						tris.append([idx.call(tri_b[0]), idx.call(tri_b[1]), idx.call(tri_b[2])])
	return [verts, tris]


## Une coupole géodésique : son pied (le haut du tambour) en c, rayon r, hauteur h. Les vitres (un
## maillage à part, le verre de la mer), la résille de titane, les nœuds ; la collision.
func geodome(c: Vector3, r: float, h: float, freq: int, name: String, collide: bool = true) -> MeshInstance3D:
	var g: Array = geo_hemisphere(freq)
	var vs: Array = g[0]
	var tris: Array = g[1]
	var pts: Array = []
	for p in vs:
		pts.append(c + Vector3((p as Vector3).x * r, (p as Vector3).y * h, (p as Vector3).z * r))
	var nrm := func(p: Vector3) -> Vector3:
		var q: Vector3 = p - c
		return Vector3(q.x / (r * r), q.y / (h * h), q.z / (r * r)).normalized()
	var faces: Array = []
	var gt: Array = []
	for t in tris:
		var a: Vector3 = pts[t[0]]
		var b: Vector3 = pts[t[1]]
		var cc: Vector3 = pts[t[2]]
		var n: Vector3 = (b - a).cross(cc - a).normalized()
		if n.dot(nrm.call((a + b + cc) / 3.0)) < 0.0:
			n = -n
		gt.append([a, b, cc, n])
		faces.append(a)
		faces.append(b)
		faces.append(cc)
	var mi: MeshInstance3D = own_mesh(name, "verre115", gt)
	glass_nodes.append(mi)
	# la résille : une barre par arête, un nœud par sommet (un peu en dedans du verre)
	var edges: Dictionary = {}
	for t2 in tris:
		for e in [[t2[0], t2[1]], [t2[1], t2[2]], [t2[2], t2[0]]]:
			var i0: int = mini(int(e[0]), int(e[1]))
			var i1: int = maxi(int(e[0]), int(e[1]))
			edges[Vector2i(i0, i1)] = true
	var key_s: String = "titane115_clair"
	for e2 in edges:
		var pa: Vector3 = pts[(e2 as Vector2i).x]
		var pb: Vector3 = pts[(e2 as Vector2i).y]
		var mid: Vector3 = (pa + pb) * 0.5
		var n2: Vector3 = nrm.call(mid)
		var z: Vector3 = (pb - pa).normalized()
		var y: Vector3 = (n2 - z * n2.dot(z)).normalized()
		var x: Vector3 = y.cross(z).normalized()
		box(Transform3D(Basis(x, y, z), mid - n2 * 0.2), Vector3(0.22, 0.34, pa.distance_to(pb) + 0.06), key_s, 1.0, 1 | 2 | 4 | 8)
	for p2 in pts:
		var n3: Vector3 = nrm.call(p2)
		var b3: Basis = _basis_up(n3)
		cyl(Transform3D(b3, p2 - n3 * 0.42), 0.26, 0.26, 0.3, key_s, 6, true, 1.0)
	if collide:
		_trimesh(faces)
	return mi


static func _basis_up(n: Vector3) -> Basis:
	var y: Vector3 = n.normalized()
	var x: Vector3 = Vector3.FORWARD.cross(y)
	if x.length() < 0.01:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


# =================================================================== le tambour

## Le tambour vitré d'un dôme (drum115) : centre c (au sol), rayon r, hauteur h. gaps : [[angle en degrés, demi-
## largeur en m], …] (les ouvertures des galeries et du tube). Les vitres vont dans un maillage à part.
func drum115(c: Vector3, r: float, h: float, gaps: Array, name: String) -> void:
	var n: int = maxi(int(round(TAU * r / 4.2)), 12)
	var sill: float = 0.7
	var beam: float = 0.55
	var in_gap := func(a_deg: float, extra: float) -> bool:
		for gp in gaps:
			var da: float = absf(wrapf(a_deg - float(gp[0]), -180.0, 180.0))
			if deg_to_rad(da) * r < float(gp[1]) + extra:
				return true
		return false
	var panes: Array = []
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = TAU * (k + 1) / n
		var am: float = (a0 + a1) * 0.5
		var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * r
		var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * r
		var out := Vector3(cos(am), 0, sin(am))
		var gap: bool = in_gap.call(rad_to_deg(am), 0.0)
		# la ceinture du haut (au-dessus des ouvertures aussi)
		quad4("nacre115", p0 + Vector3.UP * (h - beam), p1 + Vector3.UP * (h - beam), p1 + Vector3.UP * h, p0 + Vector3.UP * h, -out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		quad4("nacre115", p0 + Vector3.UP * (h - beam) + out * 0.5, p1 + Vector3.UP * (h - beam) + out * 0.5, p1 + Vector3.UP * h + out * 0.5, p0 + Vector3.UP * h + out * 0.5, out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		quad4("nacre115", p0 + Vector3.UP * (h - beam), p1 + Vector3.UP * (h - beam), p1 + Vector3.UP * (h - beam) + out * 0.5, p0 + Vector3.UP * (h - beam) + out * 0.5, Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2))
		if gap:
			continue
		# le socle, la vitre, le pilier
		quad4("nacre115_gris", p0, p1, p1 + Vector3.UP * sill, p0 + Vector3.UP * sill, -out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		quad4("nacre115_gris", p0 + Vector3.UP * sill, p1 + Vector3.UP * sill, p1 + Vector3.UP * sill + out * 0.5, p0 + Vector3.UP * sill + out * 0.5, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2))
		quad4("nacre115_gris", p0 + out * 0.5, p1 + out * 0.5, p1 + Vector3.UP * sill + out * 0.5, p0 + Vector3.UP * sill + out * 0.5, out, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		panes.append([p0 + out * 0.25 + Vector3.UP * sill, p1 + out * 0.25 + Vector3.UP * sill, out])
		var bs := Basis.looking_at(-out, Vector3.UP)
		box(Transform3D(bs, p0 + out * 0.25 + Vector3.UP * (h * 0.5)), Vector3(0.3, h, 0.5), "titane115_clair", 1.0)
		col_box(Transform3D(Basis.looking_at(p1 - p0, Vector3.UP), (p0 + p1) * 0.5 + out * 0.25 + Vector3.UP * (h * 0.5)), Vector3(0.45, h, p0.distance_to(p1) + 0.1))
		# un projecteur vers le dehors, de temps en temps (il éclaire le fond, à travers le verre)
		if k % 6 == 0:
			box(Transform3D(bs, p0 + out * 0.6 + Vector3.UP * (h - beam - 0.3)), Vector3(0.4, 0.25, 0.3), "titane115_sombre", 1.0)
			box(Transform3D(bs, p0 + out * 0.76 + Vector3.UP * (h - beam - 0.3)), Vector3(0.3, 0.16, 0.02), "led115_blanc", 1.0)
	var hh: float = h - beam - sill
	var gt: Array = []
	for pn in panes:
		var a: Vector3 = pn[0]
		var b: Vector3 = pn[1]
		var o: Vector3 = pn[2]
		gt.append([a, b, b + Vector3.UP * hh, o])
		gt.append([a, b + Vector3.UP * hh, a + Vector3.UP * hh, o])
	var mi: MeshInstance3D = own_mesh(name, "verre115", gt)
	glass_nodes.append(mi)


# =================================================================== les tubes

## Un tube de verre de a à b (les axes ; rayon r). deck : la hauteur du plancher sous l'axe (le
## plancher et la quille en dessous) ; deck < 0 : un tube tout de verre (le Funiculaire : une fine
## quille de titane en bas, le rail en haut). rib : l'écart des anneaux de titane. Les vitres dans un
## maillage à part ; la collision (le plancher, les parois).
func glass_tube(a: Vector3, b: Vector3, r: float, deck: float, rib: float, name: String, walk_key: String = "terrazzo115") -> void:
	var ax: Vector3 = (b - a).normalized()
	var len: float = a.distance_to(b)
	var side: Vector3 = ax.cross(Vector3.UP).normalized()
	var upv: Vector3 = side.cross(ax).normalized()
	var seg: int = 28
	var full: bool = deck < 0.0
	# l'angle (autour de l'axe) où le cercle coupe le plancher
	var cut: float = PI if full else acos(clampf(-deck / r, -1.0, 1.0))
	var faces: Array = []
	var gt: Array = []
	for i in range(seg):
		var t0: float = -cut + (2.0 * cut) * float(i) / seg
		var t1: float = -cut + (2.0 * cut) * float(i + 1) / seg
		var d0: Vector3 = upv * cos(t0) + side * sin(t0)
		var d1: Vector3 = upv * cos(t1) + side * sin(t1)
		var q0: Vector3 = a + d0 * r
		var q1: Vector3 = a + d1 * r
		var q2: Vector3 = b + d1 * r
		var q3: Vector3 = b + d0 * r
		var nm: Vector3 = (d0 + d1).normalized()
		gt.append([q0, q1, q2, nm])
		gt.append([q0, q2, q3, nm])
		for p in [q0, q1, q2, q0, q2, q3]:
			faces.append(p)
	var mi: MeshInstance3D = own_mesh(name, "verre115", gt)
	glass_nodes.append(mi)
	_trimesh(faces)
	if full:
		# la quille (une poutre de titane sous le tube) et le rail (en haut, dedans)
		var kb := Basis(-side, upv, ax).orthonormalized()
		box(Transform3D(kb, (a + b) * 0.5 - upv * (r + 0.12)), Vector3(0.7, 0.3, len), "titane115_sombre", 2.0)
		box(Transform3D(kb, (a + b) * 0.5 + upv * (r - 0.45)), Vector3(0.36, 0.42, len), "titane115", 2.0)
	else:
		# la quille (sous le plancher) : une coque de titane sombre
		var ks: int = 10
		for i2 in range(ks):
			var u0: float = cut + (TAU - 2.0 * cut) * float(i2) / ks
			var u1: float = cut + (TAU - 2.0 * cut) * float(i2 + 1) / ks
			var e0: Vector3 = upv * cos(u0) + side * sin(u0)
			var e1: Vector3 = upv * cos(u1) + side * sin(u1)
			quad4("titane115_sombre", a + e0 * r, a + e1 * r, b + e1 * r, b + e0 * r, (e0 + e1).normalized(), Vector2(0, 0), Vector2(1, 0), Vector2(1, len / 4.0), Vector2(0, len / 4.0))
		# le plancher (une passerelle de terrazzo, des diodes au ras du sol)
		var w: float = 2.0 * r * sin(cut)
		var bs := Basis(-side, Vector3.UP, ax).orthonormalized()
		var mid: Vector3 = (a + b) * 0.5 - upv * deck
		box(Transform3D(bs, mid + Vector3.DOWN * 0.1), Vector3(w, 0.2, len), walk_key, 2.0, 4 | 1 | 2)
		col_box(Transform3D(bs, mid + Vector3.DOWN * 0.15), Vector3(w, 0.3, len))
		for s2 in [-1.0, 1.0]:
			box(Transform3D(bs, mid + side * s2 * (w * 0.5 - 0.15) + Vector3.UP * 0.04), Vector3(0.06, 0.04, len), "led115_cyan", 1.0, 4)
	# les anneaux de titane
	var nr: int = maxi(int(len / rib), 1)
	for k in range(nr + 1):
		var p2: Vector3 = a.lerp(b, float(k) / nr)
		var rb := Basis(side, ax, upv).orthonormalized()
		ring(Transform3D(rb, p2 - ax * 0.15), r - 0.05, r + 0.18, 0.3, "titane115_clair", 32)


# =================================================================== le sol d'un dôme

## Un disque de sol (terrazzo) au centre c, rayon r, en anneaux et secteurs ; holes : [[Vector3, rayon]]
## (des trous ronds : le puits). La collision suit le maillage.
func floor_disc(c: Vector3, r: float, holes: Array, key: String = "terrazzo115") -> void:
	var rings_n: int = maxi(int(r / 3.0), 4)
	var faces: Array = []
	for i in range(rings_n):
		var r0: float = r * float(i) / rings_n
		var r1: float = r * float(i + 1) / rings_n
		var seg: int = maxi(int(TAU * r1 / 3.0), 8)
		for j in range(seg):
			var a0: float = TAU * j / seg
			var a1: float = TAU * (j + 1) / seg
			var am: float = (a0 + a1) * 0.5
			var rm: float = (r0 + r1) * 0.5
			var cm: Vector3 = c + Vector3(cos(am), 0, sin(am)) * rm
			var skip: bool = false
			for hl in holes:
				if Vector2(cm.x - (hl[0] as Vector3).x, cm.z - (hl[0] as Vector3).z).length() < float(hl[1]) + 0.9:
					skip = true
			if skip:
				continue
			var p0: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * r0
			var p1: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * r0
			var p2: Vector3 = c + Vector3(cos(a1), 0, sin(a1)) * r1
			var p3: Vector3 = c + Vector3(cos(a0), 0, sin(a0)) * r1
			tri(key, p0, p2, p1, Vector3.UP, Vector2(p0.x, p0.z) / 4.0, Vector2(p2.x, p2.z) / 4.0, Vector2(p1.x, p1.z) / 4.0)
			tri(key, p0, p3, p2, Vector3.UP, Vector2(p0.x, p0.z) / 4.0, Vector2(p3.x, p3.z) / 4.0, Vector2(p2.x, p2.z) / 4.0)
			for p in [p0, p2, p1, p0, p3, p2]:
				faces.append(p)
	_trimesh(faces)


# =================================================================== les maisons

## Une maison-bulle : une sphère de nacre (rayon r) posée au sol en pos, sa porte vers face (un petit
## vestibule), ses hublots (une ou deux rangées), un liseré de diodes. Renvoie la porte (dehors).
func bubble_house(pos: Vector3, r: float, face: Vector3, tint: String = "", floors: int = 1) -> Vector3:
	var f := Vector3(face.x, 0, face.z).normalized()
	var cy: float = r * 0.82
	var c: Vector3 = pos + Vector3.UP * cy
	var key: String = "nacre115" if tint == "" else "nacre115_" + tint
	ball(Transform3D(Basis(), c), r, key, 20, 12)
	# le socle (un anneau de titane), le liseré de diodes à mi-hauteur
	ring(Transform3D(Basis(), pos), r * 0.55, r * 0.62, 0.3, "titane115_sombre", 24)
	ring(Transform3D(Basis(), c + Vector3.DOWN * 0.05), r + 0.01, r + 0.06, 0.08, "led115_cyan", 32)
	# les hublots
	var rows_y: Array = [0.15] if floors < 2 else [-0.15, 0.42]
	var yaw0: float = atan2(f.z, f.x)
	for ry in rows_y:
		var n_h: int = 5 if floors < 2 else 6
		for k in range(n_h):
			var a: float = yaw0 + TAU * (k + 0.5) / n_h
			var el: float = float(ry)
			var dirn := Vector3(cos(a) * cos(el), sin(el), sin(a) * cos(el))
			porthole115(Transform3D(_basis_up(dirn), c + dirn * (r - 0.05)), 0.55 if floors < 2 else 0.5)
	# le vestibule (la porte), vers face
	var bs := Basis.looking_at(-f, Vector3.UP)
	var vx: Transform3D = Transform3D(bs, pos + f * (r * 0.92))
	box(vx * T(0, 1.35, 0), Vector3(2.2, 2.7, 1.6), key, 1.5, 63 - 8)
	box(vx * T(0, 2.75, 0.1), Vector3(2.5, 0.16, 1.9), "titane115_clair", 1.0)
	box(vx * T(0, 1.15, 0.81), Vector3(1.2, 2.25, 0.04), "hublot115", 1.0)
	box(vx * T(0, 2.4, 0.82), Vector3(1.0, 0.06, 0.04), "led115_ambre", 1.0)
	col_box(vx * T(0, 1.35, -0.2), Vector3(2.2, 2.7, 1.2))
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = r
	cs.shape = sh
	cs.position = c
	body.add_child(cs)
	return pos + f * (r * 0.92 + 1.6)


## Un hublot : un anneau de titane et son verre (xf : son centre, son axe +Y vers le dehors).
func porthole115(xf: Transform3D, r: float, key: String = "hublot115") -> void:
	ring(xf * T(0, -0.05, 0), r - 0.1, r + 0.06, 0.12, "titane115_clair", 16)
	cyl(xf * T(0, -0.02, 0), r - 0.08, r - 0.08, 0.05, key, 16, true, 1.0)


## Une tour-coquillage : une tour ronde torsadée (le mur-rideau des Nuées), une couronne en conque de
## nacre, des balcons en spirale. Renvoie la porte.
func shell_tower(c: Vector3, r: float, floors: int, twist: float, door_dir: Vector3) -> Vector3:
	round113(c, r, floors, 4.5, twist)
	var top: float = 4.5 + floors * FH
	# la couronne : une conque de nacre (des anneaux qui se resserrent en spirale)
	var n: int = 7
	for k in range(n):
		var t: float = float(k) / n
		var rr: float = lerpf(r + 0.4, 0.5, t)
		var a: float = t * TAU * 1.2
		var off := Vector3(cos(a), 0, sin(a)) * (r * 0.18 * (1.0 - t))
		cyl(Transform3D(Basis(Vector3.UP, a), c + off + Vector3.UP * (top + 0.3 + t * 5.0)), rr, lerpf(r + 0.4, 0.5, t + 1.0 / n), 5.0 / n + 0.05, "nacre115", 24, k == n - 1, 2.0)
	ring(Transform3D(Basis(), c + Vector3.UP * (top + 0.3)), r + 0.3, r + 0.5, 0.12, "led115_cyan", 32)
	var f := Vector3(door_dir.x, 0, door_dir.z).normalized()
	var bs := Basis.looking_at(-f, Vector3.UP)
	box(Transform3D(bs, c + f * (r - 0.6) + Vector3.UP * 2.9), Vector3(3.4, 0.2, 2.2), "titane115_clair", 1.0)
	return c + f * (r + 0.6)


# =================================================================== les petits objets

## Un lampadaire : un mât de titane blanc courbé, une goutte de lumière (aigue-marine ou ambre).
func lamp115(pos: Vector3, yaw: float = 0.0, h: float = 4.8, color: String = "cyan", real_light: bool = false) -> void:
	var b := Basis(Vector3.UP, yaw)
	cyl(Transform3D(Basis(), pos), 0.16, 0.1, 0.4, "titane115", 8, true)
	cyl(Transform3D(Basis(), pos), 0.08, 0.06, h, "titane115_clair", 8, false)
	var tip: Vector3 = pos + Vector3.UP * h
	var head: Vector3 = tip + b * Vector3(0, 0.1, 0.7)
	beam(tip, head + Vector3.UP * 0.25, 0.06, "titane115_clair")
	ball(Transform3D(Basis(), head), 0.26, "led115_" + color, 10, 6)
	ring(Transform3D(Basis(), head + Vector3.UP * 0.18), 0.12, 0.3, 0.06, "titane115_clair", 12)
	col_cyl(pos, 0.12, h)
	if real_light:
		glows115.append([head + Vector3.DOWN * 0.3, Mats115.LED.get(color, Color(1, 1, 1)), 1.6, 14.0])


## Un banc : une coque de nacre posée sur un pied de titane, un coussin.
func bench115(xf: Transform3D, w: float = 2.4, cushion: String = "") -> void:
	box(xf * T(0, 0.2, 0), Vector3(w * 0.7, 0.4, 0.3), "titane115_sombre", 1.0)
	box(xf * T(0, 0.45, 0), Vector3(w, 0.12, 0.62), "nacre115", 1.0)
	box(xf * T(0, 0.8, -0.3), Vector3(w, 0.6, 0.1), "nacre115", 1.0)
	box(xf * T(0, 0.53, 0.02), Vector3(w - 0.2, 0.06, 0.5), "tissu115" + ("" if cushion == "" else "_" + cushion), 1.0)
	col_box(xf * T(0, 0.3, 0), Vector3(w, 0.6, 0.62))


## Une enseigne du Dôme (une plaque de verre bleu nuit cerclée de nacre).
func sign115(xf: Transform3D, sign_id: String, w: float = 3.2, h: float = 1.6) -> void:
	box(xf * T(0, 0, -0.05), Vector3(w + 0.16, h + 0.16, 0.08), "nacre115", 1.0)
	quadz(xf * T(0, 0, 0.0), w, h, "enseigne115_" + sign_id)


## Un totem d'orientation (une stèle de nacre, une enseigne de chaque côté).
func totem115(pos: Vector3, yaw: float, sign_id: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	box(Transform3D(b, pos + Vector3.UP * 1.4), Vector3(1.9, 2.8, 0.34), "nacre115", 1.0)
	box(Transform3D(b, pos + Vector3.UP * 2.86), Vector3(1.96, 0.06, 0.38), "led115_cyan", 1.0)
	sign115(Transform3D(b, pos + Vector3.UP * 1.75 + b * Vector3(0, 0, 0.19)), sign_id, 1.6, 0.8)
	sign115(Transform3D(b * Basis(Vector3.UP, PI), pos + Vector3.UP * 1.75 + b * Vector3(0, 0, -0.19)), sign_id, 1.6, 0.8)
	col_box(Transform3D(b, pos + Vector3.UP * 1.4), Vector3(1.9, 2.8, 0.34))


## Un corail qui luit : des branches (une petite arborescence de cylindres) qui partent de pos.
func coral115(pos: Vector3, h: float, couleur: String, seed_k: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_k
	var stack: Array = [[pos, Vector3.UP, h * 0.45, 0.09 * h, 0]]
	var guard: int = 0
	while not stack.is_empty() and guard < 60:
		guard += 1
		var s: Array = stack.pop_back()
		var p: Vector3 = s[0]
		var d: Vector3 = s[1]
		var ln: float = s[2]
		var rad: float = s[3]
		var depth: int = s[4]
		var q: Vector3 = p + d * ln
		rod(p, q, rad, rad * 0.75, "corail115_" + couleur, 6)
		if depth >= 3 or ln < 0.12:
			ball(Transform3D(Basis(), q), rad * 1.4, "corail115_" + couleur, 6, 3)
			continue
		for k in range(2 + int(r.randf() < 0.4)):
			var nd: Vector3 = (d + Vector3(r.randf_range(-0.7, 0.7), r.randf_range(0.0, 0.4), r.randf_range(-0.7, 0.7))).normalized()
			stack.append([q, nd, ln * r.randf_range(0.6, 0.78), rad * 0.72, depth + 1])


## Une tour de culture (hydroponie) : un fût de titane, des anneaux de pots verts, deux réglettes de
## lampes roses et violettes.
func hydro_tower115(pos: Vector3, h: float = 6.0) -> void:
	cyl(Transform3D(Basis(), pos), 0.55, 0.55, 0.3, "titane115_sombre", 12, true)
	cyl(Transform3D(Basis(), pos), 0.32, 0.32, h, "nacre115", 12, true)
	var n: int = int(h / 0.6)
	for k in range(n):
		var y: float = 0.5 + k * 0.6
		ring(Transform3D(Basis(Vector3.UP, float(k) * 0.4), pos + Vector3.UP * y), 0.32, 0.6, 0.16, "titane115_clair", 10)
		for j in range(6):
			var a: float = TAU * j / 6.0 + float(k) * 0.5
			var pp: Vector3 = pos + Vector3(cos(a) * 0.52, y + 0.2, sin(a) * 0.52)
			ball(Transform3D(Basis(), pp), 0.17, "feuille115_salade" if (j + k) % 3 != 0 else "feuille115_rouge", 6, 3)
	for s in [-1.0, 1.0]:
		var lp: Vector3 = pos + Vector3(s * 1.1, 0, 0)
		cyl(Transform3D(Basis(), lp), 0.05, 0.05, h + 0.4, "titane115_clair", 6, false)
		box(Transform3D(Basis(), lp + Vector3(-s * 0.06, h * 0.5 + 0.3, 0)), Vector3(0.05, h - 0.4, 0.14), "culture115", 1.0)
	col_cyl(pos, 0.65, h)


## Un tube d'algues : un cylindre de verre plein d'une eau verte qui luit, cerclé de titane.
func algae_tube115(pos: Vector3, h: float, r: float) -> void:
	cyl(Transform3D(Basis(), pos), r + 0.08, r + 0.08, 0.35, "titane115_sombre", 14, true)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.35), r, r, h - 0.7, "algue115", 14, true)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (h - 0.35)), r + 0.08, r + 0.08, 0.35, "titane115_sombre", 14, true)
	for k in range(3):
		ring(Transform3D(Basis(), pos + Vector3.UP * (1.0 + k * (h - 2.0) / 2.0)), r, r + 0.05, 0.08, "titane115_clair", 14)
	col_cyl(pos, r + 0.1, h)


## Une cuve d'aquarium : un socle, un cylindre de verre, l'eau qui luit, un couvercle. Renvoie le
## centre de l'eau (pour y mettre des bêtes).
func tank115(pos: Vector3, r: float, h: float) -> Vector3:
	cyl(Transform3D(Basis(), pos), r + 0.25, r + 0.25, 0.6, "nacre115", 24, true)
	ring(Transform3D(Basis(), pos + Vector3.UP * 0.6), r, r + 0.25, 0.08, "led115_cyan", 24)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.62), r - 0.03, r - 0.03, h - 0.2, "eau115_aquarium", 24, true)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.6), r, r, h, "vitre115", 24, false)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (0.6 + h)), r + 0.2, r + 0.2, 0.3, "nacre115", 24, true)
	col_cyl(pos, r + 0.25, h + 0.9)
	return pos + Vector3.UP * (0.6 + h * 0.5)

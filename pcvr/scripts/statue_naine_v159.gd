extends RefCounted
## V159 : un roi nain de pierre (les deux gardiens de la Grande Porte de Forgefer, sur la Montagne
## de Feu), sculpté au lieu d'être fait de boîtes : un socle à deux gradins et sa frise de runes,
## le roi debout dans sa cotte, la ceinture et sa boucle, les épaulières, la cape dans le dos, la
## grande barbe et ses deux tresses, le casque et la couronne à pointes, les mains posées sur le
## manche de la hache à double tranchant, dont le fer repose devant lui.
## Repère : at = le pied du socle ; +Z = devant (vers la terrasse). Un maillage par matière.
## Les matières : mats["pierre"], mats["bronze"], mats["fer"], mats["rune"].

const SEG: int = 20


## Le roi entier ; renvoie le nœud (le socle a sa collision, posée par l'appelant).
static func make(parent: Node3D, at: Vector3, mats: Dictionary) -> Node3D:
	var s := Node3D.new()
	s.name = "Roi_de_pierre_v159"
	parent.add_child(s)
	s.position = at
	var acc := {}
	for k in ["pierre", "bronze", "fer", "rune"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		acc[k] = st
	# --- le socle : deux gradins, une frise de runes sur le gradin du haut (devant et côtés)
	_boite(acc, "pierre", Vector3(0, 0.45, 0), Vector3(3.4, 0.9, 3.4))
	_boite(acc, "pierre", Vector3(0, 1.25, 0), Vector3(2.9, 0.7, 2.9))
	_boite(acc, "pierre", Vector3(0, 0.93, 0), Vector3(3.15, 0.08, 3.15))
	for k in range(5):
		var x: float = -1.0 + k * 0.5
		_boite(acc, "rune", Vector3(x, 1.25, 1.46), Vector3(0.05, 0.4, 0.02))
		_boite(acc, "rune", Vector3(x + 0.09, 1.36, 1.46), Vector3(0.05, 0.2, 0.02), Basis(Vector3.BACK, 0.7 if k % 2 == 0 else -0.7))
		if k % 2 == 1:
			_boite(acc, "rune", Vector3(x - 0.08, 1.16, 1.46), Vector3(0.05, 0.18, 0.02), Basis(Vector3.BACK, -0.7))
	# --- les bottes
	for sx in [-1.0, 1.0]:
		_tour(acc, "pierre", Vector3(sx * 0.55, 1.6, 0.25), [Vector2(0.42, 0.0), Vector2(0.44, 0.25), Vector2(0.36, 0.5), Vector2(0.0, 0.52)], Vector3(1.0, 1.0, 1.45))
	# --- la cotte (évasée en bas), le torse en tonneau, le cou
	_tour(acc, "pierre", Vector3(0, 1.95, 0), [Vector2(1.38, 0.0), Vector2(1.34, 0.3), Vector2(1.2, 1.2), Vector2(1.1, 2.3)], Vector3(1.0, 1.0, 0.86))
	for k2 in range(6):
		# les bandes de mailles de la cotte (de légers bourrelets)
		var y2: float = 2.15 + k2 * 0.33
		var r2: float = lerpf(1.36, 1.12, float(k2) / 6.0)
		_tour(acc, "pierre", Vector3(0, y2, 0), [Vector2(r2, 0.0), Vector2(r2 + 0.04, 0.06), Vector2(r2, 0.12)], Vector3(1.0, 1.0, 0.86), false)
	_tour(acc, "pierre", Vector3(0, 4.25, 0), [Vector2(1.1, 0.0), Vector2(1.24, 0.7), Vector2(1.3, 1.5), Vector2(1.16, 2.2), Vector2(0.72, 2.6), Vector2(0.4, 2.8), Vector2(0.0, 2.85)], Vector3(1.0, 1.0, 0.82))
	# la ceinture et sa boucle
	_tour(acc, "bronze", Vector3(0, 4.12, 0), [Vector2(1.15, 0.0), Vector2(1.19, 0.05), Vector2(1.19, 0.3), Vector2(1.15, 0.35)], Vector3(1.0, 1.0, 0.86), false)
	_boite(acc, "bronze", Vector3(0, 4.3, 1.0), Vector3(0.62, 0.48, 0.12))
	_boite(acc, "pierre", Vector3(0, 4.3, 1.07), Vector3(0.3, 0.2, 0.06))
	# --- la cape, dans le dos (un demi-tour, plus large en bas)
	_tour(acc, "pierre", Vector3(0, 1.95, -0.05), [Vector2(1.55, 0.0), Vector2(1.5, 1.6), Vector2(1.42, 3.2), Vector2(1.36, 4.6), Vector2(1.0, 5.0)], Vector3(1.0, 1.0, 0.92), false, deg_to_rad(200.0), deg_to_rad(340.0))
	# --- les épaulières
	for sx2 in [-1.0, 1.0]:
		_tour(acc, "bronze", Vector3(sx2 * 1.12, 6.25, 0), [Vector2(0.62, 0.0), Vector2(0.58, 0.22), Vector2(0.4, 0.45), Vector2(0.0, 0.52)], Vector3(1.0, 1.0, 0.95))
	# --- les bras : de l'épaule au coude, du coude aux mains, posées sur le haut du manche
	for sx3 in [-1.0, 1.0]:
		var epaule := Vector3(sx3 * 1.2, 6.2, 0.0)
		var coude := Vector3(sx3 * 1.1, 5.05, 0.55)
		var poing := Vector3(sx3 * 0.22, 5.15, 1.5)
		_tube(acc, "pierre", [epaule, coude, poing], [0.36, 0.31, 0.27])
		_tour(acc, "bronze", coude + Vector3(0, -0.1, 0), [Vector2(0.33, 0.0), Vector2(0.35, 0.1), Vector2(0.33, 0.3)], Vector3.ONE, false)
		_boule(acc, "pierre", poing + Vector3(0, -0.02, 0.02), Vector3(0.3, 0.26, 0.3))
	# --- la hache : le manche debout devant le roi, le fer à double tranchant posé sur le socle
	var hx: Vector3 = Vector3(0, 1.6, 1.55)
	_tube(acc, "pierre", [hx + Vector3(0, 0.05, 0), hx + Vector3(0, 3.85, 0)], [0.11, 0.1], 8)
	_tour(acc, "bronze", hx + Vector3(0, 3.82, 0), [Vector2(0.16, 0.0), Vector2(0.18, 0.12), Vector2(0.0, 0.25)], Vector3.ONE)
	_boite(acc, "bronze", hx + Vector3(0, 0.95, 0), Vector3(0.36, 0.7, 0.3))
	for sx4 in [-1.0, 1.0]:
		_lame(acc, "bronze", hx + Vector3(sx4 * 0.18, 0.95, 0), sx4)
	# --- la tête : le cou, la tête, le nez, les yeux (deux runes qui rougeoient à peine)
	_tour(acc, "pierre", Vector3(0, 7.0, 0.05), [Vector2(0.5, 0.0), Vector2(0.48, 0.25)], Vector3.ONE, false)
	_boule(acc, "pierre", Vector3(0, 7.64, 0.08), Vector3(0.7, 0.72, 0.7))
	_tour(acc, "pierre", Vector3(0, 7.5, 0.7), [Vector2(0.15, 0.0), Vector2(0.11, 0.22), Vector2(0.0, 0.3)], Vector3(1.0, 1.0, 1.0), true, 0.0, TAU, Basis(Vector3.RIGHT, PI * 0.42))
	for sx5 in [-1.0, 1.0]:
		_boule(acc, "rune", Vector3(sx5 * 0.24, 7.72, 0.62), Vector3(0.07, 0.05, 0.03))
		_boite(acc, "pierre", Vector3(sx5 * 0.25, 7.86, 0.6), Vector3(0.3, 0.07, 0.1), Basis(Vector3.BACK, sx5 * -0.18))
	# --- la barbe : une grande pointe qui descend sur le torse, la moustache, deux tresses
	_tour(acc, "pierre", Vector3(0, 7.4, 0.6), [Vector2(0.7, 0.0), Vector2(0.8, -0.5), Vector2(0.74, -1.2), Vector2(0.5, -2.0), Vector2(0.18, -2.6), Vector2(0.0, -2.75)], Vector3(1.0, 1.0, 0.62))
	# les mèches de la barbe : des sillons (de fines tresses en relief, de haut en bas)
	for k5 in range(5):
		var xb: float = -0.44 + k5 * 0.22
		_tube(acc, "pierre", [Vector3(xb, 7.25, 1.02), Vector3(xb * 0.9, 6.4, 1.06), Vector3(xb * 0.6, 5.5, 0.92), Vector3(xb * 0.25, 4.85, 0.74)], [0.07, 0.075, 0.06, 0.03], 6)
	for sx6 in [-1.0, 1.0]:
		_tube(acc, "pierre", [Vector3(sx6 * 0.05, 7.42, 0.78), Vector3(sx6 * 0.32, 7.35, 0.74), Vector3(sx6 * 0.5, 7.12, 0.62)], [0.08, 0.07, 0.05], 6)
		var t0: Vector3 = Vector3(sx6 * 0.42, 6.9, 0.7)
		_tube(acc, "pierre", [t0, t0 + Vector3(sx6 * 0.05, -0.7, 0.12), t0 + Vector3(sx6 * 0.03, -1.4, 0.18)], [0.1, 0.09, 0.08], 6)
		_tour(acc, "bronze", t0 + Vector3(sx6 * 0.03, -1.5, 0.18), [Vector2(0.11, 0.0), Vector2(0.12, 0.08), Vector2(0.11, 0.16)], Vector3.ONE, false)
	# --- le casque, la crête, la couronne à pointes
	_tour(acc, "pierre", Vector3(0, 7.86, 0.06), [Vector2(0.7, 0.0), Vector2(0.66, 0.3), Vector2(0.48, 0.6), Vector2(0.2, 0.78), Vector2(0.0, 0.82)], Vector3.ONE)
	_boite(acc, "pierre", Vector3(0, 8.45, 0.06), Vector3(0.12, 0.35, 1.1))
	_boite(acc, "pierre", Vector3(0, 7.75, 0.72), Vector3(0.1, 0.35, 0.06))
	_tour(acc, "bronze", Vector3(0, 7.84, 0.06), [Vector2(0.71, 0.0), Vector2(0.74, 0.06), Vector2(0.74, 0.22), Vector2(0.71, 0.28)], Vector3.ONE, false)
	for k3 in range(8):
		var a: float = TAU * k3 / 8.0
		var p := Vector3(sin(a) * 0.72, 8.12, 0.06 + cos(a) * 0.72)
		_tour(acc, "bronze", p, [Vector2(0.09, 0.0), Vector2(0.0, 0.26)], Vector3(1.0, 1.0, 0.6), true, 0.0, TAU, Basis(Vector3.UP, a))
	# --- les maillages
	for k4 in acc:
		var st2: SurfaceTool = acc[k4]
		var mesh: ArrayMesh = st2.commit()
		if mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mats.get(k4, null)
		s.add_child(mi)
	return s


# =================================================================== les formes

## Un morceau fini : chaque triangle tourné vers l'extérieur (dehors.call(milieu, i) donne le
## côté extérieur ; Godot montre les faces dont les sommets tournent dans le sens des aiguilles
## d'une montre), lissé, avec ses tangentes, versé dans le maillage de sa matière.
static func _fini(acc: Dictionary, key: String, verts: PackedVector3Array, uvs: PackedVector2Array, idx: PackedInt32Array, dehors: Callable) -> void:
	for t in range(0, idx.size(), 3):
		var a: Vector3 = verts[idx[t]]
		var b: Vector3 = verts[idx[t + 1]]
		var c: Vector3 = verts[idx[t + 2]]
		var g: Vector3 = (a + b + c) / 3.0
		var out: Vector3 = dehors.call(g, t / 3)
		if (b - a).cross(c - a).dot(out) > 0.0:
			var tmp: int = idx[t + 1]
			idx[t + 1] = idx[t + 2]
			idx[t + 2] = tmp
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(verts.size()):
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	for k in idx:
		st.add_index(k)
	st.generate_normals()
	st.generate_tangents()
	var m: ArrayMesh = st.commit()
	if m.get_surface_count() > 0:
		(acc[key] as SurfaceTool).append_from(m, 0, Transform3D.IDENTITY)


## Un tour (une forme de révolution) : profil [Vector2(rayon, hauteur)] autour de +Y, posé en c,
## étiré par k (x, y, z), tourné par b ; de l'angle a0 à a1 (une demi-cape, par exemple).
static func _tour(acc: Dictionary, key: String, c: Vector3, profil: Array, k: Vector3 = Vector3.ONE, ferme: bool = true, a0: float = 0.0, a1: float = TAU, b: Basis = Basis.IDENTITY) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var n: int = SEG if a1 - a0 > PI * 1.5 else maxi(6, int(SEG * (a1 - a0) / TAU) + 1)
	var plein: bool = absf(a1 - a0 - TAU) < 0.001
	var cols: int = n + 1
	var long_: float = 0.0
	var vs: Array = [0.0]
	for i in range(1, profil.size()):
		long_ += (profil[i] as Vector2).distance_to(profil[i - 1])
		vs.append(long_)
	for i in range(profil.size()):
		var pr: Vector2 = profil[i]
		for j in range(cols):
			var a: float = a0 + (a1 - a0) * float(j) / n
			verts.append(c + b * Vector3(sin(a) * pr.x * k.x, pr.y * k.y, cos(a) * pr.x * k.z))
			uvs.append(Vector2(float(j) / n * TAU * maxf(pr.x, 0.3) * 0.5, float(vs[i]) * 0.5))
	for i in range(profil.size() - 1):
		for j in range(n):
			var i0: int = i * cols + j
			idx.append_array(PackedInt32Array([i0, i0 + 1, i0 + cols, i0 + 1, i0 + cols + 1, i0 + cols]))
	var n_cote: int = idx.size() / 3
	var bas_y: float = (profil[0] as Vector2).y
	if ferme and plein and (profil[0] as Vector2).x > 0.01:
		# le fond : une rondelle
		var base: int = verts.size()
		verts.append(c + b * Vector3(0, bas_y * k.y, 0))
		uvs.append(Vector2.ZERO)
		for j2 in range(n):
			idx.append_array(PackedInt32Array([base, j2, j2 + 1]))
	var axe: Vector3 = b * Vector3.UP
	var vers_haut: bool = (profil[profil.size() - 1] as Vector2).y >= bas_y
	var dehors := func(g: Vector3, t: int) -> Vector3:
		if t >= n_cote:
			return -axe if vers_haut else axe
		var d: Vector3 = g - c
		return d - axe * d.dot(axe)
	_fini(acc, key, verts, uvs, idx, dehors)


## Un tube qui suit un chemin (rayons par point).
static func _tube(acc: Dictionary, key: String, chemin: Array, rayons: Array, cotes: int = 10) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var cols: int = cotes + 1
	var along: float = 0.0
	for i in range(chemin.size()):
		var p: Vector3 = chemin[i]
		var fwd: Vector3 = ((chemin[mini(i + 1, chemin.size() - 1)] as Vector3) - (chemin[maxi(i - 1, 0)] as Vector3)).normalized()
		var side: Vector3 = fwd.cross(Vector3(0.31, 0.27, 0.91)).normalized()
		var up: Vector3 = side.cross(fwd).normalized()
		if i > 0:
			along += p.distance_to(chemin[i - 1])
		for j in range(cols):
			var a: float = TAU * float(j) / cotes
			verts.append(p + (side * cos(a) + up * sin(a)) * float(rayons[i]))
			uvs.append(Vector2(float(j) / cotes, along * 0.5))
	for i in range(chemin.size() - 1):
		for j in range(cotes):
			var i0: int = i * cols + j
			idx.append_array(PackedInt32Array([i0, i0 + cols, i0 + 1, i0 + 1, i0 + cols, i0 + cols + 1]))
	var dehors := func(g: Vector3, _t: int) -> Vector3:
		var best: Vector3 = chemin[0]
		var bd: float = INF
		for i2 in range(chemin.size() - 1):
			var pa: Vector3 = chemin[i2]
			var pb: Vector3 = chemin[i2 + 1]
			var ab: Vector3 = pb - pa
			var tt: float = clampf((g - pa).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
			var q: Vector3 = pa + ab * tt
			if q.distance_squared_to(g) < bd:
				bd = q.distance_squared_to(g)
				best = q
		return g - best
	_fini(acc, key, verts, uvs, idx, dehors)


## Une boule (étirée par r).
static func _boule(acc: Dictionary, key: String, c: Vector3, r: Vector3) -> void:
	var prof: Array = []
	for i in range(9):
		var t: float = -PI * 0.5 + PI * float(i) / 8.0
		prof.append(Vector2(cos(t), sin(t)))
	_tour(acc, key, c, prof, r, false)


## Une boîte (taille s, tournée par b).
static func _boite(acc: Dictionary, key: String, c: Vector3, s: Vector3, b: Basis = Basis.IDENTITY) -> void:
	var bm := BoxMesh.new()
	bm.size = s
	(acc[key] as SurfaceTool).append_from(bm, 0, Transform3D(b, c))


## Une lame de hache en croissant (dans le plan x-y), épaisse de 12 cm, côté sx.
static func _lame(acc: Dictionary, key: String, c: Vector3, sx: float) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var pts: Array = []
	# le bord coupant, un arc ; le talon, contre le manche
	for i in range(9):
		var t: float = -0.5 + float(i) / 8.0
		pts.append(Vector2(sx * (0.62 + cos(t * 2.2) * 0.38), t * 1.3))
	pts.append(Vector2(sx * 0.02, 0.22))
	pts.append(Vector2(sx * 0.02, -0.22))
	var e: float = 0.06
	var n: int = pts.size()
	var milieu := Vector2.ZERO
	for p in pts:
		milieu += p
	milieu /= n
	for side in [1.0, -1.0]:
		for p in pts:
			verts.append(c + Vector3(p.x, p.y, side * e))
			uvs.append(Vector2(p.x, p.y))
	var n_faces: int = 0
	for i in range(1, n - 1):
		idx.append_array(PackedInt32Array([0, i, i + 1, n, n + i + 1, n + i]))
		n_faces += 2
	for i in range(n):
		var j: int = (i + 1) % n
		idx.append_array(PackedInt32Array([i, j, n + i, j, n + j, n + i]))
	var cm := c + Vector3(milieu.x, milieu.y, 0)
	var dehors := func(g: Vector3, t: int) -> Vector3:
		if t < n_faces:
			return Vector3(0, 0, 1) if g.z > c.z else Vector3(0, 0, -1)
		var d: Vector3 = g - cm
		d.z = 0.0
		return d
	_fini(acc, key, verts, uvs, idx, dehors)

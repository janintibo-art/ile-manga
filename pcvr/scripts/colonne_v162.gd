extends RefCounted
## V162 : une colonne antique sculptée (l'Atlantide), au lieu de trois cylindres : la plinthe carrée,
## la base aux deux tores et à la scotie, le fût cannelé (24 cannelures) et galbé, l'astragale d'or, le
## chapiteau ionique (l'échine, les deux coussinets et leurs volutes enroulées, devant et derrière),
## l'abaque. Un maillage par taille (gardé une fois fait), deux surfaces : la pierre (0) et l'or (1).
## Repère : le pied de la colonne à l'origine ; h : la hauteur totale ; r : le rayon du fût.

const Sculpt = preload("res://scripts/statue_naine_v159.gd")
static var _cache: Dictionary = {}


static func mesh(h: float, r: float) -> ArrayMesh:
	var key: String = "%.2f_%.2f" % [h, r]
	if _cache.has(key):
		return _cache[key]
	var acc := {}
	for k in ["pierre", "or"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		acc[k] = st
	# la plinthe, la base (deux tores, une scotie entre eux)
	Sculpt._boite(acc, "pierre", Vector3(0, 0.08, 0), Vector3(r * 3.0, 0.16, r * 3.0))
	Sculpt._tour(acc, "pierre", Vector3(0, 0.16, 0), [Vector2(r * 1.4, 0.0), Vector2(r * 1.47, 0.05), Vector2(r * 1.42, 0.12), Vector2(r * 1.22, 0.15),
		Vector2(r * 1.16, 0.2), Vector2(r * 1.24, 0.25), Vector2(r * 1.27, 0.29), Vector2(r * 1.16, 0.33), Vector2(r * 1.04, 0.36), Vector2(r * 1.0, 0.38)], Vector3.ONE, false)
	# le fût cannelé et galbé
	var y0: float = 0.54
	var y1: float = h - 0.5
	_fut(acc, "pierre", y0, y1, r)
	# l'astragale d'or, l'échine
	var rt: float = r * 0.88
	Sculpt._tour(acc, "or", Vector3(0, y1 - 0.02, 0), [Vector2(rt * 0.98, 0.0), Vector2(rt * 1.07, 0.04), Vector2(rt * 0.98, 0.08)], Vector3.ONE, false)
	Sculpt._tour(acc, "pierre", Vector3(0, y1 + 0.06, 0), [Vector2(rt * 0.98, 0.0), Vector2(rt * 1.25, 0.1), Vector2(rt * 1.38, 0.17), Vector2(rt * 1.3, 0.2)], Vector3.ONE, false)
	# les deux coussinets (le long de z) et leurs volutes, devant et derrière
	var yv: float = h - 0.28
	for sx in [-1.0, 1.0]:
		var cx: float = sx * r * 1.18
		Sculpt._tour(acc, "pierre", Vector3(cx, yv, -r * 1.3), [Vector2(r * 0.26, 0.0), Vector2(r * 0.2, r * 0.9), Vector2(r * 0.17, r * 1.3), Vector2(r * 0.2, r * 1.7), Vector2(r * 0.26, r * 2.6)],
			Vector3.ONE, false, 0.0, TAU, Basis(Vector3.RIGHT, PI * 0.5))
		for sz in [-1.0, 1.0]:
			var c := Vector3(cx, yv, sz * r * 1.31)
			var pts: Array = []
			var rs: Array = []
			for i in range(26):
				var t: float = float(i) / 25.0
				var a: float = t * TAU * 2.3 * sx + PI * 0.5
				var rho: float = r * 0.26 * (1.0 - t * 0.82)
				pts.append(c + Vector3(cos(a) * rho, sin(a) * rho, sz * 0.01 * t))
				rs.append(r * 0.045 * (1.0 - t * 0.5))
			Sculpt._tube(acc, "pierre", pts, rs, 6)
			Sculpt._boule(acc, "or", c + Vector3(0, 0, sz * 0.012), Vector3(r * 0.06, r * 0.06, r * 0.03))
	# l'abaque, et son liseré d'or
	Sculpt._boite(acc, "pierre", Vector3(0, h - 0.06, 0), Vector3(r * 3.0, 0.12, r * 3.0))
	Sculpt._boite(acc, "or", Vector3(0, h - 0.125, 0), Vector3(r * 3.04, 0.02, r * 3.04))
	var mesh := ArrayMesh.new()
	for k2 in ["pierre", "or"]:
		(acc[k2] as SurfaceTool).commit(mesh)
	_cache[key] = mesh
	return mesh


## Une colonne brisée (l'avenue de la Porte des Marées) : la base, un tronçon de fût cassé de biais,
## sa cassure irrégulière ; pas de chapiteau.
static func brisee(h: float, r: float) -> ArrayMesh:
	var key: String = "b%.2f_%.2f" % [h, r]
	if _cache.has(key):
		return _cache[key]
	var acc := {}
	for k in ["pierre", "or"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		acc[k] = st
	Sculpt._boite(acc, "pierre", Vector3(0, 0.08, 0), Vector3(r * 3.0, 0.16, r * 3.0))
	Sculpt._tour(acc, "pierre", Vector3(0, 0.16, 0), [Vector2(r * 1.4, 0.0), Vector2(r * 1.47, 0.05), Vector2(r * 1.42, 0.12), Vector2(r * 1.22, 0.15),
		Vector2(r * 1.16, 0.2), Vector2(r * 1.24, 0.25), Vector2(r * 1.27, 0.29), Vector2(r * 1.16, 0.33), Vector2(r * 1.04, 0.36), Vector2(r * 1.0, 0.38)], Vector3.ONE, false)
	_fut(acc, "pierre", 0.54, h, r, 0.55)
	var mesh := ArrayMesh.new()
	(acc["pierre"] as SurfaceTool).commit(mesh)
	_cache[key] = mesh
	return mesh


## Un fût effilé et cannelé (la tour du Grand Cristal) : de r0 en bas à r1 en haut, n cannelures.
static func fut_effile(h: float, r0: float, r1: float, n: int) -> ArrayMesh:
	var acc := {"pierre": SurfaceTool.new()}
	(acc["pierre"] as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var na: int = n * 4
	var ny: int = 20
	var cols: int = na + 1
	for j in range(ny + 1):
		var t: float = float(j) / ny
		var rr: float = lerpf(r0, r1, t)
		for i in range(cols):
			var a: float = TAU * float(i) / na
			var f: float = absf(sin(a * n * 0.5))
			var rad: float = rr * (1.0 - 0.05 * pow(f, 0.35))
			verts.append(Vector3(cos(a) * rad, t * h, sin(a) * rad))
			uvs.append(Vector2(float(i) / na * TAU * rr, t * h))
	for j2 in range(ny):
		for i2 in range(na):
			var i0: int = j2 * cols + i2
			idx.append_array(PackedInt32Array([i0, i0 + 1, i0 + cols, i0 + 1, i0 + cols + 1, i0 + cols]))
	Sculpt._fini(acc, "pierre", verts, uvs, idx, func(g: Vector3, _t: int) -> Vector3: return Vector3(g.x, 0.0, g.z))
	return (acc["pierre"] as SurfaceTool).commit()


## Le fût : 24 cannelures (des creux arrondis entre de fines arêtes), plus mince en haut (le galbe).
static func _fut(acc: Dictionary, key: String, y0: float, y1: float, r: float, casse: float = 0.0) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var na: int = 96
	var ny: int = 14
	var cols: int = na + 1
	for j in range(ny + 1):
		var t: float = float(j) / ny
		var y: float = lerpf(y0, y1, t)
		var rr: float = r * (1.0 - 0.12 * pow(t, 1.6) + 0.02 * sin(t * PI))
		for i in range(cols):
			var a: float = TAU * float(i) / na
			var f: float = absf(sin(a * 12.0))
			var rad: float = rr * (1.0 - 0.045 * pow(f, 0.35))
			var yy: float = y
			if casse > 0.0 and j == ny:
				# la cassure : de biais, irrégulière
				yy -= casse * (0.5 + 0.5 * cos(a)) + 0.12 * absf(sin(a * 5.0 + 1.3))
			verts.append(Vector3(cos(a) * rad, yy, sin(a) * rad))
			uvs.append(Vector2(float(i) / na * TAU * r, y))
	for j2 in range(ny):
		for i2 in range(na):
			var i0: int = j2 * cols + i2
			idx.append_array(PackedInt32Array([i0, i0 + 1, i0 + cols, i0 + 1, i0 + cols + 1, i0 + cols]))
	Sculpt._fini(acc, key, verts, uvs, idx, func(g: Vector3, _t: int) -> Vector3: return Vector3(g.x, 0.0, g.z))

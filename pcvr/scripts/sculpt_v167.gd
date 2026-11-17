extends RefCounted
## V167 : les outils de sculpture, sans kit (pour les îles dont le kit n'a pas ceux de V166 : Larsen…).
## On sculpte en repère local dans des accumulateurs (un par matière : loc()), puis pose() en fait un
## maillage par matière, accroché à un nœud, posé par un repère.
##  - tour() : une forme de révolution à normales franches ; le profil [Vector2(rayon, hauteur)] est
##    parcouru la matière à gauche (vers le haut sur une paroi extérieure, vers le bas sur une paroi
##    intérieure, de l'extérieur vers l'axe sur un dessus) ; arêtes vives là où le profil casse ;
##  - nappe() : une nappe à deux faces (une toile, une feuille) ;
##  - tube(), boule(), boite() : ceux de la statue naine (statue_naine_v159).

const Sculpt = preload("res://scripts/statue_naine_v159.gd")


static func loc(keys: Array) -> Dictionary:
	var d := {}
	for k in keys:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		d[k] = st
	return d


static func tour(L: Dictionary, key: String, c: Vector3, prof: Array, b: Basis = Basis.IDENTITY, seg: int = 24) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = prof.size()
	var nseg: Array = []
	for i in range(n - 1):
		var t: Vector2 = (prof[i + 1] as Vector2) - (prof[i] as Vector2)
		nseg.append(Vector2(t.y, -t.x).normalized() if t.length() > 0.0001 else Vector2(1, 0))
	var arc: float = 0.0
	var vi: int = 0
	for i in range(n - 1):
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var ns: Vector2 = nseg[i]
		var na: Vector2 = ns
		var nb: Vector2 = ns
		if i > 0 and (nseg[i - 1] as Vector2).dot(ns) > 0.82:
			na = ((nseg[i - 1] as Vector2) + ns).normalized()
		if i < n - 2 and (nseg[i + 1] as Vector2).dot(ns) > 0.82:
			nb = ((nseg[i + 1] as Vector2) + ns).normalized()
		var l: float = p0.distance_to(p1)
		for j in range(seg + 1):
			var a: float = TAU * float(j) / seg
			var dr := Vector3(sin(a), 0, cos(a))
			for e in range(2):
				var p: Vector2 = p0 if e == 0 else p1
				var nn: Vector2 = na if e == 0 else nb
				st.set_normal((b * (dr * nn.x + Vector3.UP * nn.y)).normalized())
				st.set_uv(Vector2(float(j) / seg * TAU * maxf(p.x, 0.25) * 0.5, (arc + (l if e == 1 else 0.0)) * 0.5))
				st.add_vertex(c + b * (dr * p.x + Vector3.UP * p.y))
		for j2 in range(seg):
			var q: int = vi + j2 * 2
			for t2 in [q, q + 1, q + 2, q + 1, q + 3, q + 2]:
				st.add_index(t2)
		vi += (seg + 1) * 2
		arc += l
	st.generate_tangents()
	(L[key] as SurfaceTool).append_from(st.commit(), 0, Transform3D.IDENTITY)


static func nappe(L: Dictionary, key: String, pts: Array, nu: int, nv: int, uvs: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in range(2):
		for i in range(pts.size()):
			st.set_uv(uvs[i])
			st.add_vertex(pts[i])
	var n: int = pts.size()
	for j in range(nv):
		for i in range(nu):
			var a: int = j * (nu + 1) + i
			var b: int = a + 1
			var c: int = a + nu + 1
			var d: int = c + 1
			for t in [a, b, c, b, d, c]:
				st.add_index(t)
			for t2 in [a, c, b, b, c, d]:
				st.add_index(n + t2)
	st.generate_normals()
	st.generate_tangents()
	(L[key] as SurfaceTool).append_from(st.commit(), 0, Transform3D.IDENTITY)


static func tube(L: Dictionary, key: String, chemin: Array, rayons: Array, cotes: int = 8) -> void:
	Sculpt._tube(L, key, chemin, rayons, cotes)


static func boule(L: Dictionary, key: String, c: Vector3, r: Vector3) -> void:
	Sculpt._boule(L, key, c, r)


static func boite(L: Dictionary, key: String, c: Vector3, s: Vector3, b: Basis = Basis.IDENTITY) -> void:
	Sculpt._boite(L, key, c, s, b)


## Fait un maillage par matière (mats : clé -> Material), accroché à parent, posé par xf ; les nœuds
## s'appellent « prefixe_clé_n » (n : le nombre d'enfants du parent, pour qu'ils restent uniques).
static func pose(parent: Node3D, L: Dictionary, mats: Dictionary, xf: Transform3D, prefixe: String) -> void:
	for k in L:
		var mesh: ArrayMesh = (L[k] as SurfaceTool).commit()
		if mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "%s_%s_%d" % [prefixe, str(k), parent.get_child_count()]
		mi.mesh = mesh
		mi.material_override = mats.get(k)
		mi.transform = xf
		mi.visibility_range_end = 300.0
		parent.add_child(mi)

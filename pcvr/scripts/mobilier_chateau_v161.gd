extends RefCounted
## V161 : le mobilier de la Citadelle des Nuées (l'île flottante), sculpté au lieu d'être fait de boîtes.
##  - trone() : le trône des Rois-Ciel, en bois doré : un socle, quatre pieds tournés, l'assise et son
##    coussin de velours bleu, les accoudoirs à volutes sur leurs colonnettes et leurs balustres, le
##    dossier de velours dans son cadre doré, deux montants tournés et leurs pommeaux à pointe, la
##    crête en arc et son médaillon serti d'une pierre bleue (l'aigle de pierre s'y perche) ;
##  - lutrin() : le lutrin de la bibliothèque : un pied en croix, une colonne tournée, le pupitre
##    incliné et son rebord, le grand livre ouvert (les pages bombées, écrites, une lettrine), sa
##    reliure de cuir et son signet.
## Repère : at = le sol sous le meuble ; +Z = devant (là où l'on s'assoit, là où l'on lit).
## Les matières : mats["or"], mats["velours"], mats["bois"], mats["papier"] (les pages écrites),
## mats["tranche"] (le papier des tranches), mats["cuir"], mats["gemme"].

const Sculpt = preload("res://scripts/statue_naine_v159.gd")


static func _acc(keys: Array) -> Dictionary:
	var acc := {}
	for k in keys:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		acc[k] = st
	return acc


static func _poser(acc: Dictionary, node: Node3D, mats: Dictionary) -> void:
	for k in acc:
		var mesh: ArrayMesh = (acc[k] as SurfaceTool).commit()
		if mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Mobilier_" + str(k)
		mi.mesh = mesh
		mi.material_override = mats.get(k, null)
		node.add_child(mi)


## Une colonne tournée (profil [rayon, hauteur]) posée en p.
static func _tourne(acc: Dictionary, key: String, p: Vector3, profil: Array) -> void:
	Sculpt._tour(acc, key, p, profil, Vector3.ONE, true)


# =================================================================== le trône

static func trone(parent: Node3D, at: Vector3, mats: Dictionary) -> Node3D:
	var t := Node3D.new()
	t.name = "Trone_v161"
	parent.add_child(t)
	t.position = at
	var acc := _acc(["or", "velours", "bois", "gemme"])
	# le socle, mouluré
	Sculpt._boite(acc, "or", Vector3(0, 0.07, 0), Vector3(2.0, 0.14, 1.5))
	Sculpt._boite(acc, "bois", Vector3(0, 0.15, 0), Vector3(1.86, 0.04, 1.36))
	# les pieds tournés
	var pied: Array = [Vector2(0.1, 0.0), Vector2(0.12, 0.05), Vector2(0.07, 0.12), Vector2(0.085, 0.22), Vector2(0.055, 0.32), Vector2(0.075, 0.4), Vector2(0.06, 0.46), Vector2(0.08, 0.47)]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_tourne(acc, "or", Vector3(sx * 0.66, 0.17, sz * 0.44), pied)
	# l'assise, son tablier sculpté, le coussin de velours
	Sculpt._boite(acc, "or", Vector3(0, 0.66, 0), Vector3(1.5, 0.12, 1.04))
	Sculpt._boite(acc, "or", Vector3(0, 0.55, 0.5), Vector3(1.4, 0.16, 0.05))
	Sculpt._boite(acc, "bois", Vector3(0, 0.55, 0.53), Vector3(1.1, 0.09, 0.02))
	for k in range(5):
		Sculpt._boule(acc, "or", Vector3(-0.44 + k * 0.22, 0.55, 0.545), Vector3(0.035, 0.035, 0.02))
	Sculpt._boule(acc, "velours", Vector3(0, 0.76, 0.04), Vector3(0.7, 0.1, 0.48))
	# les accoudoirs : une colonnette devant, des balustres, la main courante et sa volute
	var col: Array = [Vector2(0.06, 0.0), Vector2(0.07, 0.04), Vector2(0.045, 0.1), Vector2(0.055, 0.22), Vector2(0.04, 0.33), Vector2(0.06, 0.4)]
	for sx2 in [-1.0, 1.0]:
		var x: float = sx2 * 0.72
		_tourne(acc, "or", Vector3(x, 0.72, 0.42), col)
		for k2 in range(3):
			_tourne(acc, "or", Vector3(x, 0.72, 0.18 - k2 * 0.22), [Vector2(0.025, 0.0), Vector2(0.035, 0.12), Vector2(0.02, 0.24), Vector2(0.03, 0.38)])
		var bras: Array = [Vector3(x, 1.12, -0.46), Vector3(x, 1.13, 0.0), Vector3(x, 1.14, 0.36), Vector3(x, 1.12, 0.5), Vector3(x, 1.05, 0.56), Vector3(x, 0.98, 0.53), Vector3(x, 0.96, 0.46)]
		Sculpt._tube(acc, "or", bras, [0.05, 0.055, 0.06, 0.065, 0.06, 0.05, 0.04], 10)
		Sculpt._boule(acc, "or", Vector3(x, 1.03, 0.5), Vector3(0.075, 0.075, 0.075))
		Sculpt._boite(acc, "velours", Vector3(x, 1.17, -0.04), Vector3(0.1, 0.04, 0.72))
	# le dossier : deux montants tournés, le velours dans son cadre, les pommeaux
	var montant: Array = [Vector2(0.08, 0.0), Vector2(0.09, 0.06), Vector2(0.06, 0.14), Vector2(0.065, 0.6), Vector2(0.085, 0.66), Vector2(0.06, 0.72), Vector2(0.06, 1.6), Vector2(0.085, 1.66), Vector2(0.06, 1.72), Vector2(0.06, 2.2), Vector2(0.09, 2.26), Vector2(0.07, 2.3)]
	for sx3 in [-1.0, 1.0]:
		var bx: float = sx3 * 0.74
		_tourne(acc, "or", Vector3(bx, 0.6, -0.48), montant)
		Sculpt._boule(acc, "or", Vector3(bx, 3.0, -0.48), Vector3(0.1, 0.1, 0.1))
		_tourne(acc, "or", Vector3(bx, 3.07, -0.48), [Vector2(0.05, 0.0), Vector2(0.0, 0.24)])
	Sculpt._boite(acc, "velours", Vector3(0, 1.78, -0.5), Vector3(1.32, 1.96, 0.06))
	Sculpt._boite(acc, "or", Vector3(0, 0.79, -0.48), Vector3(1.42, 0.08, 0.1))
	Sculpt._boite(acc, "or", Vector3(0, 2.77, -0.48), Vector3(1.42, 0.08, 0.1))
	for sx4 in [-1.0, 1.0]:
		Sculpt._boite(acc, "or", Vector3(sx4 * 0.66, 1.78, -0.47), Vector3(0.05, 1.94, 0.08))
	# le galon doré du dossier : un losange et des fleurons
	for k3 in range(4):
		var a: float = TAU * k3 / 4.0
		var p: Vector3 = Vector3(sin(a) * 0.32, 1.85 + cos(a) * 0.42, -0.465)
		var q: Vector3 = Vector3(sin(a + TAU / 4.0) * 0.32, 1.85 + cos(a + TAU / 4.0) * 0.42, -0.465)
		Sculpt._tube(acc, "or", [p, q], [0.018, 0.018], 6)
		Sculpt._boule(acc, "or", p, Vector3(0.04, 0.04, 0.02))
	Sculpt._boule(acc, "or", Vector3(0, 1.85, -0.46), Vector3(0.08, 0.08, 0.03))
	# la crête en arc et son médaillon
	var arc: Array = []
	var rs: Array = []
	for k4 in range(11):
		var u: float = float(k4) / 10.0
		arc.append(Vector3(-0.74 + 1.48 * u, 2.86 + 0.32 * sin(u * PI), -0.48))
		rs.append(0.05)
	Sculpt._tube(acc, "or", arc, rs, 8)
	Sculpt._tour(acc, "or", Vector3(0, 3.12, -0.52), [Vector2(0.0, 0.0), Vector2(0.21, 0.0), Vector2(0.23, 0.03), Vector2(0.21, 0.07), Vector2(0.0, 0.08)], Vector3.ONE, false, 0.0, TAU, Basis(Vector3.RIGHT, PI * 0.5))
	Sculpt._boule(acc, "gemme", Vector3(0, 3.12, -0.43), Vector3(0.08, 0.08, 0.04))
	for k5 in range(8):
		var a2: float = TAU * k5 / 8.0
		Sculpt._boule(acc, "or", Vector3(sin(a2) * 0.16, 3.12 + cos(a2) * 0.16, -0.44), Vector3(0.022, 0.022, 0.022))
	_poser(acc, t, mats)
	return t


# =================================================================== le lutrin

static func lutrin(parent: Node3D, at: Vector3, mats: Dictionary) -> Node3D:
	var l := Node3D.new()
	l.name = "Lutrin_v161"
	parent.add_child(l)
	l.position = at
	var acc := _acc(["bois", "papier", "tranche", "cuir", "or"])
	# le pied en croix, ses boules, la colonne tournée
	Sculpt._boite(acc, "bois", Vector3(0, 0.06, 0), Vector3(0.8, 0.08, 0.13))
	Sculpt._boite(acc, "bois", Vector3(0, 0.06, 0), Vector3(0.13, 0.08, 0.8))
	for k in range(4):
		var a: float = TAU * k / 4.0
		Sculpt._boule(acc, "bois", Vector3(sin(a) * 0.36, 0.035, cos(a) * 0.36), Vector3(0.05, 0.035, 0.05))
	_tourne(acc, "bois", Vector3(0, 0.1, 0), [Vector2(0.13, 0.0), Vector2(0.11, 0.05), Vector2(0.065, 0.12), Vector2(0.075, 0.3), Vector2(0.05, 0.48), Vector2(0.07, 0.62), Vector2(0.05, 0.78), Vector2(0.09, 0.86), Vector2(0.1, 0.9)])
	# le pupitre incliné (le bas vers le lecteur) et son rebord
	var b := Basis(Vector3.RIGHT, 0.4)
	var c := Vector3(0, 1.1, 0)
	Sculpt._boite(acc, "bois", c, Vector3(0.84, 0.05, 0.6), b)
	Sculpt._boite(acc, "bois", c + b * Vector3(0, 0.04, 0.29), Vector3(0.84, 0.06, 0.03), b)
	Sculpt._boite(acc, "bois", Vector3(0, 1.02, -0.05), Vector3(0.2, 0.14, 0.3))
	# le livre : la reliure de cuir, les tranches, les pages bombées
	Sculpt._boite(acc, "cuir", c + b * Vector3(0, 0.035, 0.0), Vector3(0.8, 0.02, 0.54), b)
	Sculpt._boite(acc, "tranche", c + b * Vector3(-0.2, 0.06, 0.0), Vector3(0.36, 0.04, 0.5), b)
	Sculpt._boite(acc, "tranche", c + b * Vector3(0.2, 0.06, 0.0), Vector3(0.36, 0.04, 0.5), b)
	_pages(acc, c, b)
	# le signet, qui pend
	Sculpt._tube(acc, "or", [c + b * Vector3(0.02, 0.1, -0.25), c + b * Vector3(0.03, 0.1, 0.0), c + b * Vector3(0.04, 0.09, 0.27), c + b * Vector3(0.05, -0.05, 0.3), c + b * Vector3(0.05, -0.22, 0.31)], [0.008, 0.008, 0.008, 0.008, 0.008], 4)
	_poser(acc, l, mats)
	return l


## Les deux pages ouvertes, bombées (UV : la page de gauche sur la moitié gauche de la texture).
static func _pages(acc: Dictionary, c: Vector3, b: Basis) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var nx: int = 12
	var nz: int = 2
	for i in range(nx + 1):
		var u: float = float(i) / nx
		var x: float = -0.38 + 0.76 * u
		var d: float = absf(x) / 0.38
		var y: float = 0.085 + 0.03 * sin(d * PI) - 0.01 * (1.0 - d)
		for j in range(nz + 1):
			var v: float = float(j) / nz
			verts.append(c + b * Vector3(x, y, -0.24 + 0.48 * v))
			uvs.append(Vector2(u, v))
	for i2 in range(nx):
		for j2 in range(nz):
			var i0: int = i2 * (nz + 1) + j2
			idx.append_array(PackedInt32Array([i0, i0 + nz + 1, i0 + 1, i0 + 1, i0 + nz + 1, i0 + nz + 2]))
	var haut: Vector3 = b * Vector3.UP
	Sculpt._fini(acc, "papier", verts, uvs, idx, func(_g: Vector3, _t: int) -> Vector3: return haut)

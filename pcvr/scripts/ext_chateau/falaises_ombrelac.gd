extends Node3D
## Extension « Le Château d'Ombrelac » : les falaises du Roc d'Ombrelac et de l'Aiguille, sculptées
## dans la roche (v10). Le relief de l'île (une grille de 2 m) ne peut pas dessiner une paroi à pic :
## la roche y était étirée. Ici, une « jupe » de roche épouse chaque falaise, un peu en avant du sol :
##  - pour chaque direction autour du roc, on lit le profil du sol, et pour chaque hauteur (tous les
##    60 cm), le point le plus avancé de la paroi ;
##  - la roche s'avance de 0,6 à 2,5 m : de grosses bosses, des bancs de roche (les strates : chacun
##    s'avance ou recule, avec un joint creusé à sa base), des fissures verticales ;
##  - en haut, elle rejoint le bord du plateau ; au pied, elle s'enfonce dans l'éboulis ou dans l'eau.
## Le shader (ombrelac_roche.gdshader) peint la pierre : les bandes des strates, le grain, les
## fissures, la mousse sur les corniches, les lichens, les coulures, le pied mouillé.
## La collision suit la jupe (un maillage plus grossier), pour ne pas entrer dans la roche au pied.

const IleO = preload("res://scripts/ext_chateau/ile_ombrelac.gd")

const PAS_Y: float = 0.6       # la hauteur d'un rang
const PAS_R: float = 0.25      # le pas de lecture du profil du sol

var ile: Node3D
var mat: ShaderMaterial
var _bosses := FastNoiseLite.new()
var _bancs := FastNoiseLite.new()
var _fentes := FastNoiseLite.new()
var _ondule := FastNoiseLite.new()


func build(island: Node3D, high_quality: bool) -> void:
	ile = island
	var t0: int = Time.get_ticks_msec()
	_bosses.seed = 18830
	_bosses.frequency = 0.035
	_bosses.fractal_octaves = 3
	_bancs.seed = 18831
	_bancs.frequency = 0.05
	_bancs.fractal_octaves = 2
	_fentes.seed = 18832
	_fentes.frequency = 0.09
	_fentes.fractal_octaves = 1
	_ondule.seed = 18833
	_ondule.frequency = 0.02
	_ondule.fractal_octaves = 2
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/ext_chateau/ombrelac_roche.gdshader")
	mat.set_shader_parameter("pied", IleO.LAC_Y)
	var q: float = 1.0 if high_quality else 0.6
	_jupe("Ombrelac_falaises_roc", IleO.ROC, IleO.ROC_R0 - 6.0, IleO.ROC_R1 + 36.0, IleO.ROC_Y, int(760 * q), 93.0)
	_jupe("Ombrelac_falaises_aiguille", IleO.AIGUILLE, 6.0, IleO.AIGUILLE_R + 18.0, IleO.AIGUILLE_Y, int(240 * q), 22.0)
	print("OMBRELAC: les falaises en ", Time.get_ticks_msec() - t0, " ms")


## Le rayon de la paroi pour chaque rang (le plus avancé où le sol atteint cette hauteur), puis le rang
## du pied (là où la pente se couche) : [rayons, pied]
func _profil(c: Vector2, dir: Vector2, r_in: float, nr: int, top: float, nrow: int) -> Array:
	var prof := PackedFloat32Array()
	prof.resize(nr)
	for k in range(nr):
		var p: Vector2 = c + dir * (r_in + k * PAS_R)
		var w: Vector3 = IleO.W(p.x, p.y)
		prof[k] = ile.height(w.x, w.z)
	# l'enveloppe : le plus haut point du sol au-delà (la paroi ne recule jamais en descendant)
	for k2 in range(nr - 2, -1, -1):
		prof[k2] = maxf(prof[k2], prof[k2 + 1])
	var rs := PackedFloat32Array()
	rs.resize(nrow)
	var k3: int = 0
	var pied: int = nrow - 1
	var couche: int = 0
	for j in range(nrow):
		var y: float = _rang_y(top, j)
		while k3 < nr - 1 and prof[k3 + 1] >= y:
			k3 += 1
		var r: float = r_in + k3 * PAS_R
		if k3 < nr - 1 and prof[k3] > prof[k3 + 1]:
			r += PAS_R * clampf((prof[k3] - y) / (prof[k3] - prof[k3 + 1]), 0.0, 1.0)
		rs[j] = r
		if k3 >= nr - 1 or prof[0] < y:
			pied = maxi(j - 1, 1)
			break
		# la pente se couche (plus de 2,5 de large pour 1 de haut) sur deux rangs : c'est le pied
		if j > 0 and y < top - 8.0 and r - rs[j - 1] > 2.5 * PAS_Y:
			couche += 1
			if couche >= 2:
				pied = maxi(j - 2, 1)
				break
		else:
			couche = 0
	return [rs, pied]


func _rang_y(top: float, j: int) -> float:
	return top - 0.1 - j * PAS_Y


## L'avancée de la roche devant le sol, en un point de la paroi (s : l'abscisse le long du pied)
func _avancee(s: float, y: float, top: float) -> float:
	var d: float = 1.5 + 1.2 * _bosses.get_noise_2d(s, y)
	# les bancs : ~3,2 m d'épaisseur, ondulés ; chacun avance ou recule d'un bloc
	var yy: float = y + _ondule.get_noise_2d(s, 0.0) * 4.0
	var banc: float = floor(yy / 3.2)
	var fr: float = yy / 3.2 - banc
	d += _bancs.get_noise_2d(s, banc * 37.0) * 0.9
	# les blocs : chaque banc est coupé en blocs de 3 à 7 m par des joints verticaux ; chaque bloc
	# avance ou recule un peu (la roche diaclasée)
	var bx: float = (s + banc * 2.3) / 5.0 + _bancs.get_noise_2d(banc * 11.0, s * 0.3) * 0.35
	var bloc: float = floor(bx)
	d += (fposmod(sin(bloc * 12.9898 + banc * 78.233) * 43758.5453, 1.0) - 0.5) * 1.0
	d -= 0.25 * (1.0 - smoothstep(0.0, 0.12, minf(bx - bloc, 1.0 - (bx - bloc))))
	# le joint à la base du banc : un creux
	d -= 0.35 * (1.0 - smoothstep(0.0, 0.22, fr))
	# les fissures verticales
	var f: float = 1.0 - absf(_fentes.get_noise_2d(s, y * 0.12))
	d -= 0.8 * smoothstep(0.86, 0.99, f)
	d = maxf(d, 0.55)
	# en haut, la roche rejoint le bord du plateau
	return d * clampf((top - y) / 1.4, 0.12, 1.0)


func _jupe(nom: String, c: Vector2, r_in: float, r_out: float, top: float, ncol: int, r_s: float) -> void:
	var nr: int = int((r_out - r_in) / PAS_R) + 1
	var y_min: float = IleO.LAC_Y - 2.5
	var nrow: int = int(ceil((top - y_min) / PAS_Y)) + 1
	var pos := PackedVector3Array()
	pos.resize(ncol * nrow)
	var cols := PackedColorArray()
	cols.resize(ncol * nrow)
	for i in range(ncol):
		var a: float = TAU * float(i) / float(ncol)
		var dir := Vector2(cos(a), sin(a))
		var s: float = a * r_s
		var res: Array = _profil(c, dir, r_in, nr, top, nrow)
		var rs: PackedFloat32Array = res[0]
		var pied: int = res[1]
		var enfoui := Vector3.ZERO
		for j in range(nrow):
			var k: int = i * nrow + j
			if j <= pied:
				var y: float = _rang_y(top, j)
				var d: float = _avancee(s, y, top)
				var p2: Vector2 = c + dir * (rs[j] + d)
				pos[k] = IleO.W(p2.x, p2.y, y)
				# R : l'avancée (les creux plus sombres) ; G : le banc ; B : près du pied
				var g: float = fposmod(floor((y + _ondule.get_noise_2d(s, 0.0) * 4.0) / 3.2) * 0.618, 1.0)
				cols[k] = Color(clampf((d - 0.4) / 1.8, 0.0, 1.0), g, 1.0 - clampf(float(pied - j) / 6.0, 0.0, 1.0), 1.0)
				if j == pied:
					# sous le pied : la roche s'enfonce dans le sol
					var pb: Vector2 = c + dir * (rs[j] - 0.4)
					enfoui = IleO.W(pb.x, pb.y, y - 1.8)
			else:
				pos[k] = enfoui
				cols[k] = Color(0.3, 0.0, 1.0, 1.0)
	# les normales : d'après les voisins de la grille
	var nrm := PackedVector3Array()
	nrm.resize(ncol * nrow)
	for i2 in range(ncol):
		var ia: int = ((i2 - 1 + ncol) % ncol) * nrow
		var ib: int = ((i2 + 1) % ncol) * nrow
		var ic: int = i2 * nrow
		var dflt := Vector3(cos(TAU * float(i2) / float(ncol)), 0.0, sin(TAU * float(i2) / float(ncol)))
		for j2 in range(nrow):
			var t_a: Vector3 = pos[ib + j2] - pos[ia + j2]
			var t_h: Vector3 = pos[ic + maxi(j2 - 1, 0)] - pos[ic + mini(j2 + 1, nrow - 1)]
			var n: Vector3 = t_h.cross(t_a)
			nrm[ic + j2] = n.normalized() if n.length_squared() > 1e-8 else (nrm[ic + j2 - 1] if j2 > 0 else dflt)
	var idx := PackedInt32Array()
	var faces := PackedVector3Array()
	for i3 in range(ncol):
		var i4: int = (i3 + 1) % ncol
		for j3 in range(nrow - 1):
			var va: int = i3 * nrow + j3
			var vb: int = i4 * nrow + j3
			var vc: int = va + 1
			var vd: int = vb + 1
			if pos[va].is_equal_approx(pos[vc]) and pos[vb].is_equal_approx(pos[vd]):
				continue
			idx.append_array([va, vc, vb, vb, vc, vd])
	# la collision : une colonne sur deux, un rang sur deux
	for i5 in range(0, ncol, 2):
		var i6: int = (i5 + 2) % ncol
		for j5 in range(0, nrow - 2, 2):
			var pa: Vector3 = pos[i5 * nrow + j5]
			var pb2: Vector3 = pos[i6 * nrow + j5]
			var pc: Vector3 = pos[i5 * nrow + j5 + 2]
			var pd: Vector3 = pos[i6 * nrow + j5 + 2]
			if (pc - pa).cross(pb2 - pa).length_squared() > 1e-6:
				faces.append_array([pa, pc, pb2])
			if (pd - pb2).cross(pc - pb2).length_squared() > 1e-6:
				faces.append_array([pb2, pc, pd])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pos
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = nom
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = nom + "_corps"
	body.collision_layer = 1
	body.collision_mask = 0
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(faces)
	sh.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = sh
	body.add_child(cs)
	add_child(body)


## (v10) Un bloc de roche anguleux (pour les éboulis au pied des falaises) : une sphère cubique,
## aplatie, taillée par quelques plans (les cassures), aux faces plates. Taille ~ 1 (rayon).
static func bloc_mesh(graine: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	var plans: Array = []
	for i in range(8):
		var n := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 1), rng.randf_range(-1, 1)).normalized()
		plans.append([n, rng.randf_range(0.5, 0.85)])
	var ech := Vector3(rng.randf_range(0.9, 1.2), rng.randf_range(0.55, 0.8), rng.randf_range(0.75, 1.0))
	var res: int = 4
	var faces := [[Vector3.RIGHT, Vector3.UP, Vector3.BACK], [Vector3.LEFT, Vector3.UP, Vector3.FORWARD],
		[Vector3.UP, Vector3.BACK, Vector3.RIGHT], [Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT],
		[Vector3.BACK, Vector3.UP, Vector3.LEFT], [Vector3.FORWARD, Vector3.UP, Vector3.RIGHT]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var nf: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var g: Array = []
		for j in range(res + 1):
			var row: Array = []
			for i2 in range(res + 1):
				var c: Vector3 = nf + u * (j * 2.0 / res - 1.0) + v * (i2 * 2.0 / res - 1.0)
				var p: Vector3 = c.normalized() * ech
				for pl in plans:
					var pn: Vector3 = pl[0]
					var over: float = p.dot(pn) - float(pl[1])
					if over > 0.0:
						p -= pn * over
				p.y = maxf(p.y, -0.35)
				row.append(p)
			g.append(row)
		for j2 in range(res):
			for i3 in range(res):
				var a: Vector3 = g[j2][i3]
				var b: Vector3 = g[j2][i3 + 1]
				var c2: Vector3 = g[j2 + 1][i3 + 1]
				var d: Vector3 = g[j2 + 1][i3]
				for t in [[a, b, c2], [a, c2, d]]:
					var n2: Vector3 = (t[2] - t[0]).cross(t[1] - t[0])
					if n2.length_squared() < 1e-10:
						continue
					n2 = n2.normalized()
					# la face doit regarder dehors
					var ordre: Array = t if n2.dot(t[0] + t[1] + t[2]) > 0.0 else [t[0], t[2], t[1]]
					if n2.dot(t[0] + t[1] + t[2]) <= 0.0:
						n2 = -n2
					for q in ordre:
						st.set_normal(n2)
						st.add_vertex(q)
	return st.commit()

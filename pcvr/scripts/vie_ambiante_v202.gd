extends Node3D
## V202 : la vie qui accompagne le plongeur. Les bancs de la V55 tournent autour de points fixes (le
## Jardin de corail, l'Atlantide, l'épave, quelques côtes) : dans une mer de plus d'un kilomètre, on
## pouvait plonger longtemps sans croiser un poisson. Ici, où que l'on plonge :
##   - neuf bancs vivent autour du nageur (sardines, demoiselles, chirurgiens, poissons-anges,
##     perroquets, rougets et mérous près du fond) : ils arrivent de loin, devant soi, traversent la
##     vue, s'écartent si l'on passe au milieu ; quand on les a laissés derrière, d'autres viennent ;
##   - des crabes marchent de côté sur le sable, autour de soi.
## Rien sous le dôme de l'Atlantide, rien hors de l'eau, rien là où la mer a moins de 3,5 m de fond.
## Tout s'arrête dès qu'on sort de l'eau (aucun coût à terre).

const SEA_Y: float = -0.42
const FOND_MIN: float = 3.5          # m d'eau au moins pour qu'un banc vienne
const LOIN: float = 42.0             # au-delà, le banc est repris et renvoyé devant soi
const DERRIERE: float = 20.0         # … ou dès qu'il est passé derrière soi, à cette distance
const D_ARRIVEE := Vector2(24.0, 36.0)
const D_PLONGEON := Vector2(5.0, 20.0)   # au moment où l'on plonge : de la vie tout de suite
const N_CRABES: int = 14
const CRABE_LOIN: float = 30.0

## [espèce de l'atlas, nombre, rayon du banc, taille, vitesse (m/s), près du fond]
const BANCS := [
	[3, 60, 3.4, 0.28, 1.8, false],
	[2, 36, 2.4, 0.24, 1.2, false],
	[1, 22, 2.6, 0.38, 1.3, false],
	[4, 12, 2.2, 0.42, 1.0, false],
	[6, 10, 2.2, 0.5, 1.0, false],
	[7, 16, 2.0, 0.32, 1.0, true],
	[5, 2, 1.3, 1.0, 0.6, true],
	[3, 48, 3.0, 0.26, 1.7, false],
	[1, 16, 2.4, 0.34, 1.2, false],
]

var main: Node
var mer: Node
var vie: Node
var bancs: Array = []                # {mmi, n, offsets, sizes, scatter, rayon, vitesse, fond, vivant, pos, cap, age, t, sol, sol_t}
var crabes: MultiMeshInstance3D
var _crabes: Array = []              # {vivant, pos, cap, t, pause, taille, sol_t}
var dans_l_eau: bool = false
var essai: bool = false              # (les tests mènent eux-mêmes « pas »)
var _rng := RandomNumberGenerator.new()
var _etait: bool = false


func build(main_node: Node, mer_node: Node, vie_node: Node) -> void:
	main = main_node
	mer = mer_node
	vie = vie_node
	name = "Vie_ambiante_v202"
	_rng.seed = 20201
	for b in BANCS:
		_faire_banc(b)
	_faire_crabes()
	print("ILE_MANGA_V202: la vie autour du plongeur (%d bancs, %d crabes)" % [bancs.size(), N_CRABES])


func _faire_banc(b: Array) -> void:
	var n: int = int(b[1])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = vie._fish_mesh
	mm.instance_count = n
	var offsets: Array = []
	var sizes: Array = []
	for i in range(n):
		offsets.append(Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-1, 1)).normalized() * pow(_rng.randf(), 0.5) * float(b[2]))
		sizes.append(float(b[3]) * _rng.randf_range(0.8, 1.25))
		mm.set_instance_custom_data(i, Color(_rng.randf(), float(b[0]) / 8.0, _rng.randf_range(0.6, 1.1), 0.0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -500, 0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Banc_ambiant_%d" % bancs.size()
	mmi.multimesh = mm
	mmi.material_override = vie._fish_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-4000, -60, -4000), Vector3(8000, 70, 8000))
	mmi.visible = false
	add_child(mmi)
	var sc := PackedVector3Array()
	sc.resize(n)
	bancs.append({"mmi": mmi, "n": n, "offsets": offsets, "sizes": sizes, "scatter": sc, "rayon": float(b[2]), "vitesse": float(b[4]),
		"fond": bool(b[5]), "vivant": false, "pos": Vector3.ZERO, "cap": 0.0, "age": 0.0, "t": _rng.randf() * 50.0, "sol": -30.0, "sol_t": 0.0})


# =================================================================== les crabes

## Un tube effilé de a à b (6 pans).
func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, c0: Color, c1: Color) -> void:
	var axe: Vector3 = (b - a).normalized()
	var u: Vector3 = axe.cross(Vector3.UP if absf(axe.y) < 0.9 else Vector3.RIGHT).normalized()
	var v: Vector3 = axe.cross(u)
	for k in range(6):
		var a0: float = TAU * k / 6.0
		var a1: float = TAU * (k + 1) / 6.0
		var n0: Vector3 = u * cos(a0) + v * sin(a0)
		var n1: Vector3 = u * cos(a1) + v * sin(a1)
		var q := [[a + n0 * r0, n0, c0], [a + n1 * r0, n1, c0], [b + n0 * r1, n0, c1], [b + n1 * r1, n1, c1]]
		for idx in [0, 2, 1, 1, 2, 3]:
			st.set_color(q[idx][2])
			st.set_normal(q[idx][1])
			st.add_vertex(q[idx][0])


## Une boule aplatie (rayons r), tournée par « rot », de couleur c (dessous : c_bas).
func _boule(st: SurfaceTool, centre: Vector3, r: Vector3, c: Color, c_bas: Color, rot: Basis = Basis(), rows: int = 6, segs: int = 10) -> void:
	for i in range(rows):
		for j in range(segs):
			var q: Array = []
			for di in [0, 1]:
				for dj in [0, 1]:
					var lat: float = lerpf(-PI * 0.5, PI * 0.5, float(i + di) / rows)
					var a: float = TAU * float(j + dj) / segs
					var d := Vector3(sin(a) * cos(lat), sin(lat), cos(a) * cos(lat))
					q.append([centre + rot * (d * r), (rot * (d / r)).normalized(), c_bas.lerp(c, smoothstep(-0.5, 0.2, d.y))])
			for idx in [0, 1, 2, 2, 1, 3]:
				st.set_color(q[idx][2])
				st.set_normal(q[idx][1])
				st.add_vertex(q[idx][0])


## Un crabe (large de 1 : on le met à l'échelle) : la carapace bombée et tachetée, huit pattes en trois
## segments (la hanche, le genou plus haut que le dos, la pointe au sol), deux pinces, deux yeux sur
## tige. Il regarde vers -Z et marche de côté (le long de X).
func _crabe_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dos := Color(0.55, 0.17, 0.09)
	var clair := Color(0.8, 0.42, 0.22)
	var ventre := Color(0.88, 0.78, 0.62)
	var sombre := Color(0.33, 0.09, 0.06)
	# la carapace : plus large que longue, le bord clair, le dos tacheté
	var rows: int = 8
	var segs: int = 16
	for i in range(rows):
		for j in range(segs):
			var pts: Array = []
			for di in [0, 1]:
				for dj in [0, 1]:
					var lat: float = lerpf(-PI * 0.5, PI * 0.5, float(i + di) / rows)
					var a: float = TAU * float(j + dj) / segs
					var r: float = cos(lat)
					# (l'avant, vers -Z, est plus large et plus droit que l'arrière)
					var large: float = 0.4 * (1.0 + 0.12 * -cos(a))
					var p := Vector3(sin(a) * r * large, 0.13 + sin(lat) * (0.11 if lat > 0.0 else 0.05), cos(a) * r * 0.3)
					var nrm := Vector3(sin(a) * r, sin(lat) * 2.2, cos(a) * r).normalized()
					var tache: float = 0.5 + 0.5 * sin(p.x * 37.0) * sin(p.z * 43.0 + 1.3)
					var col: Color = ventre if lat < -0.15 else dos.lerp(sombre, tache * 0.6 * (1.0 - r)).lerp(clair, clampf(pow(r, 3.0), 0.0, 1.0) * 0.7)
					pts.append([p, nrm, col])
			for k in [0, 1, 2, 2, 1, 3]:
				st.set_color(pts[k][2])
				st.set_normal(pts[k][1])
				st.add_vertex(pts[k][0])
	for side in [-1.0, 1.0]:
		# les pattes : quatre de chaque côté, en éventail
		for k in range(4):
			var ev: float = (k - 1.3) * 0.38                 # l'angle de l'éventail (vers l'arrière pour les dernières)
			var dir := Vector3(cos(ev) * side, 0.0, sin(ev))
			var hanche: Vector3 = Vector3(side * 0.3, 0.11, -0.06 + k * 0.07)
			var genou: Vector3 = hanche + dir * 0.3 + Vector3(0, 0.1, 0)
			var cheville: Vector3 = genou + dir * 0.24 + Vector3(0, -0.13, 0)
			var pointe: Vector3 = cheville + dir * 0.1 + Vector3(0, -0.08, 0)
			_tube(st, hanche, genou, 0.034, 0.028, clair, dos)
			_tube(st, genou, cheville, 0.028, 0.02, dos, clair)
			_tube(st, cheville, pointe, 0.02, 0.004, clair, sombre)
			_boule(st, genou, Vector3(0.034, 0.034, 0.034), dos, dos, Basis(), 3, 6)
		# la pince : le bras replié devant, la main renflée, deux doigts
		var epaule := Vector3(side * 0.26, 0.11, -0.2)
		var coude := Vector3(side * 0.44, 0.1, -0.36)
		var poignet := Vector3(side * 0.3, 0.09, -0.5)
		_tube(st, epaule, coude, 0.045, 0.04, clair, dos)
		_tube(st, coude, poignet, 0.04, 0.045, dos, dos)
		var rot := Basis(Vector3.UP, 0.9 * side)
		_boule(st, poignet + rot * Vector3(0, 0, -0.08), Vector3(0.07, 0.065, 0.12), dos, clair, rot, 5, 8)
		_tube(st, poignet + rot * Vector3(0, 0.025, -0.16), poignet + rot * Vector3(0, 0.03, -0.31), 0.035, 0.006, clair, ventre)
		_tube(st, poignet + rot * Vector3(0, -0.03, -0.16), poignet + rot * Vector3(0, -0.012, -0.29), 0.026, 0.005, clair, ventre)
		# l'œil sur sa tige
		_tube(st, Vector3(side * 0.1, 0.2, -0.26), Vector3(side * 0.11, 0.29, -0.29), 0.012, 0.012, clair, clair)
		_boule(st, Vector3(side * 0.11, 0.305, -0.29), Vector3(0.024, 0.024, 0.024), Color(0.03, 0.03, 0.04), Color(0.03, 0.03, 0.04), Basis(), 4, 6)
	return st.commit()


func _faire_crabes() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _crabe_mesh()
	mm.instance_count = N_CRABES
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.42
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crabes = MultiMeshInstance3D.new()
	crabes.name = "Crabes_v202"
	crabes.multimesh = mm
	crabes.material_override = mat
	crabes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crabes.custom_aabb = AABB(Vector3(-4000, -60, -4000), Vector3(8000, 70, 8000))
	crabes.visible = false
	add_child(crabes)
	for i in range(N_CRABES):
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -500, 0)))
		_crabes.append({"vivant": false, "pos": Vector3.ZERO, "cap": 0.0, "t": 0.0, "pause": 0.0, "taille": _rng.randf_range(0.2, 0.4), "age": 0.0, "sol_t": 0.0, "sens": 1.0})


# =================================================================== la boucle

func _sol(x: float, z: float) -> float:
	return float(main._height_at(x, z))


func _sous_dome(p: Vector3) -> bool:
	return mer != null and mer.get("atl") != null and mer.atl.in_dome(p)


func _process(delta: float) -> void:
	if essai or main == null or not bool(main.get("game_started")):
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var avant: Vector3 = -cam.global_basis.z
	var eau: bool = mer != null and (bool(mer.under) or bool(mer.swimming))
	pas(delta, cam.global_position, avant, eau)


## Un pas : « oeil » le regard du plongeur, « avant » où il regarde, « eau » s'il est dans la mer.
func pas(delta: float, oeil: Vector3, avant: Vector3, eau: bool) -> void:
	dans_l_eau = eau and not _sous_dome(oeil)
	if not dans_l_eau:
		if _etait:
			_etait = false
			for b in bancs:
				b["vivant"] = false
				(b["mmi"] as Node3D).visible = false
			for c in _crabes:
				c["vivant"] = false
			crabes.visible = false
		return
	var plongeon: bool = not _etait
	_etait = true
	var av := Vector2(avant.x, avant.z)
	var cap_vue: float = atan2(av.x, av.y) if av.length() > 0.05 else _rng.randf() * TAU
	# ---------------------------------------------------------------- les bancs
	var places: int = 0
	for b in bancs:
		var vers_b: Vector3 = (b["pos"] as Vector3) - oeil
		var d_b: float = vers_b.length()
		if not bool(b["vivant"]) or d_b > LOIN or (d_b > DERRIERE and vers_b.dot(avant) < -0.25 * d_b):
			# (un seul banc replacé par image, sauf au plongeon : tous)
			if plongeon or places < 1:
				places += 1
				_placer_banc(b, oeil, cap_vue, D_PLONGEON if plongeon else D_ARRIVEE)
		if bool(b["vivant"]):
			_nager(b, delta, oeil)
	# ---------------------------------------------------------------- les crabes
	crabes.visible = true
	var mm: MultiMesh = crabes.multimesh
	var replace: int = 0
	for i in range(N_CRABES):
		var c: Dictionary = _crabes[i]
		if not bool(c["vivant"]) or (c["pos"] as Vector3).distance_to(oeil) > CRABE_LOIN + 12.0:
			if plongeon or replace < 1:
				replace += 1
				_placer_crabe(c, oeil, cap_vue, plongeon)
			if not bool(c["vivant"]):
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -500, 0)))
				continue
		_marcher(c, delta)
		var p: Vector3 = c["pos"]
		var bob: float = sin(float(c["t"]) * 9.0) * 0.004 if float(c["pause"]) <= 0.0 else 0.0
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(c["cap"])).scaled(Vector3.ONE * float(c["taille"]) * clampf(float(c["age"]), 0.05, 1.0)), p + Vector3(0, bob, 0)))


func _placer_banc(b: Dictionary, oeil: Vector3, cap_vue: float, dist: Vector2) -> void:
	b["vivant"] = false
	(b["mmi"] as Node3D).visible = false
	var a: float = cap_vue + _rng.randf_range(-1.05, 1.05)
	var d: float = _rng.randf_range(dist.x, dist.y)
	var x: float = oeil.x + sin(a) * d
	var z: float = oeil.z + cos(a) * d
	var r: float = b["rayon"]
	var sol: float = _sol(x, z)
	for k in range(4):
		sol = maxf(sol, _sol(x + cos(k * PI * 0.5) * r, z + sin(k * PI * 0.5) * r))
	if sol > SEA_Y - FOND_MIN:
		return
	var y: float
	if bool(b["fond"]):
		y = sol + 1.0 + r * 0.6
	else:
		y = clampf(oeil.y + _rng.randf_range(-3.5, 2.5), sol + 1.5 + r * 0.6, SEA_Y - 1.0 - r * 0.6)
	y = minf(y, SEA_Y - 0.8)
	var p := Vector3(x, y, z)
	if _sous_dome(p):
		return
	b["pos"] = p
	# il vient passer devant le plongeur, à quelques mètres : il vise un point devant lui, de côté
	var but := Vector2(oeil.x + sin(cap_vue) * _rng.randf_range(3.0, 9.0), oeil.z + cos(cap_vue) * _rng.randf_range(3.0, 9.0))
	var cote: float = (1.0 if _rng.randf() < 0.5 else -1.0) * _rng.randf_range(2.0, 6.0)
	but += Vector2(cos(cap_vue), -sin(cap_vue)) * cote
	b["cap"] = atan2(but.x - x, but.y - z)
	b["age"] = 0.0
	b["sol"] = sol
	b["sol_t"] = 0.0
	b["vivant"] = true
	var sc: PackedVector3Array = b["scatter"]
	sc.fill(Vector3.ZERO)
	b["scatter"] = sc
	(b["mmi"] as Node3D).visible = true


func _nager(b: Dictionary, delta: float, oeil: Vector3) -> void:
	b["age"] = float(b["age"]) + delta
	b["t"] = float(b["t"]) + delta
	var t: float = b["t"]
	var cap: float = float(b["cap"]) + sin(t * 0.21) * 0.25 * delta
	b["cap"] = cap
	var dir := Vector3(sin(cap), 0.0, cos(cap))
	var pos: Vector3 = b["pos"]
	var r: float = b["rayon"]
	pos += dir * float(b["vitesse"]) * delta
	b["sol_t"] = float(b["sol_t"]) - delta
	if float(b["sol_t"]) <= 0.0:
		b["sol_t"] = 0.3
		# le fond le plus haut sous le banc (au centre, devant, sur les deux flancs) : aucun poisson
		# dans le sable ni dans un récif
		var devant: Vector3 = pos + dir * (r + 3.0)
		var flanc := Vector3(dir.z, 0.0, -dir.x) * r
		var haut: float = maxf(_sol(pos.x, pos.z), _sol(devant.x, devant.z))
		haut = maxf(haut, maxf(_sol(pos.x + flanc.x, pos.z + flanc.z), _sol(pos.x - flanc.x, pos.z - flanc.z)))
		b["sol"] = haut
		# la côte, le dôme : demi-tour
		if haut > SEA_Y - FOND_MIN + 0.5 or _sous_dome(devant):
			b["cap"] = cap + PI * 0.75
	var sol: float = b["sol"]
	var y_min: float = sol + 0.8 + r * 0.5
	var y_max: float = maxf(SEA_Y - 0.9 - r * 0.5, y_min)
	var y_but: float = clampf(pos.y + sin(t * 0.33) * 0.4 * delta, y_min, y_max)
	if bool(b["fond"]):
		y_but = y_min
	pos.y = lerpf(pos.y, y_but, clampf(delta * 1.5, 0.0, 1.0))
	b["pos"] = pos
	var grandit: float = clampf(float(b["age"]) / 1.5, 0.05, 1.0)
	var turn := Basis.looking_at(-dir, Vector3.UP)
	var mm: MultiMesh = (b["mmi"] as MultiMeshInstance3D).multimesh
	var offs: Array = b["offsets"]
	var sizes: Array = b["sizes"]
	var sc: PackedVector3Array = b["scatter"]
	var nageur: Vector3 = oeil + Vector3.DOWN * 0.3
	var pres: bool = pos.distance_to(nageur) < r + 5.0
	var k_fuite: float = clampf(delta * 6.0, 0.0, 1.0)
	var k_retour: float = clampf(delta * 0.8, 0.0, 1.0)
	for i in range(int(b["n"])):
		var o: Vector3 = offs[i]
		var p: Vector3 = pos + turn * (o + Vector3(sin(t * 0.7 + i) * 0.3, sin(t * 0.9 + i * 1.7) * 0.2, cos(t * 0.6 + i * 0.5) * 0.3))
		var push: Vector3 = sc[i]
		if pres:
			var away: Vector3 = p - nageur
			var d: float = away.length()
			if d < 3.5 and d > 0.01:
				push = push.lerp(away / d * (3.5 - d) * 1.6, k_fuite)
			else:
				push = push.lerp(Vector3.ZERO, k_retour)
			sc[i] = push
			p += push
		elif push != Vector3.ZERO:
			push = push.lerp(Vector3.ZERO, k_retour)
			sc[i] = push
			p += push
		p.y = clampf(p.y, sol + 0.35, SEA_Y - 0.5)
		var d2: Vector3 = (dir + push * 0.25).normalized()
		mm.set_instance_transform(i, Transform3D(Basis.looking_at(d2, Vector3.UP).scaled(Vector3.ONE * float(sizes[i]) * grandit), p))
	b["scatter"] = sc


func _placer_crabe(c: Dictionary, oeil: Vector3, cap_vue: float, plongeon: bool) -> void:
	c["vivant"] = false
	var a: float = cap_vue + _rng.randf_range(-1.5, 1.5)
	var d: float = _rng.randf_range(4.0, 22.0) if plongeon else _rng.randf_range(9.0, 22.0)
	var x: float = oeil.x + sin(a) * d
	var z: float = oeil.z + cos(a) * d
	var sol: float = _sol(x, z)
	# sur le fond de la mer seulement, et pas trop loin sous le plongeur (on ne le verrait pas)
	if sol > SEA_Y - 2.0 or oeil.y - sol > 26.0:
		return
	var p := Vector3(x, sol + 0.02, z)
	if _sous_dome(p):
		return
	c["pos"] = p
	c["cap"] = _rng.randf() * TAU
	c["sens"] = 1.0 if _rng.randf() < 0.5 else -1.0
	c["pause"] = _rng.randf_range(0.0, 3.0)
	c["t"] = _rng.randf() * 10.0
	c["age"] = 0.0
	c["vivant"] = true


func _marcher(c: Dictionary, delta: float) -> void:
	c["t"] = float(c["t"]) + delta
	c["age"] = float(c["age"]) + delta
	if float(c["pause"]) > 0.0:
		c["pause"] = float(c["pause"]) - delta
		if float(c["pause"]) <= 0.0:
			c["cap"] = float(c["cap"]) + _rng.randf_range(-1.2, 1.2)
			c["sens"] = 1.0 if _rng.randf() < 0.5 else -1.0
			c["marche"] = _rng.randf_range(2.0, 7.0)
		return
	c["marche"] = float(c.get("marche", 3.0)) - delta
	if float(c["marche"]) <= 0.0:
		c["pause"] = _rng.randf_range(1.0, 5.0)
		return
	# de côté : le long de son axe X
	var cap: float = c["cap"]
	var cote := Vector3(cos(cap), 0.0, -sin(cap)) * float(c["sens"])
	var p: Vector3 = c["pos"] + cote * 0.35 * delta
	c["sol_t"] = float(c["sol_t"]) - delta
	if float(c["sol_t"]) <= 0.0:
		c["sol_t"] = 0.25
		var sol: float = _sol(p.x, p.z)
		if sol > SEA_Y - 1.5:
			c["sens"] = -float(c["sens"])
			return
		c["y"] = sol + 0.02
	p.y = lerpf(p.y, float(c.get("y", p.y)), clampf(delta * 6.0, 0.0, 1.0))
	c["pos"] = p


## Combien de bancs vivent près de ce point ? (tests)
func bancs_pres(p: Vector3, d: float) -> int:
	var n: int = 0
	for b in bancs:
		if bool(b["vivant"]) and (b["pos"] as Vector3).distance_to(p) < d:
			n += 1
	return n


func crabes_pres(p: Vector3, d: float) -> int:
	var n: int = 0
	for c in _crabes:
		if bool(c["vivant"]) and (c["pos"] as Vector3).distance_to(p) < d:
			n += 1
	return n

extends SceneTree
## Extension « Le Château d'Ombrelac » (v14) : l'outil qui calcule le plan des chemins des habitants
## (scripts/ext_chateau/chemins_ombrelac.gd). À relancer quand le château change :
##   godot --headless --path pcvr -s tools/ext_chateau_chemins.gd
## 1. une grille (tous les 50 cm) sur tous les planchers du château : un point où l'on tient debout
##    (rien dans un cylindre de 24 cm de rayon, de 35 cm à 1,75 m au-dessus du sol) ;
## 2. deux points voisins sont reliés si rien ne coupe le passage et si le sol continue (marche ≤ 40 cm) ;
## 3. chaque lieu des habitants (vie_ombrelac.definir) s'accroche à la grille ;
## 4. sur chaque morceau d'un seul tenant (un étage), l'arbre des plus courts chemins depuis le lieu le
##    plus central, puis on tire chaque bout de chemin au plus droit (là où un habitant passe en ligne
##    droite : son cylindre glisse sans rien toucher, le sol suit).

const Omb = preload("res://scripts/ext_chateau/ombrelac.gd")
const Vie = preload("res://scripts/ext_chateau/vie_ombrelac.gd")
const OUT := "res://scripts/ext_chateau/chemins_ombrelac.gd"
const ST: float = 0.5
const X0: float = -72.0
const X1: float = 72.0
const Z0: float = -60.0
const Z1: float = 70.0
const MARCHE: float = 0.4

var o
var fr: int = 0
var space: PhysicsDirectSpaceState3D
var xf: Transform3D
var inv: Transform3D
var cyl := CylinderShape3D.new()
var pos: Array = []            # id → Vector3 (château)
var cell: Dictionary = {}      # Vector2i → [ids]
var adj: Array = []            # id → [ids]


func _initialize() -> void:
	var r := Node3D.new()
	root.add_child(r)
	o = Omb.new()
	r.add_child(o)
	o.setup(null)
	o.build_island()
	o.build_town()
	o.set_process(false)
	cyl.radius = 0.24
	cyl.height = 1.4


func _process(_d: float) -> bool:
	fr += 1
	if fr < 3:
		return false
	var t0: int = Time.get_ticks_msec()
	space = o.get_world_3d().direct_space_state
	xf = o.chateau.global_transform
	inv = xf.affine_inverse()
	_grille()
	print("CHEMINS: grille ", pos.size(), " points en ", Time.get_ticks_msec() - t0, " ms")
	var d: Dictionary = Vie.definir(o.chateau)
	var lieux: Dictionary = {}
	for n in d["spots"]:
		lieux[n] = (d["spots"][n] as Dictionary)["appr"]
	for m in d["maisons"]:
		lieux[m] = d["maisons"][m]
	var plan: Dictionary = _plan(lieux)
	_ecrire(plan)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 3:
		_carte(args[0], float(args[1]), float(args[2]), lieux)
	print("CHEMINS: fini en ", Time.get_ticks_msec() - t0, " ms")
	quit()
	return true


# =================================================================== la grille

func _ray(a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(xf * a, xf * b))


func _libre(p: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cyl
	q.transform = Transform3D(Basis(), xf * (p + Vector3.UP * 1.05))
	return space.intersect_shape(q, 1).is_empty()


## Le sol sous p (entre +h et -b) : sa hauteur, ou NAN
func _sol(p: Vector3, h: float = 0.6, b: float = 0.8) -> float:
	var hit: Dictionary = _ray(p + Vector3.UP * h, p + Vector3.DOWN * b)
	if hit.is_empty() or (hit["normal"] as Vector3).y < 0.6:
		return NAN
	return (inv * (hit["position"] as Vector3)).y


func _grille() -> void:
	var nx: int = int((X1 - X0) / ST)
	var nz: int = int((Z1 - Z0) / ST)
	for i in range(nx + 1):
		for j in range(nz + 1):
			var x: float = X0 + i * ST
			var z: float = Z0 + j * ST
			var y: float = 62.0
			var ids: Array = []
			for _k in range(160):
				var hit: Dictionary = _ray(Vector3(x, y, z), Vector3(x, -10.0, z))
				if hit.is_empty():
					break
				var hp: Vector3 = inv * (hit["position"] as Vector3)
				var up: bool = (hit["normal"] as Vector3).y > 0.7
				if up and _libre(hp):
					ids.append(pos.size())
					pos.append(hp)
					adj.append([])
				# (le rayon qui frôle un mur reste dessus : on descend plus vite)
				y = minf(hp.y, y) - (0.03 if up else 0.2)
			if not ids.is_empty():
				cell[Vector2i(i, j)] = ids
	for c in cell:
		for a in cell[c]:
			for dv in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
				for b in cell.get(c + dv, []):
					if absf((pos[a] as Vector3).y - (pos[b] as Vector3).y) <= MARCHE and _passe(pos[a], pos[b], false):
						(adj[a] as Array).append(b)
						(adj[b] as Array).append(a)


## Peut-on aller de a à b en ligne droite ? (court : deux rayons ; long : le cylindre qui glisse)
func _passe(a: Vector3, b: Vector3, long: bool) -> bool:
	for h in [0.5, 1.3]:
		if not _ray(a + Vector3.UP * h, b + Vector3.UP * h).is_empty():
			return false
		if not _ray(b + Vector3.UP * h, a + Vector3.UP * h).is_empty():
			return false
	if long:
		var q := PhysicsShapeQueryParameters3D.new()
		var c2 := CylinderShape3D.new()
		c2.radius = 0.2
		c2.height = 1.3
		q.shape = c2
		q.transform = Transform3D(Basis(), xf * (a + Vector3.UP * 1.05))
		q.motion = xf.basis * (b - a)
		var r: PackedFloat32Array = space.cast_motion(q)
		if r.size() > 0 and r[0] < 1.0:
			return false
	# le sol continue
	var n: int = maxi(2, int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 0.3)))
	var prev: float = a.y
	for k in range(1, n):
		var p: Vector3 = a.lerp(b, float(k) / n)
		var y: float = _sol(p)
		if is_nan(y) or absf(y - prev) > MARCHE or absf(y - p.y) > 0.5:
			return false
		prev = y
	return absf(b.y - prev) <= MARCHE


# =================================================================== le plan

func _plan(lieux: Dictionary) -> Dictionary:
	# les lieux s'accrochent à la grille (les deux points libres les plus proches)
	var lid: Dictionary = {}
	var manque: Array = []
	for n in lieux:
		var p: Vector3 = lieux[n]
		var y: float = _sol(p, 1.0, 0.6)
		if not is_nan(y):
			p.y = y
		var cands: Array = []
		var ci := Vector2i(roundi((p.x - X0) / ST), roundi((p.z - Z0) / ST))
		for di in range(-2, 3):
			for dj in range(-2, 3):
				for g in cell.get(ci + Vector2i(di, dj), []):
					var q: Vector3 = pos[g]
					if absf(q.y - p.y) < 0.5 and Vector2(q.x - p.x, q.z - p.z).length() < 1.1:
						cands.append(g)
		cands.sort_custom(func(a, b): return (pos[a] as Vector3).distance_to(p) < (pos[b] as Vector3).distance_to(p))
		var id: int = pos.size()
		var ok: int = 0
		for g2 in cands:
			if ok >= 2:
				break
			if _passe(p, pos[g2], false) or (pos[g2] as Vector3).distance_to(p) < 0.05:
				if ok == 0:
					pos.append(p)
					adj.append([])
				(adj[id] as Array).append(g2)
				(adj[g2] as Array).append(id)
				ok += 1
		if ok == 0:
			manque.append(n)
		else:
			lid[n] = id
	if not manque.is_empty():
		print("CHEMINS: lieux sans accès : ", manque)
	# les morceaux d'un seul tenant
	var comp: Dictionary = {}
	var morceaux: Array = []
	for n2 in lid:
		var s: int = lid[n2]
		if comp.has(s):
			(morceaux[comp[s]] as Array).append(n2)
			continue
		var k: int = morceaux.size()
		morceaux.append([n2])
		var file: Array = [s]
		comp[s] = k
		while not file.is_empty():
			var c: int = file.pop_back()
			for v in adj[c]:
				if not comp.has(v):
					comp[v] = k
					file.append(v)
	# une place d'un groupe coupée du reste de son groupe (dans un recoin) : on la laisse
	var groupes: Dictionary = Vie.definir(o.chateau)["groupes"]
	var seuls: Array = []
	for g in groupes:
		var best: int = -1
		for n7 in groupes[g]:
			if lid.has(n7) and (best < 0 or (morceaux[comp[lid[n7]]] as Array).size() > (morceaux[best] as Array).size()):
				best = comp[lid[n7]]
		for n8 in groupes[g]:
			if lid.has(n8) and comp[lid[n8]] != best:
				seuls.append(n8)
	for n9 in seuls:
		(morceaux[comp[lid[n9]]] as Array).erase(n9)
		lid.erase(n9)
	if not seuls.is_empty():
		print("CHEMINS: places coupées de leur groupe (laissées) : ", seuls)
	morceaux = morceaux.filter(func(m): return not (m as Array).is_empty())
	# l'arbre des plus courts chemins, puis tiré au plus droit
	var points: Dictionary = {}
	var liens: Array = []
	var noms: Dictionary = {}
	for n3 in lid:
		noms[lid[n3]] = n3
	var cpt: Array = [0]
	for m in morceaux:
		var c0 := Vector3.ZERO
		for n4 in m:
			c0 += pos[lid[n4]]
		c0 /= float(m.size())
		var racine: int = lid[m[0]]
		for n5 in m:
			if (pos[lid[n5]] as Vector3).distance_to(c0) < (pos[racine] as Vector3).distance_to(c0):
				racine = lid[n5]
		var par: Dictionary = _dijkstra(racine)
		var arbre: Dictionary = {}           # id → [voisins dans l'arbre]
		for n6 in m:
			var c1: int = lid[n6]
			while c1 != racine and par.has(c1):
				var pp: int = par[c1]
				if not arbre.has(c1):
					arbre[c1] = []
				if not arbre.has(pp):
					arbre[pp] = []
				if (arbre[c1] as Array).has(pp):
					break
				(arbre[c1] as Array).append(pp)
				(arbre[pp] as Array).append(c1)
				c1 = pp
		if not arbre.has(racine):
			arbre[racine] = []
		var avant: Dictionary = points.duplicate()
		_tirer(arbre, noms, points, liens, cpt)
		_raccourcis(points, avant, liens)
		print("CHEMINS: morceau de ", m.size(), " lieux (", str(m.slice(0, 4)), "…) : ", arbre.size(), " points de grille")
	return {"points": points, "liens": liens, "manque": manque, "morceaux": morceaux}


## Des raccourcis entre les points d'un même morceau (à moins de 15 m, le passage libre) : l'arbre seul
## faisait de grands détours (les habitants cherchent leur chemin en comptant les étapes)
func _raccourcis(points: Dictionary, avant: Dictionary, liens: Array) -> void:
	var noms: Array = []
	for k in points:
		if not avant.has(k):
			noms.append(k)
	var deja: Dictionary = {}
	for l in liens:
		deja[str(l[0]) + "|" + str(l[1])] = true
		deja[str(l[1]) + "|" + str(l[0])] = true
	var n0: int = liens.size()
	for i in range(noms.size()):
		for j in range(i + 1, noms.size()):
			var a: Vector3 = points[noms[i]]
			var b: Vector3 = points[noms[j]]
			if a.distance_to(b) > 15.0 or a.distance_to(b) < 1.0 or absf(a.y - b.y) > 1.5 or deja.has(str(noms[i]) + "|" + str(noms[j])):
				continue
			if _passe(a, b, true):
				liens.append([noms[i], noms[j]])
				deja[str(noms[i]) + "|" + str(noms[j])] = true
	print("CHEMINS: ", liens.size() - n0, " raccourcis")


func _dijkstra(s: int) -> Dictionary:
	var dist: Dictionary = {s: 0.0}
	var par: Dictionary = {}
	var tas: Array = [[0.0, s]]
	var fait: Dictionary = {}
	while not tas.is_empty():
		var top: Array = _pop(tas)
		var u: int = top[1]
		if fait.has(u):
			continue
		fait[u] = true
		for v in adj[u]:
			var w: float = float(top[0]) + (pos[u] as Vector3).distance_to(pos[v])
			if w < float(dist.get(v, INF)):
				dist[v] = w
				par[v] = u
				_push(tas, [w, v])
	return par


func _push(h: Array, e: Array) -> void:
	h.append(e)
	var i: int = h.size() - 1
	while i > 0:
		var p: int = (i - 1) / 2
		if float(h[p][0]) <= float(e[0]):
			break
		h[i] = h[p]
		i = p
	h[i] = e


func _pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if h.is_empty():
		return top
	var i: int = 0
	var n: int = h.size()
	while true:
		var l: int = 2 * i + 1
		if l >= n:
			break
		var c: int = l
		if l + 1 < n and float(h[l + 1][0]) < float(h[l][0]):
			c = l + 1
		if float(h[c][0]) >= float(last[0]):
			break
		h[i] = h[c]
		i = c
	h[i] = last
	return top


## Les bouts de chemin entre deux nœuds gardés (lieux, embranchements) : au plus droit
func _tirer(arbre: Dictionary, noms: Dictionary, points: Dictionary, liens: Array, cpt: Array) -> void:
	var garde: Dictionary = {}
	for id in arbre:
		if noms.has(id) or (arbre[id] as Array).size() != 2:
			garde[id] = true
	var vu: Dictionary = {}
	var chaines: Array = []
	for g in garde:
		for v in arbre[g]:
			var k1: String = "%d_%d" % [mini(g, v), maxi(g, v)]
			if vu.has(k1):
				continue
			var ch: Array = [g]
			var prev: int = g
			var cur: int = v
			while true:
				vu["%d_%d" % [mini(prev, cur), maxi(prev, cur)]] = true
				ch.append(cur)
				if garde.has(cur):
					break
				var nx: int = -1
				for w in arbre[cur]:
					if w != prev:
						nx = w
				prev = cur
				cur = nx
			chaines.append(ch)
	var nommes: Dictionary = {}
	for ch2 in chaines:
		var i: int = 0
		var suite: Array = [ch2[0]]
		while i < ch2.size() - 1:
			var j: int = ch2.size() - 1
			while j > i + 1 and not _passe(pos[ch2[i]], pos[ch2[j]], true):
				j -= 1
			suite.append(ch2[j])
			i = j
		for k in range(suite.size()):
			var id2: int = suite[k]
			if not nommes.has(id2):
				nommes[id2] = str(noms[id2]) if noms.has(id2) else "c%d" % cpt[0]
				if not noms.has(id2):
					cpt[0] += 1
				var p: Vector3 = pos[id2]
				points[nommes[id2]] = Vector3(snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01))
			if k > 0:
				liens.append([nommes[suite[k - 1]], nommes[id2]])
	# un morceau d'un seul lieu
	for id3 in arbre:
		if noms.has(id3) and not nommes.has(id3):
			var p3: Vector3 = pos[id3]
			points[str(noms[id3])] = Vector3(snappedf(p3.x, 0.01), snappedf(p3.y, 0.01), snappedf(p3.z, 0.01))


func _ecrire(plan: Dictionary) -> void:
	var s: String = "extends RefCounted\n"
	s += "## Extension « Le Château d'Ombrelac » (v14) : le plan des chemins des habitants, calculé par\n"
	s += "## tools/ext_chateau_chemins.gd (à relancer quand le château change). Repère du château.\n"
	s += "## %d points, %d liens, %d morceaux d'un seul tenant (on passe de l'un à l'autre d'un coup).\n\n" % [plan["points"].size(), plan["liens"].size(), plan["morceaux"].size()]
	s += "const POINTS := {\n"
	var ks: Array = plan["points"].keys()
	ks.sort()
	for k in ks:
		var p: Vector3 = plan["points"][k]
		s += "\t\"%s\": Vector3(%s, %s, %s),\n" % [k, _f(p.x), _f(p.y), _f(p.z)]
	s += "}\n\nconst LIENS := [\n"
	for l in plan["liens"]:
		s += "\t[\"%s\", \"%s\"],\n" % [l[0], l[1]]
	s += "]\n"
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("CHEMINS: écrit ", OUT, " : ", plan["points"].size(), " points, ", plan["liens"].size(), " liens, ", plan["morceaux"].size(), " morceaux")


func _f(v: float) -> String:
	var t: String = "%.2f" % v
	return "0.0" if t == "-0.00" else t


## (mise au point) la carte des morceaux d'un seul tenant, entre deux hauteurs : un pixel par point
func _carte(fichier: String, y0: float, y1: float, lieux: Dictionary) -> void:
	var w: int = int((X1 - X0) / ST) + 1
	var h: int = int((Z1 - Z0) / ST) + 1
	var img := Image.create(w * 2, h * 2, false, Image.FORMAT_RGB8)
	img.fill(Color(0.08, 0.08, 0.1))
	var comp: Dictionary = {}
	var k: int = 0
	for s in range(pos.size()):
		if comp.has(s):
			continue
		var file: Array = [s]
		comp[s] = k
		while not file.is_empty():
			var c: int = file.pop_back()
			for v in adj[c]:
				if not comp.has(v):
					comp[v] = k
					file.append(v)
		k += 1
	for s2 in range(pos.size()):
		var p: Vector3 = pos[s2]
		if p.y < y0 or p.y > y1:
			continue
		var col := Color.from_hsv(fmod(float(comp[s2]) * 0.618, 1.0), 0.7, 0.9)
		var i: int = roundi((p.x - X0) / ST) * 2
		var j: int = roundi((p.z - Z0) / ST) * 2
		if i >= 0 and j >= 0 and i < w * 2 - 1 and j < h * 2 - 1:
			img.set_pixel(i, j, col)
			img.set_pixel(i + 1, j, col)
			img.set_pixel(i, j + 1, col)
			img.set_pixel(i + 1, j + 1, col)
	for n in lieux:
		var q: Vector3 = lieux[n]
		if q.y < y0 - 0.5 or q.y > y1:
			continue
		var i2: int = roundi((q.x - X0) / ST) * 2
		var j2: int = roundi((q.z - Z0) / ST) * 2
		for a in range(-1, 2):
			for b in range(-1, 2):
				if i2 + a >= 0 and j2 + b >= 0 and i2 + a < w * 2 and j2 + b < h * 2:
					img.set_pixel(i2 + a, j2 + b, Color.WHITE)
	img.save_png(fichier)
	print("CHEMINS: carte ", fichier)

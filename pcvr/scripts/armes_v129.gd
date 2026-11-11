extends RefCounted
## V129 : les armes en vrai détail. Chaque arme est un objet forgé, plus une boîte grise :
##  - les lames ont une vraie section (un losange, la gorge creusée au milieu, le fil plus clair
##    sur les bords), s'effilent jusqu'à la pointe ; le sabre est courbe, à un seul tranchant ;
##  - les poignées sont filetées (cuir et fil de laiton en spirale), les gardes ont des quillons
##    recourbés, les pommeaux sont tournés, les gemmes taillées en facettes ;
##  - chaque arme a son « âme », dans le thème de son monde (ame_arme_v129.gd l'anime) :
##      épée en bois : rien que le bois ciré ;
##      épée d'acier, hache, sabre : un reflet qui glisse le long du fil de temps en temps ;
##      épée naine : des runes de forge qui respirent comme des braises, quelques escarbilles ;
##      Épée des Nuées : une veine d'éclair dans la gorge, des arcs bleus qui crépitent ;
##      Trident des Marées : la pierre de mer qui ondule, des gouttes qui perlent et tombent ;
##      Lame du Cœur : un cristal rouge et or qui bat comme un cœur (« toum-toum ») ;
##      Bâton d'Arcanelle : un cristal violet qui flotte et tourne dans une griffe de bois tors,
##      un anneau de runes en orbite.
## Les maillages sont calculés une seule fois par arme (cache), puis partagés.
## Repère : poignée à l'origine, lame vers +Y (comme les anciens modèles) ; le repère « Pointe »
## (la traînée de la lame) est au bout.

const Ame := preload("res://scripts/ame_arme_v129.gd")

## Âme de chaque arme : couleur, couleur vive, genre d'effet (traînées, impacts).
const AMES := {
	"": {"c": Color(1.0, 0.86, 0.62), "c2": Color(1.0, 1.0, 0.95), "genre": "poing"},
	"epee_bois": {"c": Color(1.0, 0.8, 0.5), "c2": Color(1.0, 0.95, 0.82), "genre": "bois"},
	"epee": {"c": Color(0.66, 0.86, 1.0), "c2": Color(1.0, 1.0, 1.0), "genre": "acier"},
	"hache": {"c": Color(1.0, 0.7, 0.38), "c2": Color(1.0, 0.95, 0.8), "genre": "acier"},
	"epee_naine": {"c": Color(1.0, 0.42, 0.1), "c2": Color(1.0, 0.85, 0.42), "genre": "forge"},
	"epee_nuees": {"c": Color(0.42, 0.72, 1.0), "c2": Color(0.9, 0.97, 1.0), "genre": "foudre"},
	"trident_marees": {"c": Color(0.2, 0.88, 0.95), "c2": Color(0.85, 1.0, 1.0), "genre": "maree"},
	"sabre_corsaire": {"c": Color(1.0, 0.76, 0.28), "c2": Color(1.0, 0.95, 0.7), "genre": "or"},
	"lame_coeur": {"c": Color(1.0, 0.32, 0.26), "c2": Color(1.0, 0.82, 0.55), "genre": "coeur"},
	"baton_sorcier": {"c": Color(0.68, 0.42, 1.0), "c2": Color(0.92, 0.85, 1.0), "genre": "arcane"},
	"pelle": {"c": Color(1.0, 0.85, 0.6), "c2": Color(1.0, 1.0, 0.9), "genre": "bois"},
	"pinceau": {"c": Color(1.0, 0.6, 0.9), "c2": Color(1.0, 0.95, 1.0), "genre": "arcane"},
}
const MODELES := ["epee_bois", "epee", "hache", "epee_naine", "epee_nuees", "trident_marees", "sabre_corsaire", "lame_coeur", "baton_sorcier"]

static var _mats: Dictionary = {}
static var _cache: Dictionary = {}      # id -> Array de [nom, ArrayMesh, matériau, Transform3D]
static var _dot: Texture2D


static func has(id: String) -> bool:
	return id in MODELES


static func ame(id: String) -> Dictionary:
	return AMES.get(id, AMES[""])


# =================================================================== matériaux

static func _m(key: String, col: Color, rough: float, metal: float = 0.0, vcol: bool = false) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.6
	m.vertex_color_use_as_albedo = vcol
	_mats[key] = m
	return m


static func _glow(key: String, col: Color, emit: Color, energy: float, rough: float = 0.12, metal: float = 0.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.emission_enabled = true
	m.emission = emit
	m.emission_energy_multiplier = energy
	m.rim_enabled = true
	m.rim = 0.4
	m.set_meta("e0", energy)
	_mats[key] = m
	return m


## Le point doux (pour les particules et les reflets), calculé une seule fois.
static func dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.25, Color(1, 1, 1, 0.65))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_dot = t
	return _dot


# =================================================================== géométrie

## Un triangle tourné vers n (Godot : face avant dans le sens des aiguilles d'une montre).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, ca: Color, cb: Color, cc: Color, na: Vector3 = Vector3.ZERO, nb: Vector3 = Vector3.ZERO, nc: Vector3 = Vector3.ZERO) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t: Vector3 = b
		b = c
		c = t
		var tc: Color = cb
		cb = cc
		cc = tc
		var tn: Vector3 = nb
		nb = nc
		nc = tn
	st.set_color(ca)
	st.set_normal(n if na == Vector3.ZERO else na)
	st.add_vertex(a)
	st.set_color(cb)
	st.set_normal(n if nb == Vector3.ZERO else nb)
	st.add_vertex(b)
	st.set_color(cc)
	st.set_normal(n if nc == Vector3.ZERO else nc)
	st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	var n: Vector3 = (na + nb + nc + nd).normalized()
	_tri(st, a, b, c, n, ca, cb, cc, na, nb, nc)
	_tri(st, a, c, d, n, ca, cc, cd, na, nc, nd)


static func _g(v: float) -> Color:
	return Color(v, v, v)


## Section d'une lame : [Vector2(x, z), teinte] dans l'ordre autour.
static func _section(w: float, t: float, g: float, single: bool, cristal: bool) -> Array:
	var h: float = t * 0.5
	var s: Array = []
	if cristal:
		s = [[Vector2(w * 0.5, 0), 1.0], [Vector2(w * 0.22, h), 0.8], [Vector2(-w * 0.22, h), 0.9], [Vector2(-w * 0.5, 0), 1.0],
			[Vector2(-w * 0.22, -h), 0.8], [Vector2(w * 0.22, -h), 0.9]]
		return s
	var fond: float = h * (1.0 - 0.6 * g)
	var fc: float = 0.7 - 0.18 * g
	if single:
		# dos plat à +x, tranchant à -x
		s.append([Vector2(w * 0.5, h * 0.92), 0.72])
		s.append([Vector2(w * 0.12, h), 0.8])
		s.append([Vector2(-w * 0.02, fond), fc])
		s.append([Vector2(-w * 0.16, h * 0.96), 0.8])
		s.append([Vector2(-w * 0.5, 0), 1.0])
		s.append([Vector2(-w * 0.16, -h * 0.96), 0.8])
		s.append([Vector2(-w * 0.02, -fond), fc])
		s.append([Vector2(w * 0.12, -h), 0.8])
		s.append([Vector2(w * 0.5, -h * 0.92), 0.72])
		return s
	var gw: float = 0.12 if g > 0.0 else 0.06
	s.append([Vector2(w * 0.5, 0), 1.0])
	s.append([Vector2(w * 0.32, h), 0.74])
	s.append([Vector2(w * gw, h), 0.7])
	s.append([Vector2(0, fond), fc])
	s.append([Vector2(-w * gw, h), 0.7])
	s.append([Vector2(-w * 0.32, h), 0.74])
	s.append([Vector2(-w * 0.5, 0), 1.0])
	s.append([Vector2(-w * 0.32, -h), 0.74])
	s.append([Vector2(-w * gw, -h), 0.7])
	s.append([Vector2(0, -fond), fc])
	s.append([Vector2(w * gw, -h), 0.7])
	s.append([Vector2(w * 0.32, -h), 0.74])
	return s


## Lame : y0 (base), long, w0/w1 (largeur base/avant la pointe), pointe (fraction effilée),
## ep (épaisseur), gorge (profondeur relative 0..1), gorge_fin (fraction), courbe (m), un_tranchant,
## cristal (facettes irrégulières), veinage (bois).
static func _add_lame(st: SurfaceTool, p: Dictionary) -> void:
	var y0: float = float(p.get("y0", 0.1))
	var L: float = float(p["long"])
	var w0: float = float(p["w0"])
	var w1: float = float(p.get("w1", w0))
	var tip: float = float(p.get("pointe", 0.18))
	var ep: float = float(p.get("ep", 0.007))
	var gorge: float = float(p.get("gorge", 0.0))
	var gfin: float = float(p.get("gorge_fin", 0.7))
	var bend: float = float(p.get("courbe", 0.0))
	var single: bool = bool(p.get("un_tranchant", false))
	var cristal: bool = bool(p.get("cristal", false))
	var veinage: bool = bool(p.get("veinage", false))
	var n_r: int = 30
	var rings: Array = []
	var shades: Array = []
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 129
	for i in range(n_r + 1):
		var u: float = float(i) / n_r
		var w: float
		var t: float = ep * lerpf(1.0, 0.6, u)
		if u < 1.0 - tip:
			w = lerpf(w0, w1, u / (1.0 - tip))
		else:
			var s: float = (u - (1.0 - tip)) / tip
			w = w1 * pow(maxf(cos(s * PI * 0.5), 0.0), 0.85 if not single else 0.7)
			t *= lerpf(1.0, 0.2, s * s)
		if cristal and i > 0 and i < n_r:
			w *= rnd.randf_range(0.9, 1.08)
		var g: float = 0.0
		if gorge > 0.0:
			g = gorge * (1.0 - smoothstep(gfin - 0.14, gfin, u)) * smoothstep(0.0, 0.05, u)
		var cx: float = bend * u * u
		var y: float = y0 + L * u
		var sec: Array = _section(w, t, g, single, cristal)
		var ring: Array = []
		var sh: Array = []
		for e in sec:
			var q: Vector2 = e[0]
			ring.append(Vector3(cx + q.x, y, q.y))
			var v: float = float(e[1])
			if veinage:
				v *= 0.86 + 0.14 * sin(y * 70.0 + q.x * 260.0 + sin(y * 13.0) * 2.0)
			sh.append(v)
		rings.append(ring)
		shades.append(sh)
	var ns: int = (rings[0] as Array).size()
	for i in range(n_r):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for j in range(ns):
			var j2: int = (j + 1) % ns
			var a: Vector3 = ra[j]
			var b: Vector3 = ra[j2]
			var c: Vector3 = rb[j2]
			var d: Vector3 = rb[j]
			# normale de la facette (perpendiculaire à l'arête de section, vers l'extérieur)
			var e2: Vector3 = b - a
			var tang: Vector3 = (d - a)
			if tang.length() < 1e-6:
				tang = Vector3.UP
			var n: Vector3 = e2.cross(tang).normalized()
			var mid: Vector3 = (a + b) * 0.5
			var ctr := Vector3(bend * pow(float(i) / n_r, 2.0), mid.y, 0)
			if n.dot(mid - ctr) < 0.0:
				n = -n
			_quad(st, a, b, c, d, _g(shades[i][j]), _g(shades[i][j2]), _g(shades[i + 1][j2]), _g(shades[i + 1][j]), n, n, n, n)
	# fond (côté garde)
	var r0: Array = rings[0]
	var cen: Vector3 = Vector3(0, y0, 0)
	for j in range(ns):
		_tri(st, cen, r0[j], r0[(j + 1) % ns], Vector3.DOWN, _g(0.6), _g(0.6), _g(0.6))


## Tour (corps de révolution autour de Y) : prof = [Vector2(rayon, y)…]. wrap : relief en
## spirale (cuir, fil) de cette hauteur, turns tours sur la longueur.
static func _add_tour(st: SurfaceTool, prof: Array, segs: int = 18, wrap: float = 0.0, turns: float = 0.0, xf: Transform3D = Transform3D.IDENTITY, shade: float = 1.0) -> void:
	var n: int = prof.size()
	var y_a: float = (prof[0] as Vector2).y
	var y_b: float = (prof[n - 1] as Vector2).y
	var span: float = maxf(absf(y_b - y_a), 0.001)
	var basis: Basis = xf.basis
	for i in range(n - 1):
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var d0: Vector2 = (prof[mini(i + 1, n - 1)] as Vector2) - (prof[maxi(i - 1, 0)] as Vector2)
		var d1: Vector2 = (prof[mini(i + 2, n - 1)] as Vector2) - (prof[i] as Vector2)
		var n0: Vector2 = Vector2(d0.y, -d0.x).normalized()
		var n1: Vector2 = Vector2(d1.y, -d1.x).normalized()
		if n0.x < 0.0 and absf(n0.x) > 0.01:
			n0 = -n0
		if n1.x < 0.0 and absf(n1.x) > 0.01:
			n1 = -n1
		for k in range(segs):
			var a0: float = TAU * k / segs
			var a1: float = TAU * (k + 1) / segs
			var pts: Array = []
			var nrm: Array = []
			var cols: Array = []
			for e in [[p0, n0, a0], [p0, n0, a1], [p1, n1, a1], [p1, n1, a0]]:
				var pp: Vector2 = e[0]
				var nn: Vector2 = e[1]
				var ang: float = e[2]
				var r: float = pp.x
				var cv: float = shade
				if wrap > 0.0:
					var ph: float = ang * 2.0 + (pp.y - y_a) / span * turns * TAU
					var bump: float = pow(0.5 + 0.5 * sin(ph), 0.45)
					r += wrap * bump
					cv = shade * (0.5 + 0.5 * bump)
				var v := Vector3(cos(ang) * r, pp.y, sin(ang) * r)
				var nv := Vector3(cos(ang) * nn.x, nn.y, sin(ang) * nn.x).normalized()
				pts.append(xf * v)
				nrm.append((basis * nv).normalized())
				cols.append(_g(cv))
			_quad(st, pts[0], pts[1], pts[2], pts[3], cols[0], cols[1], cols[2], cols[3], nrm[0], nrm[1], nrm[2], nrm[3])


## Tube le long d'un chemin (repères transportés) ; rayons par point ; aplat : ellipse (0..1).
static func _add_tube(st: SurfaceTool, path: Array, radii: Array, segs: int = 8, aplat: float = 1.0, xf: Transform3D = Transform3D.IDENTITY, shade_fn: Callable = Callable(), caps: bool = true) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var tans: Array = []
	for i in range(n):
		var a: Vector3 = path[maxi(i - 1, 0)]
		var b: Vector3 = path[mini(i + 1, n - 1)]
		tans.append((b - a).normalized())
	var t0: Vector3 = tans[0]
	var nn: Vector3 = Vector3.FORWARD if absf(t0.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	nn = (nn - t0 * nn.dot(t0)).normalized()
	var frames: Array = []
	for i in range(n):
		var t: Vector3 = tans[i]
		nn = (nn - t * nn.dot(t)).normalized()
		var bb: Vector3 = t.cross(nn).normalized()
		frames.append([nn, bb])
	var rings: Array = []
	var nrms: Array = []
	var cols: Array = []
	for i in range(n):
		var P: Vector3 = path[i]
		var r: float = float(radii[i])
		var fN: Vector3 = frames[i][0]
		var fB: Vector3 = frames[i][1]
		var ring: Array = []
		var nr: Array = []
		var cl: Array = []
		for k in range(segs):
			var ang: float = TAU * k / segs
			var dirv: Vector3 = fN * cos(ang) + fB * sin(ang) * aplat
			ring.append(xf * (P + dirv * r))
			nr.append((xf.basis * (fN * cos(ang) * aplat + fB * sin(ang))).normalized())
			var cv: float = 1.0
			if shade_fn.is_valid():
				cv = float(shade_fn.call(float(i) / (n - 1), ang))
			cl.append(_g(cv))
		rings.append(ring)
		nrms.append(nr)
		cols.append(cl)
	for i in range(n - 1):
		for k in range(segs):
			var k2: int = (k + 1) % segs
			_quad(st, rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k], cols[i][k], cols[i][k2], cols[i + 1][k2], cols[i + 1][k],
				nrms[i][k], nrms[i][k2], nrms[i + 1][k2], nrms[i + 1][k])
	if caps:
		for e in [[0, -1.0], [n - 1, 1.0]]:
			var i: int = e[0]
			if float(radii[i]) < 0.0005:
				continue
			var c: Vector3 = xf * (path[i] as Vector3)
			var tn: Vector3 = (xf.basis * (tans[i] as Vector3)).normalized() * float(e[1])
			for k in range(segs):
				_tri(st, c, rings[i][k], rings[i][(k + 1) % segs], tn, cols[i][k], cols[i][k], cols[i][k])


## Gemme taillée : rondiste de rayon r, table en haut (ht), culasse en pointe (hb). Axe : Y de xf.
static func _add_gemme(st: SurfaceTool, r: float, ht: float, hb: float, facets: int = 8, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var top := Vector3(0, ht, 0)
	var bot := Vector3(0, -hb, 0)
	for k in range(facets):
		var a0: float = TAU * k / facets
		var a1: float = TAU * (k + 1) / facets
		var g0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var g1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var t0 := Vector3(cos(a0) * r * 0.55, ht, sin(a0) * r * 0.55)
		var t1 := Vector3(cos(a1) * r * 0.55, ht, sin(a1) * r * 0.55)
		# couronne (facette inclinée)
		var nc: Vector3 = (g1 - g0).cross(t0 - g0).normalized()
		var mid: Vector3 = (g0 + g1 + t0 + t1) * 0.25
		if nc.dot(mid - Vector3(0, ht * 0.4, 0)) < 0.0:
			nc = -nc
		var A: Vector3 = xf * g0
		var B: Vector3 = xf * g1
		var C: Vector3 = xf * t1
		var D: Vector3 = xf * t0
		var nw: Vector3 = (xf.basis * nc).normalized()
		_quad(st, A, B, C, D, _g(1), _g(1), _g(0.85), _g(0.85), nw, nw, nw, nw)
		# table
		_tri(st, xf * top, D, C, (xf.basis * Vector3.UP).normalized(), _g(0.9), _g(0.9), _g(0.9))
		# culasse
		var nb: Vector3 = (g1 - g0).cross(bot - g0).normalized()
		if nb.dot((g0 + g1) * 0.5 - Vector3(0, -hb * 0.4, 0)) < 0.0:
			nb = -nb
		_tri(st, A, B, xf * bot, (xf.basis * nb).normalized(), _g(0.75), _g(0.75), _g(0.55))


## Nappe paramétrée (s, d) -> point, avec une épaisseur ; deux faces et les bords.
## fn(s, d) -> Vector3 (feuillet moyen), ep(s, d) -> épaisseur, nrm : axe de l'épaisseur,
## teinte(s, d) -> valeur.
static func _add_nappe(st: SurfaceTool, fn: Callable, ep: Callable, nrm: Vector3, ns: int, nd: int, teinte: Callable, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var grid: Array = []
	for i in range(ns + 1):
		var row: Array = []
		for j in range(nd + 1):
			var s: float = float(i) / ns
			var d: float = float(j) / nd
			row.append([fn.call(s, d), float(ep.call(s, d)), float(teinte.call(s, d))])
		grid.append(row)
	for side in [1.0, -1.0]:
		var pts: Array = []
		for i in range(ns + 1):
			var row: Array = []
			for j in range(nd + 1):
				var e: Array = grid[i][j]
				row.append((e[0] as Vector3) + nrm * float(e[1]) * 0.5 * side)
			pts.append(row)
		for i in range(ns):
			for j in range(nd):
				var a: Vector3 = pts[i][j]
				var b: Vector3 = pts[i + 1][j]
				var c: Vector3 = pts[i + 1][j + 1]
				var d2: Vector3 = pts[i][j + 1]
				var n: Vector3 = (b - a).cross(d2 - a).normalized()
				if n.dot(nrm * side) < 0.0:
					n = -n
				var wn: Vector3 = (xf.basis * n).normalized()
				_quad(st, xf * a, xf * b, xf * c, xf * d2, _g(grid[i][j][2]), _g(grid[i + 1][j][2]), _g(grid[i + 1][j + 1][2]), _g(grid[i][j + 1][2]), wn, wn, wn, wn)
	# bords s = 0 et s = 1 (le long de d), d = 0 et d = 1 (le long de s)
	for i in [0, ns]:
		for j in range(nd):
			var e0: Array = grid[i][j]
			var e1: Array = grid[i][j + 1]
			var a: Vector3 = (e0[0] as Vector3) + nrm * float(e0[1]) * 0.5
			var b: Vector3 = (e1[0] as Vector3) + nrm * float(e1[1]) * 0.5
			var c: Vector3 = (e1[0] as Vector3) - nrm * float(e1[1]) * 0.5
			var d3: Vector3 = (e0[0] as Vector3) - nrm * float(e0[1]) * 0.5
			var other: Vector3 = grid[1 if i == 0 else ns - 1][j][0]
			var n2: Vector3 = ((e0[0] as Vector3) - other).normalized()
			var wn2: Vector3 = (xf.basis * n2).normalized()
			_quad(st, xf * a, xf * b, xf * c, xf * d3, _g(e0[2]), _g(e1[2]), _g(e1[2]), _g(e0[2]), wn2, wn2, wn2, wn2)
	for j in [0, nd]:
		for i in range(ns):
			var e0: Array = grid[i][j]
			var e1: Array = grid[i + 1][j]
			if float(e0[1]) < 0.0008 and float(e1[1]) < 0.0008:
				continue
			var a: Vector3 = (e0[0] as Vector3) + nrm * float(e0[1]) * 0.5
			var b: Vector3 = (e1[0] as Vector3) + nrm * float(e1[1]) * 0.5
			var c: Vector3 = (e1[0] as Vector3) - nrm * float(e1[1]) * 0.5
			var d3: Vector3 = (e0[0] as Vector3) - nrm * float(e0[1]) * 0.5
			var other: Vector3 = grid[i][1 if j == 0 else nd - 1][0]
			var n2: Vector3 = ((e0[0] as Vector3) - other).normalized()
			var wn2: Vector3 = (xf.basis * n2).normalized()
			_quad(st, xf * a, xf * b, xf * c, xf * d3, _g(e0[2]), _g(e1[2]), _g(e1[2]), _g(e0[2]), wn2, wn2, wn2, wn2)


## Une rune (traits) dans une case (w × h), centrée en (cx, cy) sur le plan z ; seed : laquelle.
static func _rune_traits(seed: int, cx: float, cy: float, w: float, h: float) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed * 7919 + 13
	var lines: Array = []
	var x0: float = cx - w * 0.5
	var x1: float = cx + w * 0.5
	var ya: float = cy - h * 0.5
	var yb: float = cy + h * 0.5
	var stave_x: float = cx + r.randf_range(-0.2, 0.2) * w
	lines.append([Vector2(stave_x, ya), Vector2(stave_x, yb)])
	var n: int = r.randi_range(1, 3)
	for k in range(n):
		var yy: float = lerpf(ya, yb, r.randf_range(0.15, 0.85))
		var side: float = -1.0 if r.randf() < 0.5 else 1.0
		var x_end: float = x1 if side > 0.0 else x0
		match r.randi_range(0, 2):
			0:
				lines.append([Vector2(stave_x, yy), Vector2(x_end, yy + h * 0.22)])
			1:
				lines.append([Vector2(stave_x, yy), Vector2(x_end, yy - h * 0.22)])
			2:
				lines.append([Vector2(stave_x, yy + h * 0.15), Vector2(x_end, yy)])
				lines.append([Vector2(x_end, yy), Vector2(stave_x, yy - h * 0.15)])
	return lines


static func _add_traits(st: SurfaceTool, lines: Array, z: float, r: float, xf: Transform3D = Transform3D.IDENTITY) -> void:
	for l in lines:
		var a: Vector2 = l[0]
		var b: Vector2 = l[1]
		_add_tube(st, [Vector3(a.x, a.y, z), Vector3(b.x, b.y, z)], [r, r], 4, 1.0, xf)


static func _commit(st: SurfaceTool) -> ArrayMesh:
	return st.commit()


static func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _boule(r: float, y: float, segs: int = 14, sy: float = 1.0) -> Array:
	var prof: Array = []
	for k in range(9):
		var a: float = -PI * 0.5 + PI * k / 8.0
		prof.append(Vector2(maxf(cos(a) * r, 0.0), y + sin(a) * r * sy))
	return prof


# =================================================================== les modèles

## Le modèle de l'arme (nœud racine prêt à poser dans la main, au sol ou en vitrine).
static func build(id: String) -> Node3D:
	if not has(id):
		return null
	var root := Node3D.new()
	root.name = "Modele_" + id
	if not _cache.has(id):
		_cache[id] = _parts(id)
	var parts: Array = _cache[id]
	var named: Dictionary = {}
	for e in parts:
		var mi := MeshInstance3D.new()
		mi.name = str(e[0])
		mi.mesh = e[1]
		mi.material_override = e[2]
		mi.transform = e[3]
		var parent: Node3D = root
		if str(e[0]) in ["Cristal_baton", "Orbite_runes"]:
			var holder_name: String = "Cristal" if str(e[0]) == "Cristal_baton" else "Orbite"
			if not named.has(holder_name):
				var h := Node3D.new()
				h.name = holder_name
				h.position = Vector3(0, 1.115, 0)
				root.add_child(h)
				named[holder_name] = h
			parent = named[holder_name]
			mi.transform = Transform3D(mi.transform.basis, mi.transform.origin - Vector3(0, 1.115, 0))
		parent.add_child(mi)
		named[str(e[0])] = mi
	var tip := Marker3D.new()
	tip.name = "Pointe"
	tip.position = TIPS[id]
	root.add_child(tip)
	_ame(root, id, named)
	return root


const TIPS := {
	"epee_bois": Vector3(0, 0.74, 0), "epee": Vector3(0, 0.82, 0), "hache": Vector3(0, 0.66, 0.19),
	"epee_naine": Vector3(0, 0.67, 0), "epee_nuees": Vector3(0, 0.98, 0), "trident_marees": Vector3(0, 1.2, 0),
	"sabre_corsaire": Vector3(0.088, 0.82, 0), "lame_coeur": Vector3(0, 1.01, 0), "baton_sorcier": Vector3(0, 1.2, 0),
}
## Bas et haut du fil (pour le reflet et les arcs), et courbure.
const FILS := {
	"epee_bois": [0.11, 0.73, 0.0], "epee": [0.11, 0.8, 0.0], "epee_naine": [0.12, 0.65, 0.0], "epee_nuees": [0.12, 0.96, 0.0],
	"sabre_corsaire": [0.13, 0.8, 0.09], "lame_coeur": [0.22, 0.99, 0.0], "hache": [0.5, 0.71, 0.0],
	"trident_marees": [0.9, 1.18, 0.0], "baton_sorcier": [1.05, 1.18, 0.0],
}


static func _parts(id: String) -> Array:
	match id:
		"epee":
			return _p_epee()
		"epee_bois":
			return _p_bois()
		"hache":
			return _p_hache()
		"epee_naine":
			return _p_naine()
		"epee_nuees":
			return _p_nuees()
		"trident_marees":
			return _p_trident()
		"sabre_corsaire":
			return _p_sabre()
		"lame_coeur":
			return _p_coeur()
		"baton_sorcier":
			return _p_baton()
	return []


static func _I() -> Transform3D:
	return Transform3D.IDENTITY


## Poignée filetée (cuir et fil), de y_a à y_b.
static func _poignee(y_a: float, y_b: float, r: float, wrap: float, turns: float) -> Array:
	var prof: Array = []
	for k in range(49):
		var u: float = float(k) / 48.0
		var y: float = lerpf(y_a, y_b, u)
		prof.append(Vector2(r * (0.92 + 0.12 * sin(u * PI)), y))
	return prof


static func _p_epee() -> Array:
	var acier := _m("v129_acier", Color(0.84, 0.86, 0.9), 0.14, 0.95, true)
	var laiton := _m("v129_laiton", Color(0.8, 0.62, 0.3), 0.26, 0.9)
	var cuir := _m("v129_cuir", Color(0.3, 0.18, 0.1), 0.8, 0.0, true)
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.1, "long": 0.72, "w0": 0.05, "w1": 0.038, "pointe": 0.2, "ep": 0.0075, "gorge": 0.65, "gorge_fin": 0.6})
	out.append(["Lame", st.commit(), acier, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.075, 0.08, 0.0148, 0.0011, 10.0), 24, 0.0011, 10.0)
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	# garde : quillons qui se relèvent un peu vers la lame, boutons au bout
	var path: Array = []
	var radii: Array = []
	for k in range(17):
		var x: float = lerpf(-0.105, 0.105, float(k) / 16.0)
		var ax: float = absf(x) / 0.105
		path.append(Vector3(x, 0.088 + 0.016 * ax * ax, 0))
		radii.append(lerpf(0.0105, 0.0062, ax))
	_add_tube(st, path, radii, 10, 0.8)
	for sx in [-1.0, 1.0]:
		_add_tour(st, _boule(0.0105, 0.0), 12, 0.0, 0.0, Transform3D(Basis(), Vector3(sx * 0.108, 0.105, 0)))
	_add_tube(st, [Vector3(0, 0.076, 0), Vector3(0, 0.104, 0)], [0.017, 0.012], 4, 0.55)
	# viroles et pommeau en roue
	_add_tour(st, [Vector2(0.0, 0.07), Vector2(0.0165, 0.07), Vector2(0.0172, 0.078), Vector2(0.0165, 0.086), Vector2(0.0, 0.086)], 16)
	_add_tour(st, [Vector2(0.0, -0.088), Vector2(0.0165, -0.088), Vector2(0.0172, -0.08), Vector2(0.0165, -0.072), Vector2(0.0, -0.072)], 16)
	var roue := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.108, 0))
	_add_tour(st, [Vector2(0.0, -0.011), Vector2(0.018, -0.011), Vector2(0.026, -0.007), Vector2(0.028, 0.0), Vector2(0.026, 0.007), Vector2(0.018, 0.011), Vector2(0.0, 0.011)], 22, 0.0, 0.0, roue)
	_add_tour(st, _boule(0.007, -0.135, 10, 0.7), 10)
	out.append(["Garde", st.commit(), laiton, _I()])
	return out


static func _p_bois() -> Array:
	var bois := _m("v129_bois_cire", Color(0.78, 0.58, 0.36), 0.55, 0.0, true)
	var fonce := _m("v129_bois_fonce", Color(0.36, 0.22, 0.12), 0.6, 0.0, true)
	var corde := _m("v129_corde", Color(0.78, 0.7, 0.54), 0.95, 0.0, true)
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.105, "long": 0.64, "w0": 0.05, "w1": 0.044, "pointe": 0.13, "ep": 0.017, "veinage": true})
	out.append(["Lame", st.commit(), bois, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.075, 0.085, 0.0155, 0.0019, 13.0), 24, 0.0019, 13.0)
	out.append(["Poignee", st.commit(), corde, _I()])
	st = _st()
	var path: Array = []
	var radii: Array = []
	for k in range(9):
		var x: float = lerpf(-0.085, 0.085, float(k) / 8.0)
		path.append(Vector3(x, 0.095, 0))
		radii.append(0.0135 - 0.003 * absf(x) / 0.085)
	_add_tube(st, path, radii, 10, 0.75)
	for sx in [-1.0, 1.0]:
		_add_tour(st, _boule(0.0105, 0.0, 10, 0.75), 10, 0.0, 0.0, Transform3D(Basis(), Vector3(sx * 0.085, 0.095, 0)))
	_add_tour(st, _boule(0.021, -0.095, 14, 0.85), 14)
	out.append(["Garde", st.commit(), fonce, _I()])
	return out


static func _p_hache() -> Array:
	var fer := _m("v129_fer_forge", Color(0.62, 0.64, 0.68), 0.32, 0.9, true)
	var frene := _m("v129_frene", Color(0.5, 0.34, 0.2), 0.6, 0.0, true)
	var cuir := _m("v129_cuir", Color(0.3, 0.18, 0.1), 0.8, 0.0, true)
	var out: Array = []
	var st := _st()
	# manche : un peu renflé vers le bas, veinage
	var prof: Array = []
	for k in range(15):
		var u: float = float(k) / 14.0
		prof.append(Vector2(0.0175 + 0.004 * sin(u * PI * 0.8) - 0.002 * u, lerpf(-0.07, 0.72, u)))
	_add_tour(st, prof, 14, 0.0, 0.0, _I(), 1.0)
	out.append(["Manche", st.commit(), frene, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.06, 0.1, 0.0205, 0.0012, 8.0), 24, 0.0012, 8.0)
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	# le fer : douille (œil), tranchant barbu en éventail, talon (marteau), languettes
	_add_tour(st, [Vector2(0.0, 0.592), Vector2(0.024, 0.592), Vector2(0.027, 0.6), Vector2(0.027, 0.672), Vector2(0.024, 0.68), Vector2(0.0, 0.68)], 14)
	var fn := func(s: float, d: float) -> Vector3:
		var ay: float = lerpf(0.672, 0.6, s)
		var ez: float = 0.172 + 0.024 * sin(PI * s) - 0.03 * s * s
		var ey: float = lerpf(0.722, 0.488, s)
		var dd: float = pow(d, 0.9)
		var y: float = lerpf(ay, ey, dd)
		y += 0.034 * sin(PI * dd) * pow(s, 3.0)
		y -= 0.009 * sin(PI * dd) * pow(1.0 - s, 3.0)
		return Vector3(0, y, lerpf(0.024, ez, dd))
	var ep := func(_s: float, d: float) -> float:
		return 0.024 * pow(1.0 - d, 1.4) + 0.0014
	var te := func(_s: float, d: float) -> float:
		return 0.62 if d < 0.8 else lerpf(0.62, 1.0, (d - 0.8) / 0.2)
	_add_nappe(st, fn, ep, Vector3.RIGHT, 12, 10, te)
	# talon (marteau)
	_add_tube(st, [Vector3(0, 0.636, -0.02), Vector3(0, 0.636, -0.05)], [0.018, 0.016], 4, 1.0)
	# languettes et rivets
	for sx in [-1.0, 1.0]:
		_add_tube(st, [Vector3(sx * 0.0195, 0.47, 0), Vector3(sx * 0.0205, 0.595, 0)], [0.0035, 0.004], 6, 0.4)
		for yy in [0.5, 0.56]:
			_add_tour(st, _boule(0.0035, 0.0, 8), 8, 0.0, 0.0, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(sx * 0.022, yy, 0)))
	_add_tour(st, [Vector2(0.0, -0.085), Vector2(0.019, -0.085), Vector2(0.021, -0.075), Vector2(0.021, -0.062), Vector2(0.0, -0.062)], 14)
	out.append(["Fer", st.commit(), fer, _I()])
	return out


static func _p_naine() -> Array:
	var acier := _m("v129_acier_nain", Color(0.76, 0.77, 0.8), 0.16, 0.92, true)
	var orm := _m("v129_or_nain", Color(0.92, 0.7, 0.28), 0.24, 0.95)
	var cuir := _m("v129_cuir", Color(0.3, 0.18, 0.1), 0.8, 0.0, true)
	var rubis := _glow("v129_rubis", Color(0.75, 0.04, 0.06), Color(0.9, 0.05, 0.05), 0.5, 0.05)
	var runes := _glow("v129_runes_forge", Color(1.0, 0.3, 0.05), Color(1.0, 0.32, 0.04), 3.2)
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.11, "long": 0.56, "w0": 0.082, "w1": 0.07, "pointe": 0.17, "ep": 0.011, "gorge": 0.55, "gorge_fin": 0.74})
	out.append(["Lame", st.commit(), acier, _I()])
	st = _st()
	for k in range(5):
		var cy: float = 0.17 + k * 0.068
		for side in [1.0, -1.0]:
			_add_traits(st, _rune_traits(k + 3, 0.0, cy, 0.024, 0.052), side * 0.0029, 0.0016)
	out.append(["Runes", st.commit(), runes, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.07, 0.08, 0.0175, 0.0013, 7.0), 24, 0.0013, 7.0)
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	# garde lourde aux cornes qui retombent vers la main, évasées au bout
	var path: Array = []
	var radii: Array = []
	for k in range(17):
		var x: float = lerpf(-0.12, 0.12, float(k) / 16.0)
		var ax: float = absf(x) / 0.12
		path.append(Vector3(x, 0.095 - 0.026 * ax * ax * ax, 0))
		radii.append(0.0115 + 0.007 * ax * ax * ax)
	_add_tube(st, path, radii, 10, 0.7)
	for sx in [-1.0, 1.0]:
		_add_tour(st, _boule(0.0175, 0.0, 12, 0.75), 12, 0.0, 0.0, Transform3D(Basis(), Vector3(sx * 0.12, 0.069, 0)))
	_add_tube(st, [Vector3(0, 0.08, 0), Vector3(0, 0.112, 0)], [0.026, 0.02], 6, 0.6)
	for yy in [-0.035, 0.0, 0.035]:
		_add_tour(st, [Vector2(0.0, yy - 0.005), Vector2(0.0195, yy - 0.005), Vector2(0.0205, yy), Vector2(0.0195, yy + 0.005), Vector2(0.0, yy + 0.005)], 14)
	_add_tour(st, [Vector2(0.0, -0.075), Vector2(0.02, -0.075), Vector2(0.026, -0.085), Vector2(0.022, -0.095), Vector2(0.0, -0.095)], 16)
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		_add_tube(st, [Vector3(cos(a) * 0.02, -0.092, sin(a) * 0.02), Vector3(cos(a) * 0.026, -0.112, sin(a) * 0.026), Vector3(cos(a) * 0.012, -0.13, sin(a) * 0.012)], [0.004, 0.0035, 0.0015], 6)
	out.append(["Garde", st.commit(), orm, _I()])
	st = _st()
	_add_gemme(st, 0.022, 0.012, 0.02, 8, Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.108, 0)))
	_add_gemme(st, 0.011, 0.005, 0.008, 8, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.096, 0.013)))
	_add_gemme(st, 0.011, 0.005, 0.008, 8, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.096, -0.013)))
	out.append(["Rubis", st.commit(), rubis, _I()])
	return out


static func _p_nuees() -> Array:
	var acier := _m("v129_acier_nuees", Color(0.86, 0.9, 0.97), 0.1, 0.96, true)
	var orb := _m("v129_or_blanc", Color(0.96, 0.86, 0.6), 0.2, 0.95, true)
	var cuir := _m("v129_cuir_bleu", Color(0.16, 0.24, 0.5), 0.6, 0.3, true)
	var saphir := _glow("v129_saphir", Color(0.12, 0.35, 0.85), Color(0.25, 0.55, 1.0), 0.9, 0.05)
	var eclair := _glow("v129_veine_eclair", Color(0.7, 0.88, 1.0), Color(0.45, 0.75, 1.0), 3.2)
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.11, "long": 0.87, "w0": 0.048, "w1": 0.032, "pointe": 0.22, "ep": 0.007, "gorge": 0.55, "gorge_fin": 0.8})
	out.append(["Lame", st.commit(), acier, _I()])
	st = _st()
	var r := RandomNumberGenerator.new()
	r.seed = 4129
	for side in [1.0, -1.0]:
		var pts: Array = []
		var rad: Array = []
		for k in range(23):
			var y: float = 0.15 + k * 0.026
			pts.append(Vector3((r.randf_range(-1.0, 1.0)) * 0.0038, y, side * 0.0022))
			rad.append(0.0011 if k % 4 else 0.0015)
		_add_tube(st, pts, rad, 4, 1.0, _I(), Callable(), false)
	out.append(["Veine", st.commit(), eclair, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.08, 0.085, 0.0145, 0.001, 14.0), 24, 0.001, 14.0)
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	# garde en ailes : cinq pennes de chaque côté, qui s'ouvrent vers la lame
	for sx in [-1.0, 1.0]:
		for k in range(5):
			var lenk: float = 0.125 - k * 0.018
			var ang: float = 0.32 + k * 0.2
			var yk: float = 0.098 - k * 0.004
			var fz: float = -0.0016 * k
			var fn := func(s2: float, d: float) -> Vector3:
				var along := Vector3(sx * cos(ang), sin(ang), 0)
				var across := Vector3(-sx * sin(ang), cos(ang), 0)
				var wid: float = 0.02 * sin(PI * minf(s2 * 0.9 + 0.08, 1.0)) * (1.0 - 0.35 * s2)
				var bendv: float = 0.025 * s2 * s2
				return Vector3(sx * 0.014, yk, fz) + along * lenk * s2 + across * ((d - 0.35) * wid + bendv)
			var ep := func(_s2: float, d: float) -> float:
				return 0.0034 * (1.0 - absf(d - 0.35) * 1.2) + 0.0008
			var te := func(s2: float, d: float) -> float:
				return 0.78 + 0.22 * (0.5 + 0.5 * sin(d * 34.0 - s2 * 9.0))
			_add_nappe(st, fn, ep, Vector3(0, 0, 1), 10, 6, te)
	_add_tube(st, [Vector3(0, 0.08, 0), Vector3(0, 0.112, 0)], [0.016, 0.012], 8, 0.7)
	_add_tour(st, [Vector2(0.0, -0.09), Vector2(0.016, -0.09), Vector2(0.0175, -0.082), Vector2(0.016, -0.075), Vector2(0.0, -0.075)], 16)
	var crois := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.107, 0))
	_add_tour(st, [Vector2(0.0, -0.007), Vector2(0.019, -0.007), Vector2(0.024, 0.0), Vector2(0.019, 0.007), Vector2(0.0, 0.007)], 18, 0.0, 0.0, crois)
	out.append(["Garde", st.commit(), orb, _I()])
	st = _st()
	_add_gemme(st, 0.012, 0.006, 0.01, 8, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.107, 0.007)))
	_add_gemme(st, 0.012, 0.006, 0.01, 8, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, -0.107, -0.007)))
	_add_gemme(st, 0.009, 0.004, 0.007, 8, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.097, 0.012)))
	_add_gemme(st, 0.009, 0.004, 0.007, 8, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.097, -0.012)))
	out.append(["Saphirs", st.commit(), saphir, _I()])
	return out


static func _p_trident() -> Array:
	var orm := _m("v129_or_atlante", Color(0.95, 0.77, 0.38), 0.22, 0.95, true)
	var nacre := _m("v129_nacre", Color(0.92, 0.94, 0.96), 0.18, 0.2, true)
	nacre.rim_enabled = true
	nacre.rim = 0.5
	nacre.rim_tint = 0.8
	var pierre := _glow("v129_pierre_mer", Color(0.3, 0.9, 1.0), Color(0.25, 0.9, 1.0), 2.0, 0.05)
	var out: Array = []
	var st := _st()
	_add_tour(st, [Vector2(0.0, -0.31), Vector2(0.004, -0.29), Vector2(0.012, -0.25), Vector2(0.017, -0.215), Vector2(0.0145, -0.2)], 12)
	var prof: Array = []
	for k in range(25):
		prof.append(Vector2(0.0145, lerpf(-0.2, 0.84, float(k) / 24.0)))
	_add_tour(st, prof, 14, 0.0, 0.0)
	for yy in [-0.12, 0.12, 0.5, 0.78]:
		_add_tour(st, [Vector2(0.0145, yy - 0.012), Vector2(0.019, yy - 0.006), Vector2(0.02, yy), Vector2(0.019, yy + 0.006), Vector2(0.0145, yy + 0.012)], 14)
	# couronne de la tête, et les trois dents (barbelures)
	_add_tour(st, [Vector2(0.014, 0.82), Vector2(0.024, 0.84), Vector2(0.03, 0.87), Vector2(0.026, 0.9), Vector2(0.016, 0.91), Vector2(0.0, 0.91)], 16)
	_add_tube(st, [Vector3(0, 0.9, 0), Vector3(0, 1.0, 0), Vector3(0, 1.12, 0)], [0.011, 0.009, 0.006], 8)
	_add_tour(st, [Vector2(0.0, 1.115), Vector2(0.016, 1.13), Vector2(0.012, 1.16), Vector2(0.0, 1.205)], 4)
	for sx in [-1.0, 1.0]:
		var pth: Array = []
		var rr: Array = []
		for i in range(11):
			var u: float = float(i) / 10.0
			var x: float = sx * (0.02 + 0.085 * sin(minf(u * 1.7, 1.0) * PI * 0.5))
			pth.append(Vector3(x, 0.88 + 0.22 * u, 0))
			rr.append(lerpf(0.01, 0.0055, u))
		_add_tube(st, pth, rr, 8)
		_add_tour(st, [Vector2(0.0, 1.095), Vector2(0.013, 1.11), Vector2(0.009, 1.135), Vector2(0.0, 1.17)], 4, 0.0, 0.0, Transform3D(Basis(), Vector3(sx * 0.105, 0, 0)))
		# barbelure vers l'intérieur
		_add_tube(st, [Vector3(sx * 0.1, 1.12, 0), Vector3(sx * 0.082, 1.095, 0)], [0.005, 0.0005], 6)
		# volute de vague à la base de la dent
		var vol: Array = []
		var vr: Array = []
		for i in range(10):
			var a: float = i * 0.62
			var rad: float = 0.022 * (1.0 - i / 12.0)
			vol.append(Vector3(sx * (0.035 + cos(a) * rad), 0.9 + sin(a) * rad, 0))
			vr.append(lerpf(0.005, 0.002, i / 9.0))
		_add_tube(st, vol, vr, 6)
	_add_tube(st, [Vector3(0, 1.12, 0), Vector3(0, 1.095, 0.0)], [0.004, 0.0005], 6)
	out.append(["Or", st.commit(), orm, _I()])
	st = _st()
	# bandes de nacre en spirale sur la hampe (là où la main tient)
	var pn: Array = []
	for k in range(17):
		pn.append(Vector2(0.0152, lerpf(-0.1, 0.11, float(k) / 16.0)))
	_add_tour(st, pn, 24, 0.0012, 5.0)
	_add_tour(st, _boule(0.017, 0.87, 12), 12)
	out.append(["Nacre", st.commit(), nacre, _I()])
	st = _st()
	_add_gemme(st, 0.019, 0.009, 0.014, 10, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.868, 0.026)))
	_add_gemme(st, 0.019, 0.009, 0.014, 10, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.868, -0.026)))
	out.append(["Pierre", st.commit(), pierre, _I()])
	return out


static func _p_sabre() -> Array:
	var bleui := _m("v129_acier_bleui", Color(0.6, 0.66, 0.78), 0.2, 0.9, true)
	var laiton := _m("v129_laiton_coquille", Color(0.82, 0.62, 0.28), 0.28, 0.9)
	laiton.cull_mode = BaseMaterial3D.CULL_DISABLED
	var orm := _m("v129_or_grave", Color(1.0, 0.8, 0.36), 0.22, 1.0)
	var bois := _m("v129_ebene", Color(0.17, 0.1, 0.07), 0.45, 0.0, true)
	var drap := _m("v129_drap_rouge", Color(0.62, 0.06, 0.06), 0.85, 0.0, true)
	drap.cull_mode = BaseMaterial3D.CULL_DISABLED
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.115, "long": 0.71, "w0": 0.044, "w1": 0.038, "pointe": 0.16, "ep": 0.0078, "gorge": 0.35, "gorge_fin": 0.7, "courbe": 0.088, "un_tranchant": true})
	out.append(["Lame", st.commit(), bleui, _I()])
	st = _st()
	# rinceau gravé à l'or le long du dos, des deux côtés
	for side in [1.0, -1.0]:
		var pth: Array = []
		var rr: Array = []
		for i in range(25):
			var u: float = 0.04 + 0.55 * float(i) / 24.0
			pth.append(Vector3(0.088 * u * u + 0.011 + 0.0035 * sin(u * 60.0), 0.115 + 0.71 * u, side * 0.0036))
			rr.append(0.00085)
		_add_tube(st, pth, rr, 4, 1.0, _I(), Callable(), false)
	# coquille de laiton (tournée vers la main) et pommeau
	out.append(["Gravure", st.commit(), orm, _I()])
	st = _st()
	_add_tour(st, [Vector2(0.015, 0.118), Vector2(0.034, 0.112), Vector2(0.05, 0.1), Vector2(0.058, 0.086), Vector2(0.06, 0.078)], 26, 0.0, 0.0, Transform3D(Basis(), Vector3(0, 0, 0.004)))
	_add_tour(st, [Vector2(0.0, 0.096), Vector2(0.016, 0.096), Vector2(0.018, 0.106), Vector2(0.016, 0.116), Vector2(0.0, 0.116)], 14)
	var arc: Array = []
	var ar: Array = []
	for i in range(13):
		var u: float = float(i) / 12.0
		arc.append(Vector3(-0.056 + 0.05 * u * u, lerpf(0.082, -0.085, u), 0.0) + Vector3(-0.012 * sin(u * PI), 0, 0))
		ar.append(0.0042)
	_add_tube(st, arc, ar, 8)
	_add_tour(st, [Vector2(0.0, -0.105), Vector2(0.008, -0.103), Vector2(0.017, -0.094), Vector2(0.018, -0.082), Vector2(0.0, -0.082)], 14)
	_add_tour(st, [Vector2(0.0, 0.068), Vector2(0.016, 0.068), Vector2(0.017, 0.076), Vector2(0.0, 0.076)], 14)
	out.append(["Garde", st.commit(), laiton, _I()])
	st = _st()
	_add_tour(st, _poignee(-0.082, 0.068, 0.0148, 0.0012, 11.0), 24, 0.0012, 11.0)
	out.append(["Poignee", st.commit(), bois, _I()])
	st = _st()
	# le ruban rouge noué sous la coquille
	for k in range(2):
		var pth: Array = []
		var rr: Array = []
		for i in range(8):
			var u: float = float(i) / 7.0
			pth.append(Vector3(0.022 + 0.018 * u + k * 0.006, 0.085 - 0.11 * u, 0.012 * sin(u * 3.0 + k)))
			rr.append(0.007)
		_add_tube(st, pth, rr, 6, 0.18)
	out.append(["Ruban", st.commit(), drap, _I()])
	return out


static func _p_coeur() -> Array:
	var cristal := _glow("v129_cristal_coeur", Color(0.85, 0.14, 0.12, 0.82), Color(1.0, 0.22, 0.08), 0.75, 0.04, 0.35)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.clearcoat_enabled = true
	cristal.clearcoat = 1.0
	cristal.rim = 0.7
	cristal.rim_tint = 0.3
	var coeur := _glow("v129_coeur_vif", Color(1.0, 0.85, 0.6), Color(1.0, 0.62, 0.3), 4.0)
	var orm := _m("v129_or_coeur", Color(1.0, 0.8, 0.38), 0.22, 1.0)
	var cuir := _m("v129_cuir_rouge", Color(0.32, 0.08, 0.06), 0.7, 0.0, true)
	var out: Array = []
	var st := _st()
	_add_lame(st, {"y0": 0.205, "long": 0.81, "w0": 0.058, "w1": 0.044, "pointe": 0.2, "ep": 0.018, "cristal": true})
	# éclats de cristal au pied de la lame
	for k in range(3):
		var a: float = TAU * k / 3.0 + 0.4
		_add_gemme(st, 0.009, 0.004, 0.03, 6, Transform3D(Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), 0.5) * Basis(Vector3.RIGHT, PI), Vector3(cos(a) * 0.018, 0.235, sin(a) * 0.018)))
	out.append(["Cristal_lame", st.commit(), cristal, _I()])
	st = _st()
	_add_tube(st, [Vector3(0, 0.23, 0), Vector3(0, 0.6, 0), Vector3(0, 0.88, 0), Vector3(0, 0.97, 0)], [0.005, 0.0042, 0.0028, 0.0006], 6)
	out.append(["Coeur", st.commit(), coeur, _I()])
	st = _st()
	# garde en cœur : deux lobes d'or autour du pied de la lame, et des quillons
	var pth: Array = []
	var rr: Array = []
	for i in range(41):
		var t: float = TAU * float(i) / 40.0
		var hx: float = 16.0 * pow(sin(t), 3.0)
		var hy: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pth.append(Vector3(hx * 0.0026, 0.2 + hy * 0.0026 - 0.01, 0))
		rr.append(0.0045)
	_add_tube(st, pth, rr, 8, 1.0, _I(), Callable(), false)
	var q: Array = []
	var qr: Array = []
	for i in range(11):
		var x: float = lerpf(-0.11, 0.11, float(i) / 10.0)
		q.append(Vector3(x, 0.205 - 0.02 * pow(absf(x) / 0.11, 2.0), 0))
		qr.append(lerpf(0.009, 0.005, absf(x) / 0.11))
	_add_tube(st, q, qr, 8, 0.8)
	_add_tour(st, [Vector2(0.0, 0.185), Vector2(0.021, 0.19), Vector2(0.024, 0.2), Vector2(0.02, 0.21), Vector2(0.0, 0.212)], 16)
	_add_tour(st, _boule(0.026, -0.012, 16), 16)
	out.append(["Garde", st.commit(), orm, _I()])
	st = _st()
	_add_tour(st, _poignee(0.01, 0.19, 0.017, 0.0012, 9.0), 24, 0.0012, 9.0)
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	_add_gemme(st, 0.012, 0.006, 0.01, 8, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.012, 0.024)))
	_add_gemme(st, 0.012, 0.006, 0.01, 8, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, -0.012, -0.024)))
	out.append(["Cristal_pommeau", st.commit(), cristal, _I()])
	return out


static func _p_baton() -> Array:
	var bois := _m("v129_bois_tors", Color(0.46, 0.31, 0.19), 0.85, 0.0, true)
	var bronze := _m("v129_bronze", Color(0.72, 0.5, 0.3), 0.3, 0.9)
	var cuir := _m("v129_cuir", Color(0.3, 0.18, 0.1), 0.8, 0.0, true)
	var cris := _glow("v129_cristal_arcane", Color(0.5, 0.28, 0.9), Color(0.55, 0.3, 1.0), 1.1, 0.04, 0.2)
	cris.clearcoat_enabled = true
	var rune := _glow("v129_runes_arcanes", Color(0.8, 0.65, 1.0), Color(0.65, 0.45, 1.0), 2.0)
	var out: Array = []
	var st := _st()
	# le bois tors : le fût ondule, tourne, avec des nœuds
	var rn := RandomNumberGenerator.new()
	rn.seed = 67
	var pth: Array = []
	var rr: Array = []
	for i in range(41):
		var u: float = float(i) / 40.0
		var y: float = lerpf(-0.14, 1.03, u)
		pth.append(Vector3(0.011 * sin(u * 9.0) + 0.006 * sin(u * 23.0), y, 0.009 * cos(u * 7.0)))
		var knot: float = 0.006 if i in [9, 21, 30] else 0.0
		rr.append(lerpf(0.017, 0.023, u) + knot + rn.randf_range(-0.0012, 0.0012))
	var grain := func(s: float, a: float) -> float:
		return 0.72 + 0.28 * (0.5 + 0.5 * sin(a * 3.0 + s * 38.0))
	_add_tube(st, pth, rr, 12, 1.0, _I(), grain)
	# la griffe : quatre doigts de bois qui tiennent le cristal
	for k in range(4):
		var a: float = TAU * k / 4.0 + 0.3
		var cl: Array = []
		var cr: Array = []
		for i in range(10):
			var u: float = float(i) / 9.0
			var rad: float = 0.02 + 0.05 * sin(u * PI * 0.85)
			cl.append(Vector3(cos(a + u * 0.6) * rad, 1.0 + 0.2 * u, sin(a + u * 0.6) * rad))
			cr.append(lerpf(0.011, 0.0025, u))
		_add_tube(st, cl, cr, 8, 1.0, _I(), grain)
	out.append(["Bois", st.commit(), bois, _I()])
	st = _st()
	for yy in [0.16, 0.74, 0.985]:
		var c: Vector3 = pth[int(round((yy + 0.14) / 1.17 * 40.0))]
		_add_tour(st, [Vector2(0.0, yy - 0.012), Vector2(0.026, yy - 0.012), Vector2(0.029, yy), Vector2(0.026, yy + 0.012), Vector2(0.0, yy + 0.012)], 14, 0.0, 0.0, Transform3D(Basis(), Vector3(c.x, 0, c.z)))
	_add_tour(st, [Vector2(0.0, -0.17), Vector2(0.012, -0.165), Vector2(0.02, -0.15), Vector2(0.021, -0.135), Vector2(0.0, -0.135)], 12, 0.0, 0.0, Transform3D(Basis(), Vector3((pth[0] as Vector3).x, 0, (pth[0] as Vector3).z)))
	out.append(["Bronze", st.commit(), bronze, _I()])
	st = _st()
	var c0: Vector3 = pth[5]
	_add_tour(st, _poignee(-0.06, 0.12, 0.0205, 0.0013, 7.0), 24, 0.0013, 7.0, Transform3D(Basis(), Vector3(c0.x, 0, c0.z)))
	out.append(["Poignee", st.commit(), cuir, _I()])
	st = _st()
	_add_gemme(st, 0.032, 0.07, 0.055, 8, Transform3D(Basis(), Vector3(0, 1.115, 0)))
	out.append(["Cristal_baton", st.commit(), cris, _I()])
	st = _st()
	for k in range(8):
		var a: float = TAU * k / 8.0
		var lines: Array = _rune_traits(k + 40, 0.0, 0.0, 0.016, 0.026)
		var xf := Transform3D(Basis(Vector3.UP, -a + PI * 0.5), Vector3(cos(a) * 0.075, 1.115, sin(a) * 0.075))
		_add_traits(st, lines, 0.0, 0.0012, xf)
	out.append(["Orbite_runes", st.commit(), rune, _I()])
	return out


# =================================================================== l'âme

static func _ame(root: Node3D, id: String, named: Dictionary) -> void:
	var a: Dictionary = ame(id)
	var node := Ame.new()
	node.name = "Ame_v129"
	node.genre = str(a["genre"])
	node.couleur = a["c"]
	node.couleur2 = a["c2"]
	node.arme = id
	var fil: Array = FILS.get(id, [0.1, 0.8, 0.0])
	node.fil_bas = float(fil[0])
	node.fil_haut = float(fil[1])
	node.courbe = float(fil[2])
	root.add_child(node)
	match id:
		"epee_naine":
			node.pulse = [named.get("Runes")]
			node.mode = "souffle"
			_particules(root, a["c"], Vector3(0.03, 0.26, 0.004), Vector3(0, 0.38, 0), 7, 1.6, Vector3(0, 0.35, 0), 0.016)
		"epee_nuees":
			node.pulse = [named.get("Veine")]
			node.mode = "eclair"
			_particules(root, a["c2"], Vector3(0.022, 0.4, 0.003), Vector3(0, 0.55, 0), 6, 0.5, Vector3.ZERO, 0.012)
			node.lumiere = _lumiere(root, a["c"], Vector3(0, 0.6, 0), 1.4, 0.0)
		"trident_marees":
			node.pulse = [named.get("Pierre")]
			node.mode = "vague"
			_particules(root, a["c2"], Vector3(0.1, 0.06, 0.01), Vector3(0, 1.05, 0), 5, 1.1, Vector3(0, -1.6, 0), 0.012)
		"lame_coeur":
			node.pulse = [named.get("Cristal_lame"), named.get("Coeur"), named.get("Cristal_pommeau")]
			node.mode = "coeur"
			_particules(root, a["c2"], Vector3(0.025, 0.36, 0.008), Vector3(0, 0.6, 0), 6, 1.4, Vector3(0, 0.25, 0), 0.012)
			node.lumiere = _lumiere(root, a["c"], Vector3(0, 0.55, 0), 1.6, 0.35)
		"baton_sorcier":
			node.pulse = [named.get("Cristal_baton"), named.get("Orbite_runes")]
			node.mode = "arcane"
			node.cristal = root.get_node_or_null("Cristal")
			node.orbite = root.get_node_or_null("Orbite")
			_particules(root, a["c"], Vector3(0.05, 0.05, 0.05), Vector3(0, 1.115, 0), 8, 1.3, Vector3(0, 0.15, 0), 0.014)
			node.lumiere = _lumiere(root, a["c"], Vector3(0, 1.115, 0), 1.6, 0.3)
	if id in ["epee", "hache", "sabre_corsaire", "epee_naine", "epee_nuees", "lame_coeur"]:
		node.reflet = _reflet(root)


static func _particules(root: Node3D, col: Color, box: Vector3, at: Vector3, amount: int, life: float, grav: Vector3, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Particules_ame"
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.position = at
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = box
	p.gravity = grav
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.06
	p.direction = Vector3.UP
	p.spread = 180.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var cr := Curve.new()
	cr.add_point(Vector2(0, 0.2))
	cr.add_point(Vector2(0.2, 1.0))
	cr.add_point(Vector2(1, 0))
	p.scale_amount_curve = cr
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r, col.g, col.b, 1.0)
	m.albedo_texture = dot()
	q.material = m
	p.mesh = q
	root.add_child(p)
	return p


static func _lumiere(root: Node3D, col: Color, at: Vector3, rng: float, energy: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "Lueur_ame"
	l.light_color = col
	l.omni_range = rng
	l.light_energy = energy
	l.shadow_enabled = false
	l.position = at
	root.add_child(l)
	return l


static func _reflet(root: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Reflet"
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1, 1, 1, 0)
	m.albedo_texture = dot()
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	root.add_child(mi)
	return mi

extends Node3D
## V100 : le Village des Arbres-Maisons, dans la Clairière des Géants de l'Île Crayonnée.
## Quatre chênes géants (30 à 40 m) font le tour de la clairière, autour de la Palette de pierre.
## Dans chacun, à 8 à 11 m du sol, une plate-forme ronde en planches et une maison ronde (murs en
## planches, toit pointu en bardeaux, porte en arc, fenêtres rondes, jardinière, cheminée).
## On y monte par un escalier qui tourne autour du tronc et ressort par une trappe dans le
## plancher ; quatre passerelles de corde relient les plates-formes (la dernière passe au-dessus
## de l'entrée du village). Le Grand-Chêne porte la Maison du Conseil et, encore plus haut, le
## Belvédère des Couleurs, d'où l'on voit toute l'île.
## Comme tout le reste de l'île, le village est en noir et blanc (crayon_v99 convertit ses
## matériaux) ; les habitants, partis chercher leurs couleurs, arrivent avec la V101.

const IleScript = preload("res://scripts/ile_crayon_v99.gd")
const Kit = preload("res://scripts/pasta_kit_v97.gd")
const Flora = preload("res://scripts/flora_v25.gd")
const Decor = preload("res://scripts/decor_v53.gd")

## Les chênes géants : [id, nom, maison, angle autour du centre de la clairière (degrés, repère île),
## distance au centre, rayon du pied, hauteur, hauteur de la plate-forme, rayon de la maison]
## Les trois sorties de la clairière (vers la plage à 67°, le bois à 176°, le mont à 251°) passent
## entre les arbres.
const ARBRES := [
	["pinceau", "le Chêne-Pinceau", "Maison Pinceau", 20.0, 21.0, 2.3, 31.0, 8.5, 2.2],
	["grand", "le Grand-Chêne", "Maison du Conseil", 300.0, 23.0, 3.0, 40.0, 11.0, 2.6],
	["gomme", "le Chêne-Gomme", "Maison Gomme", 213.0, 21.0, 2.4, 33.0, 9.5, 2.2],
	["buvard", "le Chêne-Buvard", "Maison Buvard", 120.0, 21.0, 2.2, 30.0, 8.0, 2.2],
]
const BELVEDERE_H: float = 19.5
const HATCH: float = PI * 0.65           # la trappe : un tiers de tour, au-dessus de la fin de l'escalier
const RING: float = 1.9                  # la largeur de l'anneau intérieur (où débouche l'escalier)
const SECTORS: int = 36

var ile: Node3D
var pc: bool = true
var arbres: Array = []                   # Dictionary par arbre (voir _make_tree_info)
var ponts: Array = []                    # {"a", "b", "mid": Vector3}
var belvedere := Vector3.ZERO            # le milieu du Belvédère (monde)
var conseil := Vector3.ZERO              # devant la porte de la Maison du Conseil
var centre := Vector3.ZERO               # le centre de la clairière (au sol)
var avoid: Array = []                    # [Vector2 monde, rayon] : là où la végétation ne pousse pas
var carte: Array = []                    # pour la carte de l'archipel : [x, z, rayon du feuillage]
var _cols: StaticBody3D
var _rng := RandomNumberGenerator.new()


static func _materials() -> void:
	var cache: Dictionary = Kit.Batch._mcache
	if cache.has("bardeaux"):
		return
	var roof: StandardMaterial3D = (Decor.planks(Color(0.52, 0.34, 0.25)) as StandardMaterial3D).duplicate()
	roof.set_meta("crayon", 5)
	cache["bardeaux"] = roof
	var under: StandardMaterial3D = (Decor.planks(Color(0.8, 0.7, 0.58)) as StandardMaterial3D).duplicate()
	under.set_meta("crayon", 6)          # le dessous des plates-formes : un trait plus léger
	cache["dessous"] = under
	var door: StandardMaterial3D = (Decor.wood(Color(0.5, 0.32, 0.2)) as StandardMaterial3D).duplicate()
	door.set_meta("crayon", 5)
	cache["porte"] = door
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(0.7, 0.58, 0.4)
	rope.roughness = 1.0
	rope.set_meta("crayon", 0)
	cache["corde"] = rope
	for k in [["fleur_rouge", Color(0.85, 0.12, 0.1)], ["fleur_jaune", Color(0.96, 0.78, 0.12)], ["fleur_bleue", Color(0.2, 0.38, 0.85)]]:
		var f := StandardMaterial3D.new()
		f.albedo_color = k[1]
		f.roughness = 0.8
		f.set_meta("crayon", 6)
		cache[str(k[0])] = f
	var flag := StandardMaterial3D.new()
	flag.albedo_color = Color(0.92, 0.9, 0.85)
	flag.roughness = 0.95
	flag.cull_mode = BaseMaterial3D.CULL_DISABLED
	flag.set_meta("crayon", 0)
	cache["fanion"] = flag


static func dir(a: float) -> Vector3:
	return Vector3(cos(a), 0.0, sin(a))


static func angdist(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


## a est-il dans l'arc qui va de a0 à a1 (dans le sens des angles croissants) ?
static func in_arc(a: float, a0: float, a1: float) -> bool:
	return wrapf(a - a0, 0.0, TAU) <= wrapf(a1 - a0, 0.0, TAU)


# =================================================================== la forme d'un chêne géant

## Le rayon du tronc à la hauteur y (sans les bosses ni l'empattement).
func rc(t: Dictionary, y: float) -> float:
	var rb: float = t["rb"]
	var ht: float = t["ht"]
	if y <= ht:
		return rb * (1.0 - 0.42 * y / ht)
	return lerpf(rb * 0.58, 0.22, clampf((y - ht) / (float(t["h"]) * 0.9 - ht), 0.0, 1.0))


## L'empattement du pied (tout autour).
func flare(t: Dictionary, y: float) -> float:
	return float(t["rb"]) * 0.35 * exp(-maxf(y, 0.0) / 1.6)


## Le rayon extérieur maximal (bosses comprises, sans les contreforts) : ce qu'il faut contourner.
func r_max(t: Dictionary, y: float) -> float:
	return rc(t, y) * 1.1 + flare(t, y)


## Le rayon du milieu des marches.
func r_stairs(t: Dictionary, y: float) -> float:
	return r_max(t, y) + 1.0


## Les contreforts (les grosses racines du pied) : pas là où l'escalier commence.
func _buttress(t: Dictionary, y: float, a: float) -> float:
	var w: float = 1.0
	for st in t["escaliers_sol"]:
		w = minf(w, smoothstep(0.55, 1.0, angdist(a, float(st))))
	return float(t["rb"]) * 0.55 * exp(-maxf(y, 0.0) / 2.0) * pow(maxf(0.0, cos(5.0 * (a - float(t["s3"])))), 4.0) * w


func _radius(t: Dictionary, y: float, a: float) -> float:
	var s1: float = t["s1"]
	return rc(t, y) * (1.0 + 0.06 * sin(3.0 * a + s1) + 0.035 * sin(7.0 * a + s1 * 2.3)) + flare(t, y) + _buttress(t, y, a)


static func _tri(st: SurfaceTool, p: Array, n: Array, uv: Array, flex: float, outer: float) -> void:
	var face: Vector3 = ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
	var navg: Vector3 = (n[0] as Vector3) + (n[1] as Vector3) + (n[2] as Vector3)
	var order: Array = [0, 2, 1] if face.dot(navg) > 0.0 else [0, 1, 2]
	for k in order:
		st.set_color(Color.WHITE)
		st.set_normal(n[k])
		st.set_uv(uv[k])
		st.set_uv2(Vector2(flex, outer))
		st.add_vertex(p[k])


## Un tube d'écorce le long d'un chemin (racine, branche) ; uv en mètres (l'écorce garde sa taille).
static func _bark_tube(st: SurfaceTool, path: Array, radii: Array, flex: Array, sides: int) -> void:
	var rings: Array = []
	var along: float = 0.0
	var prev_x := Vector3.ZERO
	for i in range(path.size()):
		var f: Vector3 = ((path[mini(i + 1, path.size() - 1)] as Vector3) - (path[maxi(i - 1, 0)] as Vector3)).normalized()
		var x: Vector3
		if i == 0:
			x = f.cross(Vector3.UP if absf(f.y) < 0.95 else Vector3.RIGHT).normalized()
		else:
			x = (prev_x - f * prev_x.dot(f)).normalized()
		prev_x = x
		var y: Vector3 = f.cross(x).normalized()
		if i > 0:
			along += (path[i] as Vector3).distance_to(path[i - 1])
		var ring: Array = []
		var circ: float = TAU * float(radii[i])
		for s in range(sides + 1):
			var a: float = TAU * float(s) / float(sides)
			var n: Vector3 = (x * cos(a) + y * sin(a)).normalized()
			ring.append([(path[i] as Vector3) + n * float(radii[i]), n, Vector2(float(s) / float(sides) * maxf(1.0, round(circ / 1.7)), along * 0.55), float(flex[i])])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a0: Array = rings[i][s]
			var b0: Array = rings[i][s + 1]
			var c0: Array = rings[i + 1][s]
			var d0: Array = rings[i + 1][s + 1]
			_tri(st, [a0[0], c0[0], b0[0]], [a0[1], c0[1], b0[1]], [a0[2], c0[2], b0[2]], float(a0[3]), 0.6)
			_tri(st, [b0[0], c0[0], d0[0]], [b0[1], c0[1], d0[1]], [b0[2], c0[2], d0[2]], float(b0[3]), 0.6)


## Le chêne géant (repère local : le pied au sol en 0).
func _tree_mesh(t: Dictionary) -> ArrayMesh:
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["seed"])
	var h: float = t["h"]
	var top: float = h * 0.9
	# ---- le tronc : des anneaux, plus serrés au pied (l'empattement, les contreforts)
	var sides: int = 30
	var ys: Array = []
	var y: float = -0.8
	while y < top:
		ys.append(y)
		y += 0.45 if y < 3.0 else (1.2 if y < float(t["ht"]) else 1.8)
	ys.append(top)
	var utile: float = maxf(4.0, round(TAU * float(t["rb"]) / 1.7))
	var rings: Array = []
	for yy in ys:
		var yv: float = float(yy)
		var ring: Array = []
		var dr: float = (_radius(t, yv + 0.2, 0.0) - _radius(t, yv - 0.2, 0.0)) / 0.4
		for s in range(sides + 1):
			var a: float = TAU * float(s) / float(sides)
			var r: float = _radius(t, yv, a)
			var radial: Vector3 = dir(a)
			var n: Vector3 = (radial - Vector3.UP * dr).normalized()
			var flex: float = clampf((yv - float(t["ht"])) / (top - float(t["ht"])), 0.0, 1.0) * 0.05
			ring.append([radial * r + Vector3.UP * yv, n, Vector2(float(s) / float(sides) * utile, yv * 0.55), flex])
		rings.append(ring)
	for i in range(rings.size() - 1):
		for s in range(sides):
			var a0: Array = rings[i][s]
			var b0: Array = rings[i][s + 1]
			var c0: Array = rings[i + 1][s]
			var d0: Array = rings[i + 1][s + 1]
			_tri(bark, [a0[0], c0[0], b0[0]], [a0[1], c0[1], b0[1]], [a0[2], c0[2], b0[2]], float(a0[3]), 0.6)
			_tri(bark, [b0[0], c0[0], d0[0]], [b0[1], c0[1], d0[1]], [b0[2], c0[2], d0[2]], float(b0[3]), 0.6)
	# ---- les racines, qui sortent des contreforts et plongent dans l'herbe
	for k in range(5):
		var a: float = float(t["s3"]) + TAU * float(k) / 5.0 + rng.randf_range(-0.12, 0.12)
		var ok: bool = true
		for st in t["escaliers_sol"]:
			if angdist(a, float(st)) < 0.95:
				ok = false
		if not ok:
			continue
		var reach: float = float(t["rb"]) * rng.randf_range(1.6, 2.1)
		var path: Array = []
		var radii: Array = []
		var flex: Array = []
		var side: Vector3 = dir(a + PI * 0.5)
		for j in range(7):
			var u: float = float(j) / 6.0
			var d: float = float(t["rb"]) * 0.8 + reach * u
			var yy2: float = 1.3 * pow(1.0 - u, 1.6) - 0.35 * u
			path.append(dir(a) * d + Vector3.UP * yy2 + side * sin(u * 3.0 + k) * 0.35)
			radii.append(lerpf(float(t["rb"]) * 0.32, 0.1, pow(u, 0.8)))
			flex.append(0.0)
		_bark_tube(bark, path, radii, flex, 10)
	# ---- les charpentières : de grosses branches qui montent en s'écartant
	var n_br: int = 8 if str(t["id"]) == "grand" else 7
	var tips: Array = []
	var crown_c := Vector3.UP * h * 0.76
	var crown_r: float = h * 0.36
	for b in range(n_br):
		var y0: float = h * rng.randf_range(0.6, 0.82)
		var a: float = TAU * float(b) / float(n_br) + rng.randf_range(-0.3, 0.3) + float(t["s1"])
		var d: Vector3 = (dir(a) + Vector3.UP * rng.randf_range(0.35, 0.75)).normalized()
		var bl: float = h * rng.randf_range(0.3, 0.4)
		var start: Vector3 = Vector3.UP * y0
		var path: Array = []
		var radii: Array = []
		var flex: Array = []
		var r0: float = rc(t, y0) * 0.45
		for j in range(7):
			var u: float = float(j) / 6.0
			var p: Vector3 = start + d * bl * u + Vector3.UP * u * u * bl * 0.18 + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)) * u
			path.append(p)
			radii.append(lerpf(r0, 0.14, pow(u, 0.9)))
			flex.append(u * u * 0.12)
		_bark_tube(bark, path, radii, flex, 10)
		tips.append([path, bl])
		# deux rameaux par charpentière
		for sgn in [-1.0, 1.0]:
			var j0: int = rng.randi_range(2, 4)
			var o: Vector3 = path[j0]
			var d2: Vector3 = (dir(a + sgn * rng.randf_range(0.5, 0.9)) + Vector3.UP * rng.randf_range(0.5, 1.0)).normalized()
			var l2: float = bl * rng.randf_range(0.38, 0.5)
			var p2: Array = []
			var r2: Array = []
			var f2: Array = []
			for j2 in range(5):
				var u2: float = float(j2) / 4.0
				p2.append(o + d2 * l2 * u2 + Vector3.DOWN * u2 * u2 * l2 * 0.1)
				r2.append(lerpf(float(radii[j0]) * 0.6, 0.06, u2))
				f2.append(0.1 + u2 * 0.3)
			_bark_tube(bark, p2, r2, f2, 7)
			tips.append([p2, l2])
	# ---- le feuillage : des grappes de feuilles au bout des branches et des rameaux
	var budget: int = int((1900.0 if str(t["id"]) == "grand" else 1400.0) * (1.0 if pc else 0.6))
	var per: int = int(budget * 0.85) / tips.size()
	for tp in tips:
		var path: Array = tp[0]
		var bl2: float = tp[1]
		for c in range(per):
			var u: float = rng.randf_range(0.45, 1.0)
			var seg: float = u * float(path.size() - 1)
			var i0: int = mini(int(seg), path.size() - 2)
			var base: Vector3 = (path[i0] as Vector3).lerp(path[i0 + 1], seg - float(i0))
			var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.55, 1.0), rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.3, maxf(1.6, bl2 * 0.28))
			Flora._card(leaves, base + off, rng.randf_range(2.2, 3.3), Flora._random_basis(rng), crown_c, crown_r, 0.55 + 0.4 * u)
	for c in range(int(budget * 0.15)):
		var p: Vector3 = Vector3.UP * top + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.8), rng.randf_range(-1, 1)) * crown_r * 0.5
		Flora._card(leaves, p, rng.randf_range(2.2, 3.0), Flora._random_basis(rng), crown_c, crown_r, 0.8)
	var mesh := ArrayMesh.new()
	bark.commit(mesh)
	leaves.commit(mesh)
	mesh.surface_set_material(0, Flora.bark_material())
	mesh.surface_set_material(1, Flora.leaf_material())
	return mesh


# =================================================================== les collisions

func _body() -> StaticBody3D:
	if _cols == null:
		_cols = StaticBody3D.new()
		_cols.name = "Village_collisions_v100"
		_cols.collision_layer = 1
		_cols.collision_mask = 0
		add_child(_cols)
	return _cols


func _box_col(xf: Transform3D, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_body().add_child(cs)
	cs.global_transform = xf


## Une forme convexe exacte (les points en coordonnées monde).
func _hull_col(pts: Array) -> void:
	var cs := CollisionShape3D.new()
	var sh := ConvexPolygonShape3D.new()
	sh.points = PackedVector3Array(pts)
	cs.shape = sh
	_body().add_child(cs)


func _cyl_col(at: Vector3, r: float, hgt: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = hgt
	cs.shape = sh
	_body().add_child(cs)
	cs.global_position = at + Vector3.UP * hgt * 0.5


## Une boîte posée « à plat » dans un secteur d'anneau, local x vers l'extérieur.
## (y : hauteur absolue ; c : seul son x, z compte)
static func _sector_xf(c: Vector3, a: float, r: float, y: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, -a), Vector3(c.x, 0.0, c.z) + dir(a) * r + Vector3.UP * y)


# =================================================================== les plates-formes

## Une plate-forme en planches autour du tronc. hatch_end : où finit l'escalier qui y débouche
## (la trappe couvre le quart de tour d'avant) ; openings : les angles des passerelles ;
## house : [angle, demi-ouverture] (pas de garde-corps derrière la maison).
func _deck(b: Kit.Batch, t: Dictionary, top: float, r_out: float, hatch_end: float, openings: Array, house: Array) -> void:
	var c: Vector3 = t["c"]
	var y: float = c.y + top
	c.y = 0.0                              # c : le centre du tronc au niveau 0 (y est absolu)
	var r_in: float = r_max(t, top) + 0.02
	var r_mid: float = r_in + RING
	var hatch0: float = hatch_end - HATCH
	for k in range(SECTORS):
		var a0: float = TAU * float(k) / SECTORS
		var a1: float = TAU * float(k + 1) / SECTORS
		var am: float = (a0 + a1) * 0.5
		var hole: bool = in_arc(am, hatch0, hatch_end)
		var rs: Array = [[r_mid, r_out]] if hole else [[r_in, r_out]]
		for part in rs:
			var ra: float = part[0]
			var rb2: float = part[1]
			_slab(b, c, a0, a1, ra, rb2, y, 0.24)
			# la collision : le secteur exact (pas de bord qui dépasse dans la trappe)
			var hp: Array = []
			for rr in [ra, rb2]:
				for aa in [a0, a1]:
					for yy in [y, y - 0.24]:
						hp.append(c + dir(aa) * float(rr) + Vector3.UP * float(yy))
			if rb2 - ra > 2.5:
				for yy2 in [y, y - 0.24]:
					hp.append(c + dir(am) * rb2 + Vector3.UP * float(yy2))
			_hull_col(hp)
		# le garde-corps du bord
		var open: bool = false
		for op in openings:
			if angdist(am, float(op)) < 0.85 / r_out + PI / SECTORS:
				open = true
		if not house.is_empty() and angdist(am, float(house[0])) < float(house[1]):
			open = true
		if not open:
			_rail_arc(b, c, a0, a1, r_out - 0.08, y)
		# le garde-corps autour de la trappe
		if hole:
			_rail_arc(b, c, a0, a1, r_mid + 0.06, y)
	# le bout de la trappe, du côté où l'escalier passe en dessous
	var p0: Vector3 = c + dir(hatch0) * (r_in + 0.1) + Vector3.UP * y
	var p1: Vector3 = c + dir(hatch0) * (r_mid + 0.06) + Vector3.UP * y
	_rail_line(b, p0, p1)
	# les jambes de force, sous le plancher (pas au-dessus de l'escalier)
	for k2 in range(8):
		var a2: float = TAU * float(k2) / 8.0 + 0.2
		# pas là où l'escalier passe sous le plancher (ses 3,5 derniers mètres)
		if in_arc(a2, hatch_end - 2.7, hatch_end + 0.15):
			continue
		var yb: float = top - 3.2
		b.tube("bois", c + dir(a2) * rc(t, yb) * 0.9 + Vector3.UP * (y - 3.2), c + dir(a2) * (r_out - 0.5) + Vector3.UP * (y - 0.24), 0.13, 7)
	# la ceinture : une poutre qui fait le tour, contre le tronc
	b.cyl("bois", Transform3D(Basis(), c + Vector3.UP * (y - 0.5)), r_in + 0.12, r_in + 0.12, 0.3, 28, false)


## Un morceau d'anneau en planches (le dessus, le dessous, les deux chants).
func _slab(b: Kit.Batch, c: Vector3, a0: float, a1: float, ra: float, rb2: float, y: float, th: float) -> void:
	var up := Vector3.UP
	var pa0: Vector3 = c + dir(a0) * ra
	var pa1: Vector3 = c + dir(a1) * ra
	var pb0: Vector3 = c + dir(a0) * rb2
	var pb1: Vector3 = c + dir(a1) * rb2
	var u0: float = a0 * rb2
	var u1: float = a1 * rb2
	var yt := up * y
	var yb := up * (y - th)
	b.quad("planches", pa0 + yt, pb0 + yt, pb1 + yt, pa1 + yt, up, Vector2(u0, ra), Vector2(u0, rb2), Vector2(u1, rb2), Vector2(u1, ra))
	b.quad("dessous", pa0 + yb, pa1 + yb, pb1 + yb, pb0 + yb, -up, Vector2(u0, ra), Vector2(u1, ra), Vector2(u1, rb2), Vector2(u0, rb2))
	var no: Vector3 = dir((a0 + a1) * 0.5)
	b.quad("bois", pb0 + yb, pb1 + yb, pb1 + yt, pb0 + yt, no, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, th), Vector2(u0, th))
	b.quad("bois", pa0 + yb, pa0 + yt, pa1 + yt, pa1 + yb, -no, Vector2(u0, 0), Vector2(u0, th), Vector2(u1, th), Vector2(u1, 0))


func _rail_arc(b: Kit.Batch, c: Vector3, a0: float, a1: float, r: float, y: float) -> void:
	var p0: Vector3 = c + dir(a0) * r + Vector3.UP * y
	var p1: Vector3 = c + dir(a1) * r + Vector3.UP * y
	_rail_line(b, p0, p1)


## Un bout de garde-corps de p0 à p1 (au niveau du plancher) : un poteau, deux lisses, sa collision.
func _rail_line(b: Kit.Batch, p0: Vector3, p1: Vector3) -> void:
	b.tube("bois", p0, p0 + Vector3.UP * 1.08, 0.055, 6, true)
	b.tube("bois", p0 + Vector3.UP * 1.02, p1 + Vector3.UP * 1.02, 0.045, 6)
	b.tube("bois", p0 + Vector3.UP * 0.55, p1 + Vector3.UP * 0.55, 0.03, 5)
	var d: Vector3 = p1 - p0
	var l: float = d.length()
	if l < 0.05:
		return
	var z: Vector3 = d / l
	var x: Vector3 = Vector3.UP.cross(z).normalized()
	_box_col(Transform3D(Basis(x, Vector3.UP, z), (p0 + p1) * 0.5 + Vector3.UP * 0.6), Vector3(0.1, 1.2, l + 0.04))


# =================================================================== les escaliers

## Un escalier qui tourne autour du tronc (sens des angles croissants), de y0 à y1 (au-dessus du
## sol de l'arbre), et arrive à l'angle a_end.
func _stairs(b: Kit.Batch, t: Dictionary, y0: float, y1: float, a_end: float, turns: float) -> void:
	var c: Vector3 = t["c"]
	var g: float = c.y
	c.y = 0.0
	var n: int = int(ceil((y1 - y0) / 0.2))
	var dh: float = (y1 - y0) / float(n)
	var span: float = turns * TAU
	var da: float = span / float(n)
	var a_start: float = a_end - span
	var rail_pts: Array = []
	for i in range(n):
		var am: float = a_start + (float(i) + 0.5) * da
		var top: float = y0 + dh * float(i + 1)
		var rs: float = r_stairs(t, top)
		var arc: float = rs * da
		# la marche : une planche épaisse, plantée dans le tronc
		var xf: Transform3D = _sector_xf(c, am, rs - 0.05, g + top - 0.05)
		b.box("planches", xf, Vector3(1.4, 0.1, arc * 0.9))
		b.box("bois", _sector_xf(c, am, rs - 0.55, g + top - 0.2), Vector3(0.5, 0.2, 0.16))
		# la collision : une rampe continue et sans marche (des morceaux d'hélice exacts, qui se
		# touchent bord à bord) ; elle passe au milieu des marches et finit à plat, au niveau du plancher
		var r_col: float = rc(t, top) * 0.97
		var r_ext: float = rs + 0.7
		var tang := Vector3(-sin(am), 0.0, cos(am))
		var pitch: float = atan(dh / (rs * da))
		var basis := Basis.from_euler(Vector3(-pitch, atan2(tang.x, tang.z), 0.0))
		var hp: Array = []
		for k2 in [i, i + 1]:
			var ak: float = a_start + float(k2) * da
			# le pied de la rampe part au ras du sol (V113 : plus de petit rebord où l'on butait)
			var hk: float = minf(y0 + dh * (float(k2) + 0.5), y1 + 0.03) if k2 > 0 else y0 - 0.02
			for rr in [r_col, r_ext]:
				hp.append(c + dir(ak) * float(rr) + Vector3.UP * (g + hk))
				hp.append(c + dir(ak) * float(rr) + Vector3.UP * (g + hk - 0.25))
		_hull_col(hp)
		# la main courante, côté vide
		var ro: float = rs + 0.62
		rail_pts.append(c + dir(am) * ro + Vector3.UP * (g + top + 0.95))
		if i % 3 == 0:
			var foot: Vector3 = c + dir(am) * ro + Vector3.UP * (g + top)
			b.tube("bois", foot, foot + Vector3.UP * 0.98, 0.045, 6, true)
		if i % 2 == 1:
			_box_col(Transform3D(basis, c + dir(am - da * 0.5) * (ro + 0.04) + Vector3.UP * (g + top + 0.5)), Vector3(0.1, 1.1, (rs + 0.66) * da * 2.0 + 0.1))
	b.noodle("bois", rail_pts, 0.045, [], 6)


# =================================================================== les passerelles

func _pont(b: Kit.Batch, pa: Vector3, pb: Vector3) -> void:
	var flat: Vector3 = (pb - pa) * Vector3(1, 0, 1)
	var span_l: float = flat.length()
	var side: Vector3 = Vector3(-flat.z, 0, flat.x).normalized()
	var sag: float = 0.035 * span_l + 0.15
	var n: int = int(span_l / 0.42)
	var pts: Array = []
	for i in range(n + 1):
		var u: float = float(i) / float(n)
		pts.append(pa.lerp(pb, u) + Vector3.DOWN * sag * sin(PI * u))
	for i in range(n):
		var q0: Vector3 = pts[i]
		var q1: Vector3 = pts[i + 1]
		var z: Vector3 = (q1 - q0).normalized()
		var x: Vector3 = side
		var y: Vector3 = z.cross(x).normalized()
		if y.y < 0.0:
			y = -y
			x = -x
		b.box("planches", Transform3D(Basis(x, y, z), (q0 + q1) * 0.5 - y * 0.03), Vector3(1.3 + (0.08 if i % 2 == 0 else 0.0), 0.06, 0.34))
	# les cordes : deux mains courantes, deux cordes porteuses, les suspentes
	for sgn in [-1.0, 1.0]:
		var rail: Array = []
		var low: Array = []
		for i2 in range(n + 1):
			var q: Vector3 = pts[i2]
			var u2: float = float(i2) / float(n)
			rail.append(q + side * 0.72 * sgn + Vector3.UP * (1.0 + 0.25 * sin(PI * u2)))
			low.append(q + side * 0.62 * sgn + Vector3.DOWN * 0.07)
		b.noodle("corde", rail, 0.035, [], 6)
		b.noodle("corde", low, 0.03, [], 5)
		for i3 in range(0, n + 1, 3):
			b.tube("corde", low[i3], rail[i3], 0.018, 4)
		# les poteaux, à chaque bout
		for e in [pa, pb]:
			var ev: Vector3 = e
			b.tube("bois", ev + side * 0.78 * sgn + Vector3.DOWN * 0.3, ev + side * 0.78 * sgn + Vector3.UP * 1.45, 0.09, 7, true)
	# la collision : un plancher en segments et deux garde-corps
	var m: int = maxi(3, n / 3)
	for k in range(m):
		var u0: float = float(k) / float(m)
		var u1: float = float(k + 1) / float(m)
		var q0b: Vector3 = pa.lerp(pb, u0) + Vector3.DOWN * sag * sin(PI * u0)
		var q1b: Vector3 = pa.lerp(pb, u1) + Vector3.DOWN * sag * sin(PI * u1)
		var z2: Vector3 = (q1b - q0b).normalized()
		var y2: Vector3 = z2.cross(side).normalized()
		var x2: Vector3 = side
		if y2.y < 0.0:
			y2 = -y2
			x2 = -x2
		var l2: float = q0b.distance_to(q1b) + 0.06
		var mid: Vector3 = (q0b + q1b) * 0.5
		_box_col(Transform3D(Basis(x2, y2, z2), mid - y2 * 0.08), Vector3(1.45, 0.16, l2))
		for sgn2 in [-1.0, 1.0]:
			_box_col(Transform3D(Basis(x2, y2, z2), mid + side * 0.76 * sgn2 + Vector3.UP * 0.6), Vector3(0.1, 1.2, l2))
	# les seuils : au bout de la passerelle, un plancher à plat qui passe sur le bord de la plate-forme
	var fl: Vector3 = (pb - pa) * Vector3(1, 0, 1)
	var dz: Vector3 = fl.normalized()
	var dxs: Vector3 = Vector3.UP.cross(dz).normalized()
	for e2 in [[pa, -dz], [pb, dz]]:
		var ep: Vector3 = e2[0]
		var inward: Vector3 = e2[1]
		_box_col(Transform3D(Basis(dxs, Vector3.UP, dz), ep + inward * 0.2 + Vector3.DOWN * 0.08), Vector3(1.45, 0.16, 0.5))
	ponts.append({"a": pa, "b": pb, "mid": (pts[n / 2] as Vector3)})


# =================================================================== les maisons

func _maison(b: Kit.Batch, t: Dictionary, center: Vector3, rr: float, nom: String) -> void:
	var up := Vector3.UP
	var axis: Vector3 = t["c"]
	var out: Vector3 = ((center - axis) * Vector3(1, 0, 1)).normalized()
	var wall_h: float = 2.8
	var roof_h: float = rr * 0.95 + 0.45
	b.cyl("planches", Transform3D(Basis(), center), rr, rr * 0.97, wall_h, 26, false)
	b.cyl("planches", Transform3D(Basis(), center + up * 0.02), rr - 0.1, rr - 0.1, 0.02, 26, true)
	b.cyl("porte", Transform3D(Basis(), center + up * (wall_h - 0.12)), rr + 0.74, rr + 0.74, 0.12, 26, false)
	b.cyl("bardeaux", Transform3D(Basis(), center + up * (wall_h - 0.02)), rr + 0.72, 0.06, roof_h, 26, true)
	b.sphere("bois", center + up * (wall_h + roof_h + 0.06), 0.15, 1.0, 6, 10)
	# la cheminée, côté extérieur
	var ch: Vector3 = center + out * rr * 0.5 + up * (wall_h + roof_h * 0.45)
	b.box("moellons", Transform3D(Basis(), ch), Vector3(0.5, 2.1, 0.5))
	b.box("moellons", Transform3D(Basis(), ch + up * 1.08), Vector3(0.66, 0.1, 0.66))
	# la porte (en arc), vers le tronc mais un peu de côté : on la voit en arrivant sur la plate-forme
	var d: Vector3 = (-out).rotated(up, 0.85)
	var x: Vector3 = up.cross(d).normalized()
	var base: Vector3 = center + d * (rr * 0.995)
	_arche(b, "bois", base + d * 0.02, x, d, 0.62, 1.38, 0.08)
	_arche(b, "porte", base + d * 0.06, x, d, 0.5, 1.3, 0.08)
	b.sphere("fer", base + up * 0.75 + d * 0.15 + x * 0.33, 0.055, 1.0, 5, 8)
	b.box("bois", Transform3D(Basis(x, up, d), base + d * 0.25 + up * 0.04), Vector3(1.3, 0.08, 0.5))
	# le nom, au-dessus de la porte
	b.box("porte", Transform3D(Basis(x, up, d), base + up * 2.2 + d * 0.06), Vector3(1.5, 0.34, 0.05))
	var lb: Label3D = Kit.label(self, nom, base + up * 2.2 + d * 0.1, d, 0.0032, Color(0.06, 0.055, 0.05))
	lb.font_size = 48
	# la lanterne, à côté de la porte
	var lp: Vector3 = base + x * 0.82 + up * 1.95 + d * 0.22
	b.tube("fer", lp + up * 0.35 - d * 0.22, lp + up * 0.35, 0.025, 5)
	b.cyl("fer", Transform3D(Basis(), lp + up * 0.2), 0.16, 0.03, 0.16, 8)
	b.cyl("fer", Transform3D(Basis(), lp - up * 0.16), 0.12, 0.12, 0.04, 8)
	b.sphere("lampe", lp, 0.1, 1.2, 5, 8)
	# les fenêtres rondes ; une jardinière sous la première
	for wi in range(3):
		var wd: Vector3 = d.rotated(up, [1.65, -1.65, PI][wi])
		var wx: Vector3 = up.cross(wd).normalized()
		var wc: Vector3 = center + wd * (rr * 0.975) + up * 1.6
		b.cyl("porte", Transform3D(Basis(wx, wd, -up), wc - wd * 0.02), 0.52, 0.52, 0.1, 18)
		b.cyl("verre", Transform3D(Basis(wx, wd, -up), wc), 0.4, 0.4, 0.12, 18)
		b.box("porte", Transform3D(Basis(wx, up, wd), wc + wd * 0.13), Vector3(0.8, 0.06, 0.04))
		b.box("porte", Transform3D(Basis(wx, up, wd), wc + wd * 0.13), Vector3(0.06, 0.8, 0.04))
		if wi == 0:
			var jb: Vector3 = wc - up * 0.66 + wd * 0.2
			b.box("porte", Transform3D(Basis(wx, up, wd), jb), Vector3(0.95, 0.22, 0.3))
			for f in range(5):
				var fp: Vector3 = jb + wx * (-0.36 + 0.18 * f) + up * 0.16
				b.sphere("feuille", fp, 0.12, 0.8, 4, 7)
				b.sphere(["fleur_rouge", "fleur_jaune", "fleur_bleue"][f % 3], fp + up * 0.1 + wd * 0.04, 0.075, 1.0, 4, 7)
	_cyl_col(center, rr + 0.02, wall_h)
	t["porte"] = base + d * 0.9


## Une porte en arc (un rectangle surmonté d'un demi-cercle), épaisse de th, posée en base,
## face vers d ; hw : la demi-largeur ; hs : la hauteur où commence l'arc.
func _arche(b: Kit.Batch, key: String, base: Vector3, x: Vector3, d: Vector3, hw: float, hs: float, th: float) -> void:
	var up := Vector3.UP
	var outline: Array = [base - x * hw, base + x * hw]
	for k in range(13):
		var a: float = PI * float(k) / 12.0
		outline.append(base + up * hs + x * (hw * cos(a)) + up * (hw * sin(a)))
	var cen: Vector3 = base + up * (hs * 0.5)
	var m: int = outline.size()
	for i in range(m):
		var p0: Vector3 = outline[i]
		var p1: Vector3 = outline[(i + 1) % m]
		b.tri(key, [cen + d * th, p0 + d * th, p1 + d * th], [d, d, d], [Vector2((cen - base).dot(x), (cen - base).y), Vector2((p0 - base).dot(x), (p0 - base).y), Vector2((p1 - base).dot(x), (p1 - base).y)])
		var sn: Vector3 = (p1 - p0).cross(d).normalized()
		if sn.dot(p0 - cen) < 0.0:
			sn = -sn
		b.quad(key, p0, p1, p1 + d * th, p0 + d * th, sn, Vector2(0, 0), Vector2(p0.distance_to(p1), 0), Vector2(p0.distance_to(p1), th), Vector2(0, th))


# =================================================================== construction

func build(island: Node3D, high_quality: bool) -> void:
	ile = island
	pc = high_quality
	_rng.seed = 10000
	_materials()
	var cl: Array = IleScript.PADS["clairiere"]
	centre = IleScript.W(float(cl[0]), float(cl[1]))
	centre.y = ile.height(centre.x, centre.z)
	for e in ARBRES:
		var a: float = deg_to_rad(float(e[3]))
		var p: Vector3 = centre + dir(a) * float(e[4])
		p.y = ile.height(p.x, p.z)
		var t := {"id": str(e[0]), "nom": str(e[1]), "maison": str(e[2]), "phi": a, "c": p, "rb": float(e[5]),
			"h": float(e[6]), "ht": float(e[6]) * 0.62, "pont": float(e[7]), "rm": float(e[8]),
			"s1": _rng.randf() * TAU, "s3": _rng.randf() * TAU, "seed": 10010 + arbres.size() * 17, "escaliers_sol": []}
		# l'escalier du sol arrive côté clairière (la trappe), un peu moins d'un tour et demi plus bas
		var top: float = t["pont"]
		var turns: float = top / 8.8
		# (calée sur un bord de secteur : l'escalier finit pile là où le plancher reprend)
		var a_end: float = round((a + PI) / (TAU / SECTORS)) * (TAU / SECTORS)
		t["turns"] = turns
		t["a_end"] = a_end
		# l'endroit où commencent les marches (les contreforts et les racines s'en écartent)
		(t["escaliers_sol"] as Array).append(a_end - turns * TAU + 0.7)
		arbres.append(t)
	for t2 in arbres:
		var t: Dictionary = t2
		var mi := MeshInstance3D.new()
		mi.name = "Chene_geant_%s_v100" % str(t["id"])
		mi.mesh = _tree_mesh(t)
		add_child(mi)
		mi.global_position = t["c"]
		var c: Vector3 = t["c"]
		# le tronc, en tronçons (il s'amincit)
		var yy: float = -0.5
		var stop: float = (BELVEDERE_H + 3.0) if str(t["id"]) == "grand" else float(t["pont"]) + 4.0
		while yy < stop:
			_cyl_col(c + Vector3.UP * yy, rc(t, yy + 2.5) * 1.0 + flare(t, yy + 2.5), 2.5)
			yy += 2.5
		avoid.append([Vector2(c.x, c.z), float(t["rb"]) * 3.3 + 1.0])
		carte.append([c.x, c.z, float(t["h"]) * 0.36])
	# les plates-formes, les maisons, les escaliers
	var n: int = arbres.size()
	var deck_out: Dictionary = {}
	for t3 in arbres:
		var t: Dictionary = t3
		var top: float = t["pont"]
		var r_in: float = r_max(t, top) + 0.02
		var grand: bool = str(t["id"]) == "grand"
		var hd: float = r_in + RING + float(t["rm"]) + (0.45 if grand else 0.1)
		deck_out[str(t["id"])] = r_in + RING + float(t["rm"]) * 2.0 + (0.45 if grand else 0.1) - 0.2
		t["r_out"] = deck_out[str(t["id"])]
		t["maison_c"] = (t["c"] as Vector3) + dir(float(t["phi"])) * hd + Vector3.UP * top
	for i in range(n):
		var t: Dictionary = arbres[i]
		var b := Kit.Batch.new()
		var c: Vector3 = t["c"]
		var top: float = t["pont"]
		var r_out: float = t["r_out"]
		var openings: Array = []
		for j in [(i + n - 1) % n, (i + 1) % n]:
			var o: Vector3 = (arbres[j] as Dictionary)["c"]
			openings.append(atan2(o.z - c.z, o.x - c.x))
		t["openings"] = openings
		var hd: float = ((t["maison_c"] as Vector3) - c).length()
		var hs: float = asin(clampf((float(t["rm"]) + 0.15) / hd, 0.0, 1.0))
		_deck(b, t, top, r_out, float(t["a_end"]), openings, [float(t["phi"]), hs])
		_maison(b, t, t["maison_c"], float(t["rm"]), str(t["maison"]))
		_stairs(b, t, 0.0, top, float(t["a_end"]), float(t["turns"]))
		_pied(b, t)
		if str(t["id"]) == "grand":
			_grand(b, t)
		b.commit(self, "Village_%s_v100" % str(t["id"]))
	# les passerelles : chaque arbre est relié au suivant (la dernière passe au-dessus de l'entrée)
	var b2 := Kit.Batch.new()
	for i2 in range(n):
		var ta: Dictionary = arbres[i2]
		var tb: Dictionary = arbres[(i2 + 1) % n]
		var ca: Vector3 = ta["c"]
		var cb: Vector3 = tb["c"]
		var dd: Vector3 = ((cb - ca) * Vector3(1, 0, 1)).normalized()
		var pa: Vector3 = ca + dd * (float(ta["r_out"]) + 0.03) + Vector3.UP * float(ta["pont"])
		var pb: Vector3 = cb - dd * (float(tb["r_out"]) + 0.03) + Vector3.UP * float(tb["pont"])
		_pont(b2, pa, pb)
	_clairiere(b2)
	b2.commit(self, "Village_passerelles_v100")
	print("ILE_MANGA_V100: le Village des Arbres-Maisons est construit (%d arbres, %d passerelles)" % [arbres.size(), ponts.size()])


## Au pied de chaque arbre : un panneau à son nom, deux tonneaux, une pile de caisses.
func _pied(b: Kit.Batch, t: Dictionary) -> void:
	var c: Vector3 = t["c"]
	var a0: float = float(t["a_end"]) - float(t["turns"]) * TAU
	var foot: float = r_stairs(t, 0.3) + 1.6
	var at: Vector3 = c + dir(a0 - 0.12) * foot
	at.y = ile.height(at.x, at.z)
	var face: Vector3 = dir(a0 - 0.12)
	var xf := Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), at)
	Kit.sign_board(b, xf, 1.7, 0.55)
	var lb: Label3D = Kit.label(self, str(t["nom"]).substr(0, 1).to_upper() + str(t["nom"]).substr(1), at + Vector3.UP * 1.68 + face * 0.1, face, 0.0028, Color(0.06, 0.055, 0.05))
	lb.font_size = 44
	_box_col(xf * Transform3D(Basis(), Vector3(0, 1.1, 0.03)), Vector3(1.7, 2.2, 0.2))
	t["panneau"] = at + face * 0.9
	# deux tonneaux et des caisses, de l'autre côté du pied de l'escalier
	var bp: Vector3 = c + dir(a0 - 0.55) * (foot + 0.3)
	bp.y = ile.height(bp.x, bp.z)
	for k in range(2):
		var o: Vector3 = bp + dir(a0 + PI * 0.5) * (0.8 * k)
		b.cyl("planches", Transform3D(Basis(), o), 0.38, 0.38, 0.95, 14)
		for hy in [0.15, 0.8]:
			b.cyl("fer", Transform3D(Basis(), o + Vector3.UP * hy), 0.395, 0.395, 0.05, 14, false)
	_cyl_col(bp + dir(a0 + PI * 0.5) * 0.4, 0.85, 1.0)
	var cp: Vector3 = c + dir(a0 - 0.85) * (foot + 0.6)
	cp.y = ile.height(cp.x, cp.z)
	var cb := Basis(Vector3.UP, a0)
	b.box("planches", Transform3D(cb, cp + Vector3.UP * 0.3), Vector3(0.7, 0.6, 0.7))
	b.box("planches", Transform3D(cb.rotated(Vector3.UP, 0.4), cp + Vector3.UP * 0.82), Vector3(0.55, 0.44, 0.55))
	_box_col(Transform3D(cb, cp + Vector3.UP * 0.5), Vector3(0.75, 1.0, 0.75))


## Le Grand-Chêne : un deuxième escalier, de la Maison du Conseil au Belvédère des Couleurs ;
## la poulie et son panier ; la longue-vue et le fanion du Belvédère.
func _grand(b: Kit.Batch, t: Dictionary) -> void:
	var c: Vector3 = t["c"]
	var phi: float = t["phi"]
	var top: float = t["pont"]
	var a1: float = float(t["a_end"]) + TAU / SECTORS
	var a_end2: float = a1 + TAU
	_stairs(b, t, top, BELVEDERE_H, a_end2, 1.0)
	var r_in: float = r_max(t, BELVEDERE_H) + 0.02
	var r_out: float = r_in + RING + 1.7
	_deck(b, t, BELVEDERE_H, r_out, a_end2, [], [])
	belvedere = c + dir(phi) * (r_in + RING) + Vector3.UP * BELVEDERE_H
	t["belv_r"] = r_out
	# la longue-vue, côté extérieur, tournée vers la mer
	var lv: Vector3 = c + dir(phi) * (r_out - 1.0) + Vector3.UP * BELVEDERE_H
	for k in range(3):
		var fa: float = phi + TAU * k / 3.0
		b.tube("fer", lv + dir(fa) * 0.38, lv + Vector3.UP * 1.15, 0.03, 5)
	var sight: Vector3 = (dir(phi) + Vector3.UP * 0.12).normalized()
	b.tube("cuivre", lv + Vector3.UP * 1.2 - sight * 0.55, lv + Vector3.UP * 1.2 + sight * 0.6, 0.08, 12, true)
	b.tube("cuivre", lv + Vector3.UP * 1.2 + sight * 0.6, lv + Vector3.UP * 1.2 + sight * 0.78, 0.11, 12, true)
	_cyl_col(lv, 0.4, 1.3)
	# un banc, face à la vue
	var bn: Vector3 = c + dir(phi + 0.9) * (r_out - 0.75) + Vector3.UP * BELVEDERE_H
	var zf: Vector3 = -dir(phi + 0.9)
	Kit.pew(b, Transform3D(Basis(Vector3.UP.cross(zf).normalized(), Vector3.UP, zf), bn), 1.8)
	# le mât et son fanion (il attend sa couleur)
	var mp: Vector3 = c + dir(phi - 1.2) * (r_out - 0.35) + Vector3.UP * BELVEDERE_H
	b.tube("bois", mp, mp + Vector3.UP * 4.2, 0.06, 7, true)
	b.sphere("bois", mp + Vector3.UP * 4.25, 0.09, 1.0, 5, 8)
	var fd: Vector3 = dir(phi - 1.2 + PI * 0.5)
	b.tri("fanion", [mp + Vector3.UP * 4.1, mp + Vector3.UP * 3.3, mp + Vector3.UP * 3.75 + fd * 1.5], [fd.cross(Vector3.UP), fd.cross(Vector3.UP), fd.cross(Vector3.UP)], [Vector2(0, 0), Vector2(0, 1), Vector2(1, 0.5)])
	var lb: Label3D = Kit.label(self, "Le Belvédère des Couleurs", c + dir(float(t["a_end"]) + 0.5) * (r_in + 0.08) + Vector3.UP * (BELVEDERE_H + 1.9), dir(float(t["a_end"]) + 0.5), 0.003, Color(0.06, 0.055, 0.05))
	lb.font_size = 48
	# la poulie : une potence au bord de la plate-forme, une corde, un panier au sol
	var pa: float = phi - 0.75
	var r_main: float = t["r_out"]
	var base: Vector3 = c + dir(pa) * (r_main - 0.3) + Vector3.UP * top
	var tip: Vector3 = c + dir(pa) * (r_main + 1.0) + Vector3.UP * (top + 2.0)
	b.tube("bois", base, base + Vector3.UP * 2.1, 0.1, 7, true)
	b.tube("bois", base + Vector3.UP * 2.0, tip, 0.08, 7, true)
	b.cyl("bois", Transform3D(Basis(dir(pa), dir(pa + PI * 0.5), Vector3.DOWN), tip - dir(pa + PI * 0.5) * 0.05 - Vector3.UP * 0.2), 0.18, 0.18, 0.1, 12)
	var g: Vector3 = c + dir(pa) * (r_main + 1.0)
	g.y = ile.height(g.x, g.z)
	b.tube("corde", tip - Vector3.UP * 0.35, g + Vector3.UP * 0.75, 0.02, 4)
	b.cyl("planches", Transform3D(Basis(), g), 0.42, 0.5, 0.5, 14)
	b.tube("corde", g + Vector3.UP * 0.5 + dir(pa) * 0.46, g + Vector3.UP * 0.75, 0.015, 4)
	b.tube("corde", g + Vector3.UP * 0.5 - dir(pa) * 0.46, g + Vector3.UP * 0.75, 0.015, 4)
	conseil = t["porte"]


## Au sol, autour de la Palette : des bancs, des lampadaires ; une balançoire sous le Chêne-Gomme.
func _clairiere(b: Kit.Batch) -> void:
	for k in range(4):
		var a: float = TAU * k / 4.0 + PI * 0.25
		var at: Vector3 = centre + dir(a) * 7.6
		at.y = ile.height(at.x, at.z)
		var zf: Vector3 = -dir(a)
		Kit.pew(b, Transform3D(Basis(Vector3.UP.cross(zf).normalized(), Vector3.UP, zf), at), 2.6)
		_box_col(Transform3D(Basis(Vector3.UP, -a), at + Vector3.UP * 0.45), Vector3(0.6, 0.9, 2.6))
		avoid.append([Vector2(at.x, at.z), 1.8])
	for k2 in range(6):
		var a2: float = TAU * k2 / 6.0 + 0.3
		var lp: Vector3 = centre + dir(a2) * 13.5
		lp.y = ile.height(lp.x, lp.z)
		b.cyl("fer", Transform3D(Basis(), lp), 0.16, 0.12, 0.25, 10)
		b.tube("fer", lp, lp + Vector3.UP * 2.7, 0.055, 7)
		b.cyl("fer", Transform3D(Basis(), lp + Vector3.UP * 3.05), 0.26, 0.04, 0.22, 8)
		b.cyl("fer", Transform3D(Basis(), lp + Vector3.UP * 2.68), 0.16, 0.16, 0.05, 8)
		b.sphere("lampe", lp + Vector3.UP * 2.88, 0.15, 1.15, 6, 10)
		_cyl_col(lp, 0.12, 2.8)
		avoid.append([Vector2(lp.x, lp.z), 0.8])
	for t2 in arbres:
		var t: Dictionary = t2
		if str(t["id"]) != "gomme":
			continue
		var sa: float = float(t["phi"]) + PI * 0.5
		var c: Vector3 = t["c"]
		var r: float = float(t["r_out"]) - 0.7
		var sw: Vector3 = c + dir(sa) * r
		var g: float = ile.height(sw.x, sw.z)
		var tg: Vector3 = dir(sa + PI * 0.5)
		for sgn in [-1.0, 1.0]:
			b.tube("corde", sw + tg * 0.32 * sgn + Vector3.UP * (float(t["pont"]) - 0.24), Vector3(sw.x, g + 0.62, sw.z) + tg * 0.32 * sgn, 0.02, 4)
		b.box("planches", Transform3D(Basis(Vector3.UP, -sa), Vector3(sw.x, g + 0.6, sw.z)), Vector3(0.32, 0.06, 0.78))


# =================================================================== services

## "belvedere", "village" (sur une plate-forme, un escalier ou une passerelle) ou "".
func zone(p: Vector3) -> String:
	for t2 in arbres:
		var t: Dictionary = t2
		var c: Vector3 = t["c"]
		var d: float = Vector2(p.x - c.x, p.z - c.z).length()
		if str(t["id"]) == "grand" and p.y > c.y + BELVEDERE_H - 1.0 and d < float(t.get("belv_r", 0.0)) + 0.6:
			return "belvedere"
		if p.y > c.y + 2.5 and d < float(t["r_out"]) + 0.6:
			return "village"
	if pont_at(p) >= 0:
		return "village"
	return ""


## L'index de la passerelle sous les pieds (ou -1).
func pont_at(p: Vector3) -> int:
	for i in range(ponts.size()):
		var a: Vector3 = ponts[i]["a"]
		var bq: Vector3 = ponts[i]["b"]
		var ab := Vector2(bq.x - a.x, bq.z - a.z)
		var ap := Vector2(p.x - a.x, p.z - a.z)
		var u: float = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q: Vector3 = a.lerp(bq, u)
		if Vector2(p.x - q.x, p.z - q.z).length() < 1.1 and absf(p.y - q.y) < 2.5:
			return i
	return -1


## Au milieu d'une passerelle ? (pour compter les traversées)
func pont_milieu(p: Vector3) -> int:
	for i in range(ponts.size()):
		var m: Vector3 = ponts[i]["mid"]
		if Vector2(p.x - m.x, p.z - m.z).length() < 2.0 and absf(p.y - m.y) < 2.5:
			return i
	return -1

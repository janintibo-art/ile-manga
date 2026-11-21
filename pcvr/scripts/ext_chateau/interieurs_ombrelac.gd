extends Node3D
## Extension « Le Château d'Ombrelac » : les intérieurs. Pour l'instant, la Grande Salle :
##  - l'estrade à l'ouest (sous la grande baie) et la table d'honneur, ses hautes chaises ;
##  - trois longues tables de chêne, leurs bancs, la vaisselle dorée, les chandeliers ;
##  - la charpente à blochets (les fermes, les aisseliers, les pannes) sous le lambris ;
##  - la grande cheminée à hotte à l'est (sous la rose), son feu qui danse ;
##  - quatre lustres de fer à bougies, suspendus à la charpente ;
##  - les bannières de l'Académie entre les baies, le tapis de l'allée.
## Les lumières (le feu, les lustres) et une sonde de reflets : le dedans est plus sombre que le
## dehors, plus chaud ; la nuit, les bougies éclairent davantage (set_nuit).
## Repère : celui du château (l'origine au centre du Roc, y = le plateau).

const Kit = preload("res://scripts/ext_chateau/archi_ombrelac.gd")

const LUMIERE := Color(1.0, 0.7, 0.42)
const AMBIANT_JOUR := Color(0.42, 0.33, 0.24)
const AMBIANT_NUIT := Color(0.07, 0.05, 0.04)

var lumieres: Array = []        # [OmniLight3D, énergie de jour, énergie de nuit]
var feu: OmniLight3D
var sonde: ReflectionProbe
var nuit: float = 0.0
## Les lieux de la salle (repère château) : nom → Vector3
var lieux: Dictionary = {}
var _t: float = 0.0


## Une poutre de section s (carrée) de a à b ; « large » : l'axe des x de la section
func _poutre(k: RefCounted, m: String, a: Vector3, b: Vector3, s: float, large := Vector3.RIGHT) -> void:
	var y: Vector3 = b - a
	var lg: float = y.length()
	if lg < 0.01:
		return
	y /= lg
	var x: Vector3 = (large - y * large.dot(y)).normalized()
	if x.length_squared() < 0.5:
		x = y.cross(Vector3.FORWARD).normalized()
	var z: Vector3 = x.cross(y)
	k.box(m, Transform3D(Basis(x, y, z), a), Vector3(s, lg, s))


## Une flamme : deux quads croisés, le bas en p
func _flamme(k: RefCounted, p: Vector3, w: float, h: float) -> void:
	var g := Vector2(p.x * 3.1 + p.y, p.z * 2.7)
	for d in [Vector3.RIGHT, Vector3.BACK]:
		var e: Vector3 = d * w * 0.5
		var n: Vector3 = d.cross(Vector3.UP)
		k.quad("flamme", Transform3D.IDENTITY, p - e, p + e, p + e + Vector3(0, h, 0), p - e + Vector3(0, h, 0), n,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), g)


## Une bougie sur sa bobèche : la cire, la flamme
func _bougie(k: RefCounted, p: Vector3, hc: float = 0.22) -> void:
	k.cyl("cire", Transform3D(Basis.IDENTITY, p), 0.035, 0.032, hc, 6)
	_flamme(k, p + Vector3(0, hc + 0.005, 0), 0.07, 0.16)


func _lumiere(p: Vector3, portee: float, jour: float, nuit_e: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = LUMIERE
	l.omni_range = portee
	l.omni_attenuation = 1.2
	l.light_energy = jour
	l.shadow_enabled = false
	l.light_specular = 0.4
	add_child(l)
	lumieres.append([l, jour, nuit_e])
	return l


# =================================================================== la Grande Salle

## c : le centre de la salle au sol ; L x W x H : le dehors des murs ; T : leur épaisseur ;
## voute : la hauteur du lambris au faîte (au-dessus de H) ; bx : les x des baies
func grande_salle(c: Vector3, L: float, W: float, H: float, T: float, voute: float, bx: Array) -> void:
	var k := Kit.new()
	var hl: float = L * 0.5 - T          # le dedans : x de -hl à hl
	var hw: float = W * 0.5 - T          # z de c.z - hw à c.z + hw
	_charpente(k, c, L, hl, hw, H, voute)
	_estrade(k, c, hl, hw)
	_tables(k, c, hl, hw)
	_cheminee(k, c, hl, hw)
	_lustres(k, c, H, voute, hw)
	_bannieres(k, c, L, hl, hw, bx)
	# le tapis de l'allée : de la porte jusqu'au mur nord
	k.quad("tapis", Transform3D.IDENTITY, Vector3(-1.3, 0.012, c.z + hw - 0.3), Vector3(1.3, 0.012, c.z + hw - 0.3),
		Vector3(1.3, 0.012, c.z - hw + 0.6), Vector3(-1.3, 0.012, c.z - hw + 0.6), Vector3.UP,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	var mi: MeshInstance3D = k.commit("Ombrelac_salle_meubles")
	mi.visibility_range_end = 160.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_salle_meubles_col"))
	# la sonde : un dedans (pas de ciel), une lumière ambiante chaude et faible
	sonde = ReflectionProbe.new()
	sonde.name = "Ombrelac_salle_sonde"
	sonde.position = Vector3(c.x, (H + voute) * 0.5 - 1.0, c.z)
	sonde.size = Vector3(hl * 2.0, H + voute + 3.0, hw * 2.0)
	sonde.interior = true
	sonde.box_projection = true
	sonde.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	sonde.ambient_color = AMBIANT_JOUR
	sonde.ambient_color_energy = 1.0
	sonde.update_mode = ReflectionProbe.UPDATE_ONCE
	sonde.max_distance = 80.0
	sonde.blend_distance = 0.5
	add_child(sonde)
	lieux["salle"] = c
	lieux["table_honneur"] = Vector3(-hl + 3.2, 0.6, c.z)
	lieux["cheminee"] = Vector3(hl - 3.0, 0.0, c.z)


## La charpente : à chaque travée une ferme à blochets (les poteaux sur leurs corbeaux, les
## blochets en porte-à-faux, les aisseliers courbes jusqu'à l'entrait retroussé), des pannes
func _charpente(k: RefCounted, c: Vector3, L: float, hl: float, hw: float, H: float, voute: float) -> void:
	var lambris := func(dz: float) -> float:
		return H + voute * (1.0 - absf(dz) / hw)
	for i in range(1, 8):
		var x: float = -L * 0.5 + 0.7 + i * (L - 1.4) / 8.0
		for s in [-1.0, 1.0]:
			var zw: float = c.z + s * (hw - 0.22)
			# le corbeau de pierre, le poteau
			k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(x, H - 4.4, c.z + s * (hw - 0.4))), Vector3(0.7, 0.9, 0.8))
			_poutre(k, "chene", Vector3(x, H - 3.5, zw), Vector3(x, H + 0.2, zw), 0.38)
			# le blochet (en porte-à-faux) et son poinçon
			var zb: float = c.z + s * (hw - 2.4)
			_poutre(k, "chene", Vector3(x, H, c.z + s * hw), Vector3(x, H, zb), 0.36, Vector3.UP)
			_poutre(k, "chene", Vector3(x, H - 0.6, zb), Vector3(x, lambris.call(hw - 2.4) - 0.1, zb), 0.32)
			# l'aisselier du bas (du poteau au bout du blochet), en quart de cercle
			var prev := Vector3(x, H - 3.0, zw)
			for j in range(1, 7):
				var a: float = PI * 0.5 * j / 6.0
				var p := Vector3(x, H - 3.0 + 3.0 * sin(a), c.z + s * ((hw - 0.22) - 2.1 * (1.0 - cos(a))))
				_poutre(k, "chene", prev, p, 0.26)
				prev = p
			# le grand aisselier (du blochet à l'entrait) : un arc brisé
			var ze: float = voute * 0.62
			var ye: float = H + ze
			var zt: float = hw * (1.0 - ze / voute)
			prev = Vector3(x, H + 0.5, zb)
			for j in range(1, 9):
				var u: float = float(j) / 8.0
				var a2: float = PI * 0.5 * u
				var p2 := Vector3(x, H + 0.5 + (ye - H - 0.5) * sin(a2), c.z + s * ((hw - 2.4) * cos(a2) + 0.0 * u))
				_poutre(k, "chene", prev, p2, 0.3)
				prev = p2
			# l'arbalétrier, sous le lambris
			_poutre(k, "chene", Vector3(x, H + 0.05, c.z + s * (hw - 0.05)), Vector3(x, H + voute - 0.25, c.z), 0.34)
			# l'entrait retroussé
			if s > 0:
				_poutre(k, "chene", Vector3(x, ye, c.z - zt), Vector3(x, ye, c.z + zt), 0.34, Vector3.UP)
	# les pannes (sous le lambris, d'un pignon à l'autre) et la panne faîtière
	for f in [0.3, 0.62]:
		for s in [-1.0, 1.0]:
			var dz: float = hw * (1.0 - f)
			var y: float = lambris.call(dz) - 0.3
			_poutre(k, "chene", Vector3(-hl, y, c.z + s * dz), Vector3(hl, y, c.z + s * dz), 0.3, Vector3.UP)
	_poutre(k, "chene", Vector3(-hl, H + voute - 0.4, c.z), Vector3(hl, H + voute - 0.4, c.z), 0.36, Vector3.UP)


## L'estrade à l'ouest : deux marches, la table d'honneur (en travers), ses hautes chaises
func _estrade(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var x1: float = -hl + 5.4
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3((-hl + x1) * 0.5, 0.0, c.z)), Vector3(x1 + hl, 0.6, hw * 2.0), true)
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(x1 + 0.4, 0.0, c.z)), Vector3(0.8, 0.3, hw * 2.0 - 4.0), true)
	k.box("bois", Transform3D(Basis.IDENTITY, Vector3((-hl + x1) * 0.5, 0.6, c.z)), Vector3(x1 + hl - 0.4, 0.04, hw * 2.0 - 0.6))
	var xt: float = -hl + 3.2
	_table(k, Vector3(xt, 0.64, c.z), 13.0, 1.4, true)
	# les chaises, face à la salle ; celle du milieu plus haute (la directrice de l'Académie)
	for i in range(9):
		var z: float = c.z + (i - 4) * 1.4
		var haut: float = 2.9 if i == 4 else 1.7
		var xc: float = xt - 1.15
		k.box("bois", Transform3D(Basis.IDENTITY, Vector3(xc, 0.64, z)), Vector3(0.55, 0.48, 0.55))
		k.box("bois", Transform3D(Basis.IDENTITY, Vector3(xc - 0.26, 0.64, z)), Vector3(0.08, haut, 0.55))
		if i == 4:
			k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(xc - 0.26, 0.64 + haut, z)), 0.16, 0.0, 0.4, 8)
	lieux["estrade"] = Vector3(xt - 0.2, 0.64, c.z)


## Une table de chêne : le plateau (le long de x, ou de z si « travers »), les tréteaux ; les
## couverts dorés ; des chandeliers sur la ligne du milieu
func _table(k: RefCounted, p: Vector3, lg: float, lar: float, travers: bool = false) -> void:
	var ax := Vector3(0, 0, 1) if travers else Vector3(1, 0, 0)
	var sx := Vector3(1, 0, 0) if travers else Vector3(0, 0, 1)
	var yaw: float = PI * 0.5 if travers else 0.0
	var b := Basis(Vector3.UP, yaw)
	k.box("bois", Transform3D(b, p + Vector3(0, 0.7, 0)), Vector3(lg, 0.09, lar), true)
	var n: int = maxi(2, int(lg / 3.2) + 1)
	for i in range(n):
		var q: Vector3 = p + ax * lerpf(-lg * 0.5 + 0.5, lg * 0.5 - 0.5, float(i) / (n - 1))
		k.box("bois", Transform3D(b, q), Vector3(0.12, 0.7, lar * 0.7))
		k.box("bois", Transform3D(b, q), Vector3(0.18, 0.1, lar * 0.85))
	k.box("bois", Transform3D(b, p + Vector3(0, 0.22, 0)), Vector3(lg - 1.0, 0.1, 0.1))
	# les couverts : une assiette et un gobelet tous les 0,8 m, des deux côtés
	var m: int = int(lg / 0.8)
	for i in range(m):
		var u: float = -lg * 0.5 + 0.4 + i * 0.8
		for s in [-1.0, 1.0]:
			if travers and s > 0:
				continue
			var a: Vector3 = p + ax * u + sx * s * (lar * 0.5 - 0.25) + Vector3(0, 0.79, 0)
			k.cyl("or", Transform3D(Basis.IDENTITY, a), 0.13, 0.14, 0.018, 12)
			k.cyl("or", Transform3D(Basis.IDENTITY, a + ax * 0.24 + sx * s * 0.08), 0.03, 0.045, 0.16, 8)
	# les chandeliers à trois branches
	var nc: int = int(lg / 3.4)
	for i in range(nc):
		var cp: Vector3 = p + ax * (-lg * 0.5 + (i + 0.5) * lg / nc) + Vector3(0, 0.79, 0)
		k.cyl("or", Transform3D(Basis.IDENTITY, cp), 0.1, 0.03, 0.32, 8)
		for j in [-1.0, 0.0, 1.0]:
			var bp: Vector3 = cp + ax * j * 0.16 + Vector3(0, 0.32 + (0.06 if j == 0.0 else 0.0), 0)
			k.cyl("or", Transform3D(Basis.IDENTITY, bp - Vector3(0, 0.03, 0)), 0.045, 0.05, 0.03, 8)
			_bougie(k, bp, 0.2)


## Trois longues tables (de part et d'autre de l'allée), leurs bancs
func _tables(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var xa: float = -hl + 7.0
	var xb: float = hl - 4.6
	for r in [-5.0, 0.0, 5.0]:
		var z: float = c.z + r
		for seg in [[xa, -2.6], [2.6, xb]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			var lg: float = x1 - x0
			var mid: float = (x0 + x1) * 0.5
			_table(k, Vector3(mid, 0, z), lg, 1.3)
			for s in [-1.0, 1.0]:
				var bz: float = z + s * 1.05
				k.box("bois", Transform3D(Basis.IDENTITY, Vector3(mid, 0.4, bz)), Vector3(lg, 0.07, 0.4), true)
				var n: int = int(lg / 3.0) + 1
				for i in range(n):
					var bxp: float = lerpf(x0 + 0.4, x1 - 0.4, float(i) / (n - 1))
					k.box("bois", Transform3D(Basis.IDENTITY, Vector3(bxp, 0.0, bz)), Vector3(0.09, 0.4, 0.32))
	# un peu de lumière au-dessus des tables (les chandeliers)
	for xl in [(xa - 2.6) * 0.5, (2.6 + xb) * 0.5]:
		_lumiere(Vector3(xl, 1.8, c.z), 11.0, 0.5, 1.0)


## La grande cheminée : les piédroits, le manteau, la hotte qui monte en se resserrant, le contre-
## cœur noirci, les chenets, les bûches, le feu
func _cheminee(k: RefCounted, c: Vector3, hl: float, hw: float) -> void:
	var xm: float = hl                     # la face du mur
	var d: float = 1.6                     # la saillie
	var lw: float = 6.0                    # la largeur du manteau
	for s in [-1.0, 1.0]:
		k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 0.0, c.z + s * (lw * 0.5 - 0.45))), Vector3(d, 2.7, 0.9), true)
		k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.06, 2.45, c.z + s * (lw * 0.5 - 0.45))), Vector3(d + 0.14, 0.25, 1.0))
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 2.7, c.z)), Vector3(d + 0.2, 0.75, lw + 0.3), true)
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.1, 3.45, c.z)), Vector3(d + 0.35, 0.2, lw + 0.5))
	# la hotte : un tronc de pyramide jusqu'au-dessous de la rose
	var y0: float = 3.65
	var y1: float = 7.4
	var a0: Vector3 = Vector3(xm - d, y0, c.z - lw * 0.5)
	var b0: Vector3 = Vector3(xm - d, y0, c.z + lw * 0.5)
	var a1: Vector3 = Vector3(xm - 0.7, y1, c.z - 1.6)
	var b1: Vector3 = Vector3(xm - 0.7, y1, c.z + 1.6)
	k.quad("pierre_int", Transform3D.IDENTITY, a0, b0, b1, a1, Vector3(-1, 0.2, 0))
	for s in [-1.0, 1.0]:
		var e0: Vector3 = a0 if s < 0 else b0
		var e1: Vector3 = a1 if s < 0 else b1
		k.quad("pierre_int", Transform3D.IDENTITY, e0, Vector3(xm, y0, e0.z), Vector3(xm, y1, e1.z), e1, Vector3(0, 0, s))
	k.quad("pierre_claire", Transform3D.IDENTITY, a1, b1, Vector3(xm, y1, b1.z), Vector3(xm, y1, a1.z), Vector3.UP)
	# le foyer : le contrecœur, l'âtre, les chenets, les bûches
	k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - 0.05, 0.0, c.z)), Vector3(0.1, 2.7, lw - 1.8))
	for s in [-1.0, 1.0]:
		k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 0.0, c.z + s * (lw * 0.5 - 0.91))), Vector3(d, 2.7, 0.02))
	k.box("suie", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5, 2.68, c.z)), Vector3(d, 0.02, lw - 1.8))
	k.box("pierre_claire", Transform3D(Basis.IDENTITY, Vector3(xm - d * 0.5 - 0.3, 0.0, c.z)), Vector3(d + 0.6, 0.12, lw + 0.8), true)
	for s in [-1.0, 1.0]:
		var cz: float = c.z + s * 0.9
		_poutre(k, "fer", Vector3(xm - d + 0.1, 0.12, cz), Vector3(xm - 0.4, 0.12, cz), 0.07)
		_poutre(k, "fer", Vector3(xm - d + 0.1, 0.12, cz), Vector3(xm - d + 0.1, 0.62, cz), 0.07)
		k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(xm - d + 0.1, 0.62, cz)), 0.08, 0.0, 0.14, 8)
	for j in range(3):
		var lz: float = c.z + (j - 1) * 0.3
		var ly: float = 0.3 + (0.22 if j == 1 else 0.0)
		_poutre(k, "bois", Vector3(xm - 0.35, ly, lz - 1.2 + j * 0.2), Vector3(xm - 1.05, ly, lz + 1.1 - j * 0.15), 0.2, Vector3.UP)
	for j in range(7):
		var fz: float = c.z + (j - 3) * 0.32
		var fh: float = 1.25 - absf(j - 3) * 0.17
		_flamme(k, Vector3(xm - 0.7 - 0.08 * (j % 2), 0.32, fz), 0.75, fh)
	feu = _lumiere(Vector3(xm - 1.4, 1.2, c.z), 16.0, 1.6, 2.6)


## Quatre lustres de fer : une grande couronne à seize bougies, une petite au-dessus, les chaînes
func _lustres(k: RefCounted, c: Vector3, H: float, voute: float, hw: float) -> void:
	for x in [-16.0, -5.5, 5.5, 16.0]:
		var p := Vector3(x, H - 9.5, c.z)
		for rr in [[1.7, 0.0, 16], [0.9, 0.9, 8]]:
			var r: float = rr[0]
			var dy: float = rr[1]
			var nb: int = rr[2]
			for i in range(nb):
				var a0: float = TAU * i / nb
				var a1: float = TAU * (i + 1) / nb
				var q0: Vector3 = p + Vector3(cos(a0) * r, dy, sin(a0) * r)
				var q1: Vector3 = p + Vector3(cos(a1) * r, dy, sin(a1) * r)
				_poutre(k, "fer", q0, q1, 0.07, Vector3.UP)
				k.cyl("fer", Transform3D(Basis.IDENTITY, q0 + Vector3(0, 0.035, 0)), 0.06, 0.07, 0.03, 6)
				_bougie(k, q0 + Vector3(0, 0.065, 0), 0.24)
			# les chaînes de la couronne au crochet
			for i in range(4):
				var a: float = TAU * i / 4.0 + 0.4
				_poutre(k, "fer", p + Vector3(cos(a) * r, dy, sin(a) * r), p + Vector3(0, 3.2, 0), 0.035)
		_poutre(k, "fer", p + Vector3(0, 3.2, 0), Vector3(x, H + voute - 0.6, c.z), 0.06)
		k.cyl("or", Transform3D(Basis.IDENTITY, p + Vector3(0, -0.5, 0)), 0.0, 0.18, 0.5, 8)
		_lumiere(p + Vector3(0, 0.6, 0), 19.0, 1.5, 2.6)


## Les bannières de l'Académie (bleu nuit et or, pourpre et argent) entre les hautes baies, deux
## grandes de part et d'autre de la baie ouest ; leur tringle dorée
func _bannieres(k: RefCounted, c: Vector3, L: float, hl: float, hw: float, bx: Array) -> void:
	var j: int = 0
	for i in range(1, 8):
		var x: float = -L * 0.5 + 0.7 + i * (L - 1.4) / 8.0
		for s in [-1.0, 1.0]:
			if s > 0 and absf(x) < 4.0:
				continue
			var z: float = c.z + s * (hw - 0.09)
			var m: String = "banniere_bleu" if j % 2 == 0 else "banniere_pourpre"
			j += 1
			_banniere(k, m, Vector3(x, 15.6, z), 1.5, 6.0, Vector3(0, 0, -s))
	for s2 in [-1.0, 1.0]:
		_banniere(k, "banniere_bleu", Vector3(-hl + 0.09, 13.0, c.z + s2 * 5.6), 2.2, 8.8, Vector3.RIGHT)


## Une bannière : le haut au milieu en p, w x h, tournée vers n
func _banniere(k: RefCounted, m: String, p: Vector3, w: float, h: float, n: Vector3) -> void:
	var u: Vector3 = Vector3.UP.cross(n).normalized() * w * 0.5
	if u.dot(Vector3(1, 0, 1)) < 0.0:
		u = -u
	k.quad(m, Transform3D.IDENTITY, p - u - Vector3(0, h, 0), p + u - Vector3(0, h, 0), p + u, p - u, n,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	_poutre(k, "or", p - u * 1.15 + n * 0.04, p + u * 1.15 + n * 0.04, 0.06, Vector3.UP)
	for e in [-1.0, 1.0]:
		k.cyl("or", Transform3D(Basis.IDENTITY, p + u * 1.15 * e + n * 0.04 - Vector3(0, 0.07, 0)), 0.07, 0.0, 0.16, 8)


# =================================================================== la vie

## 0 le jour, 1 la nuit : les bougies éclairent plus fort, le dedans s'assombrit
func set_nuit(n: float) -> void:
	nuit = n
	for e in lumieres:
		(e[0] as OmniLight3D).light_energy = lerpf(float(e[1]), float(e[2]), n)
	if sonde != null:
		sonde.ambient_color = AMBIANT_JOUR.lerp(AMBIANT_NUIT, n)


func _process(delta: float) -> void:
	if feu == null:
		return
	_t += delta
	var base: float = lerpf(1.6, 2.6, nuit)
	feu.light_energy = base * (0.86 + 0.09 * sin(_t * 9.0) + 0.05 * sin(_t * 23.0 + 1.3))

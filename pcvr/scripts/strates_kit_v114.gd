extends "res://scripts/hautefond_kit_v112.gd"
## V114 : la boîte à outils des Strates et de la Fronde. Tout ce que savent faire les kits d'avant
## (les maisons de Hautefond, les engrenages, les horloges, les tuyaux de vapeur ; les conteneurs, la
## scène, les guirlandes, les canapés de Port-Boucan…), et ce qui fait la ville sous la ville :
##  - sign114() : une enseigne sur un cadre de fer forgé ; lamp114() : un réverbère de fonte (un globe
##    toujours allumé, ou un cristal) ;
##  - track114() : une voie étroite (deux rails, des traverses) le long d'une ligne ; wagonnet114() ;
##  - bridge114() : un pont de fer en treillis (le tablier, les poutres, les garde-corps, la collision) ;
##  - flight114() : une volée d'escalier de pierre contre une paroi (marches, rampe de collision, garde-
##    corps de fer côté vide) ; rail114() : un garde-corps de fer forgé (avec collision) ;
##  - champi114() : un champignon lumineux ; chaudiere114() : une vieille chaudière devenue maison ;
##  - fresque114() : une grande fresque peinte sur un panneau de tôle (la Fronde).
## Repères : une façade « xf » regarde +Z local (comme les autres kits).

const Mats114 = preload("res://scripts/strates_mats_v114.gd")

var light_spots: Array = []              # [Vector3, Color, énergie, portée] : des lampes qui méritent une vraie lumière


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats114.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


## Une enseigne (« enseigne114_<id> ») dans un cadre de fer forgé (xf : son centre, elle regarde +Z).
func sign114(xf: Transform3D, sign_id: String, w: float = 2.6, h: float = 1.3) -> void:
	box(xf * T(0, 0, -0.05), Vector3(w + 0.16, h + 0.16, 0.06), "fer114", 1.0)
	for s in [-1.0, 1.0]:
		ball(xf * T(s * (w * 0.5 + 0.12), h * 0.5 + 0.1, -0.05), 0.07, "laiton112", 6, 3)
	quadz(xf * T(0, 0, 0.0), w, h, "enseigne114_" + sign_id)


## Une enseigne suspendue à une potence (xf : le pied de la potence contre le mur, qui regarde +Z).
func hanging_sign114(xf: Transform3D, sign_id: String, y: float = 3.2) -> void:
	box(xf * T(0, y + 0.55, 0.55), Vector3(0.06, 0.06, 1.1), "fer114", 1.0)
	beam(xf * Vector3(0, y + 0.05, 0.02), xf * Vector3(0, y + 0.55, 0.9), 0.025, "fer114")
	sign114(xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, y, 0.75)), sign_id, 1.2, 0.6)
	sign114(xf * Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(0, y, 0.75)), sign_id, 1.2, 0.6)


## Un réverbère de fonte : un fût cannelé, une lanterne à globe (lampe114) ; froid : une lampe à cristal.
## Renvoie la position du globe.
func lamp114(pos: Vector3, h: float = 4.0, cold: bool = false, real_light: bool = false) -> Vector3:
	cyl(Transform3D(Basis(), pos), 0.2, 0.16, 0.5, "fer114", 8)
	cyl(Transform3D(Basis(), pos + Vector3.UP * 0.5), 0.08, 0.06, h - 0.9, "fer114", 8, false)
	cyl(Transform3D(Basis(), pos + Vector3.UP * (h - 0.42)), 0.14, 0.1, 0.1, "laiton112", 8)
	var g: Vector3 = pos + Vector3.UP * (h - 0.12)
	ball(Transform3D(Basis(), g), 0.24, "lampe114_froid" if cold else "lampe114", 10, 6)
	cyl(Transform3D(Basis(), g + Vector3.UP * 0.2), 0.16, 0.04, 0.22, "fer114", 8)
	col_cyl(pos, 0.15, h)
	if real_light:
		light_spots.append([g, Color(0.7, 0.86, 1.0) if cold else Color(1.0, 0.76, 0.48), 1.6, 14.0])
	return g


## Une voie étroite (écartement 1 m) le long d'une ligne de points (fermée si loop) ; posée au sol.
func track114(pts: Array, loop: bool = false) -> void:
	var n: int = pts.size()
	var segs: int = n if loop else n - 1
	for i in range(segs):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % n]
		var d: Vector3 = b - a
		var flat := Vector3(d.x, 0, d.z)
		var len: float = d.length()
		if len < 0.01:
			continue
		var bs := Basis.looking_at(d.normalized(), Vector3.UP)
		var side: Vector3 = flat.normalized().cross(Vector3.UP)
		for s in [-0.5, 0.5]:
			box(Transform3D(bs, (a + b) * 0.5 + side * s + Vector3.UP * 0.2), Vector3(0.07, 0.1, len + 0.04), "rail114", 1.0, 63 - 8)
		var ns: int = maxi(int(len / 0.62), 1)
		for k in range(ns):
			var p: Vector3 = a.lerp(b, (k + 0.5) / ns)
			box(Transform3D(bs, p + Vector3.UP * 0.07), Vector3(1.5, 0.12, 0.22), "traverse114", 1.0, 63 - 8)


## Un wagonnet de mine (xf : au sol, sur la voie, le long de +Z) ; plein : chargé de cristaux.
func wagonnet114(xf: Transform3D, full: bool = true) -> void:
	box(xf * T(0, 0.75, 0), Vector3(1.1, 0.7, 1.6), "fer114_rouille", 1.0)
	box(xf * T(0, 1.12, 0), Vector3(1.16, 0.06, 1.66), "fer114", 1.0, 63 - 8 - 4)
	for sx in [-0.45, 0.45]:
		for sz in [-0.5, 0.5]:
			cyl(Transform3D(Basis(Vector3.BACK, PI * 0.5), xf * Vector3(sx + sign(sx) * 0.08, 0.28, sz)), 0.26, 0.26, 0.08, "fer114", 10)
	if full:
		for k in range(5):
			var q: Vector3 = Vector3(randf_range(-0.3, 0.3), 1.05, randf_range(-0.5, 0.5))
			ball(xf * Transform3D(Basis(), q), randf_range(0.14, 0.24), "cristal114" if k % 2 == 0 else "pierre112_sombre", 6, 4)
	col_box(xf * T(0, 0.6, 0), Vector3(1.2, 1.2, 1.7))


## Un pont de fer en treillis de a à b (les bouts, au niveau du tablier), large de w.
func bridge114(a: Vector3, b: Vector3, w: float = 2.6) -> void:
	var d: Vector3 = b - a
	var len: float = d.length()
	var dir: Vector3 = d / len
	var bs := Basis.looking_at(dir, Vector3.UP)
	var side: Vector3 = bs.x
	var mid: Vector3 = (a + b) * 0.5
	# le tablier : des planches sur deux longerons
	box(Transform3D(bs, mid + Vector3.DOWN * 0.06), Vector3(w, 0.12, len), "traverse114", 2.0)
	for s in [-1.0, 1.0]:
		box(Transform3D(bs, mid + side * s * (w * 0.5 - 0.1) + Vector3.DOWN * 0.3), Vector3(0.18, 0.36, len), "fer114", 1.0)
	col_box(Transform3D(bs, mid + Vector3.DOWN * 0.1), Vector3(w, 0.2, len + 0.2))
	# les poutres en treillis de chaque côté (la main courante en haut)
	var hh: float = 1.25
	var n: int = maxi(int(len / 1.4), 2)
	for s2 in [-1.0, 1.0]:
		var o: Vector3 = side * s2 * (w * 0.5 + 0.05)
		box(Transform3D(bs, mid + o + Vector3.UP * hh), Vector3(0.12, 0.12, len), "fer114", 1.0)
		box(Transform3D(bs, mid + o + Vector3.UP * 0.05), Vector3(0.1, 0.12, len), "fer114", 1.0)
		for k in range(n + 1):
			var p: Vector3 = a + dir * len * float(k) / n + o
			box(Transform3D(bs, p + Vector3.UP * hh * 0.5), Vector3(0.09, hh, 0.09), "fer114", 1.0)
			if k < n:
				var q: Vector3 = a + dir * len * float(k + 1) / n + o
				beam(p + Vector3.UP * 0.1, q + Vector3.UP * (hh - 0.05), 0.035, "fer114")
				beam(p + Vector3.UP * (hh - 0.05), q + Vector3.UP * 0.1, 0.035, "fer114")
		col_box(Transform3D(bs, mid + o + Vector3.UP * 0.7), Vector3(0.15, 1.4, len))
	# les rivets de laiton aux nœuds, les arcs de dessous
	var arc_n: int = 10
	for s3 in [-1.0, 1.0]:
		var prev: Vector3 = a + side * s3 * (w * 0.5 - 0.1) + Vector3.DOWN * 0.45
		for k2 in range(1, arc_n + 1):
			var t: float = float(k2) / arc_n
			var p2: Vector3 = a.lerp(b, t) + side * s3 * (w * 0.5 - 0.1) + Vector3.DOWN * (0.45 + 1.4 * sin(PI * t))
			beam(prev, p2, 0.08, "fer114")
			prev = p2


## Un garde-corps de fer forgé de a à b (au sol) : main courante, barreaux, collision.
func rail114(a: Vector3, b: Vector3, h: float = 1.1, collide: bool = true) -> void:
	var d: Vector3 = b - a
	var len: float = d.length()
	if len < 0.05:
		return
	var bs := Basis.looking_at(d / len, Vector3.UP)
	var mid: Vector3 = (a + b) * 0.5
	box(Transform3D(bs, mid + Vector3.UP * h), Vector3(0.07, 0.07, len), "fer114", 1.0)
	box(Transform3D(bs, mid + Vector3.UP * 0.12), Vector3(0.05, 0.05, len), "fer114", 1.0)
	var n: int = maxi(int(len / 0.16), 1)
	for k in range(n + 1):
		var p: Vector3 = a.lerp(b, float(k) / n)
		box(Transform3D(bs, p + Vector3.UP * h * 0.5), Vector3(0.025, h, 0.025), "fer114", 1.0, 63 - 4 - 8)
	for k2 in range(int(len / 2.0) + 1):
		var p2: Vector3 = a.lerp(b, minf(k2 * 2.0 / len, 1.0))
		ball(Transform3D(bs, p2 + Vector3.UP * (h + 0.07)), 0.05, "laiton112", 6, 3)
	if collide:
		col_box(Transform3D(bs, mid + Vector3.UP * h * 0.5), Vector3(0.1, h, len))


## Une volée d'escalier de pierre (a : le pied, b : le haut, au niveau des sols), large de w ; un mur
## d'échiffre côté « wall_side » (-1 : à gauche en montant, 1 : à droite, 0 : aucun) et un garde-corps
## de fer forgé de l'autre côté.
func flight114(a: Vector3, b: Vector3, w: float = 2.4, wall_side: float = 0.0) -> void:
	stair(a, b, w, "pierre112_clair")
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var dir: Vector3 = flat.normalized()
	var side: Vector3 = dir.cross(Vector3.UP)
	# le limon de pierre sous les marches (on ne voit pas le vide en dessous)
	var n: int = maxi(int(flat.length() / 1.2), 1)
	for k in range(n):
		var t0: float = float(k) / n
		var t1: float = float(k + 1) / n
		var p0: Vector3 = a.lerp(b, t0)
		var p1: Vector3 = a.lerp(b, t1)
		var top: float = minf(p0.y, p1.y)
		var bot: float = a.y
		var m: Vector3 = (p0 + p1) * 0.5
		box(Transform3D(Basis.looking_at(dir, Vector3.UP), Vector3(m.x, (top + bot) * 0.5 - 0.15, m.z)), Vector3(w, maxf(top - bot - 0.3, 0.05), p0.distance_to(p1) * 0.98), "pierre112_sombre", 2.0, 63 - 4)
	for s in [-1.0, 1.0]:
		var o: Vector3 = side * s * (w * 0.5 + 0.05)
		if absf(s - wall_side) < 0.1:
			continue
		rail114(a + o, b + o, 1.0)


## Un champignon lumineux (comme ceux de Port-Boucan, mais qui luit tout le temps : on est sous terre).
func champi114(pos: Vector3, h: float, r: float, couleur: String, lean: float = 0.0, yaw: float = 0.0, collide: bool = true) -> Vector3:
	var bs := Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, deg_to_rad(lean))
	var sr: float = maxf(r * 0.16, 0.05)
	cyl(Transform3D(bs, pos + Vector3.DOWN * 0.2), sr * 1.6, sr * 1.1, h * 0.25 + 0.2, "pied114", 10, false, 1.2)
	cyl(Transform3D(bs, pos + bs * Vector3(0, h * 0.25, 0)), sr * 1.1, sr * 0.9, h * 0.75, "pied114", 10, false, 1.2)
	var top: Vector3 = pos + bs * Vector3(0, h, 0)
	_dome(Transform3D(bs * Basis.from_scale(Vector3(1.0, 0.45, 1.0)), top), r, "champi114_" + couleur, 16, 5)
	disc(Transform3D(bs * Basis(Vector3.RIGHT, PI), top + bs * Vector3(0, 0.02, 0)), r * 0.96, "pied114", 16, r)
	if collide and r > 0.4:
		col_cyl(pos, sr * 1.3, h)
	return top


## Une vieille chaudière couchée, devenue maison (xf : le pied de la porte ronde, qui regarde +Z) :
## un grand cylindre de tôle rivetée, des hublots allumés, une cheminée, une porte. Renvoie la porte.
func chaudiere114(xf: Transform3D, r: float, len: float, color: String, lit: bool = true) -> Vector3:
	var ax := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	var c: Transform3D = xf * T(0, r + 0.25, -len * 0.5)
	cyl(c * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, len * 0.5)), r, r, len, "tole114_" + color, 20, true, 2.0)
	for k in range(4):
		var z: float = -len * 0.5 + 0.3 + k * (len - 0.6) / 3.0
		ring(c * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, z + 0.06)), r - 0.02, r + 0.06, 0.12, "fer114_rouille", 20)
	# les berceaux qui la tiennent
	for z2 in [-len * 0.32, len * 0.32]:
		box(xf * T(0, 0.3, -len * 0.5 + z2), Vector3(r * 1.6, 0.6, 0.5), "fer114_rouille", 1.0)
	# les hublots (des deux côtés), la cheminée
	for s in [-1.0, 1.0]:
		for z3 in [-len * 0.25, len * 0.15]:
			var hp: Transform3D = c * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * (r + 0.01), 0.15, z3))
			disc(hp, 0.32, "lampe114" if lit else "vitre114", 14)
			ring(hp * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.3, 0.4, 0.06, "laiton112", 14)
	cyl(c * T(0, r - 0.1, -len * 0.3), 0.22, 0.2, 1.6, "fer114", 10)
	# la porte ronde, au bout (+Z)
	var dp: Transform3D = xf * T(0, 0.0, 0.0)
	disc(c * T(0, 0, len * 0.5 + 0.01), r, "tole114_" + color, 20)
	box(dp * T(0, 1.05, 0.04), Vector3(0.9, 1.9, 0.06), "bois112", 1.0)
	ring(dp * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.05, 0.06)), 0.55, 0.62, 0.05, "laiton112", 16)
	col_cyl(xf * Vector3(0, 0, -len * 0.5), r * 0.8, r * 2.0 + 0.25)
	return xf * Vector3(0, 0, 1.0)


## Une grande fresque peinte sur un panneau de tôle tenu par deux pieds de fer (xf : le milieu du bas,
## qui regarde +Z).
func fresque114(xf: Transform3D, fid: String, w: float, h: float) -> void:
	box(xf * T(0, h * 0.5 + 0.4, -0.06), Vector3(w + 0.2, h + 0.2, 0.08), "fer114_rouille", 1.0)
	quadz(xf * T(0, h * 0.5 + 0.4, -0.01), w, h, "fresque114_" + fid)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.3), (h + 0.4) * 0.5, -0.2), Vector3(0.12, h + 0.4, 0.12), "fer114", 1.0)
		box(xf * T(s * (w * 0.5 - 0.3), 0.05, -0.2), Vector3(0.5, 0.1, 0.6), "fer114", 1.0)
	col_box(xf * T(0, h * 0.5 + 0.4, -0.1), Vector3(w, h, 0.2))

extends "res://scripts/pirate_kit_v68.gd"
## V69 : les pièces de l'Île des Trois Soleils. Même principe que les autres kits (la
## géométrie regroupée par matériau, les collisions dans un seul corps statique). Les matières
## « …69 » viennent de soleils_mats_v69.gd ; les autres, des kits précédents.
##  - formes : frustum (un tronc de pyramide aux faces inclinées), pyramid (une vraie pyramide,
##    collision convexe), stair (un escalier : marches dessinées, rampe pour marcher), step_pyramid
##    (pyramide à gradins : Mayas, Aztèques) ;
##  - Égypte : mud_house (maison de briques crues à toit-terrasse), pylon (le portail d'un
##    temple), obelisk, papyrus_column, seated_statue, sphinx, shaduf, papyrus_boat, oven,
##    granary, jar, mastaba ;
##  - Mayas : maya_hut (la case ovale au toit de palmes), maya_building (un édifice de pierre
##    stuqué : soubassement, portes en encorbellement, frise, crête faîtière), stela, ball_court,
##    serpent_head, beehive_logs ;
##  - Aztèques : aztec_house (maison d'adobe blanchie, toit-terrasse), shrine (un sanctuaire au
##    sommet d'une pyramide, toit haut et peint), canoe ;
##  - partout : torch_post (une torche sur un poteau), awning69 (un auvent de nattes).

const Mats69 = preload("res://scripts/soleils_mats_v69.gd")

var fires69: Array = []                   # [Vector3, taille] : les feux à allumer (torches, braseros, fours)
var animated69: Array = []                # Node3D animés (balanciers des chadoufs…)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats69.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


## Un corps convexe (collision) à partir de points du monde.
func col_convex(points: PackedVector3Array) -> void:
	var cs := CollisionShape3D.new()
	var sh := ConvexPolygonShape3D.new()
	sh.points = points
	cs.shape = sh
	body.add_child(cs)


## Un rectangle vertical qui regarde +Z local (quad() regarde -Z).
func quadz(xf: Transform3D, w: float, h: float, key: String, uv0: Vector2 = Vector2(0, 0), uv1: Vector2 = Vector2(1, 1)) -> void:
	quad(xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), w, h, key, uv0, uv1)


## Une oriflamme (une bande de tissu qui flotte), d'une matière de ce kit.
func flag69(x: Transform3D, key: String, size := Vector2(1.6, 1.0)) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = 8
	pm.orientation = PlaneMesh.FACE_Z
	var mi := MeshInstance3D.new()
	mi.name = "Oriflamme_" + key
	mi.mesh = pm
	mi.material_override = mat(key)
	mi.transform = x * Transform3D(Basis(), Vector3(size.x * 0.5 + 0.06, 0, 0))
	mi.set_meta("base", mi.transform)
	root.add_child(mi)
	flags.append(mi)
	return mi


# =================================================================== formes

## Un tronc de pyramide : base w0 × d0, sommet w1 × d1, hauteur h ; xf au milieu de la base.
func frustum(xf: Transform3D, w0: float, d0: float, w1: float, d1: float, h: float, key: String, tile: float = 2.0, top: bool = true, top_key: String = "") -> void:
	var a := [Vector3(-w0 * 0.5, 0, -d0 * 0.5), Vector3(w0 * 0.5, 0, -d0 * 0.5), Vector3(w0 * 0.5, 0, d0 * 0.5), Vector3(-w0 * 0.5, 0, d0 * 0.5)]
	var b := [Vector3(-w1 * 0.5, h, -d1 * 0.5), Vector3(w1 * 0.5, h, -d1 * 0.5), Vector3(w1 * 0.5, h, d1 * 0.5), Vector3(-w1 * 0.5, h, d1 * 0.5)]
	for i in range(4):
		var j: int = (i + 1) % 4
		var p0: Vector3 = xf * (a[j] as Vector3)
		var p1: Vector3 = xf * (a[i] as Vector3)
		var p2: Vector3 = xf * (b[i] as Vector3)
		var p3: Vector3 = xf * (b[j] as Vector3)
		var n: Vector3 = (p1 - p0).cross(p3 - p0).normalized()
		var wb: float = p0.distance_to(p1) / tile
		var wt: float = p3.distance_to(p2) / tile
		var sl: float = p0.distance_to(p3) / tile
		var off: float = (wb - wt) * 0.5
		quad4(key, p0, p1, p2, p3, -n if n.dot(xf.basis * ((a[i] as Vector3) + (a[j] as Vector3))) < 0.0 else n,
			Vector2(0, sl), Vector2(wb, sl), Vector2(wb - off, 0), Vector2(off, 0))
	if top:
		box(xf * Transform3D(Basis(), Vector3(0, h - 0.01, 0)), Vector3(w1, 0.02, d1), key if top_key == "" else top_key, tile, 4)


## Une vraie pyramide (Égypte) : quatre faces lisses, le pyramidion doré ; collision convexe.
func pyramid(c: Vector3, base: float, h: float, key: String, cap_key: String = "or69", cap_frac: float = 0.06) -> void:
	var cap_h: float = h * cap_frac
	var w1: float = base * cap_frac
	frustum(Transform3D(Basis(), c), base, base, w1, w1, h - cap_h, key, 3.0, false)
	frustum(Transform3D(Basis(), c + Vector3.UP * (h - cap_h)), w1, w1, 0.02, 0.02, cap_h, cap_key, 1.0, false)
	var pts := PackedVector3Array()
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			pts.append(c + Vector3(sx * base, 0.0, sz * base))
	pts.append(c + Vector3(0, h, 0))
	col_convex(pts)


## Un escalier de a (bas, sur le sol) à b (haut) : des marches dessinées, une rampe pour marcher
## (la pente reste sous 45°). rail : la clé des rampes de côté (rien si "").
func stair(a: Vector3, b: Vector3, w: float, key: String, rail: String = "", rail_h: float = 0.6, rail_w: float = 0.5) -> void:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var run: float = flat.length()
	var rise: float = b.y - a.y
	if run < 0.01:
		return
	var dir: Vector3 = flat / run
	var bs := Basis(Vector3.UP, atan2(dir.x, dir.z))
	var n: int = maxi(int(round(rise / 0.26)), 1)
	for i in range(n):
		var t0: float = float(i) / n
		var p: Vector3 = a + dir * run * (t0 + 0.5 / n)
		var top: float = a.y + rise * float(i + 1) / n
		var hgt: float = top - a.y + 0.02
		box(Transform3D(bs, Vector3(p.x, a.y + hgt * 0.5 - 0.02, p.z)), Vector3(w, hgt, run / n + 0.02), key, 1.6, 4 | 16 | 32 | 1 | 2)
	var slope: float = atan2(rise, run)
	var len3: float = sqrt(run * run + rise * rise)
	var cb: Basis = bs * Basis(Vector3.RIGHT, -slope)
	var mid: Vector3 = (a + b) * 0.5
	col_box(Transform3D(cb, mid + cb * Vector3(0, -0.1, 0)), Vector3(w, 0.2, len3 + 0.25))
	if rail != "":
		for s in [-1.0, 1.0]:
			var off: Vector3 = bs * Vector3(s * (w * 0.5 + rail_w * 0.5), 0, 0)
			box(Transform3D(cb, mid + off + cb * Vector3(0, rail_h * 0.5, 0)), Vector3(rail_w, rail_h, len3 + 0.1), rail, 1.6)
			col_box(Transform3D(cb, mid + off + cb * Vector3(0, rail_h * 0.5, 0)), Vector3(rail_w, rail_h, len3 + 0.1))


## Une pyramide à gradins (Mayas, Aztèques) : n gradins de hauteur th, chacun en retrait,
## murs en talus ; c au milieu de la base. Renvoie le centre du sommet (pour le temple).
func step_pyramid(c: Vector3, base_w: float, base_d: float, tiers: int, th: float, shrink: float, key: String, top_key: String = "", tile: float = 2.5) -> Vector3:
	var w: float = base_w
	var d: float = base_d
	var y: float = 0.0
	for i in range(tiers):
		var w1: float = w - shrink * 0.35
		var d1: float = d - shrink * 0.35
		frustum(Transform3D(Basis(), c + Vector3.UP * y), w, d, w1, d1, th, key, tile, true, key if i < tiers - 1 or top_key == "" else top_key)
		# une moulure en haut de chaque gradin
		box(Transform3D(Basis(), c + Vector3.UP * (y + th - 0.12)), Vector3(w1 + 0.24, 0.24, d1 + 0.24), key, tile)
		col_box(Transform3D(Basis(), c + Vector3.UP * (y + th * 0.5)), Vector3(w1, th, d1))
		y += th
		w -= shrink
		d -= shrink
	return c + Vector3.UP * y


# =================================================================== Égypte

## Une maison de briques crues : murs épais enduits (ou non), porte sombre, petites fenêtres
## hautes, toit-terrasse à parapet, bouts de poutres de palmier, escalier extérieur vers le
## toit, un auvent de nattes et des jarres sur la terrasse. xf : milieu de la base, la façade
## (la porte) regarde +Z. Renvoie la position devant la porte.
func mud_house(xf: Transform3D, w: float, d: float, h: float, opts: Dictionary = {}) -> Vector3:
	var wall: String = str(opts.get("mur", "enduit69_ocre"))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d), wall, 2.2)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d))
	# le soubassement de briques nues, qui s'effrite
	box(xf * Transform3D(Basis(), Vector3(0, 0.25, 0)), Vector3(w + 0.06, 0.5, d + 0.06), "brique69", 1.6)
	# le parapet du toit
	for s in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(0, h + 0.3, s * (d * 0.5 - 0.12))), Vector3(w, 0.6, 0.24), wall, 2.2)
		box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.12), h + 0.3, 0)), Vector3(0.24, 0.6, d - 0.48), wall, 2.2)
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.02, 0)), Vector3(w - 0.4, 0.06, d - 0.4), "limon69", 2.0, 4)
	# les poutres de palmier qui dépassent
	var nb: int = maxi(int(w / 0.9), 2)
	for k in range(nb):
		var x: float = -w * 0.5 + (k + 0.5) * w / nb
		cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, h - 0.2, d * 0.5 - 0.1)), 0.09, 0.09, 0.42, "bois69", 6)
	# la porte, deux fenêtres hautes
	var door: float = float(opts.get("porte_x", 0.0))
	quadz(xf * Transform3D(Basis(), Vector3(door, 1.0, d * 0.5 + 0.01)), 0.95, 2.0, "noir69")
	box(xf * Transform3D(Basis(), Vector3(door, 2.1, d * 0.5 + 0.06)), Vector3(1.3, 0.16, 0.14), "bois69", 1.0)
	for s2 in [-1.0, 1.0]:
		var wx: float = door + s2 * minf(w * 0.3, 1.8)
		if absf(wx) < w * 0.5 - 0.5:
			quadz(xf * Transform3D(Basis(), Vector3(wx, h - 0.75, d * 0.5 + 0.01)), 0.5, 0.35, "noir69")
	# l'escalier du toit, le long d'un pignon
	if bool(opts.get("escalier", true)):
		var sx: float = w * 0.5 + 0.55
		var a: Vector3 = xf * Vector3(sx, 0.0, d * 0.5 - 0.3)
		var b: Vector3 = xf * Vector3(sx, h, -d * 0.5 + 0.6)
		if h / maxf(d - 0.9, 0.5) < 1.0:
			stair(a, b, 1.0, wall, "")
			box(Transform3D(xf.basis, xf * Vector3(sx, h * 0.25, 0)), Vector3(1.0, h * 0.5, d - 0.9), wall, 2.2)
	# un auvent de nattes sur la terrasse, des jarres
	if bool(opts.get("auvent", true)):
		var ax: float = -w * 0.25
		for p in [Vector3(ax - 0.9, h, -0.6), Vector3(ax + 0.9, h, -0.6), Vector3(ax - 0.9, h, 0.6), Vector3(ax + 0.9, h, 0.6)]:
			cyl(xf * Transform3D(Basis(), p), 0.05, 0.05, 1.7, "bois69", 5)
		box(xf * Transform3D(Basis(), Vector3(ax, h + 1.72, 0)), Vector3(2.2, 0.05, 1.6), "palme69", 1.2)
		jar(xf * Vector3(w * 0.25, h, 0.3), 0.6)
		jar(xf * Vector3(w * 0.25 + 0.5, h, -0.2), 0.5)
	return xf * Vector3(door, 0.0, d * 0.5 + 1.2)


## Le portail d'un temple égyptien : deux môles en talus (hiéroglyphes peints), la porte au
## milieu sous sa corniche, des mâts à oriflammes. xf : milieu de la base, l'entrée vers +Z.
func pylon(xf: Transform3D, w: float, h: float, d: float, gate_w: float = 4.0) -> void:
	var tw: float = (w - gate_w) * 0.5
	for s in [-1.0, 1.0]:
		var c: Transform3D = xf * Transform3D(Basis(), Vector3(s * (gate_w * 0.5 + tw * 0.5), 0, 0))
		frustum(c, tw, d, tw * 0.82, d * 0.7, h, "hiero69", 3.0, true, "gres69")
		box(c * Transform3D(Basis(), Vector3(0, h + 0.25, 0)), Vector3(tw * 0.86, 0.5, d * 0.76), "gres69", 2.0)
		col_box(c * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(tw * 0.9, h, d * 0.85))
		# deux mâts devant chaque môle, des oriflammes
		for m in [-0.25, 0.25]:
			var mp: Vector3 = c * Vector3(m * tw, 0, d * 0.5 + 0.35)
			cyl(Transform3D(Basis(), mp), 0.16, 0.1, h + 3.0, "bois69", 6)
			flag69(Transform3D(Basis(), mp + Vector3(0.1, h + 2.4, 0)), "lin69_rouge" if m < 0 else "lin69_bleu", Vector2(0.5, 2.2))
	# la porte : jambages, linteau, corniche à gorge
	var gh: float = h * 0.62
	for s2 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(s2 * (gate_w * 0.5 - 0.3), gh * 0.5, 0)), Vector3(0.6, gh, d * 0.6), "gres69", 2.0)
		col_box(xf * Transform3D(Basis(), Vector3(s2 * (gate_w * 0.5 - 0.3), gh * 0.5, 0)), Vector3(0.6, gh, d * 0.6))
	box(xf * Transform3D(Basis(), Vector3(0, gh + 0.6, 0)), Vector3(gate_w + 0.4, 1.2, d * 0.62), "hiero69", 2.0)
	frustum(xf * Transform3D(Basis(), Vector3(0, gh + 1.2, 0)), gate_w + 0.4, d * 0.62, gate_w + 1.2, d * 0.62 + 0.6, 0.6, "gres69_ocre", 1.0)
	# le disque ailé au-dessus de la porte
	quadz(xf * Transform3D(Basis(), Vector3(0, gh + 0.6, d * 0.31 + 0.02)), 2.6, 0.7, "sym69_soleil")


## Un obélisque : fût effilé de granite rose ou de calcaire, pyramidion doré.
func obelisk(pos: Vector3, h: float, key: String = "gres69_rose") -> void:
	var w: float = h * 0.1
	box(Transform3D(Basis(), pos + Vector3(0, 0.3, 0)), Vector3(w * 1.6, 0.6, w * 1.6), "gres69", 1.5)
	frustum(Transform3D(Basis(), pos + Vector3(0, 0.6, 0)), w, w, w * 0.66, w * 0.66, h * 0.9, key, 1.0, false)
	frustum(Transform3D(Basis(), pos + Vector3(0, 0.6 + h * 0.9, 0)), w * 0.66, w * 0.66, 0.02, 0.02, h * 0.1, "or69", 0.5, false)
	for s in [-1.0, 1.0]:
		quad(Transform3D(Basis(Vector3.UP, PI if s > 0 else 0.0), pos + Vector3(0, 0.6 + h * 0.45, s * (w * 0.42 + 0.005))), w * 0.5, h * 0.7, "sym69_ankh" if s > 0 else "sym69_oeil")
	col_box(Transform3D(Basis(), pos + Vector3(0, h * 0.5, 0)), Vector3(w * 1.2, h, w * 1.2))


## Une colonne papyriforme : base ronde, fût fasciculé, chapiteau en ombelle ouverte, dé.
func papyrus_column(xf: Transform3D, r: float, h: float, key: String = "gres69", paint: bool = true) -> void:
	cyl(xf, r * 1.45, r * 1.45, 0.3, key, 16)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.3, 0)), r * 1.05, r * 0.88, h * 0.78, "hiero69" if paint else key, 16, false, 2.0)
	for k in range(3):
		ring(xf * Transform3D(Basis(), Vector3(0, 0.3 + h * 0.74 + k * 0.12, 0)), r * 0.86, r * 0.95, 0.06, "lapis69" if k == 1 else "or69", 16)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.3 + h * 0.78, 0)), r * 0.88, r * 1.75, h * 0.17, key + "_vert" if paint else key, 16)
	box(xf * Transform3D(Basis(), Vector3(0, 0.3 + h * 0.95 + 0.15, 0)), Vector3(r * 2.1, 0.3, r * 2.1), key, 1.5)
	col_cyl(xf.origin, r * 1.1, h + 0.6)


## Une statue assise (un pharaon sur son trône, coiffé du némès). s : l'échelle (1 = taille humaine).
func seated_statue(xf: Transform3D, s: float, key: String = "statue69_ocre") -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.55 * s, 0)), Vector3(0.9, 1.1, 1.2) * s, key, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 1.15 * s, -0.2 * s)), Vector3(0.62, 0.6, 0.42) * s, key, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 1.6 * s, -0.15 * s)), Vector3(0.7, 0.5, 0.42) * s, key, 1.0)
	for sx in [-0.17, 0.17]:
		box(xf * Transform3D(Basis(), Vector3(sx * s, 1.1 * s, 0.25 * s)), Vector3(0.24, 0.16, 0.7) * s, key, 1.0)
		box(xf * Transform3D(Basis(), Vector3(sx * s, 0.55 * s, 0.55 * s)), Vector3(0.22, 1.1, 0.24) * s, key, 1.0)
	# la tête et le némès
	box(xf * Transform3D(Basis(), Vector3(0, 2.05 * s, -0.12 * s)), Vector3(0.36, 0.44, 0.38) * s, key, 1.0)
	frustum(xf * Transform3D(Basis(), Vector3(0, 1.75 * s, -0.18 * s)), 0.78 * s, 0.32 * s, 0.42 * s, 0.4 * s, 0.6 * s, "statue69_dore", 0.6)
	box(xf * Transform3D(Basis(), Vector3(0, 2.33 * s, -0.16 * s)), Vector3(0.44, 0.14, 0.44) * s, "statue69_dore", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 1.1 * s, 0)), Vector3(0.95, 2.2, 1.3) * s)


## Le Sphinx : un lion couché, les pattes en avant, une tête d'homme coiffée du némès. xf : au
## milieu du corps, la tête vers +Z. s = 1 : 24 m de long.
func sphinx(xf: Transform3D, s: float = 1.0, key: String = "calc69_ocre") -> Vector3:
	var k: String = key
	# le socle taillé dans le roc
	box(xf * Transform3D(Basis(), Vector3(0, 0.6 * s, 0)), Vector3(9.0, 1.2, 26.0) * s, "calc69_dore", 3.0)
	# le corps (le dos qui s'arrondit), la croupe, la queue
	box(xf * Transform3D(Basis(), Vector3(0, 3.6 * s, -2.0 * s)), Vector3(6.4, 4.8, 15.0) * s, k, 3.0)
	cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 6.0 * s, -9.5 * s)), 2.6 * s, 2.6 * s, 15.0 * s, k, 14, true, 3.0)
	box(xf * Transform3D(Basis(), Vector3(0, 3.2 * s, -10.0 * s)), Vector3(6.0, 4.0, 2.0) * s, k, 3.0)
	cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(2.9 * s, 1.6 * s, -9.0 * s)), 0.3 * s, 0.3 * s, 0.4 * s, k, 8)
	# les pattes de devant
	for sx in [-1.9, 1.9]:
		box(xf * Transform3D(Basis(), Vector3(sx * s, 1.8 * s, 8.0 * s)), Vector3(1.8, 1.4, 9.0) * s, k, 2.0)
		for t in [-0.5, 0.0, 0.5]:
			cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3((sx + t) * s, 1.45 * s, 12.6 * s)), 0.3 * s, 0.25 * s, 0.6 * s, k, 8)
	# le poitrail, la tête, le némès, la barbe
	box(xf * Transform3D(Basis(), Vector3(0, 4.6 * s, 5.0 * s)), Vector3(5.4, 6.0, 3.0) * s, k, 3.0)
	frustum(xf * Transform3D(Basis(), Vector3(0, 6.8 * s, 5.6 * s)), 6.0 * s, 3.4 * s, 3.4 * s, 3.4 * s, 3.4 * s, k, 2.0, true)
	box(xf * Transform3D(Basis(), Vector3(0, 8.5 * s, 6.7 * s)), Vector3(2.6, 3.0, 2.0) * s, k, 2.0)
	# le visage : l'arcade, les yeux creusés, le nez, la bouche ; les pans du némès de chaque
	# côté, son dôme strié, l'uræus au front ; la barbe postiche
	box(xf * Transform3D(Basis(), Vector3(0, 9.32 * s, 7.78 * s)), Vector3(2.3, 0.22, 0.2) * s, k, 1.0)
	for sx2 in [-0.55, 0.55]:
		box(xf * Transform3D(Basis(), Vector3(sx2 * s, 8.98 * s, 7.71 * s)), Vector3(0.52, 0.2, 0.04) * s, "psombre69", 1.0)
		box(xf * Transform3D(Basis(), Vector3(sx2 * s, 8.98 * s, 7.735 * s)), Vector3(0.2, 0.12, 0.03) * s, "noir69", 1.0)
	frustum(xf * Transform3D(Basis(), Vector3(0, 8.0 * s, 7.85 * s)), 0.62 * s, 0.4 * s, 0.32 * s, 0.22 * s, 1.0 * s, k, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 7.72 * s, 7.72 * s)), Vector3(0.95, 0.09, 0.05) * s, "psombre69", 1.0)
	for sx3 in [-1.0, 1.0]:
		box(xf * Transform3D(Basis(), Vector3(sx3 * 1.62 * s, 8.1 * s, 6.95 * s)), Vector3(0.62, 3.2, 1.3) * s, k, 1.5)
		for st in range(5):
			box(xf * Transform3D(Basis(), Vector3(sx3 * 1.62 * s, (6.8 + st * 0.62) * s, 7.61 * s)), Vector3(0.64, 0.08, 0.04) * s, "psombre69", 1.0)
	frustum(xf * Transform3D(Basis(), Vector3(0, 9.95 * s, 6.3 * s)), 3.9 * s, 3.2 * s, 2.5 * s, 2.3 * s, 0.95 * s, k, 2.0)
	cyl(xf * Transform3D(Basis(), Vector3(0, 9.95 * s, 7.72 * s)), 0.13 * s, 0.09 * s, 0.5 * s, k, 8)
	box(xf * Transform3D(Basis(), Vector3(0, 6.95 * s, 7.55 * s)), Vector3(0.55, 1.1, 0.45) * s, k, 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 3.5 * s, -1.0 * s)), Vector3(7.0, 7.0, 24.0) * s)
	col_box(xf * Transform3D(Basis(), Vector3(0, 8.0 * s, 6.0 * s)), Vector3(4.0, 5.0, 3.6) * s)
	return xf * Vector3(0, 0, 15.0 * s)


## Un chadouf : deux poteaux, un balancier, un seau d'un côté, un contrepoids de terre de l'autre.
## Renvoie le nœud du balancier (pour l'animer).
func shaduf(xf: Transform3D) -> Node3D:
	for s in [-0.35, 0.35]:
		cyl(xf * Transform3D(Basis(), Vector3(s, 0, 0)), 0.08, 0.07, 2.2, "bois69", 6)
	box(xf * Transform3D(Basis(), Vector3(0, 2.15, 0)), Vector3(0.9, 0.1, 0.12), "bois69", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 1.1, 0)), Vector3(0.9, 2.2, 0.3))
	var arm := Node3D.new()
	arm.name = "Balancier"
	root.add_child(arm)
	arm.global_transform = xf * Transform3D(Basis(), Vector3(0, 2.2, 0))
	var mi := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, 4.6)
	mi.mesh = bm
	mi.material_override = mat("bois69")
	mi.position = Vector3(0, 0, 0.6)
	arm.add_child(mi)
	var cw := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.5
	cw.mesh = sm
	cw.material_override = mat("argile69")
	cw.position = Vector3(0, -0.15, -1.6)
	arm.add_child(cw)
	var rope := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.01
	cm.bottom_radius = 0.01
	cm.height = 1.6
	rope.mesh = cm
	rope.material_override = mat("cordage")
	rope.position = Vector3(0, -0.8, 2.85)
	arm.add_child(rope)
	var bucket := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.16
	bc.bottom_radius = 0.12
	bc.height = 0.26
	bucket.mesh = bc
	bucket.material_override = mat("argile69")
	bucket.position = Vector3(0, -1.65, 2.85)
	arm.add_child(bucket)
	animated69.append(arm)
	return arm


## Une barque de papyrus : un fuseau de bottes liées, les extrémités relevées.
func papyrus_boat(xf: Transform3D, l: float = 5.0) -> void:
	var n: int = 7
	for i in range(n):
		var t0: float = float(i) / n - 0.5
		var t1: float = float(i + 1) / n - 0.5
		var y0: float = 0.25 + pow(absf(t0) * 2.0, 3.0) * 0.9
		var y1: float = 0.25 + pow(absf(t1) * 2.0, 3.0) * 0.9
		var r0: float = 0.42 * (1.0 - pow(absf(t0) * 2.0, 2.0) * 0.75)
		var r1: float = 0.42 * (1.0 - pow(absf(t1) * 2.0, 2.0) * 0.75)
		var a: Vector3 = xf * Vector3(0, y0, t0 * l)
		var b: Vector3 = xf * Vector3(0, y1, t1 * l)
		var ax: Transform3D = axis_xf(a, b)
		cyl(ax, maxf(r0, 0.08), maxf(r1, 0.08), a.distance_to(b), "paille", 10, true, 0.8)
	for k in range(5):
		ring(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), xf * Vector3(0, 0.3, -l * 0.3 + k * l * 0.15)), 0.4, 0.44, 0.04, "cordage", 10)


## Un four à pain de terre (une coupole), une jarre, un grenier à coupole.
func oven(xf: Transform3D) -> Vector3:
	cyl(xf, 0.75, 0.7, 0.5, "argile69_terre", 12)
	cyl(xf * Transform3D(Basis(), Vector3(0, 0.5, 0)), 0.7, 0.05, 0.75, "argile69_terre", 12, false)
	quadz(xf * Transform3D(Basis(), Vector3(0, 0.3, 0.71)), 0.4, 0.35, "noir69")
	col_cyl(xf.origin, 0.75, 1.2)
	fires69.append([xf * Vector3(0, 0.25, 0.6), 0.25])
	return xf * Vector3(0, 0, 1.2)


func jar(pos: Vector3, h: float = 0.8, key: String = "argile69") -> void:
	var xf := Transform3D(Basis(), pos)
	cyl(xf, h * 0.12, h * 0.32, h * 0.35, key, 10)
	cyl(xf * Transform3D(Basis(), Vector3(0, h * 0.35, 0)), h * 0.32, h * 0.2, h * 0.45, key, 10, false)
	cyl(xf * Transform3D(Basis(), Vector3(0, h * 0.8, 0)), h * 0.13, h * 0.16, h * 0.2, key, 10, false)


func granary(xf: Transform3D, r: float = 1.8, h: float = 3.2) -> void:
	cyl(xf, r, r * 0.95, h * 0.55, "enduit69_ocre", 14)
	cyl(xf * Transform3D(Basis(), Vector3(0, h * 0.55, 0)), r * 0.95, 0.15, h * 0.45, "enduit69_ocre", 14, false)
	quadz(xf * Transform3D(Basis(), Vector3(0, h * 0.75, r * 0.62)), 0.5, 0.5, "noir69")
	col_cyl(xf.origin, r, h)


## Un mastaba : une tombe basse en talus, une fausse porte.
func mastaba(xf: Transform3D, w: float, d: float, h: float) -> void:
	frustum(xf, w, d, w - h * 0.5, d - h * 0.5, h, "calc69", 3.0)
	quadz(xf * Transform3D(Basis(), Vector3(0, h * 0.4, d * 0.5 - h * 0.12)), 1.2, h * 0.7, "hiero69")
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w - h * 0.25, h, d - h * 0.25))


# =================================================================== Mayas

## La case maya : murs ovales de torchis blanchi sur un soubassement de pierre, porte sombre,
## grand toit de palmes très pentu. xf : milieu, la porte vers +Z.
func maya_hut(xf: Transform3D, w: float = 6.0, d: float = 3.6, opts: Dictionary = {}) -> Vector3:
	var wall_h: float = float(opts.get("h", 1.9))
	box(xf * Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(w + 0.6, 0.4, d + 0.6), "pmaya69", 2.0)
	var sx: float = w * 0.5
	var sz: float = d * 0.5
	var wall := Transform3D(Basis().scaled(Vector3(1.0, 1.0, sz / sx)), xf * Vector3(0, 0.4, 0))
	wall.basis = xf.basis * wall.basis
	cyl(wall, sx, sx, wall_h, str(opts.get("mur", "enduit69_blanc")), 18, false, 1.5)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.4 + wall_h * 0.5, 0)), Vector3(w * 0.92, wall_h, d * 0.92))
	quadz(xf * Transform3D(Basis(), Vector3(0, 0.4 + 0.85, sz + 0.02)), 0.9, 1.7, "noir69")
	# le toit : un cône allongé en faîtage, très pentu, qui déborde
	var roof := Transform3D(Basis().scaled(Vector3(1.0, 1.0, (sz + 0.5) / (sx + 0.5))), xf * Vector3(0, 0.4 + wall_h, 0))
	roof.basis = xf.basis * roof.basis
	cyl(roof, sx + 0.6, 0.15, float(opts.get("toit_h", 3.4)), "palme69", 16, false, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.4 + wall_h + float(opts.get("toit_h", 3.4)) - 0.1, 0)), Vector3(w * 0.4, 0.2, 0.25), "palme69_sombre", 1.0)
	return xf * Vector3(0, 0, sz + 1.2)


## Un édifice maya de pierre : soubassement, murs stuqués, portes en encorbellement, frise de
## glyphes, toit plat et crête faîtière ajourée. xf : milieu de la base, la façade vers +Z.
## Renvoie la position devant la porte du milieu.
func maya_building(xf: Transform3D, w: float, d: float, h: float, opts: Dictionary = {}) -> Vector3:
	var wall: String = str(opts.get("mur", "stucr69"))
	var doors: int = int(opts.get("portes", 3))
	var base_h: float = float(opts.get("socle", 0.6))
	box(xf * Transform3D(Basis(), Vector3(0, base_h * 0.5, 0)), Vector3(w + 0.8, base_h, d + 0.8), "pmaya69", 2.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, base_h * 0.5, 0)), Vector3(w + 0.8, base_h, d + 0.8))
	var y0: float = base_h
	box(xf * Transform3D(Basis(), Vector3(0, y0 + h * 0.5, 0)), Vector3(w, h, d), wall, 2.2)
	col_box(xf * Transform3D(Basis(), Vector3(0, y0 + h * 0.5, 0)), Vector3(w, h, d))
	for i in range(doors):
		var x: float = -w * 0.5 + (i + 0.5) * w / doors
		# l'ouverture en encorbellement (un trapèze sombre)
		var p0: Vector3 = xf * Vector3(x - 0.6, y0, d * 0.5 + 0.015)
		var p1: Vector3 = xf * Vector3(x + 0.6, y0, d * 0.5 + 0.015)
		var p2: Vector3 = xf * Vector3(x + 0.25, y0 + 2.3, d * 0.5 + 0.015)
		var p3: Vector3 = xf * Vector3(x - 0.25, y0 + 2.3, d * 0.5 + 0.015)
		quad4("noir69", p0, p1, p2, p3, xf.basis * Vector3.BACK, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
		box(xf * Transform3D(Basis(), Vector3(x, y0 + 2.42, d * 0.5 + 0.05)), Vector3(1.1, 0.24, 0.12), "pmaya69", 1.0)
	# la frise : deux moulures et un bandeau de glyphes
	var fy: float = y0 + h * 0.72
	box(xf * Transform3D(Basis(), Vector3(0, fy, 0)), Vector3(w + 0.3, 0.2, d + 0.3), "pmaya69", 2.0)
	box(xf * Transform3D(Basis(), Vector3(0, y0 + h - 0.1, 0)), Vector3(w + 0.4, 0.2, d + 0.4), "pmaya69", 2.0)
	box(xf * Transform3D(Basis(), Vector3(0, (fy + y0 + h) * 0.5, 0)), Vector3(w + 0.12, y0 + h - fy - 0.2, d + 0.12), "glyphm69", 1.6, 1 | 2 | 16 | 32)
	# la crête faîtière : un mur ajouré au-dessus du toit
	if bool(opts.get("crete", true)):
		var ch: float = float(opts.get("crete_h", h * 0.8))
		var cy: float = y0 + h
		for k in range(3):
			var cw: float = w * (0.6 - k * 0.12)
			box(xf * Transform3D(Basis(), Vector3(0, cy + ch * (k + 0.5) / 3.0, -d * 0.1)), Vector3(cw, ch / 3.0 - 0.15, 0.5), wall if k % 2 == 0 else "pmaya69", 1.6)
			for j in range(3):
				quadz(xf * Transform3D(Basis(), Vector3((j - 1) * cw * 0.3, cy + ch * (k + 0.5) / 3.0, -d * 0.1 + 0.26)), cw * 0.14, ch / 3.0 * 0.5, "noir69")
	return xf * Vector3(0, 0, d * 0.5 + 1.6)


## Une stèle : une dalle de pierre sculptée (face : une clé de matière), un autel rond devant.
func stela(xf: Transform3D, w: float, h: float, face: String = "glyphm69", altar: bool = true) -> void:
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.55), "pmaya69", 1.2)
	quadz(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0.28)), w * 0.92, h * 0.94, face)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.55))
	if altar:
		cyl(xf * Transform3D(Basis(), Vector3(0, 0, 1.6)), 0.75, 0.72, 0.6, "pmaya69", 14)
		col_cyl(xf * Vector3(0, 0, 1.6), 0.75, 0.6)


## Une tête de serpent à plumes (au pied d'un escalier) : la gueule ouverte, les crocs, la
## crête de plumes. xf : au sol, la gueule vers +Z.
func serpent_head(xf: Transform3D, s: float = 1.0, key: String = "pmaya69") -> void:
	box(xf * Transform3D(Basis(), Vector3(0, 0.55 * s, 0)), Vector3(1.4, 1.1, 1.8) * s, key, 1.0)
	box(xf * Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 1.25 * s, 0.25 * s)), Vector3(1.3, 0.55, 1.7) * s, key, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.62 * s, 0.92 * s)), Vector3(1.0, 0.35, 0.06) * s, "noir69", 1.0)
	for sx in [-0.38, -0.13, 0.13, 0.38]:
		cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(sx * s, 0.98 * s, 0.86 * s)), 0.06 * s, 0.0, 0.3 * s, "calc69", 5)
	for sx2 in [-0.45, 0.45]:
		box(xf * Transform3D(Basis(), Vector3(sx2 * s, 1.45 * s, 0.7 * s)), Vector3(0.22, 0.22, 0.1) * s, "jade69", 1.0)
	for k in range(5):
		box(xf * Transform3D(Basis(Vector3.RIGHT, -0.6 + k * 0.08), Vector3(0, 1.7 * s, -0.4 * s - k * 0.2 * s)), Vector3(1.5 - k * 0.1, 0.12, 0.5) * s, "plume69", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.8 * s, 0)), Vector3(1.4, 1.6, 1.9) * s)


## Le terrain de jeu de balle : deux longs talus et leurs murs, un anneau de pierre au milieu de
## chaque mur. xf : au milieu de l'allée, l'allée selon Z. Renvoie les centres des anneaux.
func ball_court(xf: Transform3D, length: float, alley: float, wall_h: float) -> Array:
	var rings: Array = []
	for s in [-1.0, 1.0]:
		var bx: float = s * (alley * 0.5 + 1.2)
		# le talus incliné (on y fait rouler la balle), puis le mur vertical
		var p0: Vector3 = xf * Vector3(s * alley * 0.5, 0.0, -length * 0.5)
		var p1: Vector3 = xf * Vector3(s * alley * 0.5, 0.0, length * 0.5)
		var p2: Vector3 = xf * Vector3(bx + s * 1.2, 1.4, length * 0.5)
		var p3: Vector3 = xf * Vector3(bx + s * 1.2, 1.4, -length * 0.5)
		var n: Vector3 = xf.basis * Vector3(-s * 0.76, 0.65, 0).normalized()
		if s > 0:
			quad4("stucr69_blanc", p0, p1, p2, p3, n, Vector2(0, 1), Vector2(length / 2.5, 1), Vector2(length / 2.5, 0), Vector2(0, 0))
		else:
			quad4("stucr69_blanc", p1, p0, p3, p2, n, Vector2(0, 1), Vector2(length / 2.5, 1), Vector2(length / 2.5, 0), Vector2(0, 0))
		var wx: float = bx + s * 1.7
		box(xf * Transform3D(Basis(), Vector3(wx, wall_h * 0.5, 0)), Vector3(1.0, wall_h, length), "pmaya69", 2.5)
		col_box(xf * Transform3D(Basis(), Vector3(wx, wall_h * 0.5, 0)), Vector3(1.0, wall_h, length))
		col_box(xf * Transform3D(Basis(), Vector3(bx + s * 0.4, 0.5, 0)), Vector3(2.0, 1.0, length))
		box(xf * Transform3D(Basis(), Vector3(wx, wall_h + 0.15, 0)), Vector3(1.3, 0.3, length + 0.3), "pmaya69", 2.0)
		# l'anneau de pierre, vertical, au milieu du mur
		var rc: Vector3 = xf * Vector3(wx - s * 0.6, wall_h * 0.62, 0)
		ring(Transform3D(xf.basis * Basis(Vector3.BACK, PI * 0.5), rc), 0.38, 0.7, 0.28, "pmaya69", 20)
		rings.append(rc)
	return rings


## Des ruches de troncs creux (les abeilles sans dard des Mayas), sous un petit toit.
func beehive_logs(xf: Transform3D, n: int = 5) -> void:
	for s in [-1.0, 1.0]:
		cyl(xf * Transform3D(Basis(), Vector3(s * 1.4, 0, 0)), 0.07, 0.07, 1.4, "bois69", 6)
	for k in range(n):
		cyl(xf * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(1.1, 0.5 + (k % 2) * 0.32, -0.1 + (k / 2) * 0.05)) * Transform3D(Basis(), Vector3(0, -k * 0.0, 0)), 0.15, 0.15, 2.2, "bois69_sombre", 8)
	box(xf * Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 1.45, 0)), Vector3(3.2, 0.06, 1.2), "palme69", 1.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, 0.7, 0)), Vector3(3.0, 1.4, 0.6))


# =================================================================== Aztèques

## Une maison d'adobe blanchie, un bandeau peint, une porte à rideau, un toit-terrasse ; un
## petit patio fermé derrière (xf : milieu de la façade sur rue, la porte vers +Z).
func aztec_house(xf: Transform3D, w: float, d: float, h: float, opts: Dictionary = {}) -> Vector3:
	var wall: String = str(opts.get("mur", "enduit69_blanc"))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, -d * 0.5)), Vector3(w, h, d), wall, 2.2)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, -d * 0.5)), Vector3(w, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, 0.3, -d * 0.5)), Vector3(w + 0.05, 0.6, d + 0.05), "tezo69", 1.5)
	box(xf * Transform3D(Basis(), Vector3(0, h - 0.45, -d * 0.5)), Vector3(w + 0.04, 0.5, d + 0.04), "frise69", 2.0, 1 | 2 | 16 | 32)
	box(xf * Transform3D(Basis(), Vector3(0, h + 0.15, -d * 0.5)), Vector3(w + 0.2, 0.3, d + 0.2), "tezo69", 1.5)
	quadz(xf * Transform3D(Basis(), Vector3(float(opts.get("porte_x", 0.0)), 1.0, 0.012)), 1.0, 2.0, "noir69")
	quadz(xf * Transform3D(Basis(), Vector3(float(opts.get("porte_x", 0.0)), 1.15, 0.03)), 1.0, 1.7, "lin69_" + str(opts.get("rideau", "rouge")))
	if bool(opts.get("patio", false)):
		for s in [-1.0, 1.0]:
			box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.2), 0.9, -d - 2.0)), Vector3(0.4, 1.8, 4.0), wall, 2.0)
			col_box(xf * Transform3D(Basis(), Vector3(s * (w * 0.5 - 0.2), 0.9, -d - 2.0)), Vector3(0.4, 1.8, 4.0))
		box(xf * Transform3D(Basis(), Vector3(0, 0.9, -d - 4.0)), Vector3(w, 1.8, 0.4), wall, 2.0)
		col_box(xf * Transform3D(Basis(), Vector3(0, 0.9, -d - 4.0)), Vector3(w, 1.8, 0.4))
	return xf * Vector3(float(opts.get("porte_x", 0.0)), 0.0, 1.2)


## Un sanctuaire au sommet d'une pyramide (le Grand Temple) : une salle aux murs peints, une
## porte sombre, un haut toit en talus orné (bleu et blanc pour Tlaloc, rouge pour
## Huitzilopochtli). xf : milieu de la base, la porte vers +Z.
func shrine(xf: Transform3D, w: float, d: float, h: float, color: String) -> Vector3:
	var paint: String = "enduit69_bleu" if color == "bleu" else "enduit69_rouge"
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d), "enduit69_blanc", 2.0)
	col_box(xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), Vector3(w, h, d))
	box(xf * Transform3D(Basis(), Vector3(0, h * 0.85, 0)), Vector3(w + 0.05, h * 0.3, d + 0.05), "frise69", 1.6, 1 | 2 | 16 | 32)
	quadz(xf * Transform3D(Basis(), Vector3(0, h * 0.36, d * 0.5 + 0.015)), w * 0.36, h * 0.72, "noir69")
	# le haut toit : des bandes peintes
	var rh: float = h * 1.4
	for k in range(5):
		var y: float = h + k * rh / 5.0
		var shrink: float = 0.88 - k * 0.07
		var key: String = paint if (k % 2 == 0) else ("enduit69_blanc" if color == "bleu" else "frise69")
		frustum(xf * Transform3D(Basis(), Vector3(0, y, 0)), w * (shrink + 0.07), d * (shrink + 0.07), w * shrink, d * shrink, rh / 5.0, key, 1.6)
	# les créneaux : pour Tlaloc des escargots (des disques), pour Huitzilopochtli des papillons
	for i in range(5):
		var x: float = -w * 0.4 + i * w * 0.2
		cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, h + rh + 0.35, 0)), 0.28, 0.28, 0.2, "enduit69_blanc" if color == "bleu" else "enduit69_rouge", 10)
	return xf * Vector3(0, 0, d * 0.5 + 1.5)


## Une pirogue creusée dans un tronc (acalli).
func canoe(xf: Transform3D, l: float = 4.5) -> void:
	var n: int = 6
	for i in range(n):
		var t0: float = float(i) / n - 0.5
		var t1: float = float(i + 1) / n - 0.5
		var r0: float = 0.38 * (1.0 - pow(absf(t0) * 2.0, 3.0) * 0.6)
		var r1: float = 0.38 * (1.0 - pow(absf(t1) * 2.0, 3.0) * 0.6)
		var a: Vector3 = xf * Vector3(0, 0.15, t0 * l)
		var b: Vector3 = xf * Vector3(0, 0.15, t1 * l)
		cyl(axis_xf(a, b), r0, r1, a.distance_to(b), "bois69_sombre", 10, true, 1.0)
	box(xf * Transform3D(Basis(), Vector3(0, 0.33, 0)), Vector3(0.55, 0.04, l * 0.8), "noir69", 1.0)


# =================================================================== partout

## Une torche sur un poteau (le feu est posé par le chef d'orchestre, la nuit). Renvoie la flamme.
func torch_post(pos: Vector3, h: float = 2.2) -> Vector3:
	cyl(Transform3D(Basis(), pos), 0.07, 0.05, h, "bois69", 6)
	cyl(Transform3D(Basis(), pos + Vector3(0, h - 0.05, 0)), 0.08, 0.13, 0.25, "bronze69", 8)
	col_cyl(pos, 0.1, h)
	var f: Vector3 = pos + Vector3(0, h + 0.25, 0)
	fires69.append([f, 0.35])
	return f


## Un auvent de nattes sur quatre poteaux. xf : au sol, au milieu.
func awning69(xf: Transform3D, w: float, d: float, h: float = 2.3, key: String = "palme69") -> void:
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			cyl(xf * Transform3D(Basis(), Vector3(sx * w, 0, sz * d)), 0.06, 0.05, h + (0.2 if sz < 0 else 0.0), "bois69", 6)
	box(xf * Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, h + 0.1, 0)), Vector3(w + 0.4, 0.05, d + 0.4), key, 1.2)

extends "res://scripts/boucan_kit_v75.gd"
## V76 : le kit d'Astralys, la cité de cristal et de lumière des Lumens. Toutes les pièces des
## kits d'avant (boîtes, cylindres, escaliers, lampes, pièces répétées en MultiMesh…), et :
##  - spire76 : la Flèche de Cristal (une tour-flèche de cristal de 110 m, des anneaux de métal
##    perle, le Cœur qui pulse en haut) et, à son pied, la Salle du Conseil ;
##  - pavilion76 : un pavillon rond (des panneaux de nacre, de grandes baies, un dôme, un oculus
##    lumineux), creux, avec une porte : le Café, le Bazar, le Musée, l'Académie, la Serre… ;
##  - bubble76 : une maison-bulle (un dôme translucide sur un socle nacré) ;
##  - bridge76 : un pont de lumière ; lamp76 : un lampadaire à globe flottant ; bench76 : un banc
##    qui flotte ; holo76 : un panneau holographique ; fountain76 : la fontaine holographique ;
##  - fleurs et arbres de cristal (pièces répétées) ; saucer76 : une soucoupe ; pad76 : une aire
##    d'atterrissage ; arch76 : une arche ; telescope76 : le grand télescope.

const Mats76 = preload("res://scripts/astrale_mats_v76.gd")

var real_lights: Array = []              # les lumières vraies (pour la nuit)


func mat(key: String) -> Material:
	if mats.has(key):
		return mats[key]
	var m: Material = Mats76.make(key)
	if m != null:
		mats[key] = m
		return m
	return super.mat(key)


# =================================================================== formes de base

## Un dôme (une demi-sphère aplatie : rayon r, hauteur rise), posé sur xf.origin, vers +Y.
func dome76(xf: Transform3D, r: float, rise: float, key: String, seg: int = 24, rings: int = 8, from_ring: int = 0) -> void:
	for k in range(from_ring, rings):
		var b0: float = PI * 0.5 * k / rings
		var b1: float = PI * 0.5 * (k + 1) / rings
		for i in range(seg):
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var p00 := Vector3(cos(a0) * cos(b0) * r, sin(b0) * rise, sin(a0) * cos(b0) * r)
			var p10 := Vector3(cos(a1) * cos(b0) * r, sin(b0) * rise, sin(a1) * cos(b0) * r)
			var p11 := Vector3(cos(a1) * cos(b1) * r, sin(b1) * rise, sin(a1) * cos(b1) * r)
			var p01 := Vector3(cos(a0) * cos(b1) * r, sin(b1) * rise, sin(a0) * cos(b1) * r)
			var nm: Vector3 = (xf.basis * Vector3(p00.x + p11.x, (p00.y + p11.y) * r / maxf(rise, 0.01), p00.z + p11.z)).normalized()
			var u0: float = float(i) / seg * 4.0
			var u1: float = float(i + 1) / seg * 4.0
			quad4(key, xf * p00, xf * p10, xf * p11, xf * p01, nm, Vector2(u0, 1.0 - float(k) / rings), Vector2(u1, 1.0 - float(k) / rings), Vector2(u1, 1.0 - float(k + 1) / rings), Vector2(u0, 1.0 - float(k + 1) / rings))


## Un anneau lumineux plat (une ligne de lumière autour d'un rond).
func glow_ring76(xf: Transform3D, r: float, w: float, color: String, seg: int = 32) -> void:
	ring(xf, r - w * 0.5, r + w * 0.5, 0.04, "lumiere76_" + color, seg)


# =================================================================== la Flèche de Cristal

## La Flèche de Cristal (c : le centre, au sol du dais). Renvoie {heart, hall_door, hall_inside,
## council, top}.
func spire76(c: Vector3) -> Dictionary:
	var out := {}
	# la Salle du Conseil, au pied : un pavillon rond de 15 m, porte au sud (+Z)
	var hall: Dictionary = pavilion76(Transform3D(Basis(), c), 15.0, 8.0, {"door_dir": Vector3(0, 0, 1), "wall": "nacre76_", "glass": "verre76", "roof": "none", "glow": "or", "doors": 1})
	out["hall_door"] = hall["door"]
	out["hall_inside"] = hall["inside"]
	# le plafond de la salle : un anneau de métal perle autour du pied de la flèche
	ring(Transform3D(Basis(), c + Vector3.UP * 8.0), 6.4, 15.6, 0.6, "metal76_", 40)
	dome76(Transform3D(Basis(), c + Vector3.UP * 8.6), 15.6, 3.0, "nacre76_bleu", 40, 6)
	# la flèche : des tronçons hexagonaux de cristal, des bagues de métal perle, qui s'affinent
	var y: float = 8.0
	var r: float = 6.2
	var k: int = 0
	while y < 104.0:
		var hseg: float = 11.0 if y < 60.0 else 9.0
		var r1: float = maxf(r * 0.86, 1.1)
		cyl(Transform3D(Basis(), c + Vector3.UP * y), r, r1, hseg, "cristal76_" + ["blanc", "bleu", "violet"][k % 3], 6, false, 4.0)
		ring(Transform3D(Basis(), c + Vector3.UP * (y + hseg - 0.25)), r1 * 0.9, r1 + 0.45, 0.5, "metal76_or" if k % 2 == 0 else "metal76_", 6)
		y += hseg
		r = r1
		k += 1
	# la pointe
	cyl(Transform3D(Basis(), c + Vector3.UP * y), r, 0.0, 14.0, "cristal76_blanc", 6, false, 4.0)
	out["top"] = c + Vector3.UP * (y + 14.0)
	# le Cœur : une grande sphère de lumière tenue dans une cage d'arcs, aux deux tiers
	var hy: float = 72.0
	out["heart"] = c + Vector3.UP * hy
	for i in range(6):
		var a: float = TAU * i / 6.0
		beam(c + Vector3(cos(a) * 4.0, hy - 6.0, sin(a) * 4.0), c + Vector3(cos(a) * 6.5, hy, sin(a) * 6.5), 0.22, "metal76_or")
		beam(c + Vector3(cos(a) * 6.5, hy, sin(a) * 6.5), c + Vector3(cos(a) * 4.0, hy + 6.0, sin(a) * 4.0), 0.22, "metal76_or")
	# le sol physique : la salle (ses murs) et le fût (on ne passe pas au travers)
	col_cyl(c + Vector3.UP * 8.0, 6.4, 100.0)
	out["council"] = c + Vector3(0, 0.05, -5.0)
	return out


# =================================================================== les pavillons

## Un pavillon rond (xf : le centre au sol ; rayon r ; hauteur des murs h). opts : door_dir (la
## porte regarde cette direction), wall (« nacre76_ »), glass (« verre76 »), roof (« dome »,
## « flat », « none »), glow (couleur de l'anneau lumineux), doors (1 ou 2 : la deuxième en face).
## Renvoie {door (devant la porte, dehors), inside (le milieu), top}.
func pavilion76(xf: Transform3D, r: float, h: float, opts: Dictionary = {}) -> Dictionary:
	var dd: Vector3 = (opts.get("door_dir", Vector3(0, 0, 1)) as Vector3).normalized()
	var wall: String = str(opts.get("wall", "nacre76_"))
	var glass: String = str(opts.get("glass", "verre76"))
	var roof: String = str(opts.get("roof", "dome"))
	var glowc: String = str(opts.get("glow", "bleu"))
	var ndoors: int = int(opts.get("doors", 1))
	var c: Vector3 = xf.origin
	var seg: int = maxi(int(TAU * r / 3.2), 12)
	var door_a: float = atan2(dd.z, dd.x)
	var door_w: float = 2.6
	# le socle : une marche de nacre tout autour, le sol intérieur
	ring(Transform3D(Basis(), c), r - 0.2, r + 0.9, 0.22, "nacresol76", seg)
	disc(Transform3D(Basis(), c + Vector3.UP * 0.04), r, "nacresol76", seg, 3.0)
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		var am: float = (a0 + a1) * 0.5
		var is_door: bool = absf(wrapf(am - door_a, -PI, PI)) * r < door_w * 0.6
		if ndoors > 1 and absf(wrapf(am - door_a - PI, -PI, PI)) * r < door_w * 0.6:
			is_door = true
		var p0 := c + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var mid: Vector3 = (p0 + p1) * 0.5
		var wl: float = p0.distance_to(p1)
		var face := Transform3D(Basis.looking_at(-(mid - c).normalized(), Vector3.UP), mid)
		if is_door:
			# le linteau au-dessus de la porte, et le seuil qui luit
			box(face * T(0, h - 0.9, 0), Vector3(wl + 0.05, 1.8, 0.4), wall, 2.0)
			box(face * T(0, 0.03, 0.3), Vector3(wl, 0.04, 0.7), "motif76_" + glowc, 1.0)
			continue
		# le pied (nacre), la baie (verre), la frise (nacre), un montant de métal
		box(face * T(0, 0.6, 0), Vector3(wl + 0.05, 1.2, 0.4), wall, 2.0)
		if i % 3 != 1:
			box(face * T(0, 1.2 + (h - 2.4) * 0.5, 0), Vector3(wl + 0.04, h - 2.4, 0.08), glass, 2.0)
		else:
			box(face * T(0, 1.2 + (h - 2.4) * 0.5, 0), Vector3(wl + 0.05, h - 2.4, 0.4), wall, 2.0)
		box(face * T(0, h - 0.6, 0), Vector3(wl + 0.05, 1.2, 0.42), wall, 2.0)
		box(face * T(wl * 0.5, h * 0.5, 0.05), Vector3(0.16, h, 0.5), "metal76_", 1.0)
		col_box(face * T(0, h * 0.5, 0), Vector3(wl + 0.1, h, 0.45))
	# la frise lumineuse, en haut
	glow_ring76(Transform3D(Basis(), c + Vector3.UP * (h - 0.05)), r + 0.25, 0.12, glowc, seg)
	var top: float = h
	match roof:
		"dome":
			var rise: float = r * 0.62
			dome76(Transform3D(Basis(), c + Vector3.UP * h), r + 0.3, rise, "nacre76_", seg, 7, 0)
			# l'oculus : un disque de verre lumineux au sommet
			disc(Transform3D(Basis(), c + Vector3.UP * (h + rise - 0.05)), r * 0.25, "cristal76_" + glowc, 16)
			top = h + rise
		"flat":
			box(Transform3D(Basis(), c + Vector3.UP * (h + 0.15)), Vector3(r * 2.0, 0.3, r * 2.0), wall, 3.0, 4 | 8)
	# une lumière dans la salle (douce)
	var l := OmniLight3D.new()
	l.light_color = Mats76.LUEURS.get(glowc, Color(0.8, 0.9, 1.0)).lerp(Color(1, 1, 1), 0.5)
	l.light_energy = 1.1
	l.omni_range = r * 1.5
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 70.0
	l.distance_fade_length = 15.0
	root.add_child(l)
	l.global_position = c + Vector3.UP * (h - 1.0)
	real_lights.append(l)
	return {"door": c + dd * (r + 1.8) + Vector3.UP * 0.05, "inside": c + Vector3.UP * 0.05, "top": c + Vector3.UP * top}


## Une maison-bulle (xf : le centre au sol, la porte vers +Z local). Renvoie le devant de la porte.
func bubble76(xf: Transform3D, r: float, color: String) -> Vector3:
	cyl(xf, r, r, 1.0, "nacre76_" + ("rose" if color == "rose" else ""), 18, false, 2.0)
	ring(xf * T(0, 1.0, 0), r - 0.15, r + 0.15, 0.16, "metal76_", 18)
	dome76(xf * T(0, 1.0, 0), r, r * 0.85, "verre76", 18, 6, 0)
	dome76(xf * T(0, 1.0, 0), r - 0.06, r * 0.84, "nacre76_" + ("lavande" if color == "violet" else "bleu"), 18, 6, 3)
	# la porte : un ovale lumineux
	var df: Transform3D = xf * T(0, 1.1, r - 0.05)
	box(df, Vector3(1.2, 2.1, 0.12), "vitre76_on", 1.0)
	cyl(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.2, r + 0.02)), 0.62, 0.62, 0.06, "lumiere76_" + color, 14, false)
	# deux hublots
	for s in [-1.0, 1.0]:
		var a: float = s * 0.9
		cyl(xf * Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(sin(a) * r * 0.93, 2.1, cos(a) * r * 0.93)), 0.36, 0.36, 0.05, "vitre76_on", 12, true)
	col_cyl(xf.origin, r, r * 0.85 + 1.0)
	return xf * Vector3(0, 0.05, r + 1.4)


# =================================================================== ponts, lampes, bancs, holos

## Un pont de lumière de a à b (deux points au niveau du tablier), large de w.
func bridge76(a: Vector3, b: Vector3, w: float, color: String = "turquoise") -> void:
	var d: Vector3 = b - a
	var len: float = d.length()
	var mid: Vector3 = (a + b) * 0.5
	var xf := Transform3D(Basis.looking_at(-d.normalized(), Vector3.UP), mid)
	box(xf * T(0, -0.08, 0), Vector3(w, 0.16, len), "pont76_" + color, 2.0)
	for s in [-1.0, 1.0]:
		box(xf * T(s * (w * 0.5 - 0.06), 0.9, 0), Vector3(0.06, 0.06, len), "lumiere76_" + color, 1.0)
		var n: int = maxi(int(len / 3.0), 1)
		for k in range(n + 1):
			box(xf * T(s * (w * 0.5 - 0.06), 0.45, -len * 0.5 + len * k / n), Vector3(0.05, 0.9, 0.05), "metal76_", 1.0)
		col_box(xf * T(s * (w * 0.5), 0.6, 0), Vector3(0.1, 1.2, len))
	col_box(xf * T(0, -0.1, 0), Vector3(w, 0.2, len))


## Un lampadaire : un fût fin de métal perle, un globe de lumière qui flotte au-dessus.
func lamp76(pos: Vector3, color: String = "blanc", real: bool = false) -> void:
	place("lampadaire76|" + color, Transform3D(Basis(), pos))
	col_cyl(pos, 0.14, 3.6)
	_lamp_light(pos + Vector3.UP * 3.9, 1.4, 12.0, real)
	var l: Variant = lamps70[-1]
	if l != null:
		(l as OmniLight3D).light_color = Mats76.LUEURS.get(color, Color(0.9, 0.95, 1.0)).lerp(Color(1, 1, 1), 0.4)


## Un banc qui flotte (xf : le milieu, on s'assoit vers +Z). Renvoie la place assise.
func bench76(xf: Transform3D) -> Vector3:
	place("banc76", xf)
	col_box(xf * T(0, 0.3, 0), Vector3(2.0, 0.6, 0.7))
	return xf * Vector3(0, 0.5, 0.2)


## Un panneau holographique (xf : le milieu du panneau, on le lit depuis +Z) : un socle-projecteur
## et l'image qui flotte.
func holo76(xf: Transform3D, w: float, h: float, n: int) -> void:
	cyl(xf * T(0, -h * 0.5 - 0.9, 0), 0.35, 0.28, 0.25, "metal76_", 12)
	disc(xf * T(0, -h * 0.5 - 0.64, 0), 0.26, "lumiere76_bleu", 12)
	quadz(xf, w, h, "holo76_" + str(n))
	quadz(xf * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO), w, h, "holo76_" + str(n))


## La fontaine holographique (c : le centre au sol). Renvoie le centre du jet (pour les planètes).
func fountain76(c: Vector3, r: float) -> Vector3:
	ring(Transform3D(Basis(), c), r - 0.5, r, 0.7, "nacre76_", 40)
	disc(Transform3D(Basis(), c + Vector3.UP * 0.45), r - 0.45, "eau76", 40)
	disc(Transform3D(Basis(), c + Vector3.UP * 0.05), r - 0.45, "cristalsol76", 40)
	glow_ring76(Transform3D(Basis(), c + Vector3.UP * 0.72), r - 0.25, 0.1, "turquoise", 40)
	cyl(Transform3D(Basis(), c), 1.2, 0.9, 1.3, "nacre76_bleu", 16)
	cyl(Transform3D(Basis(), c + Vector3.UP * 1.3), 0.22, 0.05, 5.0, "eau76", 10, false)
	col_cyl(c, r, 0.8)
	return c + Vector3.UP * 5.0


## Une soucoupe posée (xf : le centre au sol). Une lentille de métal nacré, une coupole de verre,
## un anneau de lumières.
func saucer76(xf: Transform3D, r: float) -> void:
	for s in [-1.0, 1.0]:
		cyl(xf * T(0, 1.2, 0) * Transform3D(Basis.from_scale(Vector3(1, s, 1)), Vector3.ZERO), r, r * 0.3, r * 0.22, "soucoupe76", 28, true, 3.0)
	ring(xf * T(0, 1.12, 0), r * 0.98, r * 1.04, 0.16, "lumiere76_turquoise", 28)
	dome76(xf * T(0, 1.2 + r * 0.22, 0), r * 0.32, r * 0.28, "verre76", 18, 6)
	for k in range(3):
		var a: float = TAU * k / 3.0
		beam(xf * Vector3(cos(a) * r * 0.45, 0.85, sin(a) * r * 0.45), xf * Vector3(cos(a) * r * 0.6, 0.0, sin(a) * r * 0.6), 0.1, "metal76_")
		cyl(xf * T(cos(a) * r * 0.6, 0, sin(a) * r * 0.6), 0.25, 0.25, 0.06, "metal76_", 10)
	col_cyl(xf.origin + Vector3.UP * 0.8, r * 0.95, r * 0.45)


## Une aire d'atterrissage (c : le centre au sol).
func pad76(c: Vector3, r: float) -> void:
	disc(Transform3D(Basis(), c + Vector3.UP * 0.06), r, "cristalsol76", 40, 4.0)
	glow_ring76(Transform3D(Basis(), c + Vector3.UP * 0.08), r - 0.4, 0.25, "turquoise", 40)
	glow_ring76(Transform3D(Basis(), c + Vector3.UP * 0.08), r * 0.45, 0.18, "or", 32)


## Une arche (xf : le milieu du pied, l'arche dans le plan XY local), large de w, haute de h.
func arch76(xf: Transform3D, w: float, h: float, color: String = "or") -> void:
	var seg: int = 14
	var prev: Vector3 = xf * Vector3(-w * 0.5, 0, 0)
	for i in range(1, seg + 1):
		var a: float = PI * float(i) / seg
		var p: Vector3 = xf * Vector3(-cos(a) * w * 0.5, sin(a) * h, 0)
		beam(prev, p, 0.45, "nacre76_")
		prev = p
	var prev2: Vector3 = xf * Vector3(-w * 0.5 + 0.35, 0, 0.0)
	for i2 in range(1, seg + 1):
		var a2: float = PI * float(i2) / seg
		var p2: Vector3 = xf * Vector3(-cos(a2) * (w * 0.5 - 0.35), sin(a2) * (h - 0.35), 0.0)
		beam(prev2, p2, 0.1, "lumiere76_" + color)
		prev2 = p2
	for s in [-1.0, 1.0]:
		col_cyl(xf * Vector3(s * w * 0.5, 0, 0), 0.35, h * 0.4)


## Le grand télescope de l'Observatoire (xf : le pied ; il vise le ciel vers +Z).
func telescope76(xf: Transform3D) -> void:
	cyl(xf, 1.2, 0.9, 1.6, "metal76_", 16)
	var tube: Transform3D = xf * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(55.0)), Vector3(0, 2.2, 0))
	cyl(tube * T(0, -3.0, 0), 0.7, 0.9, 9.0, "metal76_bleu", 18)
	ring(tube * T(0, 5.9, 0), 0.8, 1.0, 0.3, "metal76_or", 18)
	disc(tube * T(0, 5.95, 0), 0.82, "cristal76_bleu", 18)
	col_cyl(xf.origin, 1.3, 2.0)


# =================================================================== les pièces répétées

func proto(key: String) -> ArrayMesh:
	if protos.has(key):
		return protos[key]
	var parts: PackedStringArray = key.split("|")
	var kind: String = parts[0]
	if not kind.ends_with("76"):
		return super.proto(key)
	var color: String = parts[1] if parts.size() > 1 else "bleu"
	var saved: Dictionary = batch
	batch = {}
	var I := Transform3D.IDENTITY
	match kind:
		"lampadaire76":
			cyl(I, 0.12, 0.06, 3.5, "metal76_", 8)
			ring(T(0, 3.5, 0), 0.05, 0.3, 0.04, "metal76_or", 12)
			ball(T(0, 3.9, 0), 0.26, "lumiere76_" + color, 10, 6)
		"banc76":
			box(T(0, 0.48, 0), Vector3(1.9, 0.12, 0.55), "nacre76_", 1.0)
			box(T(0, 0.8, -0.24), Vector3(1.9, 0.5, 0.08), "nacre76_", 1.0)
			box(T(0, 0.38, 0), Vector3(1.6, 0.04, 0.4), "lumiere76_turquoise", 1.0)
		"fleur76":
			# une fleur géante (unité : 1 m de haut ; on l'étire à la pose) : une tige, six pétales
			# lumineux, un pistil
			cyl(I, 0.05, 0.035, 1.0, "tige76", 6)
			for k in range(6):
				var a: float = TAU * k / 6.0
				var pxf := Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.RIGHT, -0.95), Vector3(0, 1.0, 0))
				quad(pxf * T(0, 0.0, 0.17), 0.24, 0.34, "petale76_" + color, Vector2(0, 0), Vector2(1, 1), true)
			ball(T(0, 1.02, 0), 0.06, "lumiere76_or", 8, 4)
			for k2 in range(3):
				var a2: float = TAU * k2 / 3.0 + 0.4
				quad(Transform3D(Basis(Vector3.UP, -a2) * Basis(Vector3.RIGHT, -1.2), Vector3(0, 0.35 + k2 * 0.12, 0)) * T(0, 0, 0.12), 0.14, 0.24, "feuille76_", Vector2(0, 0), Vector2(1, 1), true)
		"arbrecristal76":
			# un arbre de cristal (unité 1 m) : un tronc de métal, des branches, des cristaux
			cyl(I, 0.08, 0.05, 0.6, "metal76_sombre", 6)
			for k3 in range(5):
				var a3: float = TAU * k3 / 5.0 + 0.3
				var tip := Vector3(cos(a3) * 0.35, 0.95 + (k3 % 2) * 0.12, sin(a3) * 0.35)
				beam(Vector3(0, 0.55, 0), tip, 0.04, "metal76_sombre")
				cyl(Transform3D(Basis(), tip - Vector3(0, 0.04, 0)), 0.06, 0.0, 0.26, "cristal76_" + color, 5, false)
			cyl(T(0, 0.6, 0), 0.07, 0.0, 0.55, "cristal76_" + color, 5, false)
		"buisson76":
			for k4 in range(7):
				var a4: float = TAU * k4 / 7.0
				quad(Transform3D(Basis(Vector3.UP, -a4) * Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.05, 0)) * T(0, 0.2, 0.05), 0.3, 0.45, "feuille76_", Vector2(0, 0), Vector2(1, 1), true)
			ball(T(0, 0.3, 0), 0.05, "lumiere76_" + color, 6, 3)
		"cristal76":
			# un cristal posé au sol (unité 1 m)
			cyl(I, 0.18, 0.0, 1.0, "cristal76_" + color, 6, false)
			cyl(T(0.12, 0, 0.05) * Transform3D(Basis(Vector3.BACK, -0.35), Vector3.ZERO), 0.1, 0.0, 0.55, "cristal76_" + color, 6, false)
	var mesh := ArrayMesh.new()
	for k5 in batch:
		var st: SurfaceTool = batch[k5]
		var m: Material = mat(str(k5))
		if m is StandardMaterial3D and (m as StandardMaterial3D).normal_enabled:
			st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	batch = saved
	protos[key] = mesh
	return mesh

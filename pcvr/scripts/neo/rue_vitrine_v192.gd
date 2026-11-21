extends RefCounted
## V192 : la rue vitrine. Le Boulevard des Néons entre la Tour Kumo (à l'ouest) et la Tour Vertex (à l'est),
## là où l'on débarque : les deux tours se font face, la rue le dit.
##   - le trottoir de Vertex : un dallage de pierre claire à joints de bronze, et devant les guichets
##     automatiques, un médaillon d'or au V incrusté dans le sol ; deux lanternes de bronze, lumière chaude ;
##   - le trottoir de Kumo : un béton sombre, la ligne de LED cyan des livreurs, l'aire d'appontage des drones
##     (le cercle orange, la croix, ses balises) près du Dépôt 01 ; deux mâts de lumière froide ; un petit
##     robot de livraison garé devant la boutique ;
##   - des bordures de granit le long de la chaussée ;
##   - entre les deux portes, la traversée : un plateau de pierre, ses bandes blanches, une lisière cyan côté
##     Kumo et une lisière d'or côté Vertex qui se rejoignent au milieu ; ses bornes (de bronze à l'est,
##     noires à anneau cyan à l'ouest).
## Tout au sol est à plat (pas de marche) ; seuls les mâts, les bornes et le robot ont une collision.
## Repère : celui de la ville (x, z ; N._ground) ; le boulevard : la chaussée |x| < 6, les trottoirs jusqu'à 9,5.

const Kit = preload("res://scripts/neo_kit_v94.gd")

const Z0 := -176.0                    # le bout nord des trottoirs refaits (au passage piéton du quai)
const Z1 := -150.0                    # le bout sud
const ZC := -162.5                    # la traversée, entre les deux portes
const DEMI := 2.0                     # sa demi-largeur
const BORD := 6.0                     # le bord de la chaussée
const FACADE := 9.5                   # le pied des tours
const LANTERNES := [-171.0, -152.2]   # les lumières, des deux côtés (z)


## Tout poser ; renvoie ce qui a été posé (pour les tests).
static func build(N: Node3D) -> Dictionary:
	var b := Kit.Batch.new()
	var sol := Kit.Batch.new()
	var info := {"lumieres": [], "bornes": 0, "mats": 0, "robot": Vector3.ZERO, "traversee": Vector2(ZC - DEMI, ZC + DEMI)}
	_trottoir_vertex(N, b, sol)
	_trottoir_kumo(N, b, sol)
	_bordures(N, sol)
	_traversee(N, b, sol, info)
	for z in LANTERNES:
		info["lumieres"].append(_lanterne(N, b, 6.55, z))
		info["lumieres"].append(_mat_froid(N, b, -6.55, z))
		info["mats"] += 2
	info["robot"] = _robot(N, b, -7.9, -157.6)
	var m: MeshInstance3D = b.commit(N, "Rue_vitrine_v192")
	sol.commit(N, "Rue_vitrine_sol_v192", false)
	info["noeud"] = m
	return info


static func _w(N: Node3D, x: float, y: float, z: float) -> Vector3:
	return N._ground(x, z) + Vector3.UP * y


## Une plaque posée à plat : de x0 à x1, de z0 à z1, épaisse de e, son dessus à la hauteur y.
static func _plat(N: Node3D, lot: Kit.Batch, key: String, x0: float, x1: float, z0: float, z1: float, y: float, e: float = 0.01) -> void:
	lot.box(key, Transform3D(Basis(), _w(N, (x0 + x1) * 0.5, y - e * 0.5, (z0 + z1) * 0.5)), Vector3(absf(x1 - x0), e, absf(z1 - z0)))


# =================================================================== le trottoir de Vertex

static func _trottoir_vertex(N: Node3D, b: Kit.Batch, sol: Kit.Batch) -> void:
	_plat(N, sol, "k189_pierre", BORD + 0.2, FACADE, Z0, Z1, 0.014, 0.014)
	# les joints de bronze : en travers tous les 1,6 m, et un long joint au milieu
	var z: float = Z0 + 1.6
	while z < Z1 - 0.4:
		if absf(z - ZC) > 1.0:
			_plat(N, sol, "k189_bronze", BORD + 0.2, FACADE, z - 0.045, z + 0.045, 0.017, 0.004)
		z += 1.6
	_plat(N, sol, "k189_bronze", 7.86, 7.94, Z0, Z1, 0.017, 0.004)
	# le médaillon devant les guichets : un disque sombre cerclé d'or, le V d'or
	var c: Vector3 = _w(N, 7.55, 0.0, ZC)
	sol.cyl("k189_or", Transform3D(Basis(), c + Vector3.UP * 0.017), 0.78, 0.78, 0.006, 40)
	sol.cyl("k189_pierre_sombre", Transform3D(Basis(), c + Vector3.UP * 0.02), 0.7, 0.7, 0.006, 40)
	# le V couché : sa pointe vers la chaussée (vers l'ouest), ses deux branches qui s'ouvrent vers la tour
	var pointe: Vector3 = c + Vector3(-0.3, 0.026, 0.0)
	for sg in [-1.0, 1.0]:
		var th: float = 0.36
		var d := Vector3(cos(th), 0.0, sg * sin(th))
		sol.box("k189_or", Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), pointe + d * 0.31), Vector3(0.08, 0.006, 0.62))


# =================================================================== le trottoir de Kumo

static func _trottoir_kumo(N: Node3D, b: Kit.Batch, sol: Kit.Batch) -> void:
	_plat(N, sol, "beton", -FACADE, -BORD - 0.2, Z0, Z1, 0.014, 0.014)
	# la ligne des livreurs : des tirets de LED cyan, du quai à la boutique
	var z: float = Z0 + 0.3
	while z < Z1 - 0.6:
		_plat(N, sol, "neon_cyan", -7.95, -7.85, z, z + 1.3, 0.018, 0.004)
		z += 1.6
	# l'aire d'appontage des drones (près du Dépôt 01, au coin du quai) : le cercle orange, la croix blanche,
	# quatre balises
	var c: Vector3 = _w(N, -7.75, 0.0, -169.6)
	for i in range(28):
		var a: float = TAU * i / 28.0
		sol.box("k187_orange", Transform3D(Basis(Vector3.UP, a), c + Vector3(sin(a), 0.0, cos(a)) * 1.1 + Vector3.UP * 0.018), Vector3(0.26, 0.006, 0.12))
	sol.box("peinture_blanche", Transform3D(Basis(), c + Vector3.UP * 0.018), Vector3(1.1, 0.006, 0.12))
	sol.box("peinture_blanche", Transform3D(Basis(), c + Vector3.UP * 0.018), Vector3(0.12, 0.006, 1.1))
	for k in range(4):
		var a2: float = TAU * k / 4.0 + PI * 0.25
		b.cyl_at("neon_cyan", c + Vector3(sin(a2), 0.0, cos(a2)) * 1.45, 0.06, 0.05, 0.05, 8)


# =================================================================== les bordures

static func _bordures(N: Node3D, sol: Kit.Batch) -> void:
	for sx in [-1.0, 1.0]:
		var x: float = sx * (BORD + 0.12)
		for zz in [[Z0, ZC - DEMI], [ZC + DEMI, Z1]]:
			_plat(N, sol, "beton_clair", x - 0.14, x + 0.14, zz[0], zz[1], 0.05, 0.05)


# =================================================================== la traversée

static func _traversee(N: Node3D, b: Kit.Batch, sol: Kit.Batch, info: Dictionary) -> void:
	# le plateau de pierre, de trottoir à trottoir
	# (une pierre sombre : les bandes blanches s'y lisent de loin)
	_plat(N, sol, "k189_pierre_sombre", -BORD - 0.2, BORD + 0.2, ZC - DEMI, ZC + DEMI, 0.016, 0.016)
	# les bandes blanches (dans le sens des voitures)
	for i in range(12):
		var x: float = -5.5 + i * 1.0
		_plat(N, sol, "peinture_blanche", x - 0.25, x + 0.25, ZC - DEMI + 0.35, ZC + DEMI - 0.35, 0.021, 0.005)
	# les lisières : cyan côté Kumo, or côté Vertex, qui se rejoignent au milieu
	for sz in [-1.0, 1.0]:
		var z: float = ZC + sz * (DEMI - 0.12)
		_plat(N, sol, "neon_cyan", -BORD - 0.2, 0.0, z - 0.06, z + 0.06, 0.022, 0.005)
		_plat(N, sol, "k189_or", 0.0, BORD + 0.2, z - 0.06, z + 0.06, 0.022, 0.005)
	# les bornes, aux deux bouts de la traversée
	for sz2 in [-1.0, 1.0]:
		var z2: float = ZC + sz2 * (DEMI + 0.3)
		var e: Vector3 = _w(N, BORD + 0.35, 0.0, z2)
		b.cyl_at("k189_bronze", e, 0.12, 0.1, 0.88, 12)
		b.cyl_at("k189_or", e + Vector3.UP * 0.7, 0.105, 0.105, 0.04, 12)
		b.blob("k189_bronze", e + Vector3.UP * 0.9, Vector3(0.1, 0.07, 0.1), 8)
		N._col(Transform3D(Basis(), e + Vector3.UP * 0.45), Vector3(0.24, 0.9, 0.24))
		var o: Vector3 = _w(N, -BORD - 0.35, 0.0, z2)
		b.cyl_at("metal_noir", o, 0.11, 0.1, 0.9, 10)
		b.cyl_at("neon_cyan", o + Vector3.UP * 0.78, 0.105, 0.105, 0.05, 10)
		b.cyl_at("metal", o + Vector3.UP * 0.9, 0.1, 0.06, 0.05, 10)
		N._col(Transform3D(Basis(), o + Vector3.UP * 0.45), Vector3(0.22, 0.9, 0.22))
		info["bornes"] += 2


# =================================================================== les lumières

## Une lanterne de bronze (côté Vertex) : le socle, le fût et ses bagues d'or, la lanterne vitrée, son toit
static func _lanterne(N: Node3D, b: Kit.Batch, x: float, z: float) -> OmniLight3D:
	var at: Vector3 = _w(N, x, 0.0, z)
	b.cyl_at("k189_bronze", at, 0.24, 0.2, 0.55, 12)
	b.cyl_at("k189_or", at + Vector3.UP * 0.55, 0.16, 0.16, 0.05, 12)
	b.cyl_at("k189_bronze", at + Vector3.UP * 0.6, 0.075, 0.06, 3.2, 10)
	for y in [1.4, 2.6]:
		b.cyl_at("k189_or", at + Vector3.UP * y, 0.09, 0.09, 0.05, 10)
	var h: Vector3 = at + Vector3.UP * 4.05
	b.cyl_at("k189_bronze", at + Vector3.UP * 3.75, 0.13, 0.2, 0.08, 8)
	b.box("verre", Transform3D(Basis(Vector3.UP, PI * 0.25), h), Vector3(0.38, 0.52, 0.38))
	b.box("lampe_chaude", Transform3D(Basis(Vector3.UP, PI * 0.25), h), Vector3(0.16, 0.3, 0.16))
	for k in range(4):
		var a: float = TAU * k / 4.0
		b.box("k189_bronze", Transform3D(Basis(Vector3.UP, PI * 0.25), h + Vector3(sin(a + PI * 0.25), 0, cos(a + PI * 0.25)) * 0.27), Vector3(0.03, 0.54, 0.03))
	b.cyl("k189_bronze", Transform3D(Basis(Vector3.UP, PI * 0.25), h + Vector3.UP * 0.28), 0.32, 0.03, 0.3, 4)
	b.blob("k189_or", h + Vector3.UP * 0.62, Vector3(0.05, 0.07, 0.05), 6)
	N._col(Transform3D(Basis(), at + Vector3.UP * 1.5), Vector3(0.4, 3.0, 0.4))
	return N._light(h, Color(1.0, 0.76, 0.48), 6.0, 13.0)


## Un mât de lumière froide (côté Kumo) : un fût carré noir, une barre de LED cyan sur sa face, le bras et
## sa dalle de LED blanche
static func _mat_froid(N: Node3D, b: Kit.Batch, x: float, z: float) -> OmniLight3D:
	var at: Vector3 = _w(N, x, 0.0, z)
	b.box("metal_noir", Transform3D(Basis(), at + Vector3.UP * 2.25), Vector3(0.16, 4.5, 0.16))
	b.box("metal_noir", Transform3D(Basis(), at + Vector3.UP * 0.15), Vector3(0.3, 0.3, 0.3))
	b.box("neon_cyan", Transform3D(Basis(), at + Vector3(0.085, 1.0 + 1.3, 0.0)), Vector3(0.01, 2.6, 0.04))
	var bras: Vector3 = at + Vector3(0.55, 4.45, 0.0)
	b.box("metal_noir", Transform3D(Basis(), bras), Vector3(1.25, 0.08, 0.22))
	b.box("lampe_blanche", Transform3D(Basis(), bras + Vector3(0.2, -0.05, 0.0)), Vector3(0.8, 0.02, 0.16))
	N._col(Transform3D(Basis(), at + Vector3.UP * 1.5), Vector3(0.32, 3.0, 0.32))
	return N._light(bras + Vector3(0.2, -0.3, 0.0), Color(0.78, 0.9, 1.0), 6.0, 13.0)


# =================================================================== le robot de livraison

## Garé devant la boutique Kumo Express, tourné vers la rue : sa caisse blanche à liseré orange, ses yeux
## cyan, ses six roues, son fanion
static func _robot(N: Node3D, b: Kit.Batch, x: float, z: float) -> Vector3:
	var at: Vector3 = _w(N, x, 0.0, z)
	var bs := Basis(Vector3.UP, PI * 0.5)          # (son avant vers l'est, vers la rue)
	b.box("peinture_blanche", Transform3D(bs, at + Vector3.UP * 0.44), Vector3(0.56, 0.44, 0.74))
	b.box("k187_orange", Transform3D(bs, at + Vector3.UP * 0.67), Vector3(0.58, 0.03, 0.76))
	b.box("metal_noir", Transform3D(bs, at + Vector3.UP * 0.7), Vector3(0.5, 0.04, 0.68))
	for sg in [-1.0, 1.0]:
		b.box("neon_cyan", Transform3D(bs, at + Vector3(0.375, 0.52, sg * 0.1)), Vector3(0.08, 0.05, 0.01))
		for k in range(3):
			var zz: float = (k - 1) * 0.26
			b.cyl("metal_noir", Transform3D(bs * Basis(Vector3(0, 0, 1), PI * 0.5), at + bs * Vector3(sg * 0.31, 0.12, zz)), 0.11, 0.11, 0.08, 10)
	b.tube("metal", at + Vector3(-0.3, 0.7, 0.2), at + Vector3(-0.3, 1.55, 0.2), 0.008, 4)
	b.box("k187_orange", Transform3D(bs, at + Vector3(-0.3, 1.47, 0.29)), Vector3(0.18, 0.12, 0.006))
	N._col(Transform3D(bs, at + Vector3.UP * 0.4), Vector3(0.62, 0.8, 0.8))
	return at

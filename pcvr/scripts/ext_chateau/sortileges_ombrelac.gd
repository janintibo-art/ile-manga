extends "res://scripts/ext_chateau/astrolabe_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : le dedans de la Tour des Sortilèges :
##  - la Salle des Cercles, au pied : le grand cercle de runes qui luit sur le dallage, les
##    mannequins d'entraînement, le râtelier des baguettes, les bougies qui flottent ;
##  - l'escalier des Marches Flottantes : cent vingt marches de pierre, sans limon, qui tournent
##    trois fois le long du mur jusqu'au Cabinet ; du côté du vide, une rambarde de lumière ;
##  - au milieu, les feux follets qui montent sans fin jusqu'au Cabinet, par l'oculus ;
##  - le Cabinet des Sortilèges (24 m) : la sphère de cristal sur son trépied, le pupitre et son
##    grimoire dont les pages tournent seules, les livres qui volent en battant des pages, les
##    bibliothèques, le plafond étoilé, et le balcon sur le lac.
## Repère : xf = le centre de la tour, au dallage de la salle du bas (y = le plateau).

const R_ESC := 3.9                # le bord intérieur des marches (le vide au-dedans)
const R_MIL := 4.6                # le milieu des marches
const ANGLE_DEPART := PI / 6.0    # (30° : juste à gauche de la porte, qui est à l'est)
const TOURS := 3
const MARCHES_FL := 120
const OCULUS := 1.6
const COULEUR_MAGIE := Color(0.62, 0.5, 1.0)

var follets: Array = []           # [Node3D, phase, rayon, vitesse]
var flottants: Array = []         # [Node3D, position, phase, amplitude]
var livres: Array = []            # [Node3D, phase, [moitié gauche, moitié droite]]
var page: Node3D                  # la page du grimoire qui tourne
var coeur: Node3D                 # la lueur dans la sphère de cristal
var ri: float = 5.3
var cab: float = 24.0
var plafond: float = 34.0
var _tm: float = 0.0


func construire_sortileges(p: Vector3, r: float, T: float, the_cab: float, the_plafond: float) -> void:
	xf = Transform3D(Basis.IDENTITY, p)
	xf_sol = xf
	_puits = Vector3(1e6, 0, 1e6)
	_rng.seed = 6161
	ri = r - T
	cab = the_cab
	plafond = the_plafond
	var k := Kit.new()
	# --- la salle des cercles
	_dallage(k, ri, 0.0, Vector3(1e6, 0, 1e6), 0.0, func(x: float, z: float) -> bool: return Vector2(x, z).length() < ri + 0.2)
	_cercle_runes(k, 0.0)
	for a in [150.0, 210.0, 270.0]:
		var d := _dir(deg_to_rad(a))
		_mannequin(k, d * 3.3, atan2(-d.x, -d.z))
	_ratelier(k, deg_to_rad(200.0))
	_banniere(k, "banniere_pourpre", _p(0.0, 6.0, ri - 0.06), 1.2, 3.2, Vector3(0, 0, -1))
	# --- l'escalier, sa rambarde de lumière
	_escalier_flottant(k)
	# --- le cabinet
	_plancher_cabinet(k)
	_plafond_etoile(k)
	for a2 in [210.0, 240.0, 270.0]:
		var d2 := _dir(deg_to_rad(a2))
		var pos: Vector3 = d2 * (ri - 0.3)
		_rayonnage(k, _tr(pos.x, cab, pos.z, atan2(-d2.x, -d2.z)), 2.2, 3.0, 0.45, false)
	_sphere_cristal(k, _dir(deg_to_rad(95.0)) * 2.8 + Vector3(0, cab, 0))
	_pupitre(k, _dir(deg_to_rad(145.0)) * 3.4 + Vector3(0, cab, 0))
	# les fenêtres vues du dedans (le verre sur le parement intérieur, sous les baies du dehors)
	for i in range(7):
		var a3: float = 0.7 + i * 2.1
		var y: float = 4.0 + (68.0 - 10.0) * (i + 0.5) / 7
		if y + 2.4 > plafond:
			continue
		var d3 := _dir(a3)
		k.window(Transform3D(Basis(Vector3.UP, atan2(-d3.x, -d3.z)), _p(0, y, 0) + d3 * (ri + 0.02)), 1.0, 2.4, "vitre", 0.15)
	# --- les lumières : chaudes aux bougies, froides au cercle et à la sphère
	_lumiere(_p(2.5, 3.0, -2.5), 9.0, 0.6, 1.3)
	_lumiere(_p(-2.5, 3.0, 2.5), 9.0, 0.6, 1.3)
	_lueur(_p(0.0, 1.2, 0.0), Color(0.5, 0.9, 1.0), 7.0, 0.6, 1.2)
	_lumiere(_p(0.0, 12.0, 0.0), 10.0, 0.4, 1.0)
	_lueur(_p(0.0, 19.0, 0.0), COULEUR_MAGIE, 9.0, 0.4, 0.9)
	_lumiere(_p(0.0, cab + 6.0, 0.0), 10.0, 0.7, 1.4)
	_lueur(_dir(deg_to_rad(95.0)) * 2.8 + _p(0, cab + 1.9, 0), COULEUR_MAGIE, 6.0, 0.6, 1.3)
	var mi: MeshInstance3D = k.commit("Ombrelac_sortileges_meubles")
	mi.visibility_range_end = 150.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_sortileges_meubles_col"))
	_sonde(Vector3(0.0, cab * 0.5, 0.0), Vector3(ri * 2.0 + 0.6, cab + 0.4, ri * 2.0 + 0.6))
	(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	_sonde(Vector3(0.0, (cab + plafond) * 0.5, 0.0), Vector3(ri * 2.0 + 0.6, plafond - cab + 0.4, ri * 2.0 + 0.6))
	(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	# --- ce qui bouge
	_feux_follets()
	_bougies_flottantes()
	_livres_volants()
	# les lieux
	var dm := _dir(ANGLE_DEPART + float(MARCHES_FL) * 0.5 * _pas())
	var dt := _dir(deg_to_rad(-20.0))
	lieux["sortileges_porte"] = _p(r + 2.6, 0.0, 0.0)
	lieux["sortileges_salle"] = _p(1.5, 0.0, -1.5)
	lieux["sortileges_centre"] = _p(0.0, 0.0, 0.0)
	lieux["sortileges_escalier_bas"] = _p(0, 0, 0) + _dir(deg_to_rad(18.0)) * R_MIL
	lieux["sortileges_escalier_mi"] = _p(0, cab * 0.5, 0) + dm * R_MIL
	lieux["sortileges_vide_mi"] = _p(0, cab * 0.5, 0) + dm * 2.2
	lieux["sortileges_haut"] = _p(0, cab, 0) + _dir(deg_to_rad(42.0)) * 4.4
	lieux["sortileges_cabinet"] = _p(0.0, cab, -2.6)
	lieux["sortileges_bord_tremie"] = _p(0, cab, 0) + dt * 3.1
	lieux["sortileges_dans_tremie"] = _p(0, cab, 0) + dt * R_MIL
	lieux["sortileges_avant_balcon"] = _p(-3.4, cab, 0.0)
	lieux["sortileges_balcon"] = _p(-(r + 1.3), cab, 0.0)
	lieux["sortileges_balcon_dehors"] = _p(-(r + 5.0), cab, 0.0)


func _dir(a: float) -> Vector3:
	return Vector3(cos(a), 0, sin(a))


func _pas() -> float:
	return TAU * TOURS / MARCHES_FL


## Une lumière d'une autre couleur que celle des bougies
func _lueur(p: Vector3, c: Color, portee: float, jour: float, nuit_e: float) -> OmniLight3D:
	var l: OmniLight3D = _lumiere(p, portee, jour, nuit_e)
	l.light_color = c
	return l


# =================================================================== la salle des cercles

## Un anneau plat (de r0 à r1) à la hauteur y, en matière m
func _anneau_plat(k: RefCounted, m: String, y: float, r0: float, r1: float, seg: int = 48) -> void:
	for i in range(seg):
		var a0: float = TAU * i / seg
		var a1: float = TAU * (i + 1) / seg
		k.quad(m, xf, _dir(a0) * r0 + Vector3(0, y, 0), _dir(a1) * r0 + Vector3(0, y, 0), _dir(a1) * r1 + Vector3(0, y, 0), _dir(a0) * r1 + Vector3(0, y, 0), Vector3.UP)


## Un trait plat de a à b (repère tour), de largeur w
func _trait(k: RefCounted, m: String, a: Vector3, b: Vector3, w: float) -> void:
	var d: Vector3 = (b - a).normalized()
	var n := Vector3(-d.z, 0, d.x) * w * 0.5
	k.quad(m, xf, a - n, b - n, b + n, a + n, Vector3.UP)


## Le grand cercle de runes : trois anneaux, l'étoile à sept branches, les signes entre les anneaux
func _cercle_runes(k: RefCounted, y0: float) -> void:
	var y: float = y0 + 0.03
	k.cyl("pierre_claire", _tr(0.0, y0, 0.0), 2.95, 2.95, 0.025, 48)
	_anneau_plat(k, "rune", y, 2.7, 2.78)
	_anneau_plat(k, "rune", y, 2.05, 2.1)
	_anneau_plat(k, "rune_violet", y, 0.5, 0.56, 24)
	var pts: Array = []
	for i in range(7):
		pts.append(_dir(TAU * i / 7.0 - PI * 0.5) * 2.05 + Vector3(0, y + 0.002, 0))
	for i2 in range(7):
		_trait(k, "rune_violet", pts[i2], pts[(i2 + 3) % 7], 0.05)
	# les signes : de petits traits croisés, chacun le sien
	for i3 in range(21):
		var a: float = TAU * i3 / 21.0
		var c: Vector3 = _dir(a) * 2.4 + Vector3(0, y + 0.002, 0)
		var t: Vector3 = _dir(a + PI * 0.5)
		var rr: Vector3 = _dir(a)
		_trait(k, "rune", c - rr * 0.14, c + rr * 0.14, 0.035)
		match i3 % 4:
			0:
				_trait(k, "rune", c - t * 0.1 + rr * 0.1, c + t * 0.1 + rr * 0.1, 0.03)
			1:
				_trait(k, "rune", c - rr * 0.1, c + t * 0.12, 0.03)
			2:
				_trait(k, "rune", c - t * 0.1 - rr * 0.05, c + t * 0.1 + rr * 0.05, 0.03)
			_:
				_trait(k, "rune", c + rr * 0.14, c + rr * 0.04 + t * 0.1, 0.03)


## Un mannequin d'entraînement : le pied en croix, le poteau, le corps de paille, la tête, les bras
## (v12 : le corps rond serré de cordes, les bras de paille liés, la tête en sac, la cible à trois anneaux,
## les jambes de force du pied)
func _mannequin(k: RefCounted, c: Vector3, yaw: float) -> void:
	var t: Transform3D = _tr(c.x, 0.0, c.z, yaw)
	_objet("mannequin", t.origin, t.origin)
	for e in [0.0, PI * 0.5]:
		k.box("chene", t * Transform3D(Basis(Vector3.UP, e), Vector3.ZERO), Vector3(0.9, 0.1, 0.12))
	for e2 in range(4):
		var a: float = PI * 0.5 * e2
		var dd := Vector3(cos(a), 0, sin(a))
		_poutre(k, "chene", t * (dd * 0.4 + Vector3(0, 0.1, 0)), t * (dd * 0.05 + Vector3(0, 0.45, 0)), 0.05)
	k.cyl("chene", t, 0.055, 0.05, 1.7, 8)
	k.cyl("paille", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.7, 0)), 0.2, 0.25, 0.25, 12)
	k.cyl("paille", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0)), 0.25, 0.26, 0.25, 12)
	k.cyl("paille", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 0)), 0.26, 0.18, 0.2, 12)
	for yc in [0.78, 0.98, 1.18]:
		k.cyl("drap", t * Transform3D(Basis.IDENTITY, Vector3(0, yc, 0)), 0.265, 0.265, 0.025, 12, false)
	k.cyl("paille", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.4, 0)), 0.07, 0.08, 0.25, 8)
	_sphere(k, "drap", t * Vector3(0, 1.8, 0), 0.19)
	k.cyl("drap", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.62, 0)), 0.1, 0.07, 0.06, 8)
	k.cyl("paille", t * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.48, 1.3, 0)), 0.06, 0.07, 0.96, 8)
	for xa in [-0.42, -0.3, 0.3, 0.42]:
		k.cyl("drap", t * Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(xa + 0.012, 1.3, 0)), 0.075, 0.075, 0.025, 8, false)
	# une cible peinte sur la poitrine : trois anneaux
	var bz := Basis(Vector3.RIGHT, PI * 0.5)
	k.cyl("drap", t * Transform3D(bz, Vector3(0, 1.0, 0.25)), 0.17, 0.17, 0.01, 16)
	k.cyl("banniere_pourpre", t * Transform3D(bz, Vector3(0, 1.0, 0.255)), 0.12, 0.12, 0.01, 16)
	k.cyl("drap", t * Transform3D(bz, Vector3(0, 1.0, 0.26)), 0.07, 0.07, 0.01, 16)
	k.cyl("banniere_pourpre", t * Transform3D(bz, Vector3(0, 1.0, 0.265)), 0.03, 0.03, 0.01, 12)
	var col := CylinderShape3D.new()
	col.radius = 0.32
	col.height = 1.9
	k.shapes.append([col, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0))])


## Le râtelier des baguettes, contre le mur : un banc, un casier, des baguettes debout
## (v12 : le meuble sur pieds, ses tiroirs, le casier percé ; chaque baguette sa poignée, sa virole,
## son bout qui luit pour certaines)
func _ratelier(k: RefCounted, a: float) -> void:
	var d := _dir(a)
	var c: Vector3 = d * (ri - 0.35)
	var t: Transform3D = _tr(c.x, 0.0, c.z, atan2(-d.x, -d.z))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.08, 0)), Vector3(2.2, 0.77, 0.5), true)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)), Vector3(2.1, 0.08, 0.44))
	for xi in range(3):
		var xd: float = -0.72 + xi * 0.72
		k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(xd, 0.5, 0.255)), Vector3(0.62, 0.22, 0.012))
		k.box("bois", t * Transform3D(Basis.IDENTITY, Vector3(xd, 0.14, 0.255)), Vector3(0.62, 0.3, 0.012))
		k._ball(t * Transform3D(Basis.IDENTITY, Vector3(xd, 0.61, 0.27)), 0.018)
		k._ball(t * Transform3D(Basis.IDENTITY, Vector3(xd, 0.29, 0.27)), 0.018)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.85, -0.1)), Vector3(2.0, 0.08, 0.3))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.08, -0.1)), Vector3(2.0, 0.03, 0.22))
	for ex in [-1.0, 1.0]:
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(ex * 0.98, 0.93, -0.1)), Vector3(0.04, 0.2, 0.22))
	for i in range(14):
		var x: float = -0.9 + i * 0.138
		var lg: float = 0.32 + _rng.randf() * 0.12
		var m: String = ["chene", "bois", "fer", "chene"][i % 4]
		var b := Basis(Vector3(0, 0, 1), _rng.randf_range(-0.08, 0.08))
		var p0: Transform3D = t * Transform3D(b, Vector3(x, 0.93, -0.1))
		k.cyl(m, p0, 0.012, 0.007, lg, 6)
		k.cyl("chene" if m != "chene" else "bois", p0, 0.016, 0.014, 0.12, 8)
		k.cyl("or", p0 * Transform3D(Basis.IDENTITY, Vector3(0, 0.12, 0)), 0.017, 0.017, 0.012, 8)
		if i % 3 == 0:
			_sphere(k, "rune" if i % 2 == 0 else "rune_violet", p0 * Vector3(0, lg, 0), 0.014)


# =================================================================== l'escalier

## Les marches flottantes : des dalles de pierre séparées, une lueur dessous ; la rampe de collision
## qui les suit ; la rambarde de lumière côté vide (un voile, un fil violet, une collision)
func _escalier_flottant(k: RefCounted) -> void:
	var dth: float = _pas()
	var montee: float = cab / MARCHES_FL
	var lg: float = R_MIL * dth
	var larg: float = ri - R_ESC - 0.05
	for j in range(MARCHES_FL):
		var th: float = ANGLE_DEPART + (j + 0.5) * dth
		var d := _dir(th)
		var t := _dir(th + PI * 0.5)
		var yaw: float = atan2(t.x, t.z)
		var top: float = (j + 1) * montee
		var c: Vector3 = d * ((ri + R_ESC) * 0.5)
		k.box("pierre_claire", Transform3D(Basis(Vector3.UP, yaw), _p(c.x, top - 0.17, c.z)), Vector3(larg, 0.17, lg - 0.09))
		k.box("rune_violet" if j % 2 == 0 else "rune", Transform3D(Basis(Vector3.UP, yaw), _p(c.x, top - 0.18, c.z)), Vector3(larg * 0.4, 0.008, 0.06))
		# la rampe de collision
		var zt: Vector3 = (t * lg + Vector3.UP * montee).normalized()
		var y: Vector3 = zt.cross(d)
		var ctr: Vector3 = _p(0, (j + 0.5) * montee, 0) + d * ((ri + R_ESC) * 0.5)
		var rs := BoxShape3D.new()
		rs.size = Vector3(larg + 0.1, 0.3, Vector2(lg, montee).length() * 1.08)
		k.shapes.append([rs, Transform3D(Basis(d, y, zt), ctr - y * 0.15)])
		# la rambarde de lumière
		var a0: float = th - dth * 0.5
		var a1: float = th + dth * 0.5
		var ya: float = j * montee + 0.05
		var yb: float = (j + 1) * montee + 0.05
		var pa: Vector3 = _dir(a0) * R_ESC
		var pb: Vector3 = _dir(a1) * R_ESC
		k.quad("voile", xf, pa + Vector3(0, ya, 0), pb + Vector3(0, yb, 0), pb + Vector3(0, yb + 1.0, 0), pa + Vector3(0, ya + 1.0, 0), -d)
		_pl(k, "rune_violet", pa + Vector3(0, ya + 1.0, 0), pb + Vector3(0, yb + 1.0, 0), 0.03)
		var gs := BoxShape3D.new()
		gs.size = Vector3(0.12, 1.5, lg * 1.05)
		k.shapes.append([gs, Transform3D(Basis(Vector3.UP, yaw), _p(0, (j + 0.5) * montee + 0.7, 0) + d * (R_ESC - 0.04))])


# =================================================================== le cabinet

## L'angle (0..TAU) est-il au-dessus de la fin de l'escalier (la trémie) ?
func dans_tremie(a: float) -> bool:
	var fin: float = ANGLE_DEPART
	var debut: float = fin - deg_to_rad(100.0)
	var x: float = wrapf(a - debut, 0.0, TAU)
	return x < fin - debut


## Le plancher du Cabinet : des secteurs de planches (l'oculus au milieu, la trémie de l'escalier),
## la rambarde de laiton autour des deux
func _plancher_cabinet(k: RefCounted) -> void:
	var y: float = cab
	var n: int = 36
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		var tr: bool = dans_tremie((a0 + a1) * 0.5)
		var r1: float = R_ESC if tr else ri + 0.05
		var d0 := _dir(a0)
		var d1 := _dir(a1)
		k.quad("parquet", xf, d0 * OCULUS + Vector3(0, y, 0), d1 * OCULUS + Vector3(0, y, 0), d1 * r1 + Vector3(0, y, 0), d0 * r1 + Vector3(0, y, 0), Vector3.UP)
		k.quad("chene", xf, d0 * OCULUS + Vector3(0, y - 0.3, 0), d1 * OCULUS + Vector3(0, y - 0.3, 0), d1 * r1 + Vector3(0, y - 0.3, 0), d0 * r1 + Vector3(0, y - 0.3, 0), Vector3.DOWN)
		k.quad("chene", xf, d0 * OCULUS + Vector3(0, y - 0.3, 0), d1 * OCULUS + Vector3(0, y - 0.3, 0), d1 * OCULUS + Vector3(0, y, 0), d0 * OCULUS + Vector3(0, y, 0), -(d0 + d1))
		if tr:
			k.quad("chene", xf, d0 * r1 + Vector3(0, y - 0.3, 0), d1 * r1 + Vector3(0, y - 0.3, 0), d1 * r1 + Vector3(0, y, 0), d0 * r1 + Vector3(0, y, 0), d0 + d1)
		var dm: Vector3 = (d0 + d1).normalized()
		var bs := BoxShape3D.new()
		bs.size = Vector3(r1 * TAU / n * 1.1, 0.3, r1 - OCULUS)
		k.shapes.append([bs, Transform3D(Basis(Vector3.UP, atan2(dm.x, dm.z)), _p(0, y - 0.15, 0) + dm * (OCULUS + r1) * 0.5)])
	# la rambarde de l'oculus : un cercle de laiton sur ses balustres
	_rambarde_arc(k, OCULUS + 0.06, 0.0, TAU, 24)
	# la rambarde de la trémie : l'arc au bord du vide, et le côté qui ferme le début de la trémie
	var fin: float = ANGLE_DEPART
	var debut: float = fin - deg_to_rad(100.0)
	_rambarde_arc(k, R_ESC - 0.06, debut, fin, 10)
	var p0: Vector3 = _dir(debut) * (R_ESC - 0.06) + Vector3(0, y, 0)
	var p1: Vector3 = _dir(debut) * (ri - 0.02) + Vector3(0, y, 0)
	_rambarde_droite(k, p0, p1)


func _rambarde_arc(k: RefCounted, r: float, a0: float, a1: float, n: int) -> void:
	for i in range(n):
		var p0: Vector3 = _dir(lerpf(a0, a1, float(i) / n)) * r + Vector3(0, cab, 0)
		var p1: Vector3 = _dir(lerpf(a0, a1, float(i + 1) / n)) * r + Vector3(0, cab, 0)
		_rambarde_droite(k, p0, p1)


## Un bout de rambarde de laiton de p0 à p1 (repère tour, au sol) : le poteau, la main courante,
## les barreaux, la collision
func _rambarde_droite(k: RefCounted, p0: Vector3, p1: Vector3) -> void:
	_pl(k, "or", p0, p0 + Vector3(0, 1.0, 0), 0.06)
	_pl(k, "or", p0 + Vector3(0, 1.0, 0), p1 + Vector3(0, 1.0, 0), 0.05, Vector3.UP)
	_pl(k, "or", p0 + Vector3(0, 0.12, 0), p1 + Vector3(0, 0.12, 0), 0.03, Vector3.UP)
	var nb: int = maxi(1, int(p0.distance_to(p1) / 0.2))
	for b in range(1, nb):
		var q: Vector3 = p0.lerp(p1, float(b) / nb)
		_pl(k, "fer", q + Vector3(0, 0.12, 0), q + Vector3(0, 1.0, 0), 0.02)
	var d: Vector3 = (p1 - p0)
	var gs := BoxShape3D.new()
	gs.size = Vector3(0.12, 1.3, d.length() + 0.08)
	k.shapes.append([gs, Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), _p(0, 0, 0) + (p0 + p1) * 0.5 + Vector3(0, 0.65, 0))])


## Le plafond du Cabinet : un disque de lambris bleu de nuit semé d'étoiles, ses poutres rayonnantes
func _plafond_etoile(k: RefCounted) -> void:
	var y: float = plafond - 0.02
	var n: int = 28
	for i in range(n):
		var a0: float = TAU * i / n
		var a1: float = TAU * (i + 1) / n
		k.tri("lambris", xf, Vector3(0, y, 0), _dir(a0) * (ri + 0.05) + Vector3(0, y, 0), _dir(a1) * (ri + 0.05) + Vector3(0, y, 0), Vector3.DOWN,
			Vector2(0.5, 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5))
	for i2 in range(8):
		var a: float = TAU * i2 / 8.0
		_pl(k, "chene", Vector3(0, plafond - 0.25, 0), _dir(a) * ri + Vector3(0, plafond - 0.25, 0), 0.26, Vector3.UP)
	k.cyl("or", _tr(0.0, plafond - 0.5, 0.0), 0.45, 0.6, 0.3, 16)
	k.cyl("chene", _tr(0.0, plafond - 0.2, 0.0), 0.6, 0.6, 0.2, 16)


## La sphère de cristal sur son trépied de bronze, la lueur qui bat au cœur (un nœud à part)
func _sphere_cristal(k: RefCounted, c: Vector3) -> void:
	var pc: Vector3 = _p(c.x, c.y, c.z)
	_objet("sphere", pc, pc)
	for i in range(3):
		var a: float = TAU * i / 3.0
		var pied: Vector3 = pc + _dir(a) * 0.55
		_poutre(k, "bronze", pied, pc + Vector3(0, 1.1, 0) + _dir(a) * 0.12, 0.06)
		k.cyl("bronze", Transform3D(Basis.IDENTITY, pied), 0.09, 0.06, 0.06, 8)
	k.cyl("bronze", Transform3D(Basis.IDENTITY, pc + Vector3(0, 1.05, 0)), 0.18, 0.32, 0.18, 16)
	_anneau(k, pc + Vector3(0, 1.25, 0), Vector3.UP, 0.34, 0.035)
	_anneau(k, pc + Vector3(0, 1.8, 0), Vector3(1, 0, 0.3).normalized(), 0.68, 0.025)
	_sphere(k, "cristal", pc + Vector3(0, 1.8, 0), 0.55)
	var col := CylinderShape3D.new()
	col.radius = 0.62
	col.height = 2.4
	k.shapes.append([col, Transform3D(Basis.IDENTITY, pc + Vector3(0, 1.2, 0))])
	coeur = Node3D.new()
	coeur.name = "Coeur_cristal"
	coeur.position = pc + Vector3(0, 1.8, 0)
	add_child(coeur)
	var kc := Kit.new()
	_sphere(kc, "rune_violet", Vector3.ZERO, 0.16)
	for i2 in range(3):
		var ax := Vector3(cos(i2 * 2.1), 0.5, sin(i2 * 2.1)).normalized()
		var u: Vector3 = ax.cross(Vector3.UP).normalized()
		_poutre(kc, "rune", -u * 0.32, u * 0.32, 0.015)
	coeur.add_child(kc.commit("Coeur_maillage"))


## Le pupitre du grimoire : le pied, le plateau incliné, le livre ouvert, la page qui tourne seule
func _pupitre(k: RefCounted, c: Vector3) -> void:
	var d: Vector3 = -Vector3(c.x, 0, c.z).normalized()
	var yaw: float = atan2(d.x, d.z)
	var t: Transform3D = _tr(c.x, c.y, c.z, yaw)
	_objet("grimoire", t.origin, t.origin)
	# (v12) le pied : quatre griffes, la colonne tournée, le chapiteau qui porte le plateau
	var cb := BoxShape3D.new()
	cb.size = Vector3(0.4, 1.0, 0.4)
	k.shapes.append([cb, t * Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 0))])
	for e in range(4):
		var a: float = PI * 0.5 * e + PI * 0.25
		var dd := Vector3(cos(a), 0, sin(a))
		_poutre(k, "chene", t * (dd * 0.3 + Vector3(0, 0.02, 0)), t * (dd * 0.08 + Vector3(0, 0.2, 0)), 0.07)
		k._ball(t * Transform3D(Basis.IDENTITY, dd * 0.32 + Vector3(0, 0.035, 0)), 0.04)
	_colonne_tournee(k, "chene", t, 0.95, 0.09)
	k.cyl("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0)), 0.12, 0.25, 0.08, 12)
	var plateau: Transform3D = t * Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3(0, 1.05, 0))
	k.box("chene", plateau, Vector3(0.8, 0.05, 0.6))
	k.box("velours_pourpre", plateau * Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0)), Vector3(0.66, 0.03, 0.46))
	k.box("drap", plateau * Transform3D(Basis.IDENTITY, Vector3(0, 0.08, 0)), Vector3(0.62, 0.025, 0.42))
	_bougie(k, t * Vector3(0.42, 1.12, 0.1), 0.2)
	page = Node3D.new()
	page.name = "Page_grimoire"
	page.transform = plateau * Transform3D(Basis.IDENTITY, Vector3(0, 0.11, 0))
	add_child(page)
	var kp := Kit.new()
	kp.quad("drap", Transform3D.IDENTITY, Vector3(0, 0, -0.2), Vector3(0.3, 0, -0.2), Vector3(0.3, 0, 0.2), Vector3(0, 0, 0.2), Vector3.UP)
	kp.quad("drap", Transform3D.IDENTITY, Vector3(0, -0.002, -0.2), Vector3(0.3, -0.002, -0.2), Vector3(0.3, -0.002, 0.2), Vector3(0, -0.002, 0.2), Vector3.DOWN)
	page.add_child(kp.commit("Page_maillage"))


# =================================================================== ce qui bouge

func _feux_follets() -> void:
	for i in range(12):
		var n := Node3D.new()
		n.name = "Feu_follet"
		add_child(n)
		var kf := Kit.new()
		_sphere(kf, "rune" if i % 3 != 0 else "rune_violet", Vector3.ZERO, 0.09 + 0.04 * (i % 2))
		n.add_child(kf.commit("Follet_maillage"))
		follets.append([n, float(i) / 12.0, 0.5 + 0.6 * _rng.randf(), 0.6 + 0.5 * _rng.randf()])


func _bougies_flottantes() -> void:
	var places: Array = []
	for i in range(9):
		var a: float = TAU * i / 9.0 + 0.2
		places.append(_dir(a) * (2.6 + 0.6 * (i % 2)) + Vector3(0, 7.0 + 0.8 * (i % 3), 0))
	for i2 in range(10):
		var a2: float = TAU * i2 / 10.0
		places.append(_dir(a2) * (2.8 + 0.5 * (i2 % 2)) + Vector3(0, cab + 6.0 + 0.6 * (i2 % 3), 0))
	for q in places:
		var n := Node3D.new()
		n.name = "Bougie_flottante"
		var base: Vector3 = _p(q.x, q.y, q.z)
		n.position = base
		add_child(n)
		var kb := Kit.new()
		_bougie(kb, Vector3.ZERO, 0.24)
		k_goutte(kb)
		n.add_child(kb.commit("Bougie_maillage"))
		flottants.append([n, base, _rng.randf() * TAU, 0.12 + 0.06 * _rng.randf()])


## (une goutte de cire figée sous la bougie)
func k_goutte(kb: RefCounted) -> void:
	kb.cyl("cire", Transform3D(Basis.IDENTITY, Vector3(0, -0.04, 0)), 0.02, 0.04, 0.04, 6)


## Les livres volants : ouverts, ils battent des pages comme des ailes en tournant sous le plafond
func _livres_volants() -> void:
	var couv: Array = ["velours_pourpre", "velours_bleu", "velours_vert"]
	for i in range(6):
		var n := Node3D.new()
		n.name = "Livre_volant"
		add_child(n)
		var moities: Array = []
		for s in [-1.0, 1.0]:
			var h := Node3D.new()
			n.add_child(h)
			var kl := Kit.new()
			kl.box(couv[i % 3], Transform3D(Basis.IDENTITY, Vector3(s * 0.13, 0, 0)), Vector3(0.26, 0.02, 0.36))
			kl.box("drap", Transform3D(Basis.IDENTITY, Vector3(s * 0.125, 0.02, 0)), Vector3(0.24, 0.03, 0.33))
			h.add_child(kl.commit("Livre_maillage"))
			moities.append(h)
		livres.append([n, float(i) / 6.0, moities])


func set_nuit(n: float) -> void:
	super.set_nuit(n)


func _process(delta: float) -> void:
	super._process(delta)
	_tm += delta
	# les runes respirent, le cristal bat
	var puls: float = 0.5 + 0.5 * sin(_tm * 1.3)
	(Kit.mat("rune") as StandardMaterial3D).emission_energy_multiplier = 1.0 + 1.2 * puls
	(Kit.mat("rune_violet") as StandardMaterial3D).emission_energy_multiplier = 1.0 + 1.0 * (0.5 + 0.5 * sin(_tm * 0.9 + 1.0))
	if coeur != null:
		coeur.scale = Vector3.ONE * (0.85 + 0.3 * puls)
		coeur.rotation.y = _tm * 0.7
	# les feux follets montent en tournant, de la salle jusqu'au cabinet, et recommencent
	var haut: float = cab + 8.0
	for f in follets:
		var u: float = fposmod(float(f[1]) + _tm * float(f[3]) / haut, 1.0)
		var a: float = u * TAU * 3.0 + float(f[1]) * TAU
		var rr: float = float(f[2]) * (0.7 + 0.3 * sin(u * TAU * 2.0))
		(f[0] as Node3D).position = _p(0, 0.6 + u * haut, 0) + _dir(a) * rr
	# les bougies flottent
	for b in flottants:
		(b[0] as Node3D).position = (b[1] as Vector3) + Vector3(0, sin(_tm * 0.8 + float(b[2])) * float(b[3]), 0)
	# les livres volent en rond en battant des pages
	for l in livres:
		var ph: float = float(l[1]) * TAU
		var a2: float = _tm * 0.25 + ph
		var n: Node3D = l[0]
		n.position = _p(0, cab + 3.0 + 0.4 * sin(_tm * 1.1 + ph * 2.0), 0) + _dir(a2) * (2.6 + 0.3 * sin(_tm * 0.7 + ph))
		var t := _dir(a2 + PI * 0.5)
		n.basis = Basis(Vector3.UP, atan2(t.x, t.z) + PI * 0.5) * Basis(Vector3(0, 0, 1), 0.2 * sin(_tm * 0.9 + ph))
		var bat: float = 0.35 + 0.45 * sin(_tm * 5.0 + ph * 3.0)
		(l[2][0] as Node3D).rotation.z = -bat
		(l[2][1] as Node3D).rotation.z = bat
	# la page du grimoire : elle se soulève, passe de l'autre côté, et recommence
	if page != null:
		var cyc: float = fposmod(_tm, 7.0)
		page.rotation.z = (PI * smoothstep(4.5, 6.5, cyc)) if cyc < 6.9 else PI

extends "res://scripts/ext_chateau/dortoirs_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : le dedans de la Tour de l'Astrolabe (le donjon) :
##  - la Salle de l'Astrolabe, au pied : le grand astrolabe de laiton dont les anneaux tournent
##    lentement sur leur socle, le tapis bleu, les bannières, les bancs, les lanternes ;
##  - la Nacelle : une cage de laiton qui monte dans le puits, au cœur de la tour, jusqu'à
##    l'Observatoire (54 m) et en redescend. Elle part seule quand on s'y tient un instant ; elle
##    vient seule quand on l'attend devant sa grille. Les grilles (des herses de laiton) ne s'ouvrent
##    que quand elle est là ;
##  - l'Observatoire, dans l'octogone : la Grande Lunette sur sa monture, le globe céleste, la table
##    des cartes du ciel, les bibliothèques, le plafond étoilé ; trois portes sur la terrasse
##    crénelée, d'où l'on voit tout le château et le lac.
## Repère : xf = le centre du donjon, au plancher de la salle du bas (y = le plateau).

const NACELLE_DUREE := 14.0       # secondes pour monter (ou descendre)
const NACELLE_ATTENTE := 1.5      # le temps de s'y tenir avant qu'elle parte
const CAGE := 1.3                 # le demi-côté du dedans de la cage

var main: Node                    # (posé par ombrelac.gd : pour porter le héros)
var anneaux: Array = []           # [Node3D, axe, vitesse]
var elan: float = 1.0             # (v15) la vitesse des anneaux (1 : leur pas ; plus quand on les lance)
var nacelle: Node3D
var grilles: Array = []           # [Node3D, CollisionShape3D, y fermée, haut ?]
var y_bas: float = 0.0
var y_haut: float = 54.0
var t_nacelle: float = 0.0        # 0 en bas, 1 en haut
var cible: float = 0.0
var en_route: bool = false
var voyages: int = 0
var _attente: float = 0.0
var _sorti: bool = true
var _puits: Vector3               # le centre du puits (repère château)


func construire_astrolabe(p: Vector3, hs: float, T: float, HH: float, h1: float, OH: float, ri_oct: float, puits: Vector3, phs: float) -> void:
	xf = Transform3D(Basis.IDENTITY, p)
	xf_sol = xf
	_puits = p + puits
	y_bas = p.y
	y_haut = p.y + h1
	_rng.seed = 4242
	var k := Kit.new()
	var hi: float = hs - T
	# --- la salle du bas
	_dallage(k, hi, 0.0, puits, phs, func(x: float, z: float) -> bool: return absf(x) < hi + 0.3 and absf(z) < hi + 0.3)
	_plafond_salle(k, hi, HH, puits, phs)
	_cadre_puits(k, puits, phs, HH)
	_grand_astrolabe(Vector3(0.0, 0.0, 3.4))
	# (v15) on le fait tourner (tout autour, sur le tapis)
	_objet("astrolabe", _p(0.0, 0.0, 3.4), _p(0.0, 0.0, 3.4))
	k.prism("pierre_claire", _tr(0.0, 0.0, 3.4), Kit.ngon(1.1, 8, PI / 8.0), 0.0, 0.25, true)
	k.prism("pierre_claire", _tr(0.0, 0.25, 3.4), Kit.ngon(0.55, 8, PI / 8.0), 0.0, 1.1, true)
	k.cyl("or", _tr(0.0, 1.35, 3.4), 0.12, 0.08, 1.0, 10)
	var col := CylinderShape3D.new()
	col.radius = 1.0
	col.height = 1.4
	k.shapes.append([col, _tr(0.0, 0.7, 3.4)])
	k.cyl("velours_bleu", _tr(0.0, 0.0, 3.4), 3.4, 3.4, 0.03, 32)
	k.cyl("or", _tr(0.0, 0.0, 3.4), 3.5, 3.5, 0.026, 32)
	# les bancs contre les murs ouest et sud, les bannières entre les baies
	# (v12) des bancs à dossier, leurs coussins
	for zb in [-4.6, 4.6]:
		_banc(k, _tr(-hi + 0.3, 0.0, zb, PI * 0.5), 2.4)
	_banc(k, _tr(-4.6, 0.0, hi - 0.3, PI), 2.4, "velours_pourpre")
	_banc(k, _tr(4.6, 0.0, hi - 0.3, PI), 2.4, "velours_pourpre")
	_banniere(k, "banniere_bleu", _p(0.0, HH - 1.0, hi - 0.06), 1.6, 4.4, Vector3(0, 0, -1))
	_banniere(k, "banniere_pourpre", _p(-hi + 0.06, HH - 1.0, 0.0), 1.6, 4.4, Vector3(1, 0, 0))
	_banniere(k, "banniere_pourpre", _p(hi - 0.06, HH - 1.0, 4.2), 1.6, 4.4, Vector3(-1, 0, 0))
	for lp in [Vector3(-4.0, HH - 3.0, 3.4), Vector3(4.0, HH - 3.0, 3.4)]:
		var lc: Vector3 = _p(lp.x, lp.y, lp.z)
		_lanterne(k, lc)
		_poutre(k, "fer", lc + Vector3(0, 0.74, 0), _p(lp.x, HH, lp.z), 0.03)
		_bougie(k, lc - Vector3(0, 0.35, 0), 0.18)
	_lumiere(_p(0.0, HH - 3.4, 3.4), 13.0, 0.8, 1.6)
	_lumiere(_p(0.0, 3.0, -0.2), 7.0, 0.4, 0.9)
	# --- l'Observatoire
	var oct := func(x: float, z: float) -> bool:
		var v := Vector2(x, z)
		for i in range(8):
			var a: float = TAU * i / 8.0
			if v.dot(Vector2(cos(a), sin(a))) > ri_oct + 0.35:
				return false
		return true
	_dallage(k, hi, h1, puits, phs, oct)
	_plafond_obs(k, ri_oct, h1 + OH)
	_garde_corps(k, puits, phs, h1)
	_lunette(k, Vector3(0.0, h1, 2.4), Vector3(-0.62, 0.42, 0.66).normalized())
	_objet("lunette", _p(0.0, h1, 2.4), _p(0.0, h1, 2.4), Vector3.ZERO, {"grande": true})
	_globe(k, Vector3(3.7, h1, 2.2))
	_table_cartes(k, Vector3(-3.3, h1, 0.4))
	for fi in [1, 5, 7]:
		var a2: float = TAU * fi / 8.0
		var d := Vector3(cos(a2), 0, sin(a2))
		var yaw: float = atan2(-d.x, -d.z)
		var pos: Vector3 = d * (ri_oct - 0.26)
		_rayonnage(k, _tr(pos.x, h1, pos.z, yaw), 3.4, 2.8, 0.45, false)
	for la in [deg_to_rad(112.0), deg_to_rad(292.0)]:
		var dl := Vector3(cos(la), 0, sin(la))
		var lc2: Vector3 = _p(0, 0, 0) + dl * (ri_oct - 0.55) + Vector3(0, h1 + 3.2, 0)
		_lanterne(k, lc2)
		_poutre(k, "fer", lc2 + Vector3(0, 0.74, 0), lc2 + Vector3(0, 0.95, 0), 0.03)
		_poutre(k, "fer", lc2 + Vector3(0, 0.95, 0), _p(0, 0, 0) + dl * ri_oct + Vector3(0, h1 + 0.95 + 3.2, 0), 0.04)
		_bougie(k, lc2 - Vector3(0, 0.35, 0), 0.18)
		_lumiere(lc2 - Vector3(0, 0.1, 0), 10.0, 0.6, 1.4)
	var mi: MeshInstance3D = k.commit("Ombrelac_astrolabe_meubles")
	mi.visibility_range_end = 140.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_astrolabe_meubles_col"))
	_sonde(Vector3(0.0, HH * 0.5 - 0.6, 0.0), Vector3(hi * 2.0 + 1.0, HH + 1.0, hi * 2.0 + 1.0))
	_sonde(Vector3(0.0, h1 + OH * 0.5, 0.0), Vector3(ri_oct * 2.0 + 1.0, OH + 0.6, ri_oct * 2.0 + 1.0))
	(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	# --- la Nacelle et ses deux grilles
	_nacelle()
	_grille(puits, phs, 0.0, 2.9, false)
	_grille(puits, phs, h1, 1.25, true)
	_poser_nacelle()
	# les lieux
	lieux["astrolabe_porte"] = _p(hs + 2.6, 0.0, 0.0)
	lieux["astrolabe_salle"] = _p(4.2, 0.0, -0.5)
	lieux["nacelle_bas"] = _p(puits.x, 0.0, puits.z)
	lieux["nacelle_haut"] = _p(puits.x, h1, puits.z)
	lieux["nacelle_attente_bas"] = _p(puits.x + 0.4, 0.0, puits.z + phs + 1.4)
	lieux["nacelle_attente_haut"] = _p(puits.x + 0.4, h1, puits.z + phs + 1.4)
	lieux["observatoire"] = _p(2.0, h1, -0.4)
	lieux["terrasse_astrolabe"] = _p(0.0, h1, hs - 1.4)
	lieux["terrasse_astrolabe_dehors"] = _p(0.0, h1, hs + 3.0)


## Un dallage de petits carreaux (de 0,5 m) à la hauteur y, sans le trou du puits, dans la forme
## donnée (dedans(x, z))
func _dallage(k: RefCounted, hi: float, y: float, puits: Vector3, phs: float, dedans: Callable) -> void:
	var c: float = 0.5
	var n: int = int(ceil((hi + 0.3) / c))
	for i in range(-n, n):
		for j in range(-n, n):
			var x0: float = i * c
			var z0: float = j * c
			var xm: float = x0 + c * 0.5
			var zm: float = z0 + c * 0.5
			if not bool(dedans.call(xm, zm)):
				continue
			if absf(xm - puits.x) < phs and absf(zm - puits.z) < phs:
				continue
			k.quad("dalles_int", xf, Vector3(x0, y + 0.02, z0), Vector3(x0 + c, y + 0.02, z0), Vector3(x0 + c, y + 0.02, z0 + c), Vector3(x0, y + 0.02, z0 + c), Vector3.UP)


## Le plafond de la salle du bas : des planches et des poutres, le trou du puits au milieu
func _plafond_salle(k: RefCounted, hi: float, HH: float, puits: Vector3, phs: float) -> void:
	var y: float = HH - 0.02
	var z0: float = puits.z - phs
	var z1: float = puits.z + phs
	k.quad("chene", xf, Vector3(-hi, y, z1), Vector3(hi, y, z1), Vector3(hi, y, hi), Vector3(-hi, y, hi), Vector3.DOWN)
	k.quad("chene", xf, Vector3(-hi, y, -hi), Vector3(hi, y, -hi), Vector3(hi, y, z0), Vector3(-hi, y, z0), Vector3.DOWN)
	for e in [-1.0, 1.0]:
		var xa: float = e * phs
		var xb: float = e * hi
		k.quad("chene", xf, Vector3(minf(xa, xb), y, z0), Vector3(maxf(xa, xb), y, z0), Vector3(maxf(xa, xb), y, z1), Vector3(minf(xa, xb), y, z1), Vector3.DOWN)
	for x in [-5.6, -2.6, 2.6, 5.6]:
		_pl(k, "chene", Vector3(x, HH - 0.4, -hi), Vector3(x, HH - 0.4, hi), 0.38, Vector3.UP)
	for z in [-6.2, 0.6, 5.0]:
		_pl(k, "chene", Vector3(-hi, HH - 0.75, z), Vector3(hi, HH - 0.75, z), 0.3, Vector3.UP)


## Le cadre de laiton du puits, dans la salle du bas : les montants, les barreaux (au fond et sur
## les côtés), le linteau orné d'un soleil
func _cadre_puits(k: RefCounted, puits: Vector3, phs: float, HH: float) -> void:
	var x0: float = puits.x - phs
	var x1: float = puits.x + phs
	var z0: float = puits.z - phs
	var z1: float = puits.z + phs
	for c in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1)]:
		k.box("or", _tr(c.x, 0.0, c.y), Vector3(0.14, HH, 0.14))
	for i in range(1, 11):
		var u: float = float(i) / 11.0
		var xb: float = lerpf(x0, x1, u)
		var zb: float = lerpf(z0, z1, u)
		k.box("or", _tr(xb, 0.0, z0), Vector3(0.04, HH, 0.04))
		k.box("or", _tr(x0, 0.0, zb), Vector3(0.04, HH, 0.04))
		k.box("or", _tr(x1, 0.0, zb), Vector3(0.04, HH, 0.04))
	for yb in [0.05, 3.0, 6.0, 9.0]:
		k.box("or", _tr(puits.x, yb, z0), Vector3(phs * 2.0, 0.08, 0.08))
		k.box("or", _tr(x0, yb, puits.z), Vector3(0.08, 0.08, phs * 2.0))
		k.box("or", _tr(x1, yb, puits.z), Vector3(0.08, 0.08, phs * 2.0))
	k.box("or", _tr(puits.x, 2.9, z1), Vector3(phs * 2.0 + 0.14, 0.18, 0.16))
	k.cyl("or", _tr(puits.x, 3.45, z1 + 0.06) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.38, 0.38, 0.05, 16)
	for r in range(12):
		var a: float = TAU * r / 12.0
		var d := Vector3(cos(a), sin(a), 0)
		_poutre(k, "or", _p(puits.x, 3.45, z1 + 0.1) + d * 0.38, _p(puits.x, 3.45, z1 + 0.1) + d * 0.68, 0.035, Vector3(0, 0, 1))
	# la collision : le fond et les côtés (on n'entre que par la grille)
	for b in [[Vector3(puits.x, 0.0, z0 - 0.05), Vector3(phs * 2.0, HH, 0.1)], [Vector3(x0 - 0.05, 0.0, puits.z), Vector3(0.1, HH, phs * 2.0)],
			[Vector3(x1 + 0.05, 0.0, puits.z), Vector3(0.1, HH, phs * 2.0)]]:
		var bs := BoxShape3D.new()
		bs.size = b[1]
		k.shapes.append([bs, _tr(b[0].x, b[1].y * 0.5, b[0].z)])


## Le garde-corps de laiton autour du puits, dans l'Observatoire (au fond et sur les côtés)
func _garde_corps(k: RefCounted, puits: Vector3, phs: float, y: float) -> void:
	var x0: float = puits.x - phs
	var x1: float = puits.x + phs
	var z0: float = puits.z - phs
	var z1: float = puits.z + phs
	for seg in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x0, z0), Vector2(x0, z1)], [Vector2(x1, z0), Vector2(x1, z1)]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		_pl(k, "or", Vector3(a.x, y + 1.1, a.y), Vector3(b.x, y + 1.1, b.y), 0.07, Vector3.UP)
		_pl(k, "or", Vector3(a.x, y + 0.5, a.y), Vector3(b.x, y + 0.5, b.y), 0.04, Vector3.UP)
		for i in range(9):
			var u: float = float(i) / 8.0
			var q: Vector2 = a.lerp(b, u)
			k.box("or", _tr(q.x, y, q.y), Vector3(0.035, 1.1, 0.035))
		var bs := BoxShape3D.new()
		bs.size = Vector3(maxf(absf(b.x - a.x), 0.1), 1.3, maxf(absf(b.y - a.y), 0.1))
		k.shapes.append([bs, _tr((a.x + b.x) * 0.5, y + 0.65, (a.y + b.y) * 0.5)])
	for c in [Vector2(x0, z1), Vector2(x1, z1)]:
		k.box("or", _tr(c.x, y, c.y), Vector3(0.12, 1.35, 0.12))
		k.cyl("or", _tr(c.x, y + 1.35, c.y), 0.1, 0.0, 0.2, 8)


## Le plafond de l'Observatoire : un octogone peint (le bleu de nuit semé d'étoiles d'or)
func _plafond_obs(k: RefCounted, ri: float, y: float) -> void:
	var r: float = ri / cos(PI / 8.0) + 0.3
	for i in range(8):
		var a0: float = TAU * i / 8.0 + PI / 8.0
		var a1: float = a0 + TAU / 8.0
		k.tri("lambris", xf, Vector3(0, y - 0.02, 0), Vector3(cos(a0) * r, y - 0.02, sin(a0) * r), Vector3(cos(a1) * r, y - 0.02, sin(a1) * r), Vector3.DOWN)
	# une couronne de laiton au milieu, d'où partent huit nervures
	_anneau(k, _p(0, y - 0.1, 0), Vector3.UP, 1.2, 0.06)
	for i2 in range(8):
		var a2: float = TAU * i2 / 8.0 + PI / 8.0
		_poutre(k, "or", _p(cos(a2) * 1.2, y - 0.1, sin(a2) * 1.2), _p(cos(a2) * r * 0.97, y - 0.1, sin(a2) * r * 0.97), 0.08, Vector3.UP)


## Le grand astrolabe : trois anneaux de laiton emboîtés qui tournent lentement, chacun autour de son
## axe, et la sphère d'or au milieu (c : le pied, repère du donjon)
func _grand_astrolabe(c: Vector3) -> void:
	var centre: Vector3 = _p(c.x, 3.6, c.z)
	var defs := [[2.3, Vector3(0, 0, 1), 0.07, 0.11, "or"], [1.9, Vector3(1, 0, 0), -0.1, 0.09, "or"], [1.5, Vector3(0.3, 1, 0.2).normalized(), 0.16, 0.08, "cuivre_neuf"]]
	var parent: Node3D = null
	for dd in defs:
		var n := Node3D.new()
		n.name = "Anneau_astrolabe"
		var ka := Kit.new()
		var r: float = float(dd[0])
		var ax: Vector3 = dd[1]
		var u: Vector3 = ax.cross(Vector3.UP if absf(ax.y) < 0.9 else Vector3.RIGHT).normalized()
		var v: Vector3 = ax.cross(u).normalized()
		for i in range(32):
			var a0: float = TAU * i / 32.0
			var a1: float = TAU * (i + 1) / 32.0
			_poutre(ka, str(dd[4]), (u * cos(a0) + v * sin(a0)) * r, (u * cos(a1) + v * sin(a1)) * r, float(dd[3]), ax)
		# les graduations, les deux pivots
		for i2 in range(0, 32, 2):
			var a2: float = TAU * i2 / 32.0
			var q: Vector3 = (u * cos(a2) + v * sin(a2))
			_poutre(ka, "or", q * (r - 0.02), q * (r - 0.16), 0.03, ax)
		ka.box("or", Transform3D(Basis.IDENTITY, u * (r + 0.05)), Vector3(0.12, 0.12, 0.12))
		ka.box("or", Transform3D(Basis.IDENTITY, -u * (r + 0.05)), Vector3(0.12, 0.12, 0.12))
		var mi: MeshInstance3D = ka.commit("Anneau_maillage")
		n.add_child(mi)
		if parent == null:
			n.position = centre
			add_child(n)
		else:
			parent.add_child(n)
		anneaux.append([n, ax, float(dd[2])])
		parent = n
	# la sphère d'or et ses deux bagues, au cœur
	var ks := Kit.new()
	_sphere(ks, "or", Vector3.ZERO, 0.42)
	_anneau(ks, Vector3.ZERO, Vector3(0.2, 1, 0).normalized(), 0.62, 0.03)
	_anneau(ks, Vector3.ZERO, Vector3(1, 0.3, 0.4).normalized(), 0.72, 0.025)
	var ms: MeshInstance3D = ks.commit("Astrolabe_coeur")
	ms.position = centre
	add_child(ms)
	# le méridien fixe, qui tient le tout sur son pied
	var km := Kit.new()
	var ax2 := Vector3(0, 0, 1)
	for i3 in range(20):
		var b0: float = PI * 0.5 + PI * i3 / 20.0 + PI * 0.5
		var b1: float = PI * 0.5 + PI * (i3 + 1) / 20.0 + PI * 0.5
		_poutre(km, "or", centre + Vector3(cos(b0), sin(b0), 0) * 2.6, centre + Vector3(cos(b1), sin(b1), 0) * 2.6, 0.12, ax2)
	_poutre(km, "or", centre + Vector3(0, -2.6, 0), _p(c.x, 1.0, c.z), 0.14, Vector3.RIGHT)
	var mm: MeshInstance3D = km.commit("Astrolabe_meridien")
	add_child(mm)


## La Grande Lunette : le pilier, la fourche, le tube de laiton tourné vers une baie, l'oculaire,
## le chercheur, la chaise de l'astronome
func _lunette(k: RefCounted, c: Vector3, dir: Vector3) -> void:
	k.cyl("pierre_claire", _tr(c.x, c.y, c.z), 0.65, 0.5, 0.25, 12, true, true)
	k.cyl("pierre_claire", _tr(c.x, c.y + 0.25, c.z), 0.42, 0.36, 1.3, 12, true, true)
	k.cyl("or", _tr(c.x, c.y + 1.55, c.z), 0.45, 0.45, 0.1, 16)
	var pivot: Vector3 = _p(c.x, c.y + 2.25, c.z)
	var side: Vector3 = dir.cross(Vector3.UP).normalized()
	for e in [-1.0, 1.0]:
		_poutre(k, "or", _p(c.x, c.y + 1.65, c.z) + side * e * 0.5, pivot + side * e * 0.5, 0.09, dir)
		k.cyl("or", Transform3D(Basis(side.cross(Vector3.UP).normalized(), side, Vector3.UP).orthonormalized(), pivot + side * e * 0.5), 0.12, 0.12, 0.06, 10)
	var yb: Vector3 = dir
	var xb: Vector3 = side
	var zb: Vector3 = xb.cross(yb).normalized()
	var b := Basis(xb, yb, zb)
	var arr: Vector3 = pivot - dir * 1.9
	k.cyl("cuivre_neuf", Transform3D(b, arr), 0.26, 0.36, 2.0, 18)
	k.cyl("cuivre_neuf", Transform3D(b, arr + dir * 2.0), 0.36, 0.42, 3.4, 18)
	for s in [0.2, 1.95, 3.5, 5.25]:
		k.cyl("or", Transform3D(b, arr + dir * s), 0.31 + s * 0.022, 0.31 + s * 0.022, 0.12, 18)
	k.cyl("or", Transform3D(b, arr + dir * 5.4), 0.46, 0.48, 0.25, 18, false)
	k.cyl("verre", Transform3D(b, arr + dir * 5.6), 0.4, 0.4, 0.01, 18, true)
	k.cyl("or", Transform3D(b, arr - dir * 0.35), 0.06, 0.12, 0.35, 10)
	# le chercheur
	var ch: Vector3 = pivot + zb * 0.55 - dir * 0.6
	k.cyl("cuivre_neuf", Transform3D(b, ch), 0.07, 0.09, 1.3, 10)
	_poutre(k, "or", ch + dir * 0.3, ch + dir * 0.3 - zb * 0.22, 0.03)
	_poutre(k, "or", ch + dir * 1.0, ch + dir * 1.0 - zb * 0.22, 0.03)
	# la chaise de l'astronome, derrière l'oculaire
	var pc: Vector3 = arr - dir * 0.9
	# (v12) le tabouret à vis de l'astronome : trois pieds, la vis de laiton, l'assise ronde capitonnée
	var tb: Transform3D = _tr(pc.x - xf.origin.x, c.y, pc.z - xf.origin.z, atan2(dir.x, dir.z))
	for i in range(3):
		var a: float = TAU * i / 3.0
		_poutre(k, "chene", tb * Vector3(cos(a) * 0.26, 0, sin(a) * 0.26), tb * Vector3(cos(a) * 0.08, 0.38, sin(a) * 0.08), 0.045)
		_poutre(k, "chene", tb * Vector3(cos(a) * 0.19, 0.14, sin(a) * 0.19), tb * Vector3(cos(a + TAU / 3.0) * 0.19, 0.14, sin(a + TAU / 3.0) * 0.19), 0.025)
	k.cyl("chene", tb * Transform3D(Basis.IDENTITY, Vector3(0, 0.36, 0)), 0.1, 0.1, 0.06, 12)
	k.cyl("or", tb * Transform3D(Basis.IDENTITY, Vector3(0, 0.42, 0)), 0.025, 0.025, 0.1, 8)
	k.cyl("chene", tb * Transform3D(Basis.IDENTITY, Vector3(0, 0.52, 0)), 0.24, 0.24, 0.04, 16, true, true)
	k.cyl("velours_pourpre", tb * Transform3D(Basis.IDENTITY, Vector3(0, 0.56, 0)), 0.23, 0.2, 0.06, 16)
	var cs := CylinderShape3D.new()
	cs.radius = 0.26
	cs.height = 0.6
	k.shapes.append([cs, tb * Transform3D(Basis.IDENTITY, Vector3(0, 0.3, 0))])


## Le globe céleste sur son pied de chêne
func _globe(k: RefCounted, c: Vector3) -> void:
	_objet("globe", _p(c.x, c.y, c.z), _p(c.x, c.y, c.z))
	k.cyl("chene", _tr(c.x, c.y, c.z), 0.45, 0.3, 0.08, 12)
	for i in range(3):
		var a: float = TAU * i / 3.0
		_pl(k, "chene", Vector3(c.x + cos(a) * 0.4, c.y + 0.05, c.z + sin(a) * 0.4), Vector3(c.x + cos(a) * 0.2, c.y + 0.9, c.z + sin(a) * 0.2), 0.06)
	_anneau(k, _p(c.x, c.y + 1.35, c.z), Vector3.UP, 0.62, 0.05)
	_sphere(k, "velours_bleu", _p(c.x, c.y + 1.35, c.z), 0.52)
	_anneau(k, _p(c.x, c.y + 1.35, c.z), Vector3(0.38, 0, 0.92).normalized(), 0.58, 0.035)
	for j in range(14):
		var t: float = TAU * j / 14.0
		var q := Vector3(cos(t) * 0.53, sin(t * 2.3) * 0.3, sin(t) * 0.53).normalized() * 0.53
		k.box("or", Transform3D(Basis.IDENTITY, _p(c.x, c.y + 1.35, c.z) + q), Vector3(0.035, 0.035, 0.035))
	var col := CylinderShape3D.new()
	col.radius = 0.6
	col.height = 1.9
	k.shapes.append([col, _tr(c.x, c.y + 0.95, c.z)])


## La table des cartes du ciel, ses chaises, sa lampe, ses instruments
func _table_cartes(k: RefCounted, c: Vector3) -> void:
	_objet("table_cartes", _p(c.x - 0.8, c.y, c.z), _p(c.x + 0.8, c.y, c.z))
	var t0 := Transform3D(Basis.IDENTITY, Vector3(0, c.y, 0))
	var old: Transform3D = xf
	xf = xf * t0
	_table_l(k, c.x, c.z, 2.2, 1.2)
	k.quad("carte_ciel", xf, Vector3(c.x - 0.7, 0.805, c.z - 0.45), Vector3(c.x + 0.5, 0.805, c.z - 0.45), Vector3(c.x + 0.5, 0.805, c.z + 0.45), Vector3(c.x - 0.7, 0.805, c.z + 0.45), Vector3.UP,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	_lampe(k, _p(c.x + 0.8, 0.8, c.z - 0.35))
	_chaise(k, c.x - 0.5, c.z + 0.95, PI)
	_chaise(k, c.x + 0.5, c.z - 0.95, 0.0)
	_anneau(k, _p(c.x + 0.75, 0.86, c.z + 0.3), Vector3.UP, 0.14, 0.02)
	_poutre(k, "or", _p(c.x + 0.6, 0.81, c.z + 0.1), _p(c.x + 0.95, 0.81, c.z + 0.45), 0.02, Vector3.UP)
	# (v12) l'encrier, le compas ouvert sur la carte, des cartes roulées, une loupe
	_encrier(k, _p(c.x - 0.85, 0.8, c.z - 0.3))
	var cp: Vector3 = _p(c.x - 0.2, 0.81, c.z)
	_poutre(k, "or", cp + Vector3(0, 0.12, 0), cp + xf.basis * Vector3(-0.08, 0, 0.05), 0.008)
	_poutre(k, "or", cp + Vector3(0, 0.12, 0), cp + xf.basis * Vector3(0.08, 0, -0.03), 0.008)
	k._ball(Transform3D(Basis.IDENTITY, cp + Vector3(0, 0.125, 0)), 0.012)
	for r in range(3):
		var rp: Vector3 = _p(c.x - 0.95 + r * 0.04, 0.8 + 0.04 + (0.06 if r == 2 else 0.0), c.z + 0.2 + r * 0.09 - (0.06 if r == 2 else 0.0))
		k.cyl("drap", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), rp - xf.basis.z * 0.28), 0.035, 0.035, 0.56, 10)
		k.cyl("velours_bleu", Transform3D(xf.basis * Basis(Vector3.RIGHT, PI * 0.5), rp - xf.basis.z * 0.03), 0.037, 0.037, 0.03, 10, false)
	var lp: Vector3 = _p(c.x + 0.25, 0.81, c.z + 0.3)
	_anneau(k, lp + Vector3(0, 0.01, 0), Vector3.UP, 0.06, 0.012)
	k.cyl("verre", Transform3D(Basis.IDENTITY, lp + Vector3(0, 0.005, 0)), 0.055, 0.055, 0.008, 14)
	_poutre(k, "chene", lp + xf.basis * Vector3(0.06, 0.01, 0), lp + xf.basis * Vector3(0.2, 0.01, 0.04), 0.022)
	xf = old


# =================================================================== la Nacelle

func _nacelle() -> void:
	nacelle = Node3D.new()
	nacelle.name = "Nacelle"
	add_child(nacelle)
	var k := Kit.new()
	var c: float = CAGE + 0.15
	var hc: float = 2.7
	k.box("chene", Transform3D(Basis.IDENTITY, Vector3(0, -0.15, 0)), Vector3(c * 2.0, 0.15, c * 2.0))
	k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, -0.2, 0)), Vector3(c * 2.0 + 0.08, 0.06, c * 2.0 + 0.08))
	for e in [Vector2(-c, -c), Vector2(c, -c), Vector2(-c, c), Vector2(c, c)]:
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(e.x, 0, e.y)), Vector3(0.1, hc, 0.1))
	for i in range(1, 12):
		var u: float = lerpf(-c, c, float(i) / 12.0)
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(u, 0, -c)), Vector3(0.03, hc, 0.03))
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(-c, 0, u)), Vector3(0.03, hc, 0.03))
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(c, 0, u)), Vector3(0.03, hc, 0.03))
	for yb in [1.0, hc]:
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, yb, -c)), Vector3(c * 2.0, 0.06, 0.06))
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(-c, yb, 0)), Vector3(0.06, 0.06, c * 2.0))
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(c, yb, 0)), Vector3(0.06, 0.06, c * 2.0))
	k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, hc, c)), Vector3(c * 2.0, 0.08, 0.08))
	# le dôme, le câble, la lanterne du dedans
	for i2 in range(4):
		var a: float = TAU * i2 / 4.0 + PI * 0.25
		var q := Vector3(cos(a), 0, sin(a)) * c * 1.41
		_poutre(k, "or", q + Vector3(0, hc, 0), Vector3(0, hc + 1.0, 0), 0.05)
	k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(0, hc + 0.95, 0)), 0.2, 0.0, 0.4, 10)
	k.cyl("fer", Transform3D(Basis.IDENTITY, Vector3(0, hc + 1.3, 0)), 0.03, 0.03, 60.0, 6)
	_lanterne(k, Vector3(0, hc - 0.6, 0))
	_bougie(k, Vector3(0, hc - 0.95, 0), 0.16)
	k.box("velours_bleu", Transform3D(Basis.IDENTITY, Vector3(0, 0, -c + 0.3)), Vector3(c * 1.6, 0.45, 0.45))
	var mi: MeshInstance3D = k.commit("Nacelle_maillage")
	nacelle.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Nacelle_plancher"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(c * 2.0, 0.3, c * 2.0)
	cs.shape = bs
	cs.position = Vector3(0, -0.15, 0)
	body.add_child(cs)
	nacelle.add_child(body)


## Une grille de laiton (une herse) devant le puits, au niveau y ; elle monte quand la Nacelle est là
func _grille(puits: Vector3, phs: float, y: float, h: float, haut: bool) -> void:
	var n := Node3D.new()
	n.name = "Grille_nacelle"
	add_child(n)
	var k := Kit.new()
	var w: float = phs * 2.0
	for i in range(13):
		var u: float = lerpf(-w * 0.5, w * 0.5, float(i) / 12.0)
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(u, 0, 0)), Vector3(0.04, h, 0.04))
		k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(u, -0.12, 0)), 0.0, 0.03, 0.12, 6)
	for yb in [0.15, h * 0.5, h - 0.06]:
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, yb, 0)), Vector3(w, 0.06, 0.06))
	n.add_child(k.commit("Grille_maillage"))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h + 0.4, 0.2)
	cs.shape = bs
	cs.position = Vector3(0, (h + 0.4) * 0.5 - 0.2, 0)
	body.add_child(cs)
	n.add_child(body)
	var pos: Vector3 = _p(puits.x, y, puits.z + phs + 0.05)
	n.position = pos
	grilles.append([n, cs, pos, haut, h])


func nacelle_y() -> float:
	var e: float = t_nacelle * t_nacelle * (3.0 - 2.0 * t_nacelle)
	return lerpf(y_bas, y_haut, e)


func en_haut() -> bool:
	return not en_route and t_nacelle > 0.99


func en_bas() -> bool:
	return not en_route and t_nacelle < 0.01


## Un point (le héros) est-il dans la Nacelle ?
func dans_nacelle(q: Vector3) -> bool:
	var cy: float = nacelle_y()
	return absf(q.x - _puits.x) < CAGE + 0.1 and absf(q.z - _puits.z) < CAGE + 0.1 and q.y > cy - 0.6 and q.y < cy + 2.6


func partir(vers_haut: bool) -> void:
	if en_route:
		return
	cible = 1.0 if vers_haut else 0.0
	if absf(cible - t_nacelle) < 0.01:
		return
	en_route = true
	voyages += 1
	_dire("La Nacelle s'élève dans le puits… Prochain arrêt : l'Observatoire." if vers_haut else "La Nacelle redescend… Prochain arrêt : la Salle de l'Astrolabe.")


func _dire(txt: String) -> void:
	if main != null and main.has_method("_show_message_v28") and main.has_method("_player_pos_v27") and dans_nacelle(to_local(main._player_pos_v27())):
		main._show_message_v28(txt)


func _poser_nacelle() -> void:
	if nacelle != null:
		nacelle.position = Vector3(_puits.x, nacelle_y(), _puits.z)


func _physics_process(delta: float) -> void:
	if nacelle == null:
		return
	var joueur: Vector3 = to_local(main._player_pos_v27()) if main != null and main.has_method("_player_pos_v27") else Vector3.INF
	var dedans: bool = joueur != Vector3.INF and dans_nacelle(joueur)
	if not dedans:
		_sorti = true
	if not en_route:
		# on s'y tient un instant : elle part ; on l'attend devant la grille de l'autre étage : elle vient
		if dedans and _sorti:
			_attente += delta
			if _attente > NACELLE_ATTENTE:
				_attente = 0.0
				partir(t_nacelle < 0.5)
		else:
			_attente = 0.0
			if joueur != Vector3.INF and not dedans:
				var dh: float = Vector2(joueur.x - _puits.x, joueur.z - (_puits.z + PUITS_HS_DEF + 1.2)).length()
				if dh < 2.2:
					if t_nacelle > 0.5 and absf(joueur.y - y_bas) < 2.5:
						partir(false)
					elif t_nacelle < 0.5 and absf(joueur.y - y_haut) < 2.5:
						partir(true)
	var y_avant: float = nacelle_y()
	if en_route:
		var dir: float = signf(cible - t_nacelle)
		t_nacelle = clampf(t_nacelle + dir * delta / NACELLE_DUREE, 0.0, 1.0)
		if (dir > 0.0 and t_nacelle >= cible) or (dir < 0.0 and t_nacelle <= cible):
			t_nacelle = cible
			en_route = false
			_sorti = not dedans
			_dire("L'Observatoire : tout le château à vos pieds !" if t_nacelle > 0.5 else "La Salle de l'Astrolabe. Bonne journée !")
	var y_ap: float = nacelle_y()
	_poser_nacelle()
	var dy: float = y_ap - y_avant
	if absf(dy) > 0.00001 and joueur != Vector3.INF and dans_nacelle(Vector3(joueur.x, joueur.y - dy, joueur.z)):
		_porter(dy)
	# les grilles : levées quand la Nacelle est à leur étage
	for g in grilles:
		var ouverte: bool = en_haut() if bool(g[3]) else en_bas()
		(g[1] as CollisionShape3D).disabled = ouverte
		var n: Node3D = g[0]
		var voulu: Vector3 = (g[2] as Vector3) + Vector3(0, float(g[4]) + 0.2 if ouverte else 0.0, 0)
		n.position = n.position.move_toward(voulu, delta * 1.8)


const PUITS_HS_DEF := 1.7


## Le héros monte (ou descend) avec la Nacelle
func _porter(dy: float) -> void:
	if main.get("xr_active") and main.xr_active and main.get("xr_origin") != null:
		main.xr_origin.position.y += dy
		if main.get("vr_body") != null:
			main.vr_body.global_position.y += dy
			if dy > 0.0:
				main.vr_body.velocity.y = maxf(main.vr_body.velocity.y, 0.0)
	elif main.get("pc_body") != null:
		main.pc_body.global_position.y += dy
		if main.get("pc_root") != null:
			main.pc_root.position.y += dy
		if dy > 0.0:
			main.pc_body.velocity.y = maxf(main.pc_body.velocity.y, 0.0)
		if main.get("hero_v28") != null and main.hero_v28 != null and main.hero_v28.get("fall_top") != null:
			main.hero_v28.fall_top = main.pc_body.global_position.y
	if main.get("last_ok_v29") != null and main.last_ok_v29 is Array:
		main.last_ok_v29.clear()


func _process(delta: float) -> void:
	super._process(delta)
	# (v15) l'élan qu'on lui donne (on le fait tourner) retombe doucement
	elan = 1.0 + (elan - 1.0) * exp(-delta * 0.35)
	for a in anneaux:
		(a[0] as Node3D).rotate(a[1], float(a[2]) * delta * elan)

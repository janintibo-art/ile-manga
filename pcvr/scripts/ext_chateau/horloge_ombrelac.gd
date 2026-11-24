extends "res://scripts/ext_chateau/astrolabe_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : le dedans de la Tour de l'Horloge :
##  - la Salle des Poids, au pied : le grand balancier qui descend de la chambre des rouages et
##    bat lentement au-dessus de la rose des vents de laiton, les poids de fonte au bout de leurs
##    chaînes, l'établi de l'horloger ;
##  - l'escalier de pierre qui monte en huit volées le long des murs, autour du vide, jusqu'à la
##    Chambre des Rouages (28 m) ;
##  - la Chambre des Rouages : le bâti de fer et ses roues de laiton qui tournent, l'échappement qui
##    bat la seconde, les arbres qui portent le mouvement aux quatre cadrans ; les cadrans sont de
##    verre opalin : le jour on voit, en ombre, le dos des aiguilles ; la nuit ils s'allument ;
##  - sous le toit, la cloche de bronze : elle sonne les heures du jeu (autant de coups que l'heure).
## Les aiguilles des quatre cadrans (dehors et dedans) donnent l'heure du jeu.
## Repère : xf = le centre de la tour, au plancher de la salle du bas (y = le plateau).

const VOLEES := 8
const MONTEE := 3.5               # la hauteur d'une volée
const LARGEUR := 1.3              # la largeur de l'escalier (le long des murs)
const MARCHES_VOLEE := 20
const ROUAGES_Y := 28.0           # le plancher de la chambre des rouages
const PIVOT := Vector3(0.0, 2.35, 0.45)   # le pivot du balancier, au-dessus du plancher des rouages
const BOB_Y := 6.2                # le bas du balancier (la lentille), au-dessus du sol
const COUP_INTERVALLE := 2.8

var balancier: Node3D
var ancre: Node3D
var echappement: Node3D
var roues: Array = []             # [Node3D, vitesse]
var arbres: Array = []            # [Node3D, vitesse] (tournent autour de leur axe y local)
var aiguilles: Array = []         # [Node3D, Basis du cadran, heure ?]
var cloche: Node3D
var son: AudioStreamPlayer3D
var periode: float = 9.7
var angle_heure: float = 0.0      # (radians, le sens des aiguilles d'une montre, midi = 0)
var angle_minute: float = 0.0
var coups_a_sonner: int = 0
var coups_sonnes: int = 0
var derniere_heure: int = -1
var _t_balancier: float = 0.0
var _t_coup: float = 0.0
var _branle: float = 0.0          # l'élan de la cloche (décroît)
var _tic: int = 0
var heure_forcee: float = -1.0    # (pour les photos)
static var _son_cloche: AudioStreamWAV


func construire_horloge(p: Vector3, hs: float, T: float, h: float, cy: float, rc: float) -> void:
	xf = Transform3D(Basis.IDENTITY, p)
	xf_sol = xf
	_puits = Vector3(1e6, 0, 1e6)
	_rng.seed = 7171
	_cy = cy
	var k := Kit.new()
	var hi: float = hs - T
	# --- la salle des poids
	_dallage(k, hi, 0.0, Vector3(1e6, 0, 1e6), 0.0, func(x: float, z: float) -> bool: return absf(x) < hi + 0.3 and absf(z) < hi + 0.3)
	_rose_des_vents(k, Vector3(0.0, 0.0, PIVOT.z), 1.9)
	_etabli(k, Vector3(hi - 0.45, 0.0, -1.6), -PI * 0.5)
	_banc(k, _tr(-1.8, 0.0, -hi + 0.3), 2.4)
	_coffre_ferre(k, _tr(1.6, 0.0, -hi + 0.4), 1.4, 0.9, 0.7)                        # le coffre aux pièces de rechange
	# (v12) sur le coffre : une roue de rechange, une burette d'huile
	_anneau(k, _p(1.3, 0.92, -hi + 0.4), Vector3.UP, 0.18, 0.025)
	k.cyl("or", _tr(1.3, 0.9, -hi + 0.4), 0.035, 0.035, 0.03, 8)
	k.cyl("cuivre_neuf", _tr(1.95, 0.9, -hi + 0.45), 0.06, 0.05, 0.09, 10)
	_poutre(k, "cuivre_neuf", _p(1.95, 0.99, -hi + 0.45), _p(2.1, 1.07, -hi + 0.55), 0.012)
	_banniere(k, "banniere_bleu", _p(0.0, 4.6, -hi + 0.06), 1.4, 3.6, Vector3(0, 0, 1))
	_escalier(k, hi)
	_poids(k)
	# --- la chambre des rouages
	_plancher_rouages(k, hi)
	_bati(k)
	_plafond_cloche(k, hi, h)
	_etabli(k, Vector3(hi - 0.45, ROUAGES_Y, 1.8), -PI * 0.5)
	# le pupitre du gardien (v12 : sur pieds, le plateau incliné, le registre ouvert, l'encrier, le tabouret)
	var tg: Transform3D = _tr(-1.6, ROUAGES_Y, hi - 0.4)
	for ex in [-0.7, 0.7]:
		for ez in [-0.22, 0.22]:
			_colonne_tournee(k, "chene", tg * Transform3D(Basis.IDENTITY, Vector3(ex, 0, ez)), 0.95, 0.04)
	k.box("chene", tg * Transform3D(Basis.IDENTITY, Vector3(0, 0.25, 0)), Vector3(1.4, 0.05, 0.05), true)
	k.box("chene", tg * Transform3D(Basis.IDENTITY, Vector3(0, 0.82, 0)), Vector3(1.5, 0.13, 0.55), true)
	var dessus: Transform3D = tg * Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.98, 0))
	k.box("chene", dessus, Vector3(1.6, 0.04, 0.62))
	k.box("chene", dessus * Transform3D(Basis.IDENTITY, Vector3(0, 0.04, -0.3)), Vector3(1.6, 0.03, 0.03))
	_livre_ouvert(k, dessus * Transform3D(Basis.IDENTITY, Vector3(-0.15, 0.04, 0.02)), 0.5, 0.36, "velours_pourpre")
	_encrier(k, tg * Vector3(0.55, 1.0, 0.02))
	_tabouret(k, _tr(-1.6, ROUAGES_Y, hi - 1.15), 0.62)
	# --- les lanternes et les lumières
	var lp: Array = [Vector3(-2.6, 3.2, -hi + 0.35), Vector3(2.6, 3.2, -hi + 0.35), Vector3(hi - 0.35, 10.0, -hi + 0.35),
		Vector3(-hi + 0.35, 17.0, hi - 0.35), Vector3(hi - 0.35, 24.0, hi - 0.35), Vector3(-hi + 0.35, ROUAGES_Y + 3.4, -hi + 0.35), Vector3(hi - 0.35, ROUAGES_Y + 3.4, hi - 0.35)]
	for q in lp:
		var lc: Vector3 = _p(q.x, q.y, q.z)
		var d := Vector3(signf(q.x), 0, 0) if absf(q.x) > absf(q.z) else Vector3(0, 0, signf(q.z))
		_lanterne(k, lc - d * 0.1)
		_poutre(k, "fer", lc + Vector3(0, 0.74, 0) - d * 0.1, lc + Vector3(0, 0.74, 0) + d * 0.35, 0.04)
		_bougie(k, lc - d * 0.1 - Vector3(0, 0.35, 0), 0.18)
	_lumiere(_p(0.0, 4.0, 0.0), 11.0, 0.7, 1.5)
	_lumiere(_p(0.0, 14.0, 0.0), 10.0, 0.5, 1.2)
	_lumiere(_p(0.0, 23.0, 0.0), 10.0, 0.5, 1.2)
	_lumiere(_p(0.0, ROUAGES_Y + 4.5, 0.0), 12.0, 0.7, 1.5)
	_lumiere(_p(0.0, ROUAGES_Y + 3.0, -3.0), 7.0, 0.3, 0.9)
	_lumiere(_p(1.6, 41.4, 1.6), 6.0, 0.7, 1.1)
	var mi: MeshInstance3D = k.commit("Ombrelac_horloge_meubles")
	mi.visibility_range_end = 140.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_horloge_meubles_col"))
	_sonde(Vector3(0.0, ROUAGES_Y * 0.5, 0.0), Vector3(hi * 2.0 + 0.6, ROUAGES_Y + 0.4, hi * 2.0 + 0.6))
	(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	_sonde(Vector3(0.0, ROUAGES_Y + 0.2 + 10.0, 0.0), Vector3(hi * 2.0 + 0.6, 20.0, hi * 2.0 + 0.6))
	(sondes[sondes.size() - 1] as ReflectionProbe).blend_distance = 0.1
	# --- ce qui bouge : le balancier, l'ancre, les roues, les arbres, les aiguilles, la cloche
	_balancier()
	_rouages()
	_cadrans(hs, T, cy, rc)
	_cloche(h)
	# les lieux
	lieux["horloge_porte"] = _p(-hs - 2.0, 0.0, 0.0)
	lieux["horloge_salle"] = _p(1.6, 0.0, -1.6)
	lieux["horloge_escalier_bas"] = _p(-hi + LARGEUR * 0.5, 0.0, hi - LARGEUR * 0.5)
	lieux["horloge_palier_mi"] = _p(-hi + LARGEUR * 0.5, MONTEE * 4.0, hi - LARGEUR * 0.5)
	lieux["horloge_volee_mi"] = _p(0.0, MONTEE * 4.5, hi - LARGEUR * 0.5)
	lieux["horloge_vide_mi"] = _p(0.0, MONTEE * 4.5, 0.6)
	lieux["horloge_haut_escalier"] = _p(-hi + LARGEUR * 0.5, ROUAGES_Y, hi - LARGEUR * 0.5)
	lieux["horloge_rouages"] = _p(2.4, ROUAGES_Y, 2.6)
	lieux["horloge_bord_vide"] = _p(-hi + LARGEUR + 1.0, ROUAGES_Y, -1.0)
	lieux["horloge_dans_vide"] = _p(-hi + LARGEUR * 0.5, ROUAGES_Y, -1.0)
	lieux["horloge_cadran_dedans"] = _p(0.0, ROUAGES_Y, hi - 1.0)
	lieux["horloge_cadran_dehors"] = _p(0.0, ROUAGES_Y, hs + 2.0)
	lieux["horloge_centre"] = _p(0.0, 0.0, 0.0)


# =================================================================== la salle des poids

## Une rose des vents de laiton incrustée dans le dallage, sous le balancier
func _rose_des_vents(k: RefCounted, c: Vector3, r: float) -> void:
	var y: float = 0.035
	k.cyl("pierre_claire", _tr(c.x, 0.0, c.z), r + 0.25, r + 0.25, y - 0.005, 32)
	_anneau(k, _p(c.x, y, c.z), Vector3.UP, r, 0.05)
	_anneau(k, _p(c.x, y, c.z), Vector3.UP, r * 0.45, 0.03)
	for i in range(16):
		var a: float = TAU * i / 16.0
		var lg: float = r * (0.95 if i % 4 == 0 else (0.7 if i % 2 == 0 else 0.5))
		var d := Vector3(cos(a), 0, sin(a))
		var n := Vector3(-d.z, 0, d.x)
		var w: float = 0.16 if i % 4 == 0 else 0.1
		var cc: Vector3 = _p(c.x, y + 0.004, c.z)
		k.tri("or", Transform3D.IDENTITY, cc + n * w, cc + d * lg, cc - n * w, Vector3.UP)


## L'établi de l'horloger : le plateau, les tiroirs, l'étau, des roues en attente, la lampe
func _etabli(k: RefCounted, c: Vector3, yaw: float) -> void:
	var t: Transform3D = _tr(c.x, c.y, c.z, yaw)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 0.82, 0)), Vector3(2.4, 0.08, 0.8), true)
	for ex in [-1.1, 1.1]:
		k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(ex, 0, 0)), Vector3(0.1, 0.82, 0.7))
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0.55, 0.45, 0)), Vector3(1.0, 0.37, 0.7))
	for dx in [0.3, 0.8]:
		k.box("or", t * Transform3D(Basis.IDENTITY, Vector3(dx, 0.62, 0.36)), Vector3(0.1, 0.03, 0.02))
	k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(-0.9, 0.9, 0.25)), Vector3(0.22, 0.16, 0.16))
	k.box("fer", t * Transform3D(Basis.IDENTITY, Vector3(-0.9, 0.98, 0.25)), Vector3(0.06, 0.06, 0.4))
	for g in [[Vector3(-0.3, 0.9, -0.1), 0.22], [Vector3(0.15, 0.9, 0.1), 0.14], [Vector3(0.5, 0.9, -0.15), 0.3]]:
		var gc: Vector3 = t * (g[0] as Vector3)
		_anneau(k, gc + Vector3(0, 0.01, 0), Vector3.UP, float(g[1]), 0.03)
		k.cyl("or", Transform3D(Basis.IDENTITY, gc), 0.04, 0.04, 0.03, 8)
	_lampe(k, t * Vector3(0.95, 0.86, -0.2))
	# (v12) le tabouret ; les outils : le marteau, la lime, les brucelles, le tournevis ; la loupe ;
	# le râtelier d'outils contre le mur, ses outils pendus
	_tabouret(k, t * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.8)), 0.6)
	var o: Transform3D = t * Transform3D(Basis.IDENTITY, Vector3(0, 0.86, 0))
	_poutre(k, "chene", o * Vector3(0.2, 0.015, 0.3), o * Vector3(0.4, 0.015, 0.24), 0.022)
	k.box("fer", o * Transform3D(Basis(Vector3.UP, 0.3), Vector3(0.42, 0.0, 0.23)), Vector3(0.09, 0.03, 0.03))
	_poutre(k, "fer", o * Vector3(-0.1, 0.006, 0.3), o * Vector3(0.1, 0.006, 0.28), 0.01)
	_poutre(k, "chene", o * Vector3(-0.18, 0.01, 0.3), o * Vector3(-0.1, 0.01, 0.3), 0.02)
	_poutre(k, "or", o * Vector3(0.65, 0.004, 0.3), o * Vector3(0.78, 0.004, 0.26), 0.006)
	_poutre(k, "or", o * Vector3(0.65, 0.004, 0.3), o * Vector3(0.78, 0.004, 0.28), 0.006)
	var lo: Vector3 = o * Vector3(-0.45, 0.02, -0.15)
	_anneau(k, lo + Vector3(0, 0.12, 0), t.basis.z, 0.05, 0.01)
	_poutre(k, "or", lo, lo + Vector3(0, 0.07, 0), 0.01)
	k.cyl("or", Transform3D(Basis.IDENTITY, lo - Vector3(0, 0.02, 0)), 0.04, 0.035, 0.02, 10)
	k.box("chene", t * Transform3D(Basis.IDENTITY, Vector3(0, 1.1, -0.38)), Vector3(1.8, 0.5, 0.03))
	for ti in range(7):
		var tx: float = -0.75 + ti * 0.25
		var tp: Vector3 = t * Vector3(tx, 1.52, -0.35)
		k.box("fer", Transform3D(t.basis, tp), Vector3(0.012, 0.012, 0.03))
		var lgo: float = 0.18 + 0.05 * float(ti % 3)
		_poutre(k, "fer" if ti % 2 == 0 else "or", tp - t.basis.y * 0.01, tp - t.basis.y * lgo, 0.012)
		_poutre(k, "chene", tp - t.basis.y * lgo, tp - t.basis.y * (lgo + 0.09), 0.022)


## Les poids de fonte au bout de leurs chaînes, qui pendent du plancher des rouages
func _poids(k: RefCounted) -> void:
	for w in [[Vector3(-0.75, 9.5, -0.25), 0.36, 1.3], [Vector3(1.9, 16.0, -2.0), 0.3, 1.1], [Vector3(-2.0, 5.2, -2.1), 0.3, 1.1]]:
		var c: Vector3 = w[0]
		var r: float = w[1]
		var hh: float = w[2]
		k.cyl("fer", _tr(c.x, c.y, c.z), r, r, hh, 14)
		k.cyl("fer", _tr(c.x, c.y + hh, c.z), r, r * 0.4, 0.2, 14)
		k.cyl("or", _tr(c.x, c.y + hh * 0.3, c.z), r + 0.02, r + 0.02, 0.06, 14)
		k.cyl("or", _tr(c.x, c.y + hh * 0.75, c.z), r + 0.02, r + 0.02, 0.06, 14)
		# la chaîne : des maillons croisés jusqu'à la poulie, sous le plancher
		var y: float = c.y + hh + 0.2
		var i: int = 0
		while y < ROUAGES_Y - 0.6:
			var lgm: float = 0.16
			var b: Basis = Basis(Vector3.UP, PI * 0.5 * (i % 2))
			k.box("fer", Transform3D(b, _p(c.x, y, c.z)), Vector3(0.07, lgm, 0.02))
			y += lgm - 0.02
			i += 1
		_anneau(k, _p(c.x + 0.18, ROUAGES_Y - 0.55, c.z), Vector3(0, 0, 1), 0.18, 0.05)
		k.box("fer", _tr(c.x + 0.18, ROUAGES_Y - 0.55, c.z), Vector3(0.06, 0.55, 0.06))


# =================================================================== l'escalier

## La volée i (0 en bas) : son départ (au coin), sa direction, le côté du vide
func volee(i: int, hi: float) -> Array:
	var a: float = hi - LARGEUR
	var m: float = hi - LARGEUR * 0.5
	match i % 4:
		0:
			return [Vector3(-a, 0, m), Vector3(1, 0, 0), Vector3(0, 0, -1)]
		1:
			return [Vector3(m, 0, a), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
		2:
			return [Vector3(a, 0, -m), Vector3(-1, 0, 0), Vector3(0, 0, 1)]
		_:
			return [Vector3(-m, 0, -a), Vector3(0, 0, 1), Vector3(1, 0, 0)]


## Huit volées de marches de pierre prises dans les murs, des paliers aux coins, la rampe de chêne
## et ses barreaux de fer du côté du vide (on ne tombe pas) ; dessous, des rampes de collision
func _escalier(k: RefCounted, hi: float) -> void:
	var run: float = 2.0 * (hi - LARGEUR)
	var r: float = MONTEE / MARCHES_VOLEE
	var t: float = run / MARCHES_VOLEE
	for i in range(VOLEES):
		var v: Array = volee(i, hi)
		var S: Vector3 = v[0]
		var D: Vector3 = v[1]
		var V: Vector3 = v[2]
		var y0: float = i * MONTEE
		var yaw: float = atan2(D.x, D.z)
		for j in range(MARCHES_VOLEE):
			var c: Vector3 = S + D * (j + 0.5) * t
			var top: float = y0 + (j + 1) * r
			k.box("pierre_claire", Transform3D(Basis(Vector3.UP, yaw), _p(c.x, top - 0.32, c.z)), Vector3(LARGEUR, 0.32, t + 0.04))
			k.box("pierre_claire", Transform3D(Basis(Vector3.UP, yaw), _p(c.x, top - 0.02, c.z) + _xfb(D) * (t * 0.5 + 0.02)), Vector3(LARGEUR, 0.05, 0.06))
		# le limon du côté du vide
		var e: Vector3 = S + D * run
		var lim0: Vector3 = _p(S.x, y0 - 0.25, S.z) + _xfb(V) * (LARGEUR * 0.5 - 0.06)
		var lim1: Vector3 = _p(e.x, y0 + MONTEE - 0.25, e.z) + _xfb(V) * (LARGEUR * 0.5 - 0.06)
		_poutre(k, "chene", lim0, lim1, 0.14, _xfb(V))
		# la rampe : poteaux, main courante, barreaux
		var bord: Vector3 = _xfb(V) * (LARGEUR * 0.5 - 0.08)
		var a0: Vector3 = _p(S.x, y0, S.z) + bord
		var a1: Vector3 = _p(e.x, y0 + MONTEE, e.z) + bord
		_poutre(k, "chene", a0 + Vector3(0, 0.98, 0), a1 + Vector3(0, 0.98, 0), 0.08, _xfb(V))
		_poutre(k, "chene", a0, a0 + Vector3(0, 1.05, 0), 0.1)
		k.cyl("or", Transform3D(Basis.IDENTITY, a0 + Vector3(0, 1.05, 0)), 0.06, 0.0, 0.14, 6)
		for b in range(1, 20):
			var q: Vector3 = a0.lerp(a1, b / 20.0)
			_poutre(k, "fer", q, q + Vector3(0, 0.96, 0), 0.025)
		# les rampes de collision : la marche, la rambarde
		var x: Vector3 = (_xfb(D) * run + Vector3(0, MONTEE, 0)).normalized()
		var lat: Vector3 = _xfb(D).cross(Vector3.UP)
		var y: Vector3 = lat.cross(x)
		var z: Vector3 = x.cross(y)
		var lg: float = Vector2(run, MONTEE).length()
		var mid: Vector3 = (_p(S.x, y0, S.z) + _p(e.x, y0 + MONTEE, e.z)) * 0.5
		var rs := BoxShape3D.new()
		rs.size = Vector3(lg + 0.3, 0.3, LARGEUR)
		k.shapes.append([rs, Transform3D(Basis(x, y, z), mid - y * 0.15)])
		# (la rambarde : des boîtes droites, en escalier, pour ne pas déborder sur les paliers)
		for sg in range(8):
			var u0: float = sg / 8.0
			var u1: float = (sg + 1) / 8.0
			var ya: float = y0 + MONTEE * u0 - 0.3
			var yb: float = y0 + MONTEE * u1 + 1.1
			var cs: Vector3 = S + D * run * (u0 + u1) * 0.5
			var gs := BoxShape3D.new()
			gs.size = Vector3(0.1, yb - ya, run / 8.0)
			k.shapes.append([gs, Transform3D(Basis(Vector3.UP, yaw), _p(cs.x, (ya + yb) * 0.5, cs.z) + bord + _xfb(V) * 0.04)])
		# le palier d'arrivée, dans le coin (le dernier est le plancher des rouages)
		if i < VOLEES - 1:
			var pc: Vector3 = e + D * LARGEUR * 0.5
			k.box("pierre_claire", _tr(pc.x, y0 + MONTEE - 0.32, pc.z), Vector3(LARGEUR, 0.32, LARGEUR), true)
			k.cyl("pierre_claire", Transform3D(Basis(Vector3.RIGHT, PI), _p(pc.x, y0 + MONTEE - 0.32, pc.z)), LARGEUR * 0.45, 0.1, 0.9, 8)


## Une direction du repère de la tour vers le repère du château
func _xfb(d: Vector3) -> Vector3:
	return xf.basis * d


# =================================================================== la chambre des rouages

## Le plancher des rouages : des planches sur des solives, ouvert au-dessus de la dernière volée,
## une rambarde le long de la trémie
func _plancher_rouages(k: RefCounted, hi: float) -> void:
	var y: float = ROUAGES_Y
	var xa: float = -hi + LARGEUR
	var zb: float = hi - LARGEUR
	k.quad("parquet", xf, Vector3(xa, y, -hi), Vector3(hi, y, -hi), Vector3(hi, y, hi), Vector3(xa, y, hi), Vector3.UP)
	k.quad("parquet", xf, Vector3(-hi, y, zb), Vector3(xa, y, zb), Vector3(xa, y, hi), Vector3(-hi, y, hi), Vector3.UP)
	k.quad("chene", xf, Vector3(xa, y - 0.3, -hi), Vector3(hi, y - 0.3, -hi), Vector3(hi, y - 0.3, hi), Vector3(xa, y - 0.3, hi), Vector3.DOWN)
	k.quad("chene", xf, Vector3(xa, y - 0.3, -hi), Vector3(xa, y - 0.3, zb), Vector3(xa, y, zb), Vector3(xa, y, -hi), Vector3.LEFT)
	for zs in [-3.6, -1.8, 0.0, 1.8, 3.6]:
		_pl(k, "chene", Vector3(xa, y - 0.62, zs), Vector3(hi, y - 0.62, zs), 0.32, Vector3.UP)
	var c1 := BoxShape3D.new()
	c1.size = Vector3(hi - xa, 0.3, hi * 2.0)
	k.shapes.append([c1, _tr((xa + hi) * 0.5, y - 0.15, 0.0)])
	var c2 := BoxShape3D.new()
	c2.size = Vector3(LARGEUR, 0.3, LARGEUR)
	k.shapes.append([c2, _tr(-hi + LARGEUR * 0.5, y - 0.15, hi - LARGEUR * 0.5)])
	# la rambarde de la trémie
	var r0: Vector3 = _p(xa + 0.06, y, -hi)
	var r1: Vector3 = _p(xa + 0.06, y, zb)
	_poutre(k, "chene", r0 + Vector3(0, 1.0, 0), r1 + Vector3(0, 1.0, 0), 0.08, Vector3.UP)
	for b in range(0, 15):
		var q: Vector3 = r0.lerp(r1, b / 14.0)
		_poutre(k, "fer" if b % 4 != 0 else "chene", q, q + Vector3(0, 1.0, 0), 0.025 if b % 4 != 0 else 0.1)
	var gs := BoxShape3D.new()
	gs.size = Vector3(0.12, 1.3, zb + hi)
	k.shapes.append([gs, _tr(xa + 0.06, y + 0.65, (zb - hi) * 0.5)])
	# la plaque de laiton où passe la tige du balancier
	k.box("or", _tr(PIVOT.x, y, PIVOT.z), Vector3(1.0, 0.03, 0.3))


## Le bâti de fer de l'horloge, au milieu de la chambre : quatre montants, les traverses, les paliers
func _bati(k: RefCounted) -> void:
	var y: float = ROUAGES_Y
	var hx: float = 1.3
	var hz: float = 0.7
	var hh: float = 2.6
	k.box("pierre_claire", _tr(0.0, y, 0.0), Vector3(hx * 2.0 + 0.6, 0.18, hz * 2.0 + 0.6), true)
	for ex in [-hx, hx]:
		for ez in [-hz, hz]:
			k.box("fer", _tr(ex, y + 0.18, ez), Vector3(0.12, hh, 0.12))
			k.cyl("or", _tr(ex, y + 0.18 + hh, ez), 0.08, 0.0, 0.18, 6)
	for yy in [0.35, hh]:
		for ez2 in [-hz, hz]:
			_pl(k, "fer", Vector3(-hx, y + 0.18 + yy, ez2), Vector3(hx, y + 0.18 + yy, ez2), 0.1)
		for ex2 in [-hx, hx]:
			_pl(k, "fer", Vector3(ex2, y + 0.18 + yy, -hz), Vector3(ex2, y + 0.18 + yy, hz), 0.1)
	# les fleurons des montants, une plaque gravée
	k.box("or", _tr(0.0, y + 0.55, hz + 0.07), Vector3(1.1, 0.24, 0.02))
	var col := BoxShape3D.new()
	col.size = Vector3(hx * 2.0 + 0.2, hh, hz * 2.0 + 0.2)
	k.shapes.append([col, _tr(0.0, y + 0.18 + hh * 0.5, 0.0)])


## Le plafond de la chambre : un gril de poutres (on voit la cloche au-dessus), le dedans du toit en
## planches
func _plafond_cloche(k: RefCounted, hi: float, h: float) -> void:
	for e in [-3.2, -1.2, 1.2, 3.2]:
		_pl(k, "chene", Vector3(-hi, h - 0.4, e), Vector3(hi, h - 0.4, e), 0.36, Vector3.UP)
	for e2 in [-3.2, 3.2]:
		_pl(k, "chene", Vector3(e2, h - 0.9, -hi), Vector3(e2, h - 0.9, hi), 0.3, Vector3.UP)
	# le dedans du toit : une pyramide de planches
	var apex: Vector3 = Vector3(0, h + 8.0, 0)
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var o := Vector3(sin(yaw), 0, cos(yaw))
		var r := Vector3(cos(yaw), 0, -sin(yaw))
		var a: Vector3 = o * hi - r * hi + Vector3(0, h, 0)
		var b: Vector3 = o * hi + r * hi + Vector3(0, h, 0)
		k.tri("chene", xf, a, b, apex, -o * 8.0 + Vector3(0, -hi, 0))
		# les arêtiers
		_pl(k, "chene", o * hi + r * hi + Vector3(0, h, 0) - (o + r) * 0.1, apex - Vector3(0, 0.1, 0), 0.22, Vector3.UP)
	# la poutre qui porte la cloche
	_pl(k, "chene", Vector3(-1.95, h + 4.6, 0.0), Vector3(1.95, h + 4.6, 0.0), 0.34, Vector3.UP)
	for e3 in [-1.9, 1.9]:
		_pl(k, "chene", Vector3(e3, h - 0.04, -1.35), Vector3(e3, h - 0.04, 1.35), 0.3, Vector3.UP)
		_pl(k, "chene", Vector3(e3, h - 0.22, 0.0), Vector3(e3 * 0.95, h + 4.45, 0.0), 0.26, Vector3.RIGHT)


# =================================================================== ce qui bouge

func _balancier() -> void:
	var lg: float = ROUAGES_Y + PIVOT.y - BOB_Y - 0.6
	periode = TAU * sqrt(lg / 9.81)
	balancier = Node3D.new()
	balancier.name = "Balancier"
	balancier.position = _p(PIVOT.x, ROUAGES_Y + PIVOT.y, PIVOT.z)
	add_child(balancier)
	var k := Kit.new()
	k.box("fer", Transform3D(Basis.IDENTITY, Vector3(0, -lg, 0)), Vector3(0.05, lg, 0.05))
	k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, -0.2, 0)), Vector3(0.22, 0.2, 0.08))
	# la lentille : un disque de laiton, un soleil en relief
	var bob := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -lg - 0.6, -0.07))
	k.cyl("or", bob, 0.6, 0.6, 0.14, 28)
	k.cyl("cuivre_neuf", bob * Transform3D(Basis.IDENTITY, Vector3(0, 0.14, 0)), 0.32, 0.28, 0.03, 20)
	for i in range(12):
		var a: float = TAU * i / 12.0
		k.box("cuivre_neuf", Transform3D(Basis(Vector3(0, 0, 1), -a), Vector3(sin(a) * 0.42, -lg - 0.6 + cos(a) * 0.42 - 0.07, 0.08)), Vector3(0.05, 0.14, 0.02))
	balancier.add_child(k.commit("Balancier_maillage"))
	# l'ancre : elle bascule avec le balancier, au-dessus de la roue d'échappement
	ancre = Node3D.new()
	ancre.name = "Ancre"
	ancre.position = _p(PIVOT.x, ROUAGES_Y + PIVOT.y, PIVOT.z + 0.12)
	add_child(ancre)
	var ka := Kit.new()
	for e in [-1.0, 1.0]:
		_poutre(ka, "fer", Vector3.ZERO, Vector3(e * 0.36, -0.38, 0), 0.05)
		_poutre(ka, "fer", Vector3(e * 0.36, -0.38, 0), Vector3(e * 0.28, -0.52, 0), 0.05)
	ka.cyl("or", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.04)), 0.06, 0.06, 0.1, 8)
	ancre.add_child(ka.commit("Ancre_maillage"))


## Une roue dentée de laiton (dans le plan x, y ; l'axe selon z), son pignon et son arbre
func _roue(r: float, dents: int, m: String = "or") -> Kit:
	var k := Kit.new()
	var ax := Vector3(0, 0, 1)
	var ep: float = maxf(0.035, r * 0.09)
	for i in range(dents):
		var a0: float = TAU * i / dents
		var a1: float = TAU * (i + 1) / dents
		_poutre(k, m, Vector3(cos(a0), sin(a0), 0) * r * 0.88, Vector3(cos(a1), sin(a1), 0) * r * 0.88, ep, ax)
		var d := Vector3(cos(a0 + PI / dents), sin(a0 + PI / dents), 0)
		_poutre(k, m, d * r * 0.86, d * r, minf(TAU * r / dents * 0.5, ep * 1.4), ax)
	var nr: int = 5 if r > 0.3 else 4
	for i2 in range(nr):
		var a2: float = TAU * i2 / nr + 0.3
		_poutre(k, m, Vector3(cos(a2), sin(a2), 0) * 0.06, Vector3(cos(a2), sin(a2), 0) * r * 0.86, ep * 0.7, ax)
	k.cyl(m, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.06)), 0.08, 0.08, 0.12, 10)
	k.cyl("fer", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.75)), 0.03, 0.03, 1.5, 6)
	return k


func _rouages() -> void:
	var base: Vector3 = Vector3(0, ROUAGES_Y + 0.18, 0)
	# [centre (repère tour, au-dessus du bâti), rayon, dents, vitesse (rad/s)]
	var defs: Array = [
		[Vector3(-0.72, 1.05, -0.25), 0.72, 48, 0.05],
		[Vector3(0.48, 1.12, -0.25), 0.5, 32, -0.072],
		[Vector3(0.48, 1.12, 0.15), 0.3, 20, -0.072],
		[Vector3(0.48, 1.64, 0.15), 0.22, 14, 0.098],
		[Vector3(-0.72, 1.05, 0.2), 0.3, 18, 0.05],
		[Vector3(-0.45, 1.85, 0.2), 0.26, 16, -0.058],
	]
	for dd in defs:
		var n := Node3D.new()
		n.name = "Roue"
		n.position = _p(base.x + (dd[0] as Vector3).x, base.y + (dd[0] as Vector3).y, base.z + (dd[0] as Vector3).z)
		add_child(n)
		n.add_child(_roue(float(dd[1]), int(dd[2])).commit("Roue_maillage"))
		roues.append([n, float(dd[3])])
	# la roue d'échappement : elle avance d'une dent à chaque battement du balancier
	echappement = Node3D.new()
	echappement.name = "Echappement"
	echappement.position = _p(PIVOT.x, ROUAGES_Y + PIVOT.y - 0.62, PIVOT.z + 0.12)
	add_child(echappement)
	var ke := Kit.new()
	for i in range(30):
		var a0: float = TAU * i / 30.0
		var a1: float = TAU * (i + 1) / 30.0
		_poutre(ke, "or", Vector3(cos(a0), sin(a0), 0) * 0.26, Vector3(cos(a1), sin(a1), 0) * 0.26, 0.03, Vector3(0, 0, 1))
		_poutre(ke, "or", Vector3(cos(a0), sin(a0), 0) * 0.26, Vector3(cos(a0 + 0.12), sin(a0 + 0.12), 0) * 0.34, 0.025, Vector3(0, 0, 1))
	for i3 in range(4):
		var a3: float = TAU * i3 / 4.0
		_poutre(ke, "or", Vector3.ZERO, Vector3(cos(a3), sin(a3), 0) * 0.25, 0.025, Vector3(0, 0, 1))
	echappement.add_child(ke.commit("Echappement_maillage"))
	# les arbres de la minuterie : un arbre debout jusqu'au renvoi, quatre arbres vers les cadrans
	var kr := Kit.new()
	var renvoi: Vector3 = _p(0.0, _cy, 0.0)
	kr.box("fer", Transform3D(Basis.IDENTITY, renvoi - Vector3(0, 0.3, 0)), Vector3(0.6, 0.6, 0.6))
	kr.box("or", Transform3D(Basis.IDENTITY, renvoi + Vector3(0, 0.3, 0)), Vector3(0.66, 0.05, 0.66))
	add_child(kr.commit("Renvoi_maillage"))
	_arbre(_p(0.0, ROUAGES_Y + 0.18 + 2.6, 0.0), renvoi - Vector3(0, 0.3, 0), 0.6)
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var o := Vector3(sin(yaw), 0, cos(yaw))
		_arbre(renvoi + o * 0.3, renvoi + o * 5.1, 0.6 if f % 2 == 0 else -0.6)


var _cy: float = 35.0               # la hauteur du centre des cadrans


## Un arbre de fer de section carrée de a à b, qui tourne sur son axe (a est son pivot)
func _arbre(a: Vector3, b: Vector3, vitesse: float) -> void:
	var n := Node3D.new()
	n.name = "Arbre"
	var y: Vector3 = (b - a).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	n.transform = Transform3D(Basis(x, y, x.cross(y)), a)
	add_child(n)
	var k := Kit.new()
	var lg: float = a.distance_to(b)
	k.box("fer", Transform3D.IDENTITY, Vector3(0.07, lg, 0.07))
	for t in [0.15, 0.5, 0.85]:
		k.box("or", Transform3D(Basis.IDENTITY, Vector3(0, lg * t - 0.04, 0)), Vector3(0.12, 0.08, 0.12))
	n.add_child(k.commit("Arbre_maillage"))
	arbres.append([n, vitesse])


## Les quatre cadrans : la couronne de pierre, le cercle d'or, le verre opalin, les heures ; les
## aiguilles (dehors) et leur ombre (dedans) suivent l'heure du jeu
func _cadrans(hs: float, T: float, cy: float, rc: float) -> void:
	_cy = cy
	var k := Kit.new()
	for f in range(4):
		var yaw: float = f * PI * 0.5
		var bs := Basis(Vector3.UP, yaw)
		var c: Vector3 = _p(0, cy, 0) + bs * Vector3(0, 0, hs)
		var fx := Transform3D(bs, c)
		var seg: int = 40
		for i in range(seg):
			var a0: float = TAU * i / seg
			var a1: float = TAU * (i + 1) / seg
			var d0 := Vector3(cos(a0), sin(a0), 0)
			var d1 := Vector3(cos(a1), sin(a1), 0)
			var ro: float = rc + 0.6
			k.quad("pierre_claire", fx, d0 * rc + Vector3(0, 0, 0.35), d1 * rc + Vector3(0, 0, 0.35), d1 * ro + Vector3(0, 0, 0.35), d0 * ro + Vector3(0, 0, 0.35), Vector3(0, 0, 1))
			k.quad("pierre_claire", fx, d0 * ro, d1 * ro, d1 * ro + Vector3(0, 0, 0.35), d0 * ro + Vector3(0, 0, 0.35), (d0 + d1) * 0.5)
			k.quad("pierre_claire", fx, d0 * rc, d1 * rc, d1 * rc + Vector3(0, 0, 0.35), d0 * rc + Vector3(0, 0, 0.35), -(d0 + d1) * 0.5)
		_anneau(k, fx * Vector3(0, 0, 0.37), bs * Vector3(0, 0, 1), rc - 0.02, 0.1)
		_anneau(k, fx * Vector3(0, 0, -0.1), bs * Vector3(0, 0, 1), rc - 0.5, 0.04)
		# le verre
		k.cyl("cadran", fx * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.24)), rc, rc, 0.04, 40)
		# les heures (des barres de fer sur le verre ; midi double)
		for hr in range(12):
			var a: float = TAU * hr / 12.0
			var sz := Vector3(0.22, 0.75, 0.04) if hr % 3 != 0 else Vector3(0.3, 0.9, 0.04)
			var rd: float = rc - 0.25 - sz.y
			k.box("fer", fx * Transform3D(Basis(Vector3(0, 0, 1), -a), Vector3(sin(a) * rd, cos(a) * rd, -0.15)), sz)
		# les aiguilles
		for heure in [true, false]:
			var n := Node3D.new()
			n.name = "Aiguille_heures" if heure else "Aiguille_minutes"
			n.transform = fx
			add_child(n)
			var ka := Kit.new()
			var lg: float = rc * (0.55 if heure else 0.82)
			var w: float = 0.3 if heure else 0.18
			var zo: float = -0.1 if heure else -0.05
			ka.box("fer", Transform3D(Basis.IDENTITY, Vector3(0, -0.5, zo)), Vector3(w, lg + 0.5, 0.04))
			ka.box("fer", Transform3D(Basis(Vector3(0, 0, 1), PI * 0.25), Vector3(0, lg - w * 0.3, zo)), Vector3(w * 1.2, w * 1.2, 0.04))
			# l'ombre du dedans
			ka.box("fer", Transform3D(Basis.IDENTITY, Vector3(0, -0.5, -0.32)), Vector3(w * 0.9, lg + 0.5, 0.02))
			if heure:
				ka.cyl("or", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.02)), 0.22, 0.22, 0.06, 12)
				ka.cyl("or", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.9)), 0.16, 0.16, 0.55, 10)
			n.add_child(ka.commit("Aiguille_maillage"))
			aiguilles.append([n, fx.basis, heure])
	var mi: MeshInstance3D = k.commit("Ombrelac_horloge_cadrans")
	add_child(mi)


## La cloche de bronze, pendue à sa poutre sous le toit (elle se balance quand elle sonne)
func _cloche(h: float) -> void:
	cloche = Node3D.new()
	cloche.name = "Cloche"
	cloche.position = _p(0.0, h + 4.4, 0.0)
	add_child(cloche)
	var k := Kit.new()
	# le profil, de la bouche au cerveau (hauteur, rayon)
	var prof: Array = [[-2.0, 1.05], [-1.88, 1.0], [-1.6, 0.78], [-1.1, 0.64], [-0.6, 0.6], [-0.35, 0.56], [-0.2, 0.46], [-0.12, 0.0]]
	for i in range(prof.size() - 1):
		var y0: float = prof[i][0]
		var y1: float = prof[i + 1][0]
		k.cyl("bronze", Transform3D(Basis.IDENTITY, Vector3(0, y0, 0)), float(prof[i][1]), float(prof[i + 1][1]), y1 - y0, 24, false)
	# le dedans (on la voit d'en bas), les cordons, la couronne, le joug, le battant
	k.cyl("suie", Transform3D(Basis.IDENTITY, Vector3(0, -1.98, 0)), 0.9, 0.3, 1.5, 24, true)
	for yb in [-1.86, -1.62, -0.5]:
		var rb: float = 1.0 if yb < -1.8 else (0.8 if yb < -1.5 else 0.6)
		k.cyl("or", Transform3D(Basis.IDENTITY, Vector3(0, yb, 0)), rb + 0.02, rb + 0.02, 0.05, 24)
	_anneau(k, Vector3(0, 0.08, 0), Vector3(1, 0, 0), 0.18, 0.06)
	k.box("chene", Transform3D(Basis.IDENTITY, Vector3(0, 0.0, 0)), Vector3(1.6, 0.26, 0.3))
	k.box("fer", Transform3D(Basis.IDENTITY, Vector3(0, -1.5, 0)), Vector3(0.06, 1.3, 0.06))
	_sphere(k, "fer", Vector3(0, -1.6, 0), 0.14)
	cloche.add_child(k.commit("Cloche_maillage"))
	son = AudioStreamPlayer3D.new()
	son.name = "Son_cloche"
	son.position = Vector3(0, -1.0, 0)
	son.unit_size = 30.0
	son.max_distance = 420.0
	son.volume_db = -4.0
	if AudioServer.get_bus_index("Ambiance") >= 0:
		son.bus = "Ambiance"
	cloche.add_child(son)


## Le son de la cloche : la fondamentale, l'octave basse (le bourdon), la tierce mineure, la
## quinte, l'octave et ses harmoniques qui s'éteignent plus vite (fabriqué une fois)
static func son_cloche() -> AudioStreamWAV:
	if _son_cloche != null:
		return _son_cloche
	var rate: int = 22050
	var duree: float = 5.0
	var n: int = int(rate * duree)
	var f0: float = 196.0
	var parts: Array = [[0.5, 0.55, 0.35], [1.0, 1.0, 0.7], [1.19, 0.45, 1.0], [1.5, 0.3, 1.3], [2.0, 0.5, 1.6], [2.52, 0.22, 2.4], [3.01, 0.18, 3.2], [4.07, 0.1, 4.5]]
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / rate
		var v: float = 0.0
		for pp in parts:
			v += float(pp[1]) * sin(TAU * f0 * float(pp[0]) * t + float(pp[0])) * exp(-t * float(pp[2]))
		v *= minf(t * 300.0, 1.0) * 0.28
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	_son_cloche = w
	return w


## L'heure du jeu (0..24) ; midi si on ne la connaît pas
func heure() -> float:
	if heure_forcee >= 0.0:
		return heure_forcee
	if main != null and main.get("temps_v56") != null and main.temps_v56 != null:
		return float(main.temps_v56.hour)
	return 12.0


## Fait sonner n coups (un toutes les COUP_INTERVALLE secondes)
func sonner(n: int) -> void:
	coups_a_sonner = n
	_t_coup = COUP_INTERVALLE


func _coup() -> void:
	coups_sonnes += 1
	_branle = 0.22
	if son != null and is_inside_tree():
		son.stream = son_cloche()
		son.play()


func set_nuit(n: float) -> void:
	super.set_nuit(n)
	var m: StandardMaterial3D = Kit.mat("cadran")
	m.emission_energy_multiplier = lerpf(0.25, 1.8, n)


func _process(delta: float) -> void:
	super._process(delta)
	# les aiguilles : l'heure du jeu
	var hr: float = heure()
	angle_heure = TAU * fmod(hr, 12.0) / 12.0
	angle_minute = TAU * (hr - floor(hr))
	for a in aiguilles:
		var ang: float = angle_heure if bool(a[2]) else angle_minute
		(a[0] as Node3D).basis = (a[1] as Basis) * Basis(Vector3(0, 0, 1), -ang)
	# la cloche sonne à chaque heure pleine
	var hi: int = int(floor(hr))
	if derniere_heure >= 0 and hi != derniere_heure:
		var n: int = hi % 12
		sonner(12 if n == 0 else n)
	derniere_heure = hi
	if coups_a_sonner > 0:
		_t_coup += delta
		if _t_coup >= COUP_INTERVALLE:
			_t_coup = 0.0
			coups_a_sonner -= 1
			_coup()
	_branle = maxf(_branle - delta * 0.05, 0.0)
	if cloche != null:
		cloche.rotation.x = _branle * sin(Time.get_ticks_msec() * 0.001 * 2.2)
	# le balancier, l'ancre, l'échappement (une dent par battement), les roues, les arbres
	if balancier == null:
		return
	_t_balancier += delta
	var ph: float = TAU * _t_balancier / periode
	balancier.rotation.z = 0.05 * sin(ph)
	ancre.rotation.z = 0.05 * sin(ph)
	var tic: int = int(floor(_t_balancier / (periode * 0.5)))
	if tic != _tic:
		_tic = tic
		echappement.rotation.z -= TAU / 30.0
	for r in roues:
		(r[0] as Node3D).rotate_object_local(Vector3(0, 0, 1), float(r[1]) * delta)
	for b in arbres:
		(b[0] as Node3D).rotate_object_local(Vector3(0, 1, 0), float(b[1]) * delta)

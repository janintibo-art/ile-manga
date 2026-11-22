extends "res://scripts/ext_chateau/bibliotheque_ombrelac.gd"
## Extension « Le Château d'Ombrelac » : les salles d'étude, au rez-de-chaussée de l'Aile nord
## (chacune sa porte sous la galerie du cloître) :
##  - la Salle des Astres : le grand planétaire de laiton suspendu (le soleil, les planètes sur leurs
##    bras), le tableau couvert d'orbites, les pupitres, les cartes du ciel, la lunette ;
##  - la Salle des Élixirs : l'athanor (le fourneau des alchimistes) et son feu, les paillasses
##    chargées d'alambics, de fioles et de ballons qui luisent, les bocaux, les herbes qui sèchent,
##    la cuve de cuivre et son serpentin ;
##  - l'Amphithéâtre : les gradins, la chaire, le grand tableau de géométrie, le lustre.
## Repère : xf (celui de l'aile) : x le long de l'aile, z en travers (z > 0 : le cloître), y = le
## plateau ; le plafond à rz.

var sondes: Array = []
var _rng := RandomNumberGenerator.new()


## Un plafond de planches et ses solives, de x0 à x1 (repère de l'aile)
func _plafond(k: RefCounted, x0: float, x1: float, hw: float, rz: float) -> void:
	k.quad("chene", xf, Vector3(x0, rz - 0.02, -hw), Vector3(x1, rz - 0.02, -hw), Vector3(x1, rz - 0.02, hw), Vector3(x0, rz - 0.02, hw), Vector3.DOWN)
	var n: int = int((x1 - x0) / 1.4)
	for i in range(n):
		var x: float = x0 + (i + 0.5) * (x1 - x0) / n
		_pl(k, "chene", Vector3(x, rz - 0.34, -hw), Vector3(x, rz - 0.34, hw), 0.3, Vector3.UP)
	for z in [-hw * 0.5, hw * 0.5]:
		_pl(k, "chene", Vector3(x0, rz - 0.62, z), Vector3(x1, rz - 0.62, z), 0.34, Vector3.UP)


## Un cadre de bois autour d'un panneau (repère de l'aile) : a et b les coins bas, h la hauteur
func _cadre(k: RefCounted, a: Vector3, b: Vector3, h: float, n: Vector3) -> void:
	var up := Vector3(0, h, 0)
	var o: Vector3 = n * 0.03
	for seg in [[a, b], [a + up, b + up], [a, a + up], [b, b + up]]:
		_pl(k, "bois", seg[0] + o, seg[1] + o, 0.09, n)


## Un panneau (carte, tableau) : de a à b en bas (de gauche à droite vu de devant), h de haut
func _panneau(k: RefCounted, m: String, a: Vector3, b: Vector3, h: float, n: Vector3) -> void:
	var up := Vector3(0, h, 0)
	k.quad(m, xf, a, b, b + up, a + up, n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	_cadre(k, a, b, h, n)


func _sonde(c: Vector3, taille: Vector3) -> void:
	var s := ReflectionProbe.new()
	s.position = xf * c
	s.size = taille
	s.interior = true
	s.box_projection = true
	s.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	s.ambient_color = AMBIANT_JOUR
	s.update_mode = ReflectionProbe.UPDATE_ONCE
	s.max_distance = 40.0
	s.blend_distance = 0.4
	add_child(s)
	sondes.append(s)
	sonde = s


func set_nuit(n: float) -> void:
	super.set_nuit(n)
	for s in sondes:
		(s as ReflectionProbe).ambient_color = AMBIANT_JOUR.lerp(AMBIANT_NUIT, n)


# =================================================================== les trois salles

func construire_salles(the_xf: Transform3D, L: float, W: float, rz: float, T: float, refends: Array, portes: Array, bout: float = 0.0, bouts: Array = [true, true]) -> void:
	# bout : l'épaisseur de maçonnerie pleine aux deux extrémités (les tours d'angle mordent sur l'aile)
	xf = the_xf
	_rng.seed = 51177
	var k := Kit.new()
	var hw: float = W * 0.5 - T
	var hl: float = L * 0.5 - T - bout
	if bout > 0.0:
		for e in [-1.0, 1.0]:
			if not bool(bouts[0 if e < 0.0 else 1]):
				continue
			k.box("pierre_int", _tr(e * (L * 0.5 - T - bout * 0.5), -0.2, 0.0), Vector3(bout, rz + 0.2, hw * 2.0), true)
	var xa0: float = -hl
	var xa1: float = float(refends[0]) - 0.3
	var xb0: float = float(refends[0]) + 0.3
	var xb1: float = float(refends[1]) - 0.3
	var xc0: float = float(refends[1]) + 0.3
	var xc1: float = hl
	# les sols : le parquet (les Astres, l'Amphithéâtre), les dalles (les Élixirs)
	k.box("parquet", _tr((xa0 + xa1) * 0.5, -0.2, 0.0), Vector3(xa1 - xa0, 0.2, hw * 2.0 + 0.8), true)
	k.box("dalles_int", _tr((xb0 + xb1) * 0.5, -0.2, 0.0), Vector3(xb1 - xb0, 0.2, hw * 2.0 + 0.8), true)
	k.box("parquet", _tr((xc0 + xc1) * 0.5, -0.2, 0.0), Vector3(xc1 - xc0, 0.2, hw * 2.0 + 0.8), true)
	for r in [[xa0, xa1], [xb0, xb1], [xc0, xc1]]:
		_plafond(k, r[0], r[1], hw, rz)
	_astres(k, xa0, xa1, hw, rz, float(portes[0]))
	_elixirs(k, xb0, xb1, hw, rz)
	_amphi(k, xc0, xc1, hw, rz)
	var mi: MeshInstance3D = k.commit("Ombrelac_salles_meubles")
	mi.visibility_range_end = 120.0
	add_child(mi)
	if not k.shapes.is_empty():
		add_child(k.body("Ombrelac_salles_meubles_col"))
	for r2 in [[xa0, xa1], [xb0, xb1], [xc0, xc1]]:
		_sonde(Vector3((r2[0] + r2[1]) * 0.5, rz * 0.5 - 1.0, 0.0), Vector3(r2[1] - r2[0] + 1.2, rz + 2.0, hw * 2.0 + 1.2))
	lieux["salle_astres"] = _p(float(portes[0]), 0.0, hw - 1.1)
	lieux["salle_elixirs"] = _p(float(portes[1]), 0.0, hw - 1.1)
	lieux["amphitheatre"] = _p(float(portes[2]), 0.0, hw - 1.3)
	for i in range(3):
		lieux["salles_porte_%d" % i] = _p(float(portes[i]), 0.0, W * 0.5 + 1.6)


# =================================================================== la Salle des Astres

func _astres(k: RefCounted, x0: float, x1: float, hw: float, rz: float, porte: float) -> void:
	var xm: float = (x0 + x1) * 0.5
	# le tableau, sur le mur ouest, ses orbites à la craie ; la tablette à craie
	var xt: float = x0 + 0.05
	_panneau(k, "tableau", Vector3(xt, 1.0, 2.7), Vector3(xt, 1.0, -2.7), 2.3, Vector3(1, 0, 0))
	k.box("bois", _tr(xt + 0.08, 0.92, 0.0), Vector3(0.16, 0.06, 5.2))
	# la table du maître, sa chaise, ses instruments
	_table_l(k, x0 + 2.4, 0.0, 1.0, 2.2)
	_chaise(k, x0 + 1.5, 0.0, -PI * 0.5)
	k.cyl("or", _tr(x0 + 2.3, 0.77, -0.6), 0.12, 0.1, 0.03, 10)
	_anneau(k, _p(x0 + 2.3, 1.02, -0.6), Vector3.UP, 0.2, 0.015)
	_anneau(k, _p(x0 + 2.3, 1.02, -0.6), xf.basis * Vector3(1, 0, 0), 0.2, 0.015)
	_sphere(k, "lambris", _p(x0 + 2.3, 1.02, -0.6), 0.09)
	_lampe(k, _p(x0 + 2.4, 0.77, 0.7))
	# les pupitres des élèves : quatre rangs, deux colonnes, leurs bancs (face au tableau)
	for xr in [x0 + 4.8, x0 + 7.0, x0 + 9.2, x0 + 11.4]:
		for zc in [-2.3, 1.3]:
			var lg: float = 2.6
			k.box("bois", _tr(xr, 0.0, zc), Vector3(0.06, 0.72, lg))
			k.box("bois", _tr(xr - 0.3, 0.72, zc) * Transform3D(Basis(Vector3(0, 0, 1), 0.12), Vector3.ZERO), Vector3(0.62, 0.05, lg + 0.06), true)
			for e in [-1.0, 1.0]:
				k.box("bois", _tr(xr - 0.3, 0.0, zc + e * (lg * 0.5 - 0.03)), Vector3(0.58, 0.74, 0.05))
			k.box("bois", _tr(xr + 0.45, 0.0, zc), Vector3(0.34, 0.44, lg))
			# un encrier, un livre ouvert
			k.cyl("suie", _tr(xr - 0.5, 0.76, zc - 0.7), 0.035, 0.03, 0.06, 6)
			k.box("cire", _tr(xr - 0.3, 0.78, zc + 0.3, 0.1), Vector3(0.3, 0.02, 0.42))
	# le grand planétaire, pendu au plafond : le soleil, six planètes sur leurs bras
	var c: Vector3 = _p(xm + 1.0, 3.7, 0.0)
	_poutre(k, "fer", c + Vector3(0, 0.3, 0), _p(xm + 1.0, rz - 0.3, 0.0), 0.06)
	_sphere(k, "soleil", c, 0.34)
	_anneau(k, c, Vector3.UP, 0.46, 0.03)
	var planetes := [["lambris", 0.09, 0.85], ["cuivre_neuf", 0.12, 1.25], ["potion_bleu", 0.13, 1.7], ["potion_rouge", 0.1, 2.1],
		["or", 0.22, 2.6], ["pierre_claire", 0.18, 3.1]]
	for i in range(planetes.size()):
		var pl: Array = planetes[i]
		var a: float = 0.7 + i * 2.25
		var d := Vector3(cos(a), 0, sin(a))
		var y: float = 0.55 + i * 0.12
		var q: Vector3 = c + Vector3(0, y, 0) + d * float(pl[2])
		_poutre(k, "or", c + Vector3(0, y, 0), q, 0.025, Vector3.UP)
		_poutre(k, "or", q, q - Vector3(0, 0.5 + i * 0.08, 0), 0.02)
		var pc: Vector3 = q - Vector3(0, 0.5 + i * 0.08 + float(pl[1]), 0)
		_sphere(k, str(pl[0]), pc, float(pl[1]))
		if i == 5:
			_anneau(k, pc, Vector3(0.3, 1.0, 0.2).normalized(), float(pl[1]) * 1.8, 0.02)
		if i == 2:
			_sphere(k, "pierre_claire", pc + Vector3(0.28, 0.05, 0), 0.04)
	_lumiere(c, 9.0, 0.7, 1.3)
	_lumiere(_p(xm, 4.6, 0.0), 13.0, 0.6, 1.3)
	# les cartes du ciel, entre les baies (au nord et au sud)
	for xc in [x0 + 1.0, x0 + 6.6]:
		_panneau(k, "carte_ciel", Vector3(xc - 0.8, 1.4, -hw + 0.05), Vector3(xc + 0.8, 1.4, -hw + 0.05), 2.2, Vector3(0, 0, 1))
		if absf(xc - porte) > 2.5:
			_panneau(k, "carte_ciel", Vector3(xc + 0.8, 1.4, hw - 0.05), Vector3(xc - 0.8, 1.4, hw - 0.05), 2.2, Vector3(0, 0, -1))
	# la lunette sur son trépied, près d'une baie
	var tp: Vector3 = Vector3(x1 - 2.2, 1.45, hw - 1.4)
	for i in range(3):
		var a2: float = TAU * i / 3.0 + 0.3
		_pl(k, "chene", tp, tp + Vector3(cos(a2) * 0.55, -1.45, sin(a2) * 0.55), 0.05)
	var dir: Vector3 = Vector3(-0.3, 0.55, 0.78).normalized()
	_pl(k, "cuivre_neuf", tp - dir * 0.55, tp + dir * 1.05, 0.13, Vector3.UP)
	_pl(k, "or", tp + dir * 1.0, tp + dir * 1.12, 0.17, Vector3.UP)
	_pl(k, "or", tp - dir * 0.62, tp - dir * 0.5, 0.07, Vector3.UP)
	# les livres d'astronomie contre le refend
	_rayonnage(k, _tr(x1 - 0.3, 0.0, -1.2, -PI * 0.5), 5.4, 3.4, 0.5, false)


# =================================================================== la Salle des Élixirs

## Une fiole ronde (un ballon) : le liquide qui luit, le col de verre
func _ballon(k: RefCounted, p: Vector3, r: float, m: String) -> void:
	_sphere(k, m, _p(p.x, p.y + r, p.z), r)
	k.cyl("verre", _tr(p.x, p.y + r * 1.7, p.z), r * 0.28, r * 0.22, r * 1.4, 8)


## Un alambic : la cucurbite de cuivre, le chapiteau de verre, le bec, le récipient
func _alambic(k: RefCounted, p: Vector3, m: String) -> void:
	k.cyl("cuivre_neuf", _tr(p.x, p.y, p.z), 0.16, 0.2, 0.26, 12)
	_sphere(k, "verre", _p(p.x, p.y + 0.36, p.z), 0.13)
	_pl(k, "verre", Vector3(p.x, p.y + 0.42, p.z), Vector3(p.x + 0.42, p.y + 0.2, p.z + 0.1), 0.025)
	_ballon(k, Vector3(p.x + 0.46, p.y, p.z + 0.12), 0.08, m)


func _paillasse(k: RefCounted, x0: float, x1: float, z: float) -> void:
	var lg: float = x1 - x0
	k.box("bois", _tr((x0 + x1) * 0.5, 0.0, z), Vector3(lg, 0.85, 0.9), true)
	k.box("pierre_claire", _tr((x0 + x1) * 0.5, 0.85, z), Vector3(lg + 0.1, 0.07, 1.0))
	var pots := ["potion_vert", "potion_bleu", "potion_rouge", "potion_ambre", "potion_violet"]
	var x: float = x0 + 0.35
	while x < x1 - 0.35:
		var y: float = 0.92
		var zz: float = z + _rng.randf_range(-0.25, 0.25)
		var m: String = pots[_rng.randi() % pots.size()]
		match _rng.randi() % 7:
			0, 1:
				_ballon(k, Vector3(x, y, zz), _rng.randf_range(0.06, 0.12), m)
			2:
				_alambic(k, Vector3(x, y, zz), m)
				x += 0.4
			3:
				k.cyl(m, _tr(x, y, zz), 0.045, 0.045, _rng.randf_range(0.18, 0.3), 8)
				k.cyl("verre", _tr(x - 0.12, y, zz + 0.1), 0.04, 0.04, 0.24, 8)
				k.cyl(pots[(_rng.randi()) % pots.size()], _tr(x + 0.12, y, zz - 0.05), 0.04, 0.04, 0.16, 8)
			4:
				k.cyl("pierre_claire", _tr(x, y, zz), 0.1, 0.12, 0.12, 10)
				_pl(k, "bois", Vector3(x, y + 0.08, zz), Vector3(x + 0.08, y + 0.28, zz + 0.04), 0.03)
			5:
				_bougie(k, _p(x, y, zz), 0.18)
			6:
				k.box("banniere_pourpre", _tr(x, y, zz, _rng.randf() * 0.6), Vector3(0.22, 0.05, 0.3))
				k.box("banniere_bleu", _tr(x, y + 0.05, zz, _rng.randf() * 0.6), Vector3(0.2, 0.05, 0.28))
		x += _rng.randf_range(0.32, 0.6)


## Des étagères de bocaux contre un mur (repère de l'aile) : de z0 à z1, en x = xm (le mur), face
## tournée vers n (± x)
func _bocaux(k: RefCounted, xm: float, z0: float, z1: float, sx: float) -> void:
	var lg: float = z1 - z0
	var zc: float = (z0 + z1) * 0.5
	var mats := ["verre", "verre", "pierre_claire", "cuivre_neuf", "potion_ambre", "potion_vert", "potion_rouge", "bois", "verre"]
	for e in [-1.0, 1.0]:
		k.box("bois", _tr(xm + sx * 0.2, 0.0, zc + e * lg * 0.5), Vector3(0.4, 3.5, 0.06))
	for i in range(5):
		var y: float = 0.6 + i * 0.68
		k.box("bois", _tr(xm + sx * 0.2, y, zc), Vector3(0.4, 0.04, lg))
		var z: float = z0 + 0.12
		while z < z1 - 0.12:
			var r: float = _rng.randf_range(0.05, 0.1)
			var h: float = _rng.randf_range(0.12, 0.36)
			var m: String = mats[_rng.randi() % mats.size()]
			k.cyl(m, _tr(xm + sx * _rng.randf_range(0.14, 0.26), y + 0.04, z), r, r * 0.9, h, 8)
			if m == "verre" or m.begins_with("potion"):
				k.cyl("bois", _tr(xm + sx * 0.2, y + 0.04 + h, z), r * 0.5, r * 0.45, 0.04, 6)
			z += r * 2.0 + _rng.randf_range(0.02, 0.1)


func _elixirs(k: RefCounted, x0: float, x1: float, hw: float, rz: float) -> void:
	var xm: float = (x0 + x1) * 0.5
	# l'athanor : le fourneau de moellons, sa coupole, la gueule du feu, la hotte de cuivre
	var az: float = -1.3
	k.box("moellons", _tr(xm, 0.0, az), Vector3(2.2, 1.4, 2.0), true)
	k.cyl("moellons", _tr(xm, 1.4, az), 1.15, 0.45, 1.0, 16)
	k.cyl("cuivre_neuf", _tr(xm, 2.4, az), 0.3, 0.24, rz - 2.4, 10)
	k.cyl("cuivre_neuf", _tr(xm, 4.2, az), 1.3, 0.3, 0.9, 16)
	k.box("suie", _tr(xm, 0.15, az + 1.0), Vector3(0.9, 0.75, 0.02))
	k.box("pierre_claire", _tr(xm, 0.9, az + 1.02), Vector3(1.2, 0.14, 0.12))
	for j in range(4):
		_flamme(k, _p(xm - 0.3 + j * 0.2, 0.18, az + 0.96), 0.32, 0.5 - absf(j - 1.5) * 0.08)
	feu = _lumiere(_p(xm, 0.8, az + 1.5), 10.0, 1.4, 2.0)
	# une cornue sur la coupole
	_ballon(k, Vector3(xm, 2.2, az + 0.45), 0.16, "potion_vert")
	# les paillasses (deux rangs, l'allée au milieu pour la porte)
	_paillasse(k, x0 + 1.0, xm - 2.2, 2.6)
	_paillasse(k, xm + 2.2, x1 - 1.0, 2.6)
	_paillasse(k, x0 + 1.0, xm - 2.6, -hw + 0.55)
	_paillasse(k, xm + 2.6, x1 - 1.0, -hw + 0.55)
	# les bocaux contre les murs de refend
	_bocaux(k, x0, -4.2, 3.6, 1.0)
	_bocaux(k, x1, -4.2, 3.6, -1.0)
	# la cuve de cuivre et son serpentin
	var cv := Vector3(xm + 5.0, 0.0, -1.0)
	for i in range(4):
		var a: float = TAU * i / 4.0 + 0.4
		_pl(k, "fer", cv + Vector3(cos(a) * 0.5, 0, sin(a) * 0.5), cv + Vector3(cos(a) * 0.45, 0.5, sin(a) * 0.45), 0.06)
	k.cyl("cuivre_neuf", _tr(cv.x, 0.5, cv.z), 0.62, 0.66, 1.0, 16)
	k.cyl("cuivre_neuf", _tr(cv.x, 1.5, cv.z), 0.66, 0.2, 0.35, 16)
	var prev: Vector3 = cv + Vector3(0, 1.85, 0)
	for i in range(1, 30):
		var t: float = float(i) / 29.0
		var a3: float = t * TAU * 3.0
		var q := Vector3(cv.x - 1.3 + cos(a3) * 0.28, 1.9 - t * 1.0, cv.z + sin(a3) * 0.28)
		_pl(k, "cuivre_neuf", prev, q, 0.04)
		prev = q
	# les herbes qui sèchent, pendues aux solives
	for i in range(18):
		var hx: float = lerpf(x0 + 1.0, x1 - 1.0, float(i) / 17.0)
		var hz: float = -hw + 0.9 + (i % 3) * 0.5
		var hy: float = rz - 0.55 - _rng.randf_range(0.0, 0.3)
		_pl(k, "bois", Vector3(hx, rz - 0.36, hz), Vector3(hx, hy, hz), 0.012)
		k.cyl("herbes", _tr(hx, hy - 0.42, hz), 0.03, 0.13, 0.42, 6)
	# les lanternes
	for lx in [x0 + 4.5, x1 - 4.5]:
		var lp: Vector3 = _p(lx, 4.3, 0.6)
		_lanterne(k, lp)
		_poutre(k, "fer", lp + Vector3(0, 0.75, 0), _p(lx, rz - 0.2, 0.6), 0.03)
		_lumiere(lp, 11.0, 0.6, 1.4)


# =================================================================== l'Amphithéâtre

func _amphi(k: RefCounted, x0: float, x1: float, hw: float, rz: float) -> void:
	# les gradins : quatre marches de chêne qui montent vers l'ouest, face au tableau (à l'est)
	var xf0: float = x1 - 6.6           # le bord du premier gradin
	var zg0: float = -hw
	var zg1: float = hw - 1.5            # (l'allée du côté du cloître)
	for g in range(4):
		var xa: float = xf0 - 1.15 * (g + 1) if g < 3 else x0
		var xb: float = xf0 - 1.15 * g
		var y: float = 0.38 * (g + 1)
		k.box("chene", _tr((xa + xb) * 0.5, 0.0, (zg0 + zg1) * 0.5), Vector3(xb - xa, y, zg1 - zg0), true)
		# le banc (au fond du gradin), la tablette (devant)
		k.box("bois", _tr(xa + 0.3 if g < 3 else xb - 0.85, y, (zg0 + zg1) * 0.5), Vector3(0.38, 0.44, zg1 - zg0 - 0.4))
		k.box("bois", _tr(xb - 0.2, y + 0.72, (zg0 + zg1) * 0.5), Vector3(0.36, 0.04, zg1 - zg0 - 0.4))
		k.box("bois", _tr(xb - 0.05, y, (zg0 + zg1) * 0.5), Vector3(0.04, 0.72, zg1 - zg0 - 0.4))
		# les marches de l'allée
		var xm2: float = xb - 0.575
		k.box("chene", _tr((xm2 + xb) * 0.5, 0.0, zg1 + 0.55), Vector3(xb - xm2, y - 0.19, 1.1), true)
		k.box("chene", _tr((xa + xm2) * 0.5, 0.0, zg1 + 0.55), Vector3(xm2 - xa, y, 1.1), true)
		k.box("bois", _tr(xb - 0.02, y - 0.19, zg1 + 0.55), Vector3(0.05, 0.19, 1.1))
		for zl in [-3.2, -0.4, 2.0]:
			k.box("cire", _tr(xb - 0.2, y + 0.76, zl, 0.1), Vector3(0.24, 0.02, 0.3))
	# la chaire du maître, sur une estrade
	var xc: float = x1 - 3.0
	k.box("chene", _tr(xc, 0.0, 0.0), Vector3(2.6, 0.3, 3.0), true)
	k.prism("bois", _tr(xc - 0.4, 0.3, 0.0), Kit.ngon(0.55, 6, 0.0), 0.0, 1.15)
	k.box("bois", _tr(xc - 0.5, 1.45, 0.0) * Transform3D(Basis(Vector3(0, 0, 1), 0.3), Vector3.ZERO), Vector3(0.7, 0.05, 0.9))
	k.box("cire", _tr(xc - 0.5, 1.52, 0.0) * Transform3D(Basis(Vector3(0, 0, 1), 0.3), Vector3.ZERO), Vector3(0.4, 0.02, 0.6))
	# le grand tableau de géométrie, au mur est ; la règle, le compas
	var xt: float = x1 - 0.05
	_panneau(k, "tableau_amphi", Vector3(xt, 1.0, -3.6), Vector3(xt, 1.0, 3.6), 2.9, Vector3(-1, 0, 0))
	k.box("bois", _tr(xt - 0.08, 0.92, 0.0), Vector3(0.16, 0.06, 7.2))
	_pl(k, "bois", Vector3(xt - 0.06, 1.4, 3.9), Vector3(xt - 0.06, 2.6, 4.3), 0.04, Vector3(-1, 0, 0))
	# une carte du ciel et une bannière au fond, au-dessus des gradins
	_panneau(k, "carte_ciel", Vector3(x0 + 0.05, 2.4, 2.0), Vector3(x0 + 0.05, 2.4, -2.0), 3.0, Vector3(1, 0, 0))
	_banniere(k, "banniere_bleu", _p(x0 + 0.08, 5.5, -3.6), 1.1, 3.4, xf.basis * Vector3(1, 0, 0))
	_banniere(k, "banniere_pourpre", _p(x0 + 0.08, 5.5, 3.6), 1.1, 3.4, xf.basis * Vector3(1, 0, 0))
	# le lustre de fer, au-dessus des gradins
	var lc: Vector3 = _p(xf0 - 1.2, 4.3, -0.6)
	for i in range(12):
		var a0: float = TAU * i / 12.0
		var a1: float = TAU * (i + 1) / 12.0
		var q0: Vector3 = lc + Vector3(cos(a0), 0, sin(a0)) * 1.3
		var q1: Vector3 = lc + Vector3(cos(a1), 0, sin(a1)) * 1.3
		_poutre(k, "fer", q0, q1, 0.06, Vector3.UP)
		_bougie(k, q0 + Vector3(0, 0.03, 0), 0.22)
	for i in range(3):
		var a2: float = TAU * i / 3.0
		_poutre(k, "fer", lc + Vector3(cos(a2), 0, sin(a2)) * 1.3, lc + Vector3(0, 1.0, 0), 0.03)
	_poutre(k, "fer", lc + Vector3(0, 1.0, 0), Vector3(lc.x, rz - 0.3, lc.z), 0.04)
	_lumiere(lc - Vector3(0, 0.2, 0), 13.0, 1.2, 1.8)
	_lumiere(_p(x1 - 2.5, 3.6, 0.0), 9.0, 0.5, 1.1)

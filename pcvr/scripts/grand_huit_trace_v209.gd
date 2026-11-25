extends RefCounted
## V209 : le tracé du Grand Frisson, le grand huit de l'Île Foraine. Rien que des calculs : les points
## de la voie (un tous les mètres, dans le repère de l'île : x vers l'est, z vers le sud, y au-dessus
## de la mer), sa direction, son « haut » (le dévers : le wagon se penche comme les forces le
## demandent, jusqu'à la tête en bas dans la boucle), et la vitesse qu'y prend un train lâché du
## sommet. Le relief de l'île, la voie et le train lisent tous ce même tracé.

const G: float = 9.81
const PAS: float = 1.0                    # un point tous les mètres
const V_CHAINE: float = 3.6               # la chaîne de la montée (m/s)
const V_QUAI: float = 3.2                 # les pneus du quai et de la fin du freinage
const V_MINI: float = 4.5                 # les pneus de secours : le train ne s'arrête jamais en chemin
const FROTTE: float = 0.007               # le roulement
const AIR: float = 0.00016                # l'air (par mètre : a = AIR × v²)
const FREIN: float = 7.0                  # les freins de la fin (m/s²)

## Le quai : la voie y est droite, vers l'est.
const QUAI_Y: float = 5.0
const QUAI_Z: float = 70.0
const QUAI_X0: float = -100.0
const QUAI_X1: float = -55.0
## Où s'arrête le nez du train
const ARRET := Vector3(-62.0, QUAI_Y, QUAI_Z)
const DEBUT_CHAINE := Vector3(-30.0, 5.0, QUAI_Z)
const DEBUT_FREINS := Vector3(-163.0, 5.8, 89.0)
## La boucle : son entrée, vers l'est
const BOUCLE := Vector3(-66.0, 5.0, -36.0)
const BOUCLE_R_BAS: float = 24.0
const BOUCLE_R_HAUT: float = 8.5
const BOUCLE_DECALE: float = 6.0
## La vrille : la voie reste droite et tourne sur elle-même d'un tour complet
const VRILLE_X0: float = 2.0
const VRILLE_X1: float = 50.0

static var _cache: Dictionary = {}


## Les points de passage, puis les points denses de la boucle (repère de l'île).
static func _passages() -> Array:
	var p: Array = []
	# le quai, vers l'est
	for x in [QUAI_X0, -85.0, -70.0, QUAI_X1, -42.0]:
		p.append(Vector3(x, QUAI_Y, QUAI_Z))
	# la grande montée à la chaîne
	p.append(Vector3(-30.0, 5.0, QUAI_Z))
	p.append(Vector3(-14.0, 7.6, QUAI_Z))
	p.append(Vector3(4.0, 15.5, QUAI_Z))
	p.append(Vector3(30.0, 30.0, QUAI_Z))
	p.append(Vector3(56.0, 44.5, QUAI_Z))
	p.append(Vector3(76.0, 53.0, QUAI_Z))
	p.append(Vector3(92.0, 56.0, 69.0))
	# le sommet : un virage à gauche, face au large
	p.append(Vector3(108.0, 56.0, 62.0))
	p.append(Vector3(118.0, 54.5, 48.0))
	# la grande chute, vers le nord
	p.append(Vector3(121.0, 46.0, 32.0))
	p.append(Vector3(121.5, 27.0, 13.0))
	p.append(Vector3(121.5, 12.5, -5.0))
	p.append(Vector3(121.5, 6.6, -20.0))
	p.append(Vector3(121.5, 4.8, -33.0))
	p.append(Vector3(121.5, 6.6, -46.0))
	# la bosse (on ne pèse plus rien) : une parabole
	for dz in [30.0, 20.0, 10.0, 0.0, -10.0, -20.0, -30.0]:
		p.append(Vector3(121.5 - maxf(-dz, 0.0) * 0.06, 22.0 - 0.0082 * dz * dz, -88.0 + dz))
	p.append(Vector3(117.0, 6.0, -138.0))
	# le grand virage au ras de l'eau, par le nord
	p.append(Vector3(109.0, 3.4, -162.0))
	p.append(Vector3(92.0, 2.8, -186.0))
	p.append(Vector3(64.0, 2.5, -205.0))
	p.append(Vector3(24.0, 2.5, -214.0))
	p.append(Vector3(-18.0, 2.5, -213.0))
	p.append(Vector3(-58.0, 4.0, -199.0))
	# on remonte en tournant vers le sud
	p.append(Vector3(-98.0, 11.0, -175.0))
	p.append(Vector3(-128.0, 19.0, -142.0))
	p.append(Vector3(-141.0, 20.0, -104.0))
	p.append(Vector3(-132.0, 10.0, -68.0))
	p.append(Vector3(-110.0, 5.4, -44.0))
	p.append(Vector3(-88.0, 5.0, -37.0))
	# la boucle
	for q in boucle():
		p.append(q)
	var sortie: Vector3 = p[p.size() - 1]
	p.append(sortie + Vector3(16.0, 0.4, 0.0))
	# la vrille, au-dessus de la grande allée
	p.append(Vector3(VRILLE_X0 - 10.0, 8.0, sortie.z))
	p.append(Vector3(VRILLE_X0 + 8.0, 10.0, sortie.z))
	p.append(Vector3((VRILLE_X0 + VRILLE_X1) * 0.5, 11.0, sortie.z))
	p.append(Vector3(VRILLE_X1 - 8.0, 10.0, sortie.z))
	p.append(Vector3(VRILLE_X1 + 12.0, 9.0, sortie.z))
	# on tourne vers le sud, on passe sous la grande montée
	p.append(Vector3(84.0, 9.5, -20.0))
	p.append(Vector3(95.0, 11.0, 6.0))
	p.append(Vector3(93.0, 12.0, 36.0))
	p.append(Vector3(89.0, 10.0, 70.0))
	p.append(Vector3(91.0, 7.0, 104.0))
	p.append(Vector3(100.0, 4.0, 138.0))
	# le virage au ras de l'eau, par le sud
	p.append(Vector3(88.0, 3.0, 176.0))
	p.append(Vector3(52.0, 2.5, 201.0))
	p.append(Vector3(10.0, 2.5, 209.0))
	p.append(Vector3(-30.0, 3.6, 201.0))
	# les petites bosses
	p.append(Vector3(-58.0, 8.6, 187.0))
	p.append(Vector3(-84.0, 4.2, 173.0))
	p.append(Vector3(-108.0, 8.2, 160.0))
	p.append(Vector3(-134.0, 5.4, 143.0))
	# les freins, puis le retour au quai
	p.append(Vector3(-158.0, 6.0, 122.0))
	p.append(Vector3(-166.0, 6.0, 98.0))
	p.append(Vector3(-152.0, 5.4, 76.0))
	p.append(Vector3(-128.0, 5.0, QUAI_Z))
	return p


## La boucle, en goutte d'eau (large en bas, serrée en haut), un point tous les 15°.
static func boucle() -> Array:
	var out: Array = []
	var pos := Vector2(0.0, 0.0)           # (vers l'avant, vers le haut)
	var n: int = 720
	var prec: float = 0.0
	for i in range(n + 1):
		var th: float = TAU * i / n
		if i > 0:
			var tm: float = (th + prec) * 0.5
			var u: float = (1.0 + cos(tm)) * 0.5
			var r: float = BOUCLE_R_HAUT + (BOUCLE_R_BAS - BOUCLE_R_HAUT) * u * u
			var ds: float = r * (th - prec)
			pos += Vector2(cos(tm), sin(tm)) * ds
		prec = th
		if i % 30 == 0:
			out.append(BOUCLE + Vector3(pos.x, pos.y, BOUCLE_DECALE * float(i) / n))
	return out


## Catmull-Rom centripète entre p1 et p2
static func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var t0: float = 0.0
	var t1: float = t0 + sqrt(maxf(p0.distance_to(p1), 0.001))
	var t2: float = t1 + sqrt(maxf(p1.distance_to(p2), 0.001))
	var t3: float = t2 + sqrt(maxf(p2.distance_to(p3), 0.001))
	var t: float = lerpf(t1, t2, u)
	var a1: Vector3 = p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))
	var a2: Vector3 = p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1))
	var a3: Vector3 = p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2))
	var b1: Vector3 = a1 * ((t2 - t) / (t2 - t0)) + a2 * ((t - t0) / (t2 - t0))
	var b2: Vector3 = a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1))
	return b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1))


## Le tracé complet : {"pts", "tan", "haut", "v", "n", "longueur", "chaine0", "chaine1", "freins", "arret", "sommet"}
static func tracer() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var w: Array = _passages()
	var m: int = w.size()
	# la courbe fine
	var fin := PackedVector3Array()
	for i in range(m):
		var p0: Vector3 = w[(i - 1 + m) % m]
		var p1: Vector3 = w[i]
		var p2: Vector3 = w[(i + 1) % m]
		var p3: Vector3 = w[(i + 2) % m]
		var k: int = maxi(int(ceil(p1.distance_to(p2) / 0.25)), 2)
		for j in range(k):
			fin.append(_cr(p0, p1, p2, p3, float(j) / k))
	# un point tous les mètres
	var total: float = 0.0
	var cum := PackedFloat32Array()
	cum.resize(fin.size() + 1)
	for i in range(fin.size()):
		cum[i] = total
		total += fin[i].distance_to(fin[(i + 1) % fin.size()])
	cum[fin.size()] = total
	var n: int = int(round(total / PAS))
	var pas: float = total / n
	var pts := PackedVector3Array()
	pts.resize(n)
	var seg: int = 0
	for i in range(n):
		var s: float = i * pas
		while seg < fin.size() - 1 and cum[seg + 1] < s:
			seg += 1
		var a: Vector3 = fin[seg]
		var b: Vector3 = fin[(seg + 1) % fin.size()]
		var l: float = maxf(cum[seg + 1] - cum[seg], 0.00001)
		pts[i] = a.lerp(b, clampf((s - cum[seg]) / l, 0.0, 1.0))
	# la direction, la courbure
	var tan := PackedVector3Array()
	tan.resize(n)
	for i in range(n):
		tan[i] = (pts[(i + 1) % n] - pts[(i - 1 + n) % n]).normalized()
	var courbe := PackedVector3Array()
	courbe.resize(n)
	for i in range(n):
		var e: int = 3
		courbe[i] = (tan[(i + e) % n] - tan[(i - e + n) % n]) / (2.0 * e * pas)
	# les repères
	var arret: int = _proche(pts, ARRET)
	var chaine0: int = _proche(pts, DEBUT_CHAINE)
	var freins: int = _proche(pts, DEBUT_FREINS)
	var sommet: int = 0
	for i in range(n):
		if pts[i].y > pts[sommet].y:
			sommet = i
	var chaine1: int = sommet - 6
	var d: Dictionary = {"pts": pts, "tan": tan, "n": n, "pas": pas, "longueur": total, "arret": arret, "chaine0": chaine0,
		"chaine1": chaine1, "freins": freins, "sommet": sommet}
	# la vitesse d'un train parti du quai
	var v := PackedFloat32Array()
	v.resize(n)
	var vit: float = V_QUAI
	for k in range(n):
		var i: int = (arret + k) % n
		v[i] = vit
		var acc: float = acceleration(d, i, vit)
		vit = sqrt(maxf(vit * vit + 2.0 * acc * pas, 0.0))
		vit = regler(d, i, vit, pas / maxf(vit, 0.5))
	d["v"] = v
	# le haut : le wagon se penche dans les virages, comme les forces de côté le demandent
	var haut := PackedVector3Array()
	haut.resize(n)
	for i in range(n):
		var cote0: Vector3 = tan[i].cross(Vector3.UP)
		if cote0.length() < 0.2:
			haut[i] = Vector3.UP
			continue
		cote0 = cote0.normalized()
		var haut0: Vector3 = cote0.cross(tan[i]).normalized()
		var acc: Vector3 = courbe[i] * v[i] * v[i] + Vector3(0.0, G, 0.0)
		var angle: float = clampf(atan2(acc.dot(cote0), maxf(acc.dot(haut0), 0.75 * G)), -1.25, 1.25)
		haut[i] = haut0 * cos(angle) + cote0 * sin(angle)
	for _passe in range(4):
		var lisse := PackedVector3Array()
		lisse.resize(n)
		for i in range(n):
			var somme := Vector3.ZERO
			for e in range(-6, 7):
				somme += haut[(i + e + n) % n]
			somme -= tan[i] * somme.dot(tan[i])
			lisse[i] = somme.normalized() if somme.length() > 0.001 else haut[i]
		haut = lisse
	# la boucle : le haut du wagon suit la voie, jusqu'à la tête en bas
	var points_boucle: Array = boucle()
	var b0: int = _proche(pts, points_boucle[0]) - 4
	var b1: int = _proche(pts, points_boucle[points_boucle.size() - 1]) + 4
	for i in range(b0 + 1, b1):
		var dedans: Vector3 = courbe[i] - tan[i] * courbe[i].dot(tan[i])
		if dedans.length() < 0.004:
			continue
		var fondu: float = clampf(minf(float(i - b0), float(b1 - i)) / 12.0, 0.0, 1.0)
		haut[i] = haut[i].lerp(dedans.normalized(), fondu).normalized()
	d["boucle0"] = b0
	d["boucle1"] = b1
	# la vrille : un tour complet autour de la voie
	for i in range(n):
		var x: float = pts[i].x
		if x > VRILLE_X0 and x < VRILLE_X1 and absf(pts[i].z - (BOUCLE.z + BOUCLE_DECALE)) < 3.0 and pts[i].y > 7.0 and pts[i].y < 13.0:
			var q: float = (x - VRILLE_X0) / (VRILLE_X1 - VRILLE_X0)
			var doux: float = q * q * (3.0 - 2.0 * q)
			haut[i] = haut[i].rotated(tan[i], TAU * doux)
	# le quai et la montée : bien droit
	for k in range(n):
		var i: int = (freins + k) % n
		if i == chaine1:
			break
		var f: float = 1.0
		if k < 30:
			f = k / 30.0
		var droit: Vector3 = Vector3.UP - tan[i] * Vector3.UP.dot(tan[i])
		haut[i] = haut[i].lerp(droit.normalized(), f).normalized()
	d["haut"] = haut
	_cache = d
	return d


static func _proche(pts: PackedVector3Array, p: Vector3) -> int:
	var best: int = 0
	var bd: float = 1e9
	for i in range(pts.size()):
		var dd: float = pts[i].distance_squared_to(p)
		if dd < bd:
			bd = dd
			best = i
	return best


## Le nombre de mètres de i0 à i (dans le sens de la marche)
static func _apres(d: Dictionary, i0: int, i: int) -> int:
	var n: int = int(d["n"])
	return (i - i0 + n) % n


static func zone(d: Dictionary, i: int) -> String:
	var n: int = int(d["n"])
	var arret: int = int(d["arret"])
	var k: int = _apres(d, arret, i)
	if k < _apres(d, arret, int(d["chaine0"])):
		return "quai"
	if k < _apres(d, arret, int(d["chaine1"])):
		return "chaine"
	if k < _apres(d, arret, int(d["freins"])):
		return "libre"
	return "freins" if k < n else "quai"


## L'accélération le long de la voie (m/s²) : la pente, le roulement, l'air.
static func acceleration(d: Dictionary, i: int, vit: float) -> float:
	var t: Vector3 = (d["tan"] as PackedVector3Array)[i]
	return -G * t.y - FROTTE * G - AIR * vit * vit


## Ce que la machine impose à la vitesse : la chaîne, les pneus, les freins.
static func regler(d: Dictionary, i: int, vit: float, dt: float) -> float:
	match zone(d, i):
		"quai":
			return move_toward(vit, V_QUAI, 2.0 * dt)
		"chaine":
			return move_toward(vit, V_CHAINE, 14.0 * dt)
		"freins":
			return move_toward(vit, V_QUAI, FREIN * dt) if vit > V_QUAI else move_toward(vit, V_QUAI, 2.0 * dt)
	return maxf(vit, V_MINI)


## Ce que le corps ressent (en g) : Vector2(vers le haut du siège, de côté)
static func forces(d: Dictionary, i: int) -> Vector2:
	var n: int = int(d["n"])
	var tan: PackedVector3Array = d["tan"]
	var haut: PackedVector3Array = d["haut"]
	var v: PackedFloat32Array = d["v"]
	var k: Vector3 = (tan[(i + 3) % n] - tan[(i - 3 + n) % n]) / (6.0 * float(d["pas"]))
	var a: Vector3 = k * v[i] * v[i] + Vector3(0.0, G, 0.0)
	var cote: Vector3 = tan[i].cross(haut[i]).normalized()
	return Vector2(a.dot(haut[i]) / G, a.dot(cote) / G)

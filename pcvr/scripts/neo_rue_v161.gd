extends RefCounted
## V161 : la rue de Néopolis, meublée. À chaque carrefour, quatre feux tricolores sur leur potence
## (une tête au-dessus de la chaussée, une autre sur le mât, le bonhomme des piétons) qui marchent pour
## de bon : quand une rue passe au vert, l'autre est au rouge (shaders/feux_v161) ; des bornes à liseré
## de néon au bout des passages piétons. Le long des trottoirs : des poubelles (et leur couvercle), des
## bancs et des bacs à cerisiers sur le Boulevard des Néons.
## Repère : celui de l'île (x, z ; Néopolis : neo_v94._ground) ; les rues tous les PAS mètres.

const Kit = preload("res://scripts/neo_kit_v94.gd")
const IleScript = preload("res://scripts/ile_neo_v94.gd")


## Tout poser (N : Néopolis, neo_v94) ; renvoie le nombre de feux.
static func build(N: Node3D) -> int:
	var b := Kit.Batch.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 16101
	var feux: int = 0
	for kx in range(-3, 4):
		for kz in range(-3, 4):
			feux += _carrefour(N, b, kx, kz)
	_trottoirs(N, b, rng)
	b.commit(N, "Neo_rue_v161")
	return feux


# =================================================================== les carrefours

static func _carrefour(N: Node3D, b: Kit.Batch, kx: int, kz: int) -> int:
	var wx: Vector2 = IleScript.largeur(kx)
	var wz: Vector2 = IleScript.largeur(kz)
	var cx: float = kx * IleScript.PAS
	var cz: float = kz * IleScript.PAS
	var n: int = 0
	# [coin x, coin z, le bras (au-dessus de la rue), la face (vers les voitures qui arrivent), la phase]
	var poses: Array = [
		[1.0, 1.0, Vector3(-1, 0, 0), Vector3(0, 0, 1), 0.0, wx.x],
		[-1.0, -1.0, Vector3(1, 0, 0), Vector3(0, 0, -1), 0.0, wx.x],
		[1.0, -1.0, Vector3(0, 0, -1), Vector3(1, 0, 0), 1.0, wz.x],
		[-1.0, 1.0, Vector3(0, 0, 1), Vector3(-1, 0, 0), 1.0, wz.x]]
	for e in poses:
		var sx: float = e[0]
		var sz: float = e[1]
		var x: float = cx + sx * (wx.x + 0.75)
		var z: float = cz + sz * (wz.x + 0.75)
		if maxf(absf(x), absf(z)) > IleScript.ANNEAU + 6.0:
			continue
		_feu(N, b, N._ground(x, z), e[2], e[3], float(e[4]), float(e[5]))
		n += 1
	# les bornes, au bout des passages piétons (de part et d'autre de chaque passage)
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			for d in [0.3, 4.1]:
				var p1 := Vector2(cx + sx2 * (wx.x + 0.35), cz + sz2 * (wz.y + d))
				var p2 := Vector2(cx + sx2 * (wx.y + d), cz + sz2 * (wz.x + 0.35))
				for p in [p1, p2]:
					if maxf(absf(p.x), absf(p.y)) > IleScript.ANNEAU + 4.0:
						continue
					_borne(N, b, N._ground(p.x, p.y))
	return n


## Un feu tricolore sur sa potence : le mât, le bras au-dessus de la chaussée, la tête et ses trois
## lentilles (et leurs visières), une petite tête sur le mât, le bonhomme des piétons sur le côté.
static func _feu(N: Node3D, b: Kit.Batch, at: Vector3, bras: Vector3, face: Vector3, phase: float, demi: float) -> void:
	var ph: String = "ew" if phase > 0.5 else "ns"
	b.cyl_at("metal_noir", at, 0.15, 0.1, 6.3, 10)
	b.cyl_at("metal_noir", at, 0.22, 0.2, 0.25, 10)
	var top: Vector3 = at + Vector3.UP * 6.0
	var bout: Vector3 = top + bras * demi * 0.85
	b.tube("metal_noir", top, bout, 0.07, 6)
	b.tube("metal_noir", top + Vector3.DOWN * 0.9, top + bras * 1.1, 0.04, 5)
	_tete(b, bout + Vector3.DOWN * 0.62, face, ph, 1.0)
	_tete(b, at + Vector3.UP * 3.0 + face * 0.2, face, ph, 0.7)
	# le bonhomme : vers le passage piéton qui traverse la rue de ce feu
	var cote: Vector3 = -bras
	var pb := Basis(Vector3.UP, atan2(cote.x, cote.z))
	var pp: Vector3 = at + Vector3.UP * 2.4 + cote * 0.18
	b.box("metal_noir", Transform3D(pb, pp), Vector3(0.3, 0.42, 0.2))
	b.box("feux_" + ph + "_3", Transform3D(pb, pp + cote * 0.105), Vector3(0.2, 0.3, 0.01))
	N._col(Transform3D(Basis(), at + Vector3.UP * 1.5), Vector3(0.32, 3.0, 0.32))


static func _tete(b: Kit.Batch, c: Vector3, face: Vector3, ph: String, s: float) -> void:
	var bs := Basis(Vector3.UP, atan2(face.x, face.z))
	b.box("metal_noir", Transform3D(bs, c), Vector3(0.36, 1.06, 0.26) * s)
	b.box("plastique_noir", Transform3D(bs, c - face * 0.135 * s), Vector3(0.5, 1.2, 0.02) * s)
	var axe := Basis(Vector3.RIGHT, PI * 0.5)
	for k in range(3):
		var y: float = (0.32 - k * 0.32) * s
		var lc: Vector3 = c + Vector3.UP * y + face * 0.13 * s
		b.cyl("feux_" + ph + "_" + str(k), Transform3D(bs * axe, lc), 0.11 * s, 0.11 * s, 0.02 * s, 14)
		b.box("metal_noir", Transform3D(bs, lc + Vector3.UP * 0.12 * s + face * 0.09 * s), Vector3(0.28, 0.02, 0.18) * s)


## Une borne : un fût sombre, un liseré de néon cyan en haut.
static func _borne(N: Node3D, b: Kit.Batch, at: Vector3) -> void:
	b.cyl_at("metal_noir", at, 0.11, 0.1, 0.9, 10)
	b.cyl_at("neon_cyan", at + Vector3.UP * 0.78, 0.105, 0.105, 0.05, 10)
	b.cyl_at("metal", at + Vector3.UP * 0.9, 0.1, 0.06, 0.05, 10)
	N._col(Transform3D(Basis(), at + Vector3.UP * 0.45), Vector3(0.22, 0.9, 0.22))


# =================================================================== les trottoirs

static func _trottoirs(N: Node3D, b: Kit.Batch, rng: RandomNumberGenerator) -> void:
	for k in range(-3, 4):
		var w: Vector2 = IleScript.largeur(k)
		for m in range(-3, 3):
			var mid: float = (m + 0.5) * IleScript.PAS
			for side in [-1.0, 1.0]:
				# une poubelle au bord du trottoir, sur les deux sortes de rues
				var d: float = k * IleScript.PAS + side * (w.x + 0.8)
				_poubelle(N, b, N._ground(d, mid + 4.0 * side))
				_poubelle(N, b, N._ground(mid - 4.0 * side, d))
				if k == 0:
					# le Boulevard (nord-sud) : des bancs et des bacs à cerisiers
					var e: float = side * (w.y - 1.0)
					for o in [-6.0, 6.0]:
						var at: Vector3 = N._ground(e, mid + o)
						_bac(N, b, at, rng)
					var bat: Vector3 = N._ground(side * (w.y - 0.6), mid)
					Kit.bench(b, bat, -PI * 0.5 * side)
					N._col(Transform3D(Basis(), bat + Vector3.UP * 0.45), Vector3(0.6, 0.9, 1.9))


static func _poubelle(N: Node3D, b: Kit.Batch, at: Vector3) -> void:
	b.cyl_at("metal", at, 0.3, 0.33, 0.95, 12)
	b.cyl_at("metal_noir", at + Vector3.UP * 0.95, 0.35, 0.35, 0.05, 12)
	b.cyl_at("plastique_noir", at + Vector3.UP * 1.0, 0.33, 0.22, 0.12, 12)
	b.cyl_at("neon_vert", at + Vector3.UP * 0.62, 0.335, 0.335, 0.03, 12)
	N._col(Transform3D(Basis(), at + Vector3.UP * 0.55), Vector3(0.66, 1.1, 0.66))


## Un bac de béton, sa terre, un petit cerisier
static func _bac(N: Node3D, b: Kit.Batch, at: Vector3, rng: RandomNumberGenerator) -> void:
	b.box("beton", Transform3D(Basis(), at + Vector3.UP * 0.35), Vector3(1.3, 0.7, 1.3))
	b.box("terre_bac", Transform3D(Basis(), at + Vector3.UP * 0.68), Vector3(1.1, 0.04, 1.1))
	for k in range(4):
		var a: float = TAU * k / 4.0
		b.box("neon_rose", Transform3D(Basis(Vector3.UP, a), at + Vector3.UP * 0.71 + Vector3(sin(a), 0, cos(a)) * 0.64), Vector3(1.32, 0.025, 0.04))
	Kit.cherry(b, at + Vector3.UP * 0.68, rng, 0.42)
	N._col(Transform3D(Basis(), at + Vector3.UP * 0.35), Vector3(1.3, 0.7, 1.3))

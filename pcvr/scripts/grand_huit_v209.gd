extends Node3D
## V209 : le Grand Frisson, le grand huit de l'Île Foraine. La voie d'acier rouge fait le tour de
## l'île (1,7 km) : la grande montée à la chaîne (56 m), la chute, la bosse où l'on ne pèse plus
## rien, le virage au ras de l'eau, la boucle, la vrille, les petites bosses, les freins. Le train
## tourne tout seul ; quand il est à quai, on monte au premier rang.
## En réalité virtuelle, on est assis dans le wagon : le monde penche et se retourne avec lui
## (« toutes les sensations »), ou bien l'horizon reste droit (« en douceur »).

const Trace = preload("res://scripts/grand_huit_trace_v209.gd")
const Kit = preload("res://scripts/foraine_kit_v209.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")

const VOIE: float = 0.62                  # la demi-largeur entre les rails
const WAGONS: int = 3
const WAGON_L: float = 2.9
const OEIL := Vector3(-0.34, 1.3, -0.3)  # les yeux du passager du premier rang (repère du wagon)
const ATTENTE: float = 22.0               # le train reste à quai (s)
const DEPART: float = 4.0                 # après qu'on est monté
const PRES: float = 520.0                 # le train ne tourne que si on est sur l'île ou tout près

var main: Node
var ile: Node3D
var d: Dictionary
var n: int = 0
var pos: float = 0.0                      # le nez du train, en mètres le long de la voie
var vitesse: float = 0.0
var etat: String = "quai"                 # quai, marche
var attente: float = 8.0
var a_bord: bool = false
var doux: bool = false
var tours: int = 0                        # les tours faits par le joueur
var vmax_tour: float = 0.0
var g_ressenti: float = 1.0
var wagons: Array = []
var quai_pos := Vector3.ZERO              # où l'on se tient pour monter
var quai_face := Vector3.FORWARD
var supports: int = 0
var _cam: Camera3D
var _vent: AudioStreamPlayer
var _roule: AudioStreamPlayer3D
var _clic_t: float = 0.0
var _eau_t: float = 0.0
var _vib_t: float = 0.0
var _tete0 := Vector3.ZERO                # la tête dans le repère du casque, à l'embarquement
var _lacet0: float = 0.0
var _cap_doux: float = 0.0
var _cols: GK.Cols


func setup(main_node: Node, ile_node: Node3D) -> void:
	main = main_node
	ile = ile_node
	d = Trace.tracer()
	n = int(d["n"])
	pos = float(int(d["arret"])) * float(d["pas"])
	_cols = GK.Cols.new(self, "Grand_huit_cols_v209")
	_voie()
	_soutiens()
	_passerelle()
	_train()
	_sons()
	var a: Vector3 = _monde(point(pos - 1.0))
	quai_pos = Vector3(a.x, Trace.QUAI_Y + 0.32, a.z - 2.4)
	quai_face = Vector3(0, 0, 1)
	_cam = Camera3D.new()
	_cam.name = "Camera_wagon_v209"
	_cam.fov = 80.0
	_cam.near = 0.08
	_cam.far = 4000.0
	add_child(_cam)
	_placer_wagons()


# =================================================================== lecture de la voie

func _monde(local: Vector3) -> Vector3:
	return Vector3(ile.CENTER.x + local.x, local.y, ile.CENTER.z + local.z)


func _idx(s: float) -> float:
	return fposmod(s / float(d["pas"]), float(n))


func point(s: float) -> Vector3:
	var f: float = _idx(s)
	var i: int = int(f)
	var pts: PackedVector3Array = d["pts"]
	return pts[i].lerp(pts[(i + 1) % n], f - i)


## Le repère du wagon en un point de la voie (dans le monde) : -Z vers l'avant, Y le haut du wagon
func repere(s: float) -> Transform3D:
	var f: float = _idx(s)
	var i: int = int(f)
	var j: int = (i + 1) % n
	var u: float = f - i
	var tan: PackedVector3Array = d["tan"]
	var hauts: PackedVector3Array = d["haut"]
	var t: Vector3 = tan[i].lerp(tan[j], u).normalized()
	var h: Vector3 = hauts[i].lerp(hauts[j], u)
	h = (h - t * h.dot(t)).normalized()
	var droite: Vector3 = t.cross(h).normalized()
	return Transform3D(Basis(droite, h, -t), _monde(point(s)))


# =================================================================== la voie

func _voie() -> void:
	var pts: PackedVector3Array = d["pts"]
	var morceau: int = 140
	var k0: int = 0
	var num: int = 0
	while k0 < n:
		var k1: int = mini(k0 + morceau, n)
		var b := Kit.Lot.new()
		var prec: Transform3D = repere(float(k0) * float(d["pas"]))
		for i in range(k0, k1):
			var suiv: Transform3D = repere(float(i + 1) * float(d["pas"]))
			# les deux rails, la poutre du dessous
			_troncon(b, "rail", prec, suiv, Vector3(-VOIE, 0, 0), 0.085, 6)
			_troncon(b, "rail", prec, suiv, Vector3(VOIE, 0, 0), 0.085, 6)
			_troncon(b, "poutre", prec, suiv, Vector3(0, -0.52, 0), 0.24, 6)
			# une traverse par mètre : du rail à la poutre, en V
			var c: Vector3 = prec.origin
			b.tube("rail", c + prec.basis * Vector3(-VOIE, -0.04, 0), c + prec.basis * Vector3(0, -0.36, 0), 0.045, 4)
			b.tube("rail", c + prec.basis * Vector3(VOIE, -0.04, 0), c + prec.basis * Vector3(0, -0.36, 0), 0.045, 4)
			prec = suiv
		b.commit(self, "Voie_%d_v209" % num, true)
		k0 = k1
		num += 1
	# la chaîne de la montée, les freins du retour : une bande sombre entre les rails
	var b2 := Kit.Lot.new()
	for i in range(int(d["chaine0"]), int(d["chaine1"]) + 4):
		var a: Transform3D = repere(float(i))
		var c2: Transform3D = repere(float(i + 1))
		b2.tube("fer", a.origin + a.basis * Vector3(0, -0.12, 0), c2.origin + c2.basis * Vector3(0, -0.12, 0), 0.06, 4)
	var f0: int = int(d["freins"])
	for k in range(0, 34, 3):
		var fr: Transform3D = repere(float(f0 + k))
		for cote in [-0.3, 0.3]:
			b2.box("jaune", Transform3D(fr.basis, fr.origin + fr.basis * Vector3(cote, -0.1, 0)), Vector3(0.06, 0.22, 1.6))
	b2.commit(self, "Voie_chaine_v209", false, 260.0)
	print("ILE_MANGA_V209: le Grand Frisson, ", n, " m de voie en ", num, " morceaux")


## Un mètre de tube, d'un repère au suivant (les arêtes se raccordent : le tube est lisse)
func _troncon(b: Kit.Lot, key: String, a: Transform3D, c: Transform3D, decal: Vector3, r: float, cotes: int) -> void:
	var ca: Vector3 = a.origin + a.basis * decal
	var cc: Vector3 = c.origin + c.basis * decal
	for k in range(cotes):
		var a0: float = TAU * k / cotes
		var a1: float = TAU * (k + 1) / cotes
		var d0 := Vector3(cos(a0), sin(a0), 0)
		var d1 := Vector3(cos(a1), sin(a1), 0)
		var p := [ca + a.basis * (d0 * r), ca + a.basis * (d1 * r), cc + c.basis * (d1 * r), cc + c.basis * (d0 * r)]
		var nn := [a.basis * d0, a.basis * d1, c.basis * d1, c.basis * d0]
		var uv := [Vector2(a0, 0), Vector2(a1, 0), Vector2(a1, 1), Vector2(a0, 1)]
		b.tri(key, [p[0], p[1], p[2]], [nn[0], nn[1], nn[2]], [uv[0], uv[1], uv[2]])
		b.tri(key, [p[0], p[2], p[3]], [nn[0], nn[2], nn[3]], [uv[0], uv[2], uv[3]])


# =================================================================== les poteaux

func _sol(local: Vector3) -> float:
	return maxf(float(ile.height_l(local.x, local.z)), -7.0)


## Vrai si un autre bout de voie passe sous ce point (un poteau droit le traverserait)
func _gene(i: int, bas: float) -> bool:
	var pts: PackedVector3Array = d["pts"]
	var p: Vector3 = pts[i]
	for j in range(0, n, 2):
		var ecart: int = absi(j - i)
		if mini(ecart, n - ecart) < 14:
			continue
		var q: Vector3 = pts[j]
		if q.y < p.y - 0.6 and q.y > bas - 1.0 and Vector2(q.x - p.x, q.z - p.z).length() < 2.6:
			return true
	return false


func _soutiens() -> void:
	var pts: PackedVector3Array = d["pts"]
	var hauts: PackedVector3Array = d["haut"]
	var tan: PackedVector3Array = d["tan"]
	var b := Kit.Lot.new()
	var i: int = 4
	while i < n:
		var p: Vector3 = pts[i]
		var h: Vector3 = hauts[i]
		if h.y < 0.3:
			i += 3
			continue
		var tete: Vector3 = p - h * 0.78
		var sol: float = _sol(tete)
		var haut_poteau: float = tete.y - sol
		if haut_poteau < 0.5 or _gene(i, sol):
			i += 3
			continue
		var cote: Vector3 = tan[i].cross(Vector3.UP)
		cote.y = 0.0
		cote = cote.normalized() if cote.length() > 0.1 else Vector3.RIGHT
		var w: Vector3 = _monde(tete)
		var r: float = clampf(0.14 + haut_poteau * 0.006, 0.14, 0.42)
		# le collier sous la poutre
		b.tube("poutre", _monde(p - h * 0.5), w, 0.2, 6)
		if haut_poteau > 14.0:
			# un grand poteau : deux jambes écartées, des entretoises
			var e: float = haut_poteau * 0.16
			var pieds: Array = []
			for sg in [-1.0, 1.0]:
				var pl: Vector3 = tete + cote * sg * e
				pl.y = _sol(pl)
				pieds.append(_monde(pl))
				b.tube("poutre", w, _monde(pl), r, 8)
				_semelle(b, pl)
			var etages: int = int(haut_poteau / 9.0)
			for q in range(1, etages + 1):
				var f: float = float(q) / (etages + 1)
				b.tube("poutre", w.lerp(pieds[0], f), w.lerp(pieds[1], f), r * 0.5, 6)
		else:
			var pl2: Vector3 = Vector3(tete.x, sol, tete.z)
			b.tube("poutre", w, _monde(pl2), r, 8)
			_semelle(b, pl2)
		supports += 1
		i += 9 if haut_poteau < 30.0 else 7
	b.commit(self, "Soutiens_v209", true)


## Le pied d'un poteau : un dé de béton sur la terre ferme (on s'y cogne)
func _semelle(b: Kit.Lot, pied: Vector3) -> void:
	if pied.y < 0.2:
		return
	var w: Vector3 = _monde(pied)
	b.box("dalles", Transform3D(Basis(), w + Vector3.UP * 0.15), Vector3(0.9, 0.5, 0.9))
	_cols.cyl(w - Vector3.UP * 0.2, 0.35, 2.4)


## La passerelle de service, le long de la grande montée (à gauche de la voie)
func _passerelle() -> void:
	var b := Kit.Lot.new()
	var c0: int = int(d["chaine0"]) + 6
	var c1: int = int(d["chaine1"]) + 2
	var prec: Transform3D = repere(float(c0))
	for i in range(c0 + 2, c1, 2):
		var a: Transform3D = repere(float(i))
		var g0: Vector3 = prec.origin + prec.basis * Vector3(-1.55, -0.5, 0)
		var g1: Vector3 = a.origin + a.basis * Vector3(-1.55, -0.5, 0)
		var mil: Vector3 = (g0 + g1) * 0.5
		var av: Vector3 = (g1 - g0).normalized()
		var cote: Vector3 = av.cross(Vector3.UP).normalized()
		var dessus: Vector3 = cote.cross(av).normalized()
		b.box("acier", Transform3D(Basis(cote, dessus, -av), mil), Vector3(0.8, 0.05, g0.distance_to(g1) + 0.02))
		# la main courante, du côté du vide
		var r0: Vector3 = g0 + prec.basis.x * -0.4
		var r1: Vector3 = g1 + a.basis.x * -0.4
		b.tube("jaune", r0 + Vector3.UP, r1 + Vector3.UP, 0.03, 4)
		if (i / 2) % 2 == 0:
			b.tube("jaune", r1, r1 + Vector3.UP, 0.025, 4)
			b.tube("poutre", g1, a.origin + a.basis * Vector3(0, -0.52, 0), 0.04, 4)
		prec = a
	b.commit(self, "Passerelle_v209", false, 320.0)


# =================================================================== le train

func _train() -> void:
	for k in range(WAGONS):
		var w := Node3D.new()
		w.name = "Wagon_%d_v209" % k
		add_child(w)
		var b := Kit.Lot.new()
		# le châssis, les flancs
		b.box("fer", Transform3D(Basis(), Vector3(0, 0.2, 0)), Vector3(1.0, 0.16, WAGON_L - 0.5))
		b.box("wagon", Transform3D(Basis(), Vector3(0, 0.36, 0)), Vector3(1.5, 0.18, WAGON_L - 0.3))
		for sg in [-1.0, 1.0]:
			b.box("wagon", Transform3D(Basis(), Vector3(sg * 0.76, 0.66, 0.0)), Vector3(0.07, 0.5, WAGON_L - 0.4))
			b.box("jaune", Transform3D(Basis(), Vector3(sg * 0.8, 0.5, 0.0)), Vector3(0.03, 0.1, WAGON_L - 0.6))
			# les roues qui tiennent le rail (dessus, côté, dessous)
			for av in [-0.9, 0.9]:
				b.cyl("fer", Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(sg * VOIE - 0.06, 0.2, av)), 0.13, 0.13, 0.12, 8)
				b.box("acier", Transform3D(Basis(), Vector3(sg * (VOIE + 0.16), 0.08, av)), Vector3(0.1, 0.34, 0.3))
		# le nez du premier wagon, l'arrière
		if k == 0:
			b.prism("wagon", Vector3(-0.78, 0.27, -WAGON_L * 0.5 + 0.15), Vector3(-0.78, 0.74, -WAGON_L * 0.5 + 0.15), Vector3(-0.78, 0.27, -WAGON_L * 0.5 - 0.75), Vector3(1.56, 0, 0))
			b.box("jaune", Transform3D(Basis(), Vector3(0, 0.5, -WAGON_L * 0.5 - 0.3)), Vector3(1.2, 0.05, 0.5))
		else:
			b.box("wagon", Transform3D(Basis(), Vector3(0, 0.62, -WAGON_L * 0.5 + 0.18)), Vector3(1.5, 0.42, 0.07))
			b.tube("fer", Vector3(0, 0.25, -WAGON_L * 0.5), Vector3(0, 0.25, -WAGON_L * 0.5 - 0.45), 0.05, 6)
		# deux rangs de deux sièges, les dossiers hauts, les barres
		for rang in range(2):
			var z: float = 0.75 - rang * 1.25
			for sg2 in [-1.0, 1.0]:
				var x: float = sg2 * 0.34
				b.box("siege", Transform3D(Basis(), Vector3(x, 0.52, z)), Vector3(0.56, 0.12, 0.5))
				b.box("siege", Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(x, 0.98, z + 0.3)), Vector3(0.56, 0.9, 0.1))
				b.box("siege", Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(x, 1.5, z + 0.36)), Vector3(0.3, 0.2, 0.12))
			b.box("wagon", Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 0.95, z + 0.37)), Vector3(1.46, 1.0, 0.04))
			# la barre de sécurité (baissée sur les genoux)
			b.tube("jaune", Vector3(-0.66, 0.84, z - 0.18), Vector3(0.66, 0.84, z - 0.18), 0.035, 6)
			for sg3 in [-0.66, 0.0, 0.66]:
				b.tube("jaune", Vector3(sg3, 0.84, z - 0.18), Vector3(sg3, 0.42, z - 0.5), 0.03, 6)
		b.commit(w, "Wagon_corps", true, 700.0)
		wagons.append(w)


func _placer_wagons() -> void:
	for k in range(wagons.size()):
		(wagons[k] as Node3D).global_transform = repere(pos - 1.6 - k * (WAGON_L + 0.35))


## Le siège du joueur (le premier rang, à gauche) : ses yeux, dans le monde
func siege() -> Transform3D:
	var w: Transform3D = (wagons[0] as Node3D).global_transform
	return Transform3D(w.basis, w * OEIL)


# =================================================================== les sons

## Deux secondes de souffle (un bruit filtré qui se boucle sans claquer)
static func _souffle(grave: float, graine: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = graine
	var nb: int = 44100
	var brut := PackedFloat32Array()
	brut.resize(nb)
	var y: float = 0.0
	var y2: float = 0.0
	for i in range(nb):
		y += (rng.randf_range(-1.0, 1.0) - y) * grave
		y2 += (y - y2) * 0.35
		brut[i] = y2
	# le fondu de la boucle
	var fondu: int = 4000
	for i in range(fondu):
		var f: float = float(i) / fondu
		brut[i] = brut[i] * f + brut[nb - fondu + i] * (1.0 - f)
	var long: int = nb - fondu
	var pic: float = 0.001
	for i in range(long):
		pic = maxf(pic, absf(brut[i]))
	var data := PackedByteArray()
	data.resize(long * 2)
	for i in range(long):
		data.encode_s16(i * 2, int(clampf(brut[i] / pic, -1.0, 1.0) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = long
	return wav


func _sons() -> void:
	_vent = AudioStreamPlayer.new()
	_vent.name = "Vent_v209"
	_vent.stream = _souffle(0.22, 2091)
	_vent.volume_db = -60.0
	if AudioServer.get_bus_index("Bruitages") >= 0:
		_vent.bus = "Bruitages"
	add_child(_vent)
	_roule = AudioStreamPlayer3D.new()
	_roule.name = "Roulement_v209"
	_roule.stream = _souffle(0.045, 2092)
	_roule.unit_size = 14.0
	_roule.max_distance = 220.0
	_roule.volume_db = -60.0
	if AudioServer.get_bus_index("Bruitages") >= 0:
		_roule.bus = "Bruitages"
	add_child(_roule)


func _sons_tick(delta: float) -> void:
	var roule: bool = etat == "marche"
	if roule and not _roule.playing:
		_roule.play()
	elif not roule and _roule.playing:
		_roule.stop()
	if roule:
		_roule.global_position = (wagons[0] as Node3D).global_position
		_roule.volume_db = lerpf(-14.0, 4.0, clampf(vitesse / 30.0, 0.0, 1.0))
		_roule.pitch_scale = lerpf(0.6, 1.5, clampf(vitesse / 32.0, 0.0, 1.0))
	var vent: bool = a_bord and etat == "marche"
	if vent and not _vent.playing:
		_vent.play()
	elif not vent and _vent.playing:
		_vent.stop()
	if vent:
		var q: float = clampf(vitesse / 32.0, 0.0, 1.0)
		_vent.volume_db = lerpf(-34.0, -3.0, sqrt(q))
		_vent.pitch_scale = lerpf(0.7, 1.35, q)
	# le cliquetis de la chaîne
	if roule and Trace.zone(d, int(_idx(pos))) == "chaine":
		_clic_t -= delta
		if _clic_t <= 0.0:
			_clic_t = 0.42
			if main != null and main.has_method("sfx"):
				main.sfx("cliquet_roue", (wagons[0] as Node3D).global_position, -6.0)


# =================================================================== la marche

func joueur_pres() -> bool:
	if main == null or not main.has_method("_player_pos_v27"):
		return false
	var p: Vector3 = main._player_pos_v27()
	return Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() < PRES


func a_quai() -> bool:
	return etat == "quai"


func _process(delta: float) -> void:
	if main == null or wagons.is_empty():
		return
	if main.get("game_started") != null and not bool(main.game_started):
		return
	if not a_bord and not joueur_pres():
		return
	avancer(minf(delta, 0.05))
	_sons_tick(delta)
	if a_bord:
		_porter(delta)


## Un pas de temps (les tests l'appellent aussi, pour faire un tour entier sans attendre)
func avancer(dt: float) -> void:
	if etat == "quai":
		vitesse = 0.0
		attente -= dt
		if attente <= 0.0:
			etat = "marche"
			vitesse = 0.3
			vmax_tour = 0.0
			if a_bord and main.has_method("sfx"):
				main.sfx("course_depart", null, -4.0)
	else:
		var i: int = int(_idx(pos))
		var acc: float = Trace.acceleration(d, i, vitesse)
		vitesse = maxf(vitesse + acc * dt, 0.0)
		vitesse = Trace.regler(d, i, vitesse, dt)
		var avant: float = pos
		pos += vitesse * dt
		vmax_tour = maxf(vmax_tour, vitesse)
		g_ressenti = Trace.forces(d, int(_idx(pos))).x
		# le tour est fini : le nez revient à l'arrêt du quai
		var arret: float = float(int(d["arret"])) * float(d["pas"])
		var long: float = float(d["longueur"])
		if fposmod(avant - arret, long) > long * 0.5 and fposmod(pos - arret, long) < long * 0.5:
			pos = arret
			vitesse = 0.0
			etat = "quai"
			attente = ATTENTE
			if a_bord:
				_descendre(true)
		_eau(dt)
	_placer_wagons()


## Au ras de la mer, à pleine vitesse : une gerbe d'eau
func _eau(dt: float) -> void:
	_eau_t -= dt
	if _eau_t > 0.0 or vitesse < 18.0:
		return
	var w: Vector3 = (wagons[0] as Node3D).global_position
	if w.y > 3.4 or float(ile.height(w.x, w.z)) > -0.3:
		return
	_eau_t = 0.12
	var mer: Variant = main.get("mer_v55")
	if mer != null and (mer as Node).has_method("splash"):
		(mer as Node).splash(Vector3(w.x, 0.0, w.z), 0.9)


# =================================================================== le passager

func pres_du_quai(p: Vector3) -> bool:
	return a_quai() and not a_bord and p.distance_to(quai_pos) < 4.5


func monter(en_douceur: bool) -> bool:
	if a_bord or not a_quai():
		return false
	a_bord = true
	doux = en_douceur
	attente = DEPART
	if main.get("inventory_v28") != null and main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if bool(main.get("xr_active")):
		var cam: Node3D = main.xr_camera
		_tete0 = cam.position
		var av: Vector3 = -cam.transform.basis.z
		_lacet0 = atan2(-av.x, -av.z)
	else:
		_cam.current = true
		if main.get("hero_v28") != null and main.hero_v28 != null and main.hero_v28.get("hero") != null and main.hero_v28.hero != null:
			(main.hero_v28.hero as Node3D).visible = false
	_cap_doux = _cap(siege().basis)
	_porter(0.0)
	return true


static func _cap(b: Basis) -> float:
	var av: Vector3 = -b.z
	return atan2(-av.x, -av.z)


## On descend : à quai (le tour est fini) ou avant le départ
func _descendre(fin_du_tour: bool) -> void:
	a_bord = false
	if _vent != null and _vent.playing:
		_vent.stop()
	if bool(main.get("xr_active")):
		var origine: Node3D = main.xr_origin
		origine.global_transform = Transform3D(Basis(Vector3.UP, _cap(origine.global_transform.basis)), origine.global_position)
		origine.rotation = Vector3(0.0, origine.rotation.y, 0.0)
	else:
		_cam.current = false
		if main.get("pc_camera") != null and main.pc_camera != null:
			main.pc_camera.current = true
		if main.get("hero_v28") != null and main.hero_v28 != null and main.hero_v28.get("hero") != null and main.hero_v28.hero != null:
			(main.hero_v28.hero as Node3D).visible = true
	main.place_player_v35(quai_pos, quai_face)
	if fin_du_tour:
		tours += 1
		if main.has_method("sfx"):
			main.sfx("foule_acclame", null, -8.0)
		main._show_message_v28("Le Grand Frisson : %d km/h en bas de la grande chute, 56 m de haut, une boucle, une vrille. Tour n° %d !" % [int(round(vmax_tour * 3.6)), tours])


## Une autre partie est chargée pendant qu'on roulait : on n'est plus à bord (sans nous déplacer).
func lacher() -> void:
	if not a_bord:
		return
	a_bord = false
	if _vent != null and _vent.playing:
		_vent.stop()
	if bool(main.get("xr_active")):
		var origine: Node3D = main.xr_origin
		origine.rotation = Vector3(0.0, _cap(origine.global_transform.basis), 0.0)
	else:
		_cam.current = false
		if main.get("pc_camera") != null and main.pc_camera != null:
			main.pc_camera.current = true
		if main.get("hero_v28") != null and main.hero_v28 != null and main.hero_v28.get("hero") != null and main.hero_v28.hero != null:
			(main.hero_v28.hero as Node3D).visible = true


func descendre_avant_depart() -> bool:
	if not a_bord or not a_quai():
		return false
	_descendre(false)
	attente = maxf(attente, 6.0)
	return true


func texte() -> String:
	if not a_bord:
		return ""
	if a_quai():
		return "Départ dans %d s — E : descendre" % int(ceil(maxf(attente, 0.0)))
	return "%d km/h" % int(round(vitesse * 3.6))


## Où l'on se réveillerait si la partie était enregistrée en plein tour
func lieu_sur() -> Vector3:
	return quai_pos


## Le joueur est assis au premier rang : sa vue suit le wagon.
func _porter(delta: float) -> void:
	var s: Transform3D = siege()
	var base: Basis = s.basis
	if doux:
		# en douceur : l'horizon reste droit, la vue tourne seulement avec la voie
		var av: Vector3 = -s.basis.z
		if Vector2(av.x, av.z).length() > 0.35 and s.basis.y.y > 0.2:
			_cap_doux = lerp_angle(_cap_doux, _cap(s.basis), clampf(delta * 6.0, 0.0, 1.0) if delta > 0.0 else 1.0)
		base = Basis(Vector3.UP, _cap_doux)
	if bool(main.get("xr_active")):
		var ob: Basis = base * Basis(Vector3.UP, -_lacet0)
		var origine: Node3D = main.xr_origin
		origine.global_transform = Transform3D(ob, s.origin - ob * _tete0)
		main.vr_body.global_position = s.origin
		main.vr_body.velocity = Vector3.ZERO
		_vib_t -= delta
		if _vib_t <= 0.0 and etat == "marche":
			_vib_t = 0.1
			var amp: float = clampf(vitesse / 32.0 * 0.22 + maxf(g_ressenti - 2.5, 0.0) * 0.12, 0.0, 0.6)
			for h in [main.get("left_hand"), main.get("right_hand")]:
				if h != null and (h as Node).has_method("trigger_haptic_pulse") and amp > 0.03:
					h.trigger_haptic_pulse("haptic", 0.0, amp, 0.1, 0.0)
	else:
		_cam.global_transform = Transform3D(base, s.origin)
		main.pc_root.position = s.origin - Vector3.UP * 1.0
		main.pc_body.global_position = s.origin
		main.pc_body.velocity = Vector3.ZERO

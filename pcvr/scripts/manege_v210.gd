extends Node3D
## V210 : le socle des manèges à sensations de l'Île Foraine (le Marteau, la Chute, la Grande
## Balançoire). Chaque manège tourne tout seul quand on est sur l'île ; quand il est à l'arrêt, on
## monte. Le socle s'occupe du passager : sa vue suit le siège (au casque comme à l'écran), le vent
## monte avec la vitesse, les manettes vibrent. Le manège, lui, dit seulement où est le siège.
## Tout est construit dans le repère du manège (son centre au sol, son cap) : le plan du mouvement
## est le plan Z-Y du manège.

const Kit = preload("res://scripts/foraine_kit_v209.gd")
const GK = preload("res://scripts/geants_kit_v142.gd")
const Huit = preload("res://scripts/grand_huit_v209.gd")

const ATTENTE: float = 18.0               # le manège reste à l'arrêt (s)
const DEPART: float = 5.0                 # après qu'on est monté
const PRES: float = 520.0                 # il ne tourne que si on est sur l'île ou tout près
const G: float = 9.81

static var _souffle_v210: AudioStreamWAV

var main: Node
var ile: Node3D
var foraine: Node3D
var cle: String = ""                      # marteau, chute, balancoire
var titre: String = ""
var etat: String = "quai"                 # quai, marche
var attente: float = 12.0
var t: float = 0.0                        # le temps depuis le départ
var fini: bool = false                    # le manège dit quand son tour est fini
var a_bord: bool = false
var doux: bool = false
var tours: int = 0                        # les tours faits par le joueur
var vitesse: float = 0.0                  # celle du siège du joueur
var vmax_tour: float = 0.0
var hmax_tour: float = 0.0
var gmax_tour: float = 1.0
var g_ressenti: float = 1.0
var quai_pos := Vector3.ZERO              # où l'on se tient pour monter (dans le monde)
var quai_face := Vector3.FORWARD
var _cols: GK.Cols
var _cam: Camera3D
var _vent: AudioStreamPlayer
var _tete0 := Vector3.ZERO
var _lacet0: float = 0.0
var _cap0: float = 0.0
var _oeil_prec := Vector3.ZERO
var _v_prec := Vector3.ZERO
var _vib_t: float = 0.0


## local : le centre du manège sur l'île ; cap : son orientation (autour de la verticale)
func setup(main_node: Node, ile_node: Node3D, foraine_node: Node3D, local: Vector2, cap: float) -> void:
	main = main_node
	ile = ile_node
	foraine = foraine_node
	var sol: float = float(ile.height_l(local.x, local.y))
	global_transform = Transform3D(Basis(Vector3.UP, cap), Vector3(ile.CENTER.x + local.x, sol, ile.CENTER.z + local.y))
	_cols = GK.Cols.new(self, "%s_cols_v210" % cle)
	_construire()
	_cam = Camera3D.new()
	_cam.name = "Camera_%s_v210" % cle
	_cam.fov = 80.0
	_cam.near = 0.08
	_cam.far = 4000.0
	add_child(_cam)
	_vent = AudioStreamPlayer.new()
	_vent.name = "Vent_%s_v210" % cle
	if _souffle_v210 == null:
		_souffle_v210 = Huit._souffle(0.22, 2101)
	_vent.stream = _souffle_v210
	_vent.volume_db = -60.0
	if AudioServer.get_bus_index("Bruitages") >= 0:
		_vent.bus = "Bruitages"
	add_child(_vent)
	_remise()
	_poser(0.0)
	_oeil_prec = siege().origin


# =================================================================== ce que chaque manège fournit

func _construire() -> void:
	pass


## Remet le manège à l'arrêt, prêt pour un tour
func _remise() -> void:
	pass


## Un pas de temps du tour (t est déjà avancé) : place les pièces qui bougent, met « fini » à la fin
func _poser(_dt: float) -> void:
	pass


## Les yeux du passager (le joueur), dans le monde : -Z devant lui, Y vers sa tête
func siege() -> Transform3D:
	return global_transform


## La phrase de fin de tour
func bilan() -> String:
	return titre


## Un bruit propre au manège (le cliquet de la montée…)
func _bruits(_dt: float) -> void:
	pass


# =================================================================== les formes communes

## Un siège de manège (il regarde vers +Z de xf) : l'assise, le haut dossier, le harnais jaune
func _siege(b: Kit.Lot, xf: Transform3D) -> void:
	b.box("siege", xf * Transform3D(Basis(), Vector3(0, 0.0, 0.0)), Vector3(0.5, 0.1, 0.48))
	b.box("siege", xf * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3(0, 0.5, -0.27)), Vector3(0.5, 1.0, 0.1))
	b.box("siege", xf * Transform3D(Basis(Vector3.RIGHT, -0.1), Vector3(0, 1.08, -0.31)), Vector3(0.3, 0.22, 0.12))
	b.box("fer", xf * Transform3D(Basis(), Vector3(0, -0.1, -0.05)), Vector3(0.56, 0.1, 0.6))
	# le harnais passe sur les épaules (sous les yeux : il ne bouche pas la vue) et se ferme sur le ventre
	for sx in [-0.22, 0.22]:
		b.tube("jaune", xf * Vector3(sx, 0.74, -0.2), xf * Vector3(sx, 0.6, 0.1), 0.03, 6)
		b.tube("jaune", xf * Vector3(sx, 0.6, 0.1), xf * Vector3(sx * 0.8, 0.2, 0.25), 0.03, 6)
	b.tube("jaune", xf * Vector3(-0.2, 0.2, 0.25), xf * Vector3(0.2, 0.2, 0.25), 0.035, 6)


## Les yeux de celui qui est assis dans le siège posé en xf
static func _yeux(xf: Transform3D) -> Transform3D:
	return Transform3D(xf.basis * Basis(Vector3.UP, PI), xf * Vector3(0.0, 0.74, 0.03))


## Une ligne d'ampoules de a à c
func _ampoules(b: Kit.Lot, a: Vector3, c: Vector3, nb: int, r: float = 0.09) -> void:
	for k in range(nb):
		b.blob("ampoule", a.lerp(c, (k + 0.5) / nb), Vector3(r, r, r), 5)


## Une semelle de béton sous un pied (elle s'enfonce dans le sol)
func _semelle(b: Kit.Lot, pied: Vector3, r: float = 0.9) -> void:
	b.cyl("dalles", Transform3D(Basis(), Vector3(pied.x, pied.y - 3.2, pied.z)), r, r, 3.6, 10)
	_cols.cyl(Vector3(pied.x, pied.y - 3.2, pied.z), r, 4.2)


## L'enseigne du manège, sur deux poteaux (au point local at, tournée vers face)
func _enseigne(at: Vector3, face: Vector3, nom: String, sous: String) -> void:
	var b := Kit.Lot.new()
	var lac: float = atan2(face.x, face.z)
	var xf := Transform3D(Basis(Vector3.UP, lac), at)
	for sx in [-2.3, 2.3]:
		b.box("bois_blanc", xf * Transform3D(Basis(), Vector3(sx, 1.6, 0)), Vector3(0.16, 3.2, 0.16))
	b.box("bois_bleu", xf * Transform3D(Basis(), Vector3(0, 3.0, 0)), Vector3(5.0, 1.4, 0.14))
	_ampoules(b, xf * Vector3(-2.4, 3.78, 0.1), xf * Vector3(2.4, 3.78, 0.1), 9, 0.07)
	_ampoules(b, xf * Vector3(-2.4, 2.22, 0.1), xf * Vector3(2.4, 2.22, 0.1), 9, 0.07)
	b.commit(self, "Enseigne_%s_v210" % cle, true, 260.0)
	_cols.box(xf * Transform3D(Basis(), Vector3(0, 1.6, 0)), Vector3(5.0, 3.2, 0.3))
	var gf: Vector3 = (global_transform.basis * face).normalized()
	if foraine != null and foraine.has_method("_etiquette"):
		foraine._etiquette(nom, global_transform * (xf * Vector3(0, 3.18, 0.09)), gf, 0.6, Color(1.0, 0.88, 0.35))
		foraine._etiquette(sous, global_transform * (xf * Vector3(0, 2.62, 0.09)), gf, 0.2, Color(1.0, 0.96, 0.85))


# =================================================================== la marche

func joueur_pres() -> bool:
	if main == null or not main.has_method("_player_pos_v27"):
		return false
	var p: Vector3 = main._player_pos_v27()
	return Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() < PRES


func a_quai() -> bool:
	return etat == "quai"


func _process(delta: float) -> void:
	if main == null or _cam == null:
		return
	if main.get("game_started") != null and not bool(main.game_started):
		return
	if not a_bord and not joueur_pres():
		return
	avancer(minf(delta, 0.05))
	_sons_tick()
	if a_bord:
		_porter(delta)


## Un pas de temps (les tests l'appellent aussi, pour faire un tour entier sans attendre)
func avancer(dt: float) -> void:
	if dt <= 0.0:
		return
	if etat == "quai":
		vitesse = 0.0
		attente -= dt
		if attente <= 0.0:
			etat = "marche"
			t = 0.0
			fini = false
			vmax_tour = 0.0
			hmax_tour = 0.0
			gmax_tour = 1.0
			_remise()
			_poser(0.0)
			_oeil_prec = siege().origin
			_v_prec = Vector3.ZERO
			if a_bord and main.has_method("sfx"):
				main.sfx("course_depart", null, -4.0)
		return
	t += dt
	_poser(dt)
	_bruits(dt)
	var o: Vector3 = siege().origin
	var v: Vector3 = (o - _oeil_prec) / dt
	# ce que le corps ressent : l'accélération du siège, plus la pesanteur
	var acc: Vector3 = (v - _v_prec) / dt
	g_ressenti = lerpf(g_ressenti, (acc + Vector3.UP * G).length() / G, 0.5)
	_oeil_prec = o
	_v_prec = v
	vitesse = v.length()
	if t > 0.5:
		vmax_tour = maxf(vmax_tour, vitesse)
		gmax_tour = maxf(gmax_tour, g_ressenti)
	hmax_tour = maxf(hmax_tour, o.y - global_position.y)
	if fini:
		etat = "quai"
		attente = ATTENTE
		t = 0.0
		vitesse = 0.0
		g_ressenti = 1.0
		if a_bord:
			_descendre(true)
		_remise()
		_poser(0.0)
		_oeil_prec = siege().origin


func _sons_tick() -> void:
	var vent: bool = a_bord and etat == "marche"
	if vent and not _vent.playing:
		_vent.play()
	elif not vent and _vent.playing:
		_vent.stop()
	if vent:
		var q: float = clampf(vitesse / 30.0, 0.0, 1.0)
		_vent.volume_db = lerpf(-36.0, -3.0, sqrt(q))
		_vent.pitch_scale = lerpf(0.7, 1.35, q)


# =================================================================== le passager

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
	_cap0 = Huit._cap(siege().basis)
	_porter(0.0)
	return true


func _vue_rendue() -> void:
	a_bord = false
	if _vent != null and _vent.playing:
		_vent.stop()
	if bool(main.get("xr_active")):
		var origine: Node3D = main.xr_origin
		origine.global_transform = Transform3D(Basis(Vector3.UP, Huit._cap(origine.global_transform.basis)), origine.global_position)
		origine.rotation = Vector3(0.0, origine.rotation.y, 0.0)
	else:
		_cam.current = false
		if main.get("pc_camera") != null and main.pc_camera != null:
			main.pc_camera.current = true
		if main.get("hero_v28") != null and main.hero_v28 != null and main.hero_v28.get("hero") != null and main.hero_v28.hero != null:
			(main.hero_v28.hero as Node3D).visible = true


## On descend : le tour est fini, ou bien on a changé d'avis avant le départ
func _descendre(fin_du_tour: bool) -> void:
	_vue_rendue()
	main.place_player_v35(quai_pos, quai_face)
	if fin_du_tour:
		tours += 1
		if main.has_method("sfx"):
			main.sfx("foule_acclame", null, -8.0)
		main._show_message_v28(bilan())


## Une autre partie est chargée pendant le tour : on n'est plus à bord (sans nous déplacer).
func lacher() -> void:
	if a_bord:
		_vue_rendue()


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
	return "%d km/h · %d m" % [int(round(vitesse * 3.6)), int(round(siege().origin.y - global_position.y))]


func lieu_sur() -> Vector3:
	return quai_pos


## Le joueur est assis : sa vue suit le siège.
func _porter(delta: float) -> void:
	var s: Transform3D = siege()
	var base: Basis = s.basis.orthonormalized()
	if doux:
		# en douceur : l'horizon reste droit, on regarde toujours du même côté
		base = Basis(Vector3.UP, _cap0)
	if bool(main.get("xr_active")):
		var ob: Basis = base * Basis(Vector3.UP, -_lacet0)
		var origine: Node3D = main.xr_origin
		origine.global_transform = Transform3D(ob, s.origin - ob * _tete0)
		main.vr_body.global_position = s.origin
		main.vr_body.velocity = Vector3.ZERO
		_vib_t -= delta
		if _vib_t <= 0.0 and etat == "marche":
			_vib_t = 0.1
			var amp: float = clampf(vitesse / 30.0 * 0.2 + absf(g_ressenti - 1.0) * 0.14, 0.0, 0.6)
			for h in [main.get("left_hand"), main.get("right_hand")]:
				if h != null and (h as Node).has_method("trigger_haptic_pulse") and amp > 0.03:
					h.trigger_haptic_pulse("haptic", 0.0, amp, 0.1, 0.0)
	else:
		_cam.global_transform = Transform3D(base, s.origin)
		main.pc_root.position = s.origin - Vector3.UP * 1.0
		main.pc_body.global_position = s.origin
		main.pc_body.velocity = Vector3.ZERO

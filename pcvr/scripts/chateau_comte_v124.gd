extends "res://scripts/enigmes_v69.gd"
## V124 : l'intérieur du château du comte Dracula, en haut de la Butte du Comte, à Sombreval.
## On frappe à la grande porte (avec les cinq pages du docteur Vasseur, ou dix morts-vivants
## repoussés), la herse se lève, on traverse la cour… et on pousse la porte du donjon.
## Dedans (loin sous l'île, comme tous les grands donjons) :
##  1. le Grand Vestibule : un escalier d'honneur qui monte à une galerie, des armures, des
##     candélabres, un lustre, l'horloge arrêtée à minuit, et le portrait du comte qui te regarde.
##     Mortimer, le vieux majordome (un vampire qui ne mord plus), t'accueille et t'explique : la
##     porte de la Tour du Comte, sur la galerie, ne s'ouvre qu'avec les trois rubis de la famille,
##     et chacun des trois enfants du comte en porte un ;
##  2. la Galerie des Portraits : un long couloir, les portraits des disparus de Sombreval, les
##     bougies qui s'éteignent derrière toi, des murmures… et une silhouette qui passe au bout ;
##  3. la Salle de Bal : des vampires valsent au milieu du damier, sous les lustres. La comtesse Ilona
##     est l'une des danseuses : trouve celle qui n'a pas de reflet dans le grand miroir (un vrai
##     miroir : une seconde caméra qui ne voit pas la comtesse) et frappe-la ;
##  4. la Bibliothèque : des livres qui volent, une échelle, un lutrin ; tirer les trois bons livres
##     dans l'ordre du parchemin (la Nuit, les Loups, le Sang) ouvre le cabinet secret du baron
##     Sigismund, qui propose trois devinettes (ou le combat) ;
##  5. la Salle d'Armes (en bas) : le chevalier Radu, invulnérable dans l'ombre ; il faut allumer les
##     quatre braseros (il en souffle un de temps en temps) ;
##  6. la porte de la Tour du Comte : les trois rubis posés, elle s'ouvre sur l'escalier de la tour…
##     et une porte de fer, derrière laquelle le comte attend (la suite : V125).
## L'orage de Sombreval passe par les vitraux (les éclairs, le tonnerre).
## Repère : O, loin sous Sombreval ; l'origine locale est au milieu du sol du vestibule, l'entrée
## au sud (+Z), l'escalier d'honneur au nord (-Z).

const SK = preload("res://scripts/sombreval_kit_v121.gd")
const Pieces = preload("res://scripts/maisons_pieces_v81.gd")
const Vamp = preload("res://scripts/monstre_v124.gd")
const LAYER_SANS_REFLET: int = 1 << 19

## les livres de la bibliothèque : [id, titre, position locale (sur l'étagère), regard]
const LIVRES := [["nuit", "Traité de la Nuit éternelle", Vector3(16.5, 1.33, -13.35), Vector3(0, 0, 1)],
	["etoiles", "Les Étoiles et leurs secrets", Vector3(24.0, 1.0, -13.35), Vector3(0, 0, 1)],
	["loups", "Les Loups des Carpates", Vector3(39.35, 1.33, 9.0), Vector3(-1, 0, 0)],
	["herbier", "Herbier des simples", Vector3(30.0, 1.0, 13.35), Vector3(0, 0, -1)],
	["sang", "Du Sang et des Lignées", Vector3(19.0, 1.66, 13.35), Vector3(0, 0, -1)]]
const ORDRE := ["nuit", "loups", "sang"]
const DEVINETTES := [
	["Je vois tout le monde dans cette maison… sauf les maîtres. Je montre ta droite à gauche et ta gauche à droite. Qui suis-je ?",
		[["miroir", "Le miroir"], ["fenetre", "La fenêtre"], ["portrait", "Le portrait"]], "miroir"],
	["Je n'ai ni bouche ni oreilles, et pourtant je réponds à tout le monde, dans les montagnes et dans les grandes salles vides. Qui suis-je ?",
		[["vent", "Le vent"], ["echo", "L'écho"], ["fantome", "Un fantôme"]], "echo"],
	["Je pars chaque soir et je reviens chaque matin, et Père me fuit comme la peste. Qui suis-je ?",
		[["lune", "La lune"], ["facteur", "Le facteur"], ["soleil", "Le soleil"]], "soleil"],
]
## les braseros de la salle d'armes (locaux)
const BRASEROS := [Vector3(-3.0, -8.0, -34.0), Vector3(19.0, -8.0, -34.0), Vector3(-3.0, -8.0, -56.0), Vector3(19.0, -8.0, -56.0)]

var sv: Node3D                                   # sombreval_v121
var _b                                           # le lot en cours (SK.Batch)
var _flick: Array = []                           # [OmniLight3D, énergie, salle]
var _win_lights: Array = []                      # [OmniLight3D, énergie] : les vitraux (les éclairs)
var _mirror_vp: SubViewport
var _mirror_cam: Camera3D
var _mirror_c := Vector3.ZERO                    # le centre du miroir (monde)
const MIRROR_W: float = 14.0
const MIRROR_H: float = 6.6
var _danseurs: Array = []                        # [monstre, angle, rayon, vitesse]
var _ilona: Node3D
var _sigismund: Node3D
var _radu: Node3D
var _mortimer: Node3D
var _braseros: Array = []                        # Dictionary (kit.brazier63)
var _souffle_t: float = 30.0
var _bookcase: Node3D
var _tower_door: Node3D
var _sockets: Array = []                         # MeshInstance3D des trois chatons de la porte
var _pulled: Array = []                          # les livres tirés, dans l'ordre
var _flying: Array = []                          # [Node3D, centre, rayon, vitesse, phase, hauteur]
var _galerie_lights: Array = []                  # [OmniLight3D, x local, MeshInstance3D flamme]
var _galerie_peur: int = 0
var _riddle: int = 0
var _bal_music: bool = false
var _comte_eyes: StandardMaterial3D
var _clock_pend: Node3D


func _init() -> void:
	key = "chateau_comte"
	titre = "le château du comte"
	O = IleScriptW()
	bbox = AABB(Vector3(-86.0, -12.0, -62.0), Vector3(140.0, 30.0, 80.0))
	room_spawns = {
		"galerie": [["vampire", -44.0, 0.0, 1.2]],
		"biblio": [["vampire", 28.0, 0.0, -6.0]],      # V126 : un seul (deux, dans la pénombre, c'était trop)
		"armes": [["vampire_garde", 2.0, -8.0, -40.0], ["vampire_garde", 14.0, -8.0, -40.0]],
	}


static func IleScriptW() -> Vector3:
	return Vector3(-60.0, -110.0, 2080.0)


func setup(main_node: Node, manager: Node) -> void:
	super.setup(main_node, manager)
	sv = manager


func _defaults() -> Dictionary:
	return {"mortimer": false, "ilona": false, "sigismund": false, "sigismund_paix": false, "radu": false,
		"poses": 0, "tour": false, "biblio_ouverte": false, "bal_vu": false, "radu_vu": false}


func rubis() -> int:
	return int(bool(state["ilona"])) + int(bool(state["sigismund"])) + int(bool(state["radu"]))


func entry() -> Array:
	return [W(Vector3(0, 0.05, 11.2)), Vector3(0, 0, -1)]


func exit_point() -> Array:
	if sv != null and sv.has_method("keep_out_point"):
		return sv.keep_out_point()
	return [Vector3.ZERO, Vector3(0, 0, 1)]


# =================================================================== construction

func ensure_built() -> void:
	if built:
		return
	built = true
	var t0: int = Time.get_ticks_msec()
	kit = Kit.new()
	kit.setup69(self, main, pc)
	kit.body.name = "Collisions_donjon_" + key
	_build()
	_register()
	_apply_state()
	_hide_all(false)
	print("ILE_MANGA_V124: %s construit en %d ms (%d salles)" % [titre, Time.get_ticks_msec() - t0, rooms.size()])


func _build() -> void:
	add_room("hall", Vector3(-12, 0, -15), Vector3(12, 14, 15), Vector3(0, 0.05, 11.0), Vector3(0, 0, -1), ["galerie", "biblio", "escalier", "tour"])
	add_room("galerie", Vector3(-52, 0, -2.5), Vector3(-12, 6, 2.5), Vector3(-14.0, 0.05, 0), Vector3(-1, 0, 0), ["hall", "bal"])
	add_room("bal", Vector3(-82, 0, -14), Vector3(-52, 12, 14), Vector3(-54.5, 0.05, 0), Vector3(-1, 0, 0), ["galerie"])
	add_room("biblio", Vector3(12, 0, -14), Vector3(40, 12, 14), Vector3(14.5, 0.05, 0), Vector3(1, 0, 0), ["hall", "cabinet"])
	add_room("cabinet", Vector3(40, 0, -5), Vector3(50, 5, 5), Vector3(41.5, 0.05, 0), Vector3(1, 0, 0), ["biblio"])
	add_room("escalier", Vector3(6, -8, -31), Vector3(10, 6, -15), Vector3(8.0, 0.05, -16.0), Vector3(0, 0, -1), ["hall", "armes"])
	add_room("armes", Vector3(-6, -8, -59), Vector3(22, 2, -31), Vector3(8.0, -7.95, -33.0), Vector3(0, 0, -1), ["escalier"])
	add_room("tour", Vector3(-3, 6, -22), Vector3(3, 16, -15), Vector3(0, 6.05, -16.0), Vector3(0, 0, -1), ["hall"])
	_build_hall()
	_build_galerie()
	_build_bal()
	_build_biblio()
	_build_cabinet()
	_build_escalier()
	_build_armes()
	_build_tour()
	_fill_lights()


## V126 : une lumière douce, cachée sous les plafonds, dans les grandes salles : on voit les murs,
## les meubles et les vampires ; les bougies gardent leurs halos (rien de tout ça ne vacille)
func _fill_lights() -> void:
	var step: float = 10.0 if pc else 13.0
	for rn in ["hall", "galerie", "bal", "biblio", "armes"]:
		var a: Vector3 = rooms[rn]["a"]
		var b: Vector3 = rooms[rn]["b"]
		var nx: int = maxi(1, int(round((b.x - a.x) / step)))
		var nz: int = maxi(1, int(round((b.z - a.z) / step)))
		var y: float = minf(a.y + 4.2, b.y - 1.2)
		for i in range(nx):
			for k in range(nz):
				var lt := OmniLight3D.new()
				lt.name = "Appoint_v126"
				lt.set_meta("appoint_v126", true)
				lt.light_color = Color(1.0, 0.8, 0.62)
				lt.light_energy = 0.55
				lt.omni_range = step * 1.25
				lt.omni_attenuation = 0.8
				lt.shadow_enabled = false
				lt.light_specular = 0.2
				(rooms[rn]["root"] as Node3D).add_child(lt)
				lt.global_position = W(Vector3(lerpf(a.x, b.x, (i + 0.5) / nx), y, lerpf(a.z, b.z, (k + 0.5) / nz)))


## Une boîte (locale) dessinée dans le lot en cours ; « solid » : avec une collision
func bx(k: String, l: Vector3, size: Vector3, yaw: float = 0.0, solid: bool = false) -> void:
	_b.box(k, X(l, yaw), size)
	if solid:
		kit.col_box(X(l, yaw), size)


func cy(k: String, l: Vector3, r0: float, r1: float, h: float, sides: int = 12) -> void:
	_b.cyl(k, X(l), r0, r1, h, sides)


func _commit(room_n: String, label: String) -> void:
	_b.commit(rooms[room_n]["root"], label, true)
	_b = SK.Batch.new()


## Les murs d'une salle : un soubassement (low, 1,2 m) et le haut (high) ; des ouvertures
## [côté (« n » -Z, « s » +Z, « e » +X, « w » -X), centre, largeur, hauteur]
func walls(x0: float, x1: float, z0: float, z1: float, y0: float, h: float, low: String, high: String, openings: Array = [], t: float = 0.6) -> void:
	for side in ["n", "s", "e", "w"]:
		var along_x: bool = side in ["n", "s"]
		var a0: float = (x0 - t) if along_x else z0
		var a1: float = (x1 + t) if along_x else z1
		var fixed: float = (z0 - t * 0.5) if side == "n" else ((z1 + t * 0.5) if side == "s" else ((x1 + t * 0.5) if side == "e" else (x0 - t * 0.5)))
		var gaps: Array = []
		for o in openings:
			if str(o[0]) == side:
				gaps.append([float(o[1]) - float(o[2]) * 0.5, float(o[1]) + float(o[2]) * 0.5, float(o[3])])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		var cur: float = a0
		for g in gaps:
			if g[0] > cur:
				_wall_seg(along_x, fixed, cur, g[0], y0, h, t, low, high)
			if float(g[2]) < h:
				_wall_seg(along_x, fixed, g[0], g[1], y0 + float(g[2]), h - float(g[2]), t, high, high)
			cur = g[1]
		if cur < a1:
			_wall_seg(along_x, fixed, cur, a1, y0, h, t, low, high)


func _wall_seg(along_x: bool, fixed: float, a: float, b: float, y0: float, h: float, t: float, low: String, high: String) -> void:
	if b - a < 0.01 or h < 0.01:
		return
	var mid: float = (a + b) * 0.5
	var len: float = b - a
	var c: Vector3 = Vector3(mid, 0, fixed) if along_x else Vector3(fixed, 0, mid)
	var sz := Vector3(len, h, t) if along_x else Vector3(t, h, len)
	kit.col_box(X(c + Vector3.UP * (y0 + h * 0.5)), sz)
	var lh: float = minf(1.25, h) if low != high else 0.0
	if lh > 0.0:
		var s1 := Vector3(len, lh, t + 0.04) if along_x else Vector3(t + 0.04, lh, len)
		bx(low, c + Vector3.UP * (y0 + lh * 0.5), s1)
		# la cimaise dorée au-dessus du soubassement
		var s3 := Vector3(len, 0.06, t + 0.1) if along_x else Vector3(t + 0.1, 0.06, len)
		bx("dorure_terne", c + Vector3.UP * (y0 + lh), s3)
	var s2 := Vector3(len, h - lh, t) if along_x else Vector3(t, h - lh, len)
	bx(high, c + Vector3.UP * (y0 + lh + (h - lh) * 0.5), s2)


func floor_ceil(x0: float, x1: float, z0: float, z1: float, y0: float, h: float, fk: String, ck: String) -> void:
	var c := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	var sz := Vector3(x1 - x0 + 1.2, 0.5, z1 - z0 + 1.2)
	bx(fk, c + Vector3.UP * (y0 - 0.25), sz, 0.0, true)
	if ck != "":
		bx(ck, c + Vector3.UP * (y0 + h + 0.25), sz, 0.0, true)


## Un encadrement de porte (pierre claire) et une arche en anse de panier, dans le mur (yaw : la
## porte regarde +Z local tourné de yaw)
func doorway(l: Vector3, yaw: float, w: float, h: float, k: String = "pierre_chateau_claire") -> void:
	var bs := Basis(Vector3.UP, yaw)
	for s in [-1.0, 1.0]:
		bx(k, l + bs * Vector3(s * (w * 0.5 + 0.18), h * 0.5, 0), Vector3(0.36, h, 0.9), yaw)
	bx(k, l + bs * Vector3(0, h + 0.2, 0), Vector3(w + 0.72, 0.4, 0.9), yaw)
	bx("dorure_terne", l + bs * Vector3(0, h + 0.44, 0), Vector3(w * 0.3, 0.12, 0.95), yaw)


# ------------------------------------------------------------------- les éclairages

## Une flamme de bougie (une petite goutte lumineuse) et sa bougie
func candle(l: Vector3, h: float = 0.22) -> void:
	cy("cire", l, 0.022, 0.02, h, 8)
	_b.blob("bougie", O + l + Vector3.UP * (h + 0.03), Vector3(0.012, 0.03, 0.012), 6)


func light(room_n: String, l: Vector3, energy: float, rng: float, col: Color = Color(1.0, 0.68, 0.38), shadow: bool = false) -> OmniLight3D:
	var lt := OmniLight3D.new()
	lt.light_color = col
	lt.light_energy = energy
	# V126 : les flammes portent plus loin (le vrai jeu était bien plus sombre que les essais)
	lt.omni_range = rng * 1.35
	lt.omni_attenuation = 1.0
	lt.shadow_enabled = shadow and pc
	(rooms[room_n]["root"] as Node3D).add_child(lt)
	lt.global_position = W(l)
	_flick.append([lt, energy, room_n])
	return lt


## Un candélabre sur pied : cinq bougies
func candelabre(room_n: String, l: Vector3, lit: bool = true) -> OmniLight3D:
	cy("dorure", l, 0.18, 0.14, 0.06, 10)
	cy("dorure", l + Vector3.UP * 0.06, 0.03, 0.025, 1.45, 8)
	cy("dorure", l + Vector3.UP * 1.48, 0.11, 0.05, 0.05, 10)
	for k in range(5):
		var a: float = TAU * k / 5.0
		var p: Vector3 = l + Vector3(cos(a) * 0.17, 1.5, sin(a) * 0.17)
		_b.tube("dorure", O + l + Vector3.UP * 1.5, O + p, 0.012, 5)
		cy("dorure", p, 0.03, 0.035, 0.03, 8)
		if lit:
			candle(p + Vector3.UP * 0.03)
		else:
			cy("cire", p + Vector3.UP * 0.03, 0.022, 0.02, 0.12, 8)
	kit.col_cyl(W(l), 0.2, 1.6)
	if lit:
		return light(room_n, l + Vector3.UP * 1.9, 1.2, 7.0)
	return null


## Une applique murale (deux bougies) ; « out » : la direction de la salle
func applique(room_n: String, l: Vector3, out: Vector3, lit: bool = true) -> OmniLight3D:
	var side: Vector3 = out.cross(Vector3.UP)
	bx("dorure", l, Vector3(0.16, 0.26, 0.06), atan2(out.x, out.z))
	for s in [-1.0, 1.0]:
		var p: Vector3 = l + out * 0.2 + side * (s * 0.14) + Vector3.UP * 0.05
		_b.tube("dorure", O + l + out * 0.03, O + p, 0.012, 5)
		cy("dorure", p, 0.03, 0.035, 0.025, 8)
		if lit:
			candle(p + Vector3.UP * 0.025, 0.16)
	if lit:
		return light(room_n, l + out * 0.35 + Vector3.UP * 0.3, 0.75, 5.5)
	return null


## Un lustre : un cercle de fer forgé, des bougies, la chaîne jusqu'au plafond
func lustre(room_n: String, l: Vector3, r: float, ceil_y: float, lit: bool = true) -> void:
	_b.tube("fer_noir", O + l + Vector3.UP * 0.6, O + Vector3(l.x, ceil_y, l.z), 0.025, 6)
	for k in range(4):
		var a: float = TAU * k / 4.0
		_b.tube("fer_noir", O + l + Vector3.UP * 0.6, O + l + Vector3(cos(a) * r, 0.0, sin(a) * r), 0.018, 5)
	var n: int = int(r * 10.0)
	for k2 in range(n):
		var a0: float = TAU * k2 / n
		var a1: float = TAU * (k2 + 1) / n
		_b.tube("fer_noir", O + l + Vector3(cos(a0) * r, 0, sin(a0) * r), O + l + Vector3(cos(a1) * r, 0, sin(a1) * r), 0.03, 5)
		if k2 % 2 == 0:
			var p: Vector3 = l + Vector3(cos(a0) * r, 0.03, sin(a0) * r)
			if lit:
				candle(p, 0.18)
			else:
				cy("cire", p, 0.022, 0.02, 0.1, 6)
	if lit:
		light(room_n, l + Vector3.DOWN * 0.3, 2.6, 13.0, Color(1.0, 0.7, 0.42), true)


## Un vitrail (l : son centre, out : vers la salle) ; une lueur froide (la lune), que les éclairs
## illuminent
func vitrail(room_n: String, l: Vector3, out: Vector3, w: float, h: float) -> void:
	var yaw: float = atan2(out.x, out.z)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	mi.material_override = SK.mat("vitrail_comte")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(rooms[room_n]["root"] as Node3D).add_child(mi)
	mi.global_transform = X(l + out * 0.02, yaw)
	var bs := Basis(Vector3.UP, yaw)
	bx("pierre_chateau_claire", l + out * 0.05 + Vector3.DOWN * (h * 0.5 + 0.1), Vector3(w + 0.5, 0.2, 0.3), yaw)
	for s in [-1.0, 1.0]:
		bx("pierre_chateau_claire", l + out * 0.05 + bs * Vector3(s * (w * 0.5 + 0.12), 0, 0), Vector3(0.24, h, 0.2), yaw)
	var lt := OmniLight3D.new()
	lt.light_color = Color(0.5, 0.56, 0.85)
	lt.light_energy = 0.35
	lt.omni_range = h * 1.4
	lt.shadow_enabled = false
	(rooms[room_n]["root"] as Node3D).add_child(lt)
	lt.global_position = W(l + out * 1.2)
	_win_lights.append([lt, 0.35])


## Un tableau (cadre doré, toile) ; « tex » : une texture (ou rien : le vieux paysage de nuit)
func tableau(room_n: String, l: Vector3, out: Vector3, w: float, h: float, tex: Texture2D = null, tint: Color = Color(1, 1, 1)) -> MeshInstance3D:
	var yaw: float = atan2(out.x, out.z)
	var bs := Basis(Vector3.UP, yaw)
	var fw: float = 0.09
	for s in [-1.0, 1.0]:
		bx("dorure", l + bs * Vector3(s * (w * 0.5 + fw * 0.5), 0, 0.04), Vector3(fw, h + fw * 2.0, 0.08), yaw)
		bx("dorure", l + bs * Vector3(0, s * (h * 0.5 + fw * 0.5), 0.04), Vector3(w, fw, 0.08), yaw)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex if tex != null else _tex("res://assets/textures/chateau/toile_peinte.png")
	m.albedo_color = tint
	m.roughness = 0.55
	mi.material_override = m
	(rooms[room_n]["root"] as Node3D).add_child(mi)
	mi.global_transform = X(l + out * 0.03, yaw)
	return mi


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Une armure de chevalier sur son socle (vide… sans doute)
func armure_statue(l: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	bx("pierre_chateau_claire", l + Vector3.UP * 0.15, Vector3(0.8, 0.3, 0.8), yaw, true)
	var b0: Vector3 = l + Vector3.UP * 0.3
	for s in [-1.0, 1.0]:
		cy("acier", b0 + bs * Vector3(s * 0.12, 0, 0), 0.075, 0.09, 0.85, 10)
		cy("acier", b0 + bs * Vector3(s * 0.12, 0.85, 0), 0.09, 0.11, 0.1, 10)
	cy("acier", b0 + Vector3.UP * 0.9, 0.2, 0.24, 0.62, 14)
	cy("acier", b0 + Vector3.UP * 1.52, 0.24, 0.13, 0.12, 14)
	for s in [-1.0, 1.0]:
		_b.blob("acier", O + b0 + bs * Vector3(s * 0.3, 1.45, 0), Vector3(0.13, 0.1, 0.13), 8)
		_b.tube("acier", O + b0 + bs * Vector3(s * 0.33, 1.38, 0), O + b0 + bs * Vector3(s * 0.36, 0.95, 0.06), 0.06, 8)
	_b.blob("acier", O + b0 + Vector3.UP * 1.8, Vector3(0.14, 0.17, 0.15), 10)
	bx("acier_noir", b0 + Vector3.UP * 1.82 + bs * Vector3(0, 0, 0.13), Vector3(0.16, 0.025, 0.03), yaw)
	# la hallebarde
	_b.tube("bois_sombre", O + b0 + bs * Vector3(0.42, -0.25, 0.1), O + b0 + bs * Vector3(0.42, 2.2, 0.1), 0.022, 6)
	bx("acier", b0 + bs * Vector3(0.42, 2.0, 0.1), Vector3(0.04, 0.4, 0.22), yaw)
	kit.col_box(X(l + Vector3.UP * 1.1, yaw), Vector3(0.7, 2.2, 0.6))


## Des toiles d'araignée dans un coin (quad transparent)
func toile(room_n: String, l: Vector3, yaw: float, s: float = 1.2) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(s, s)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = Pieces.cobweb_texture()
	m.albedo_color = Color(0.85, 0.85, 0.82, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(rooms[room_n]["root"] as Node3D).add_child(mi)
	mi.global_transform = X(l, yaw) * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO)


## Une rangée d'étagères pleines de livres, le long d'un mur (de a à b, locales, au sol), « out »
## vers la salle ; h : la hauteur
func etageres(a: Vector3, b: Vector3, out: Vector3, h: float) -> void:
	var d: Vector3 = b - a
	var len: float = d.length()
	var yaw: float = atan2(out.x, out.z)
	var mid: Vector3 = (a + b) * 0.5
	# le fond : les dos des livres (trois rangées par mètre : la texture est calée sur le monde)
	bx("livres", mid + Vector3.UP * (h * 0.5) - out * 0.2, Vector3(len, h, 0.02) if absf(out.z) > 0.5 else Vector3(0.02, h, len), 0.0)
	var t3: float = 1.0 / 3.0
	var y: float = 0.0
	while y <= h + 0.01:
		var sz := Vector3(len, 0.04, 0.42) if absf(out.z) > 0.5 else Vector3(0.42, 0.04, len)
		bx("bois_cire", mid + Vector3.UP * (y + 0.02) - out * 0.02, sz)
		y += t3
	var n: int = int(len / 1.2)
	for k in range(n + 1):
		var p: Vector3 = a + d * (float(k) / maxf(n, 1))
		var sz2 := Vector3(0.06, h, 0.44) if absf(out.z) > 0.5 else Vector3(0.44, h, 0.06)
		bx("bois_cire", p + Vector3.UP * (h * 0.5) - out * 0.02, sz2)
	var sz3 := Vector3(len + 0.2, 0.18, 0.5) if absf(out.z) > 0.5 else Vector3(0.5, 0.18, len + 0.2)
	bx("bois_cire", mid + Vector3.UP * (h + 0.09), sz3)
	kit.col_box(X(mid + Vector3.UP * (h * 0.5) - out * 0.02), Vector3(len, h, 0.44) if absf(out.z) > 0.5 else Vector3(0.44, h, len))


func table(l: Vector3, w: float, d: float, yaw: float = 0.0, k: String = "bois_cire", nappe: bool = false) -> void:
	var bs := Basis(Vector3.UP, yaw)
	bx(k, l + Vector3.UP * 0.76, Vector3(w, 0.06, d), yaw, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			bx(k, l + bs * Vector3(sx * (w * 0.5 - 0.08), 0.37, sz * (d * 0.5 - 0.08)), Vector3(0.08, 0.74, 0.08), yaw)
	if nappe:
		bx("nappe", l + Vector3.UP * 0.6, Vector3(w + 0.06, 0.36, d + 0.06), yaw)


func chaise(l: Vector3, yaw: float, k: String = "bois_cire") -> void:
	var bs := Basis(Vector3.UP, yaw)
	bx("velours", l + Vector3.UP * 0.46, Vector3(0.46, 0.06, 0.46), yaw)
	bx(k, l + bs * Vector3(0, 0.95, -0.21), Vector3(0.46, 0.9, 0.05), yaw)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			bx(k, l + bs * Vector3(sx * 0.19, 0.22, sz * 0.19), Vector3(0.05, 0.44, 0.05), yaw)


func fauteuil(l: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	bx("velours", l + Vector3.UP * 0.25, Vector3(0.85, 0.42, 0.8), yaw, true)
	bx("velours", l + bs * Vector3(0, 0.85, -0.34), Vector3(0.85, 1.2, 0.16), yaw)
	for s in [-1.0, 1.0]:
		bx("velours", l + bs * Vector3(s * 0.38, 0.6, 0.0), Vector3(0.12, 0.3, 0.78), yaw)
	bx("dorure_terne", l + bs * Vector3(0, 1.47, -0.34), Vector3(0.9, 0.06, 0.18), yaw)


## Une cheminée de pierre (froide ; « lit » : allumée)
func cheminee(room_n: String, l: Vector3, out: Vector3, lit: bool) -> void:
	var yaw: float = atan2(out.x, out.z)
	var bs := Basis(Vector3.UP, yaw)
	bx("pierre_chateau_claire", l + bs * Vector3(0, 1.4, -0.2), Vector3(2.6, 0.25, 0.8), yaw)
	for s in [-1.0, 1.0]:
		bx("pierre_chateau_claire", l + bs * Vector3(s * 1.1, 0.65, -0.2), Vector3(0.4, 1.3, 0.8), yaw, true)
	bx("pierre_int", l + bs * Vector3(0, 2.6, -0.45), Vector3(2.2, 2.2, 0.5), yaw)
	bx("interieur", l + bs * Vector3(0, 0.65, -0.5), Vector3(1.8, 1.3, 0.1), yaw)
	bx("pierre_chateau_claire", l + bs * Vector3(0, 0.04, 0.1), Vector3(2.8, 0.08, 1.0), yaw)
	for k in range(3):
		_b.tube("bois_sombre", O + l + bs * Vector3(-0.5 + k * 0.5, 0.12, -0.25), O + l + bs * Vector3(-0.3 + k * 0.4, 0.14, 0.05), 0.06, 6)
	if lit:
		var f: CPUParticles3D = kit.fire(rooms[room_n]["root"], W(l + bs * Vector3(0, 0.2, -0.15)), 0.35, 24)
		f.emitting = true
		light(room_n, l + bs * Vector3(0, 0.8, 0.6), 1.8, 8.0, Color(1.0, 0.55, 0.25))


# =================================================================== le Grand Vestibule

func _build_hall() -> void:
	_b = SK.Batch.new()
	floor_ceil(-12, 12, -15, 15, 0, 14, "dalles_int", "lambris")
	walls(-12, 12, -15, 15, 0, 14, "pierre_int", "pierre_int", [["s", 0, 3.6, 5.5], ["w", 0, 3.0, 4.2], ["e", 0, 3.0, 4.2], ["n", 8, 2.6, 3.4], ["n", 0, 3.6, 14.0]])
	# le mur nord, au-dessus et au-dessous de la porte de la tour (sur la galerie, à 6 m)
	bx("pierre_int", Vector3(0, 3.0, -15.3), Vector3(3.6, 6.0, 0.6), 0.0, true)
	bx("pierre_int", Vector3(0, 12.3, -15.3), Vector3(3.6, 3.4, 0.6), 0.0, true)
	# l'arc du portail d'entrée, les deux autres portes
	doorway(Vector3(0, 0, 15.0), 0.0, 3.6, 5.5)
	doorway(Vector3(-12.0, 0, 0), PI * 0.5, 3.0, 4.2)
	doorway(Vector3(12.0, 0, 0), PI * 0.5, 3.0, 4.2)
	doorway(Vector3(8.0, 0, -15.0), 0.0, 2.6, 3.4)
	# les poutres du plafond
	for z in range(-12, 15, 4):
		bx("bois_sombre", Vector3(0, 13.7, z), Vector3(24.2, 0.55, 0.45))
	# le grand tapis rouge, de la porte à l'escalier
	bx("tapis_rouge", Vector3(0, 0.01, 7.5), Vector3(3.4, 0.02, 15.0))
	# l'escalier d'honneur (marches de pierre, tapis rouge, rampes de fer), jusqu'à la galerie
	var steps: int = 27
	for i in range(steps):
		var z: float = 1.0 - (i + 0.5) * (12.0 / steps)
		var top: float = (i + 1) * (6.0 / steps)
		bx("pierre_chateau_claire", Vector3(0, top * 0.5, z), Vector3(5.6, top, 12.0 / steps + 0.01))
		bx("tapis_rouge", Vector3(0, top + 0.005, z), Vector3(3.4, 0.012, 12.0 / steps + 0.01))
	var rise: float = 6.0
	var run: float = 12.0
	var slope: float = atan2(rise, run)
	var cb := Basis(Vector3.RIGHT, slope)
	kit.col_box(X(Vector3(0, 3.0 - 0.15 * cos(slope), -5.0)) * Transform3D(cb, Vector3.ZERO), Vector3(5.6, 0.3, sqrt(rise * rise + run * run) + 0.2))
	# V126 : le dessous de l'escalier est plein (avant, on y entrait par les côtés et la caméra
	# restait enfermée dans la pierre : écran noir) ; chaque bloc reste sous la rampe
	for k5 in range(1, 6):
		var low_y: float = float(k5) * 1.0 - 0.2
		kit.col_box(X(Vector3(0, low_y * 0.5, 1.0 - 2.0 * k5 - 1.0)), Vector3(6.0, low_y, 2.0))
	for s in [-1.0, 1.0]:
		# les flancs pleins de l'escalier, la rampe
		bx("pierre_chateau_claire", Vector3(s * 2.95, 3.0, -5.0), Vector3(0.3, 0.2, 13.4), 0.0)
		for k in range(14):
			var t: float = (k + 0.5) / 14.0
			var bp := Vector3(s * 2.75, t * 6.0, 1.0 - t * 12.0)
			_b.tube("fer_noir", O + bp, O + bp + Vector3.UP * 1.0, 0.02, 5)
		_b.tube("dorure_terne", O + Vector3(s * 2.75, 1.0, 1.0), O + Vector3(s * 2.75, 7.0, -11.0), 0.035, 6)
		kit.col_box(X(Vector3(s * 2.9, 3.5, -5.0)) * Transform3D(cb, Vector3.ZERO), Vector3(0.2, 1.4, 13.4))
		# le dessous de l'escalier : un mur plein
		for i2 in range(6):
			var zz: float = 1.0 - (i2 + 0.5) * 2.0
			var hh: float = (i2 + 0.5) * 1.0
			bx("pierre_int", Vector3(s * 2.75, hh * 0.5, zz), Vector3(0.12, hh, 2.0))
		armure_statue(Vector3(s * 4.2, 0, 2.0), 0.0)
		candelabre("hall", Vector3(s * 3.4, 0, 3.2))
	# la galerie (y = 6), le long du mur nord ; sa balustrade, ses piliers
	bx("parquet", Vector3(0, 5.85, -13.0), Vector3(24.0, 0.3, 4.0), 0.0, true)
	bx("bois_cire", Vector3(0, 5.6, -11.05), Vector3(24.0, 0.5, 0.15))
	for x in [-11.0, -7.0, -3.2, 3.2, 7.0, 11.0]:
		bx("pierre_chateau_claire", Vector3(x, 2.85, -11.2), Vector3(0.5, 5.7, 0.5), 0.0, true)
	for x2 in range(-11, 12):
		if absf(x2) < 2.9:
			continue
		_b.tube("fer_noir", O + Vector3(x2, 6.0, -11.15), O + Vector3(x2, 7.0, -11.15), 0.02, 5)
	for seg in [[-12.0, -2.8], [2.8, 12.0]]:
		var cxm: float = (seg[0] + seg[1]) * 0.5
		bx("dorure_terne", Vector3(cxm, 7.02, -11.15), Vector3(seg[1] - seg[0], 0.06, 0.1))
		kit.col_box(X(Vector3(cxm, 6.6, -11.15)), Vector3(seg[1] - seg[0], 1.2, 0.15))
	# la porte de la Tour du Comte (au milieu du mur nord, sur la galerie) : construite à part
	bx("pierre_chateau_claire", Vector3(0, 6.0 + 4.9, -14.85), Vector3(4.6, 0.6, 0.6))
	for s2 in [-1.0, 1.0]:
		bx("pierre_chateau_claire", Vector3(s2 * 2.0, 6.0 + 2.3, -14.85), Vector3(0.5, 4.6, 0.6))
	# le portrait du comte, au-dessus de la porte de la tour
	_commit("hall", "Vestibule_v124")
	var pc_tex: Texture2D = _tex("res://assets/textures/chateau/portrait_comte.png")
	tableau("hall", Vector3(0, 6.0 + 7.2, -14.55), Vector3(0, 0, 1), 2.6, 3.4, pc_tex)
	_comte_eyes = StandardMaterial3D.new()
	_comte_eyes.albedo_color = Color(0.3, 0.0, 0.0)
	_comte_eyes.emission_enabled = true
	_comte_eyes.emission = Color(1.0, 0.04, 0.02)
	_comte_eyes.emission_energy_multiplier = 0.0
	for s3 in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.028
		em.height = 0.04
		eye.mesh = em
		eye.material_override = _comte_eyes
		(rooms["hall"]["root"] as Node3D).add_child(eye)
		eye.global_position = W(Vector3(s3 * 0.142, 6.0 + 7.2 + 0.73, -14.5))
	# les vitraux (est et ouest, en haut) ; le lustre ; les appliques
	for z2 in [-6.0, 6.0]:
		vitrail("hall", Vector3(-11.68, 9.5, z2), Vector3(1, 0, 0), 2.2, 4.4)
		vitrail("hall", Vector3(11.68, 9.5, z2), Vector3(-1, 0, 0), 2.2, 4.4)
	lustre("hall", Vector3(0, 9.0, 4.0), 1.6, 14.0)
	for z3 in [-8.0, 8.0]:
		applique("hall", Vector3(-11.65, 2.8, z3), Vector3(1, 0, 0))
		applique("hall", Vector3(11.65, 2.8, z3), Vector3(-1, 0, 0))
	applique("hall", Vector3(-6.0, 8.2, -14.65), Vector3(0, 0, 1))
	applique("hall", Vector3(6.0, 8.2, -14.65), Vector3(0, 0, 1))
	# l'horloge arrêtée à minuit, les tableaux, les toiles d'araignée
	_horloge(Vector3(-10.9, 0, -9.0))
	tableau("hall", Vector3(-11.65, 3.6, 6.0), Vector3(1, 0, 0), 1.5, 1.9)
	tableau("hall", Vector3(11.65, 3.6, 6.0), Vector3(-1, 0, 0), 1.5, 1.9, null, Color(0.8, 0.75, 0.8))
	toile("hall", Vector3(-11.5, 13.3, 14.5), PI * 0.75, 2.0)
	toile("hall", Vector3(11.5, 13.3, -14.5), -PI * 0.25, 2.0)
	toile("hall", Vector3(11.5, 13.3, 14.5), PI * 0.25 + PI * 0.5, 1.6)
	_b = SK.Batch.new()
	# les bannières rouge sombre entre les vitraux
	for s4 in [-1.0, 1.0]:
		bx("tissu_rouge_sombre", Vector3(s4 * 11.66, 9.0, 0), Vector3(0.03, 6.0, 1.6))
		bx("dorure_terne", Vector3(s4 * 11.6, 12.05, 0), Vector3(0.08, 0.08, 1.9))
	_commit("hall", "Vestibule_deco_v124")
	_build_tower_door()


## L'horloge du vestibule : arrêtée sur minuit (comme toutes celles de la ville)
func _horloge(l: Vector3) -> void:
	bx("bois_cire", l + Vector3.UP * 1.1, Vector3(0.6, 2.2, 0.45), PI * 0.5, true)
	bx("bois_cire", l + Vector3.UP * 2.35, Vector3(0.7, 0.3, 0.52), PI * 0.5)
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.22
	cm.height = 0.02
	face.mesh = cm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.82, 0.78, 0.66)
	fm.roughness = 0.4
	face.material_override = fm
	(rooms["hall"]["root"] as Node3D).add_child(face)
	face.global_transform = X(l + Vector3(0.24, 1.85, 0)) * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3.ZERO)
	for a in [0.0, 0.02]:
		bx("fer_noir", l + Vector3(0.26, 1.85 + 0.1, 0), Vector3(0.01, 0.2 - a * 3.0, 0.015 + a))
	_clock_pend = Node3D.new()
	(rooms["hall"]["root"] as Node3D).add_child(_clock_pend)
	_clock_pend.global_position = W(l + Vector3(0.24, 1.55, 0))
	var pend := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.08
	pm.bottom_radius = 0.08
	pm.height = 0.02
	pend.mesh = pm
	pend.material_override = SK.mat("dorure")
	pend.rotation = Vector3(0, 0, PI * 0.5)
	pend.position = Vector3(0, -0.85, 0)
	_clock_pend.add_child(pend)


## La porte de la Tour du Comte : deux battants de chêne noir cerclés de fer, trois chatons vides
func _build_tower_door() -> void:
	_tower_door = Node3D.new()
	_tower_door.name = "Porte_tour"
	(rooms["hall"]["root"] as Node3D).add_child(_tower_door)
	_tower_door.global_transform = X(Vector3(0, 6.0, -14.8))
	for s in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.name = "Battant_%d" % (0 if s < 0 else 1)
		leaf.position = Vector3(s * 1.75, 0, 0)
		_tower_door.add_child(leaf)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.75, 4.6, 0.18)
		mi.mesh = bm
		mi.material_override = SK.mat("bois_sombre")
		mi.position = Vector3(-s * 0.875, 2.3, 0)
		leaf.add_child(mi)
		for yy in [0.7, 2.3, 3.9]:
			var band := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(1.7, 0.1, 0.22)
			band.mesh = bb
			band.material_override = SK.mat("fer_noir")
			band.position = Vector3(-s * 0.875, yy, 0)
			leaf.add_child(band)
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.6, 4.6, 0.4)
	cs.shape = sh
	cs.position = Vector3(0, 2.3, 0)
	sb.add_child(cs)
	_tower_door.add_child(sb)
	# les trois chatons (un rubis par enfant du comte)
	for k in range(3):
		var sock := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.11
		sp.height = 0.16
		sock.mesh = sp
		sock.material_override = SK.mat("rubis_eteint")
		sock.position = Vector3(-0.7 + k * 0.7, 4.95, 0.3)
		_tower_door.add_child(sock)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.12
		tm.outer_radius = 0.17
		ring.mesh = tm
		ring.material_override = SK.mat("dorure")
		ring.rotation = Vector3(PI * 0.5, 0, 0)
		ring.position = sock.position
		_tower_door.add_child(ring)
		_sockets.append(sock)


func _show_tower(open: bool, animate: bool) -> void:
	if _tower_door == null:
		return
	var n: int = int(state["poses"])
	for k in range(_sockets.size()):
		(_sockets[k] as MeshInstance3D).material_override = SK.mat("rubis" if k < n else "rubis_eteint")
	var sb: StaticBody3D = _tower_door.get_node("Corps")
	for s in [0, 1]:
		var leaf: Node3D = _tower_door.get_node("Battant_%d" % s)
		var target: float = (1.0 if s == 0 else -1.0) * (1.75 if open else 0.0)
		if animate:
			create_tween().tween_property(leaf, "rotation:y", target, 3.0).set_trans(Tween.TRANS_SINE)
		else:
			leaf.rotation.y = target
	sb.collision_layer = 0 if open else 1


# =================================================================== la Galerie des Portraits

const DISPARUS := ["abdellah", "adele", "agathe", "ambroise", "anselme", "aristide", "aubin", "augustin", "babette", "bastien", "bernard", "berthe",
	"bertrand", "bruno", "anne_rose", "barthelemy", "brahim", "amine"]


func _build_galerie() -> void:
	_b = SK.Batch.new()
	floor_ceil(-52, -12, -2.5, 2.5, 0, 6, "parquet", "lambris")
	walls(-52, -12, -2.5, 2.5, 0, 6, "lambris", "damas", [["e", 0, 6.0, 6.0], ["w", 0, 6.0, 6.0]])
	bx("tapis_rouge", Vector3(-32, 0.01, 0), Vector3(39.0, 0.02, 2.2))
	for x in range(-50, -12, 4):
		bx("bois_sombre", Vector3(x, 5.75, 0), Vector3(0.35, 0.5, 5.2))
	_commit("galerie", "Galerie_v124")
	# les portraits des disparus (des deux côtés), les appliques entre eux
	var k: int = 0
	for x in range(-48, -14, 4):
		for s in [-1.0, 1.0]:
			var id: String = DISPARUS[k % DISPARUS.size()]
			k += 1
			var tex: Texture2D = _tex("res://assets/textures/portraits/%s.png" % id)
			# les portraits ont jauni (un vernis ancien), on les voit à peine
			tableau("galerie", Vector3(float(x) + 2.0, 2.6, s * 2.47), Vector3(0, 0, -s), 0.95, 1.2, tex, Color(0.72, 0.62, 0.52))
	_b = SK.Batch.new()
	for x2 in range(-50, -12, 4):
		var s2: float = 1.0 if (x2 / 4) % 2 == 0 else -1.0
		var lt: OmniLight3D = applique("galerie", Vector3(float(x2), 2.8, s2 * 2.45), Vector3(0, 0, -s2))
		_galerie_lights.append([lt, float(x2)])
	toile("galerie", Vector3(-51.5, 5.5, 2.0), PI * 0.75, 1.2)
	toile("galerie", Vector3(-13.0, 5.5, -2.0), -PI * 0.25, 1.0)
	_commit("galerie", "Galerie_deco_v124")


# =================================================================== la Salle de Bal

func _build_bal() -> void:
	_b = SK.Batch.new()
	floor_ceil(-82, -52, -14, 14, 0, 12, "marbre_damier", "lambris")
	walls(-82, -52, -14, 14, 0, 12, "lambris", "damas", [["e", 0, 3.0, 4.2]])
	doorway(Vector3(-52.0, 0, 0), PI * 0.5, 3.0, 4.2)
	# les pilastres dorés, la corniche
	for z in [-12.0, -6.0, 6.0, 12.0]:
		bx("pierre_chateau_claire", Vector3(-81.6, 6.0, z), Vector3(0.5, 12.0, 0.7))
		bx("pierre_chateau_claire", Vector3(-52.4, 6.0, z), Vector3(0.5, 12.0, 0.7))
	for x in [-77.0, -71.0, -63.0, -57.0]:
		bx("pierre_chateau_claire", Vector3(x, 6.0, -13.6), Vector3(0.7, 12.0, 0.5))
		bx("pierre_chateau_claire", Vector3(x, 6.0, 13.6), Vector3(0.7, 12.0, 0.5))
	bx("dorure_terne", Vector3(-67.0, 11.7, -13.9), Vector3(30.0, 0.3, 0.3))
	bx("dorure_terne", Vector3(-67.0, 11.7, 13.9), Vector3(30.0, 0.3, 0.3))
	# l'estrade des musiciens (vide : la musique joue toute seule…), un clavecin couvert d'un drap
	bx("parquet", Vector3(-55.0, 0.2, -10.0), Vector3(5.0, 0.4, 7.0), 0.0, true)
	bx("drap_poussiere", Vector3(-55.0, 1.0, -10.5), Vector3(1.0, 1.0, 2.2), 0.2, true)
	for s in [-1.0, 1.0]:
		chaise(Vector3(-56.0, 0.4, -8.0 + s * 1.0), PI * 0.5)
	# des fauteuils et des tables le long des murs, sous des draps
	for z2 in [-9.0, 9.0]:
		fauteuil(Vector3(-80.0, 0, z2), PI * 0.5)
		fauteuil(Vector3(-80.0, 0, z2 + 1.4), PI * 0.5)
	table(Vector3(-67.0, 0, 12.4), 6.0, 1.0, 0.0, "bois_cire", true)
	for i in range(5):
		cy("dorure", Vector3(-69.4 + i * 1.2, 0.79, 12.4), 0.04, 0.03, 0.18, 8)
	_commit("bal", "Bal_v124")
	# les rideaux de velours, les vitraux (nord et sud), les lustres
	_b = SK.Batch.new()
	for x2 in [-74.0, -67.0, -60.0]:
		vitrail("bal", Vector3(x2, 6.0, -13.68), Vector3(0, 0, 1), 2.4, 5.2)
		vitrail("bal", Vector3(x2, 6.0, 13.68), Vector3(0, 0, -1), 2.4, 5.2)
		for s2 in [-1.0, 1.0]:
			bx("velours", Vector3(x2 + s2 * 1.55, 5.8, -13.45), Vector3(0.7, 9.2, 0.12))
			bx("velours", Vector3(x2 + s2 * 1.55, 5.8, 13.45), Vector3(0.7, 9.2, 0.12))
	for x3 in [-74.0, -67.0, -60.0]:
		lustre("bal", Vector3(x3, 8.6, 0), 1.4, 12.0, x3 != -74.0)
	for z3 in [-10.0, 10.0]:
		applique("bal", Vector3(-52.65, 3.2, z3), Vector3(-1, 0, 0))
	toile("bal", Vector3(-81.5, 11.5, -13.5), -PI * 0.25 + PI, 2.2)
	toile("bal", Vector3(-52.6, 11.5, 13.5), PI * 0.25, 1.8)
	_commit("bal", "Bal_deco_v124")
	_build_mirror()


## Le grand miroir du mur ouest : une seconde caméra, de l'autre côté du verre, qui voit toute la
## salle… sauf ce qui n'a pas de reflet (la couche LAYER_SANS_REFLET)
func _build_mirror() -> void:
	var c := Vector3(-81.55, 0.6 + MIRROR_H * 0.5, 0)
	_mirror_c = W(c)
	_b = SK.Batch.new()
	# le cadre doré, ciselé
	for s in [-1.0, 1.0]:
		bx("dorure", c + Vector3(0.05, 0, s * (MIRROR_W * 0.5 + 0.12)), Vector3(0.14, MIRROR_H + 0.48, 0.24))
		bx("dorure", c + Vector3(0.05, s * (MIRROR_H * 0.5 + 0.12), 0), Vector3(0.14, 0.24, MIRROR_W))
	bx("dorure", c + Vector3(0.08, MIRROR_H * 0.5 + 0.5, 0), Vector3(0.12, 0.5, 2.2))
	_commit("bal", "Miroir_cadre_v124")
	_mirror_vp = SubViewport.new()
	_mirror_vp.name = "Miroir_v124"
	_mirror_vp.size = Vector2i(1280, int(1280.0 * MIRROR_H / MIRROR_W)) if pc else Vector2i(896, int(896.0 * MIRROR_H / MIRROR_W))
	_mirror_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_mirror_vp.msaa_3d = Viewport.MSAA_2X if pc else Viewport.MSAA_DISABLED
	add_child(_mirror_vp)
	_mirror_cam = Camera3D.new()
	_mirror_cam.cull_mask = 0xFFFFF & ~LAYER_SANS_REFLET
	_mirror_cam.projection = Camera3D.PROJECTION_FRUSTUM
	_mirror_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_mirror_vp.add_child(_mirror_cam)
	var mi := MeshInstance3D.new()
	mi.name = "Miroir_verre"
	var qm := QuadMesh.new()
	qm.size = Vector2(MIRROR_W, MIRROR_H)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = _mirror_vp.get_texture()
	m.albedo_color = Color(0.86, 0.86, 0.9)
	m.uv1_scale = Vector3(-1, 1, 1)
	m.uv1_offset = Vector3(1, 0, 0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = 1 << 18
	(rooms["bal"]["root"] as Node3D).add_child(mi)
	mi.global_transform = X(c, PI * 0.5)
	# le miroir ne se voit pas dans lui-même
	_mirror_cam.cull_mask &= ~(1 << 18)


## La caméra du miroir : le reflet de l'œil du joueur, de l'autre côté du plan ; son cadre passe
## exactement par les bords du miroir (un frustum décentré).
func _mirror_tick(on: bool) -> void:
	if _mirror_vp == null:
		return
	_mirror_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if not on:
		return
	var eye: Vector3 = main.xr_camera.global_position if main.xr_active else get_viewport().get_camera_3d().global_position
	var n := Vector3(1, 0, 0)
	var d: float = (eye - _mirror_c).dot(n)
	if d < 0.05:
		return
	var refl: Vector3 = eye - n * (2.0 * d)
	var zc: Vector3 = -n
	var yc := Vector3.UP
	var xc: Vector3 = yc.cross(zc)
	_mirror_cam.global_transform = Transform3D(Basis(xc, yc, zc), refl)
	var rel: Vector3 = _mirror_c - refl
	var off := Vector2(rel.dot(xc), rel.dot(yc))
	_mirror_cam.set_frustum(MIRROR_H, off, d, d + 60.0)


# =================================================================== la Bibliothèque

func _build_biblio() -> void:
	_b = SK.Batch.new()
	floor_ceil(12, 40, -14, 14, 0, 12, "parquet", "lambris")
	walls(12, 40, -14, 14, 0, 12, "lambris", "lambris", [["w", 0, 30.0, 12.0], ["e", 0, 2.4, 3.2]])
	doorway(Vector3(12.0, 0, 0), PI * 0.5, 3.0, 4.2)
	# les grandes étagères : tout autour, jusqu'à 7 m
	etageres(Vector3(13.0, 0, -13.6), Vector3(39.0, 0, -13.6), Vector3(0, 0, 1), 7.0)
	etageres(Vector3(13.0, 0, 13.6), Vector3(39.0, 0, 13.6), Vector3(0, 0, -1), 7.0)
	etageres(Vector3(39.6, 0, -13.0), Vector3(39.6, 0, -1.6), Vector3(-1, 0, 0), 7.0)
	etageres(Vector3(39.6, 0, 1.6), Vector3(39.6, 0, 13.0), Vector3(-1, 0, 0), 7.0)
	# une coursive en bois à 4 m (on ne peut pas y monter : elle fait le décor), son garde-corps
	bx("bois_cire", Vector3(26.0, 4.0, -12.4), Vector3(26.0, 0.12, 1.4))
	bx("bois_cire", Vector3(26.0, 4.0, 12.4), Vector3(26.0, 0.12, 1.4))
	for s in [-1.0, 1.0]:
		bx("dorure_terne", Vector3(26.0, 4.95, s * 11.75), Vector3(26.0, 0.06, 0.06))
		for x in range(13, 40):
			_b.tube("bois_cire", O + Vector3(x, 4.06, s * 11.75), O + Vector3(x, 4.95, s * 11.75), 0.025, 5)
	# l'échelle roulante
	for s2 in [-1.0, 1.0]:
		_b.tube("bois_cire", O + Vector3(22.0 + s2 * 0.25, 0, -12.6), O + Vector3(22.0 + s2 * 0.25, 4.1, -13.2), 0.03, 6)
	for k in range(12):
		var t: float = (k + 0.5) / 12.0
		_b.tube("bois_cire", O + Vector3(21.75, t * 4.1, -12.6 - t * 0.6), O + Vector3(22.25, t * 4.1, -12.6 - t * 0.6), 0.02, 5)
	# les tables de lecture, les fauteuils, le lutrin, les globes, la cheminée
	for z in [-5.0, 5.0]:
		table(Vector3(24.0, 0, z), 3.2, 1.3)
		chaise(Vector3(23.0, 0, z - 1.1), 0.0)
		chaise(Vector3(25.0, 0, z + 1.1), PI)
		for i in range(4):
			bx("cuir", Vector3(23.0 + i * 0.6, 0.83 + (i % 2) * 0.05, z + 0.2), Vector3(0.3, 0.08 + (i % 2) * 0.05, 0.4), 0.2 * i)
		candle(Vector3(24.8, 0.79, z - 0.3))
	fauteuil(Vector3(33.0, 0, -3.0), -PI * 0.75)
	fauteuil(Vector3(33.0, 0, 3.0), -PI * 0.25)
	# le lutrin et son parchemin
	cy("bois_cire", Vector3(17.0, 0, 0), 0.25, 0.08, 1.0, 8)
	bx("bois_cire", Vector3(17.0, 1.1, 0), Vector3(0.6, 0.06, 0.5), 0.0)
	bx("nappe", Vector3(17.0, 1.15, 0), Vector3(0.45, 0.01, 0.35), 0.0)
	kit.col_cyl(W(Vector3(17.0, 0, 0)), 0.3, 1.2)
	for g in [Vector3(30.0, 0, -8.0), Vector3(30.0, 0, 8.0)]:
		cy("bois_cire", g, 0.2, 0.06, 0.9, 8)
		_b.blob("parquet", O + g + Vector3.UP * 1.25, Vector3(0.32, 0.32, 0.32), 12)
		_b.tube("dorure", O + g + Vector3(0, 0.88, -0.36), O + g + Vector3(0, 1.62, 0.36), 0.015, 5)
		kit.col_cyl(W(g), 0.35, 1.5)
	_commit("biblio", "Bibliotheque_v124")
	cheminee("biblio", Vector3(26.0, 0, -13.0), Vector3(0, 0, 1), true)
	for x2 in [16.0, 36.0]:
		candelabre("biblio", Vector3(x2, 0, -9.0))
		candelabre("biblio", Vector3(x2, 0, 9.0))
	lustre("biblio", Vector3(26.0, 8.5, 0), 1.3, 12.0)
	# des appliques entre les étagères (sinon on ne voit pas les livres)
	for x3 in [17.0, 26.0, 35.0]:
		applique("biblio", Vector3(x3, 3.0, -13.3), Vector3(0, 0, 1))
		applique("biblio", Vector3(x3, 3.0, 13.3), Vector3(0, 0, -1))
	light("biblio", Vector3(26.0, 2.6, 0), 1.0, 14.0, Color(1.0, 0.72, 0.45))
	toile("biblio", Vector3(39.5, 11.5, 13.5), PI * 0.25, 2.0)
	toile("biblio", Vector3(12.6, 11.5, -13.5), -PI * 0.75, 2.0)
	_commit("biblio", "Bibliotheque_deco_v124")
	# les livres qui volent (lentement, en rond, au-dessus des tables)
	for i2 in range(9 if pc else 5):
		var bk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.24, 0.05, 0.32)
		bk.mesh = bm
		bk.material_override = SK.mat("cuir")
		(rooms["biblio"]["root"] as Node3D).add_child(bk)
		_flying.append([bk, W(Vector3(26.0, 0, 0)), randf_range(3.0, 8.0), randf_range(0.15, 0.35) * (1.0 if randf() < 0.5 else -1.0), randf() * TAU, randf_range(2.6, 5.5)])
	# la bibliothèque secrète (mur est) : un pan d'étagère qui pivote
	_bookcase = Node3D.new()
	_bookcase.name = "Etagere_secrete"
	(rooms["biblio"]["root"] as Node3D).add_child(_bookcase)
	_bookcase.global_transform = X(Vector3(39.75, 0, -1.4))
	var shelf := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.44, 3.4, 2.8)
	shelf.mesh = sm
	shelf.material_override = SK.mat("livres")
	shelf.position = Vector3(0, 1.7, 1.4)
	_bookcase.add_child(shelf)
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.44, 3.4, 2.8)
	cs.shape = sh
	cs.position = Vector3(0, 1.7, 1.4)
	sb.add_child(cs)
	_bookcase.add_child(sb)
	# les cinq livres qu'on peut tirer (ils dépassent un peu)
	for e in LIVRES:
		var lv := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.05, 0.27, 0.2)
		lv.mesh = lm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.05, 0.06) if str(e[0]) in ORDRE else Color(0.12, 0.2, 0.12)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.6, 0.25)
		mat.emission_energy_multiplier = 0.25
		mat.roughness = 0.5
		lv.material_override = mat
		lv.name = "Livre_" + str(e[0])
		(rooms["biblio"]["root"] as Node3D).add_child(lv)
		var f: Vector3 = e[3]
		lv.global_transform = X(e[2] + Vector3.UP * 0.14 + f * 0.06, atan2(f.x, f.z) + PI * 0.5)


func _show_bookcase(open: bool, animate: bool) -> void:
	if _bookcase == null:
		return
	var sb: StaticBody3D = _bookcase.get_node("Corps")
	var target: float = -1.45 if open else 0.0
	if animate:
		var tw := create_tween()
		tw.tween_property(_bookcase, "rotation:y", target, 2.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): sb.collision_layer = 0 if open else 1)
	else:
		_bookcase.rotation.y = target
		sb.collision_layer = 0 if open else 1


# ------------------------------------------------------------------- le cabinet du baron

func _build_cabinet() -> void:
	_b = SK.Batch.new()
	floor_ceil(40, 50, -5, 5, 0, 5, "parquet", "lambris")
	walls(40, 50, -5, 5, 0, 5, "lambris", "damas", [["w", 0, 12.0, 5.0]])
	etageres(Vector3(40.6, 0, -4.6), Vector3(49.4, 0, -4.6), Vector3(0, 0, 1), 4.2)
	etageres(Vector3(40.6, 0, 4.6), Vector3(49.4, 0, 4.6), Vector3(0, 0, -1), 4.2)
	# le bureau du baron, couvert de papiers, de bougies, d'un crâne (pour le style)
	table(Vector3(47.0, 0, 0), 1.0, 2.2, 0.0, "bois_cire")
	bx("nappe", Vector3(46.9, 0.8, -0.4), Vector3(0.5, 0.01, 0.7), 0.3)
	bx("cuir", Vector3(47.1, 0.84, 0.5), Vector3(0.45, 0.08, 0.6), 0.1)
	_b.blob("os", O + Vector3(47.2, 0.9, -0.8), Vector3(0.09, 0.1, 0.11), 10)
	candle(Vector3(46.8, 0.79, 0.95))
	candle(Vector3(46.9, 0.79, 1.05), 0.14)
	fauteuil(Vector3(48.4, 0, 0), -PI * 0.5)
	_commit("cabinet", "Cabinet_v124")
	light("cabinet", Vector3(46.9, 1.4, 1.0), 1.0, 6.0)
	tableau("cabinet", Vector3(49.65, 2.4, 0), Vector3(-1, 0, 0), 1.4, 1.0)
	toile("cabinet", Vector3(49.5, 4.6, -4.5), -PI * 0.25 + PI, 1.0)


# =================================================================== l'escalier et la salle d'armes

func _build_escalier() -> void:
	_b = SK.Batch.new()
	# un couloir de pierre qui descend de 8 m (de z = -15 à z = -31)
	bx("dalles_int", Vector3(8, -0.25, -15.6), Vector3(4.0, 0.5, 1.4), 0.0, true)
	var steps: int = 36
	for i in range(steps):
		var z: float = -16.2 - (i + 0.5) * (14.0 / steps)
		var top: float = -(i + 1) * (8.0 / steps)
		bx("pierre_chateau_claire", Vector3(8, top - 0.25, z), Vector3(4.0, 0.5, 14.0 / steps + 0.01))
	var slope: float = atan2(8.0, 14.0)
	var cb := Basis(Vector3.RIGHT, -slope)
	kit.col_box(X(Vector3(8, -4.0 - 0.15 * cos(slope), -23.2)) * Transform3D(cb, Vector3.ZERO), Vector3(4.0, 0.3, sqrt(64.0 + 196.0) + 0.2))
	bx("dalles_int", Vector3(8, -8.25, -30.6), Vector3(4.0, 0.5, 1.4), 0.0, true)
	for s in [-1.0, 1.0]:
		for k in range(8):
			var z2: float = -15.0 - k * 2.0 - 1.0
			var y0: float = -8.0 * clampf((-z2 - 16.2) / 14.0, 0.0, 1.0)
			bx("pierre_int", Vector3(8 + s * 2.3, y0 + 2.0, z2), Vector3(0.6, 9.0, 2.05), 0.0, true)
		# le plafond qui descend avec l'escalier
	for k2 in range(8):
		var z3: float = -15.0 - k2 * 2.0 - 1.0
		var y1: float = -8.0 * clampf((-z3 - 16.2) / 14.0, 0.0, 1.0)
		bx("pierre_int", Vector3(8, y1 + 4.0, z3), Vector3(4.6, 0.6, 2.05), 0.0, true)
	_commit("escalier", "Escalier_v124")
	applique("escalier", Vector3(9.95, -2.0, -21.0), Vector3(-1, 0, 0))
	applique("escalier", Vector3(6.05, -5.5, -27.0), Vector3(1, 0, 0))


func _build_armes() -> void:
	_b = SK.Batch.new()
	floor_ceil(-6, 22, -59, -31, -8, 10, "dalles_int", "pierre_int")
	walls(-6, 22, -59, -31, -8, 10, "pierre_int", "pierre_int", [["s", 8, 3.6, 4.0]])
	# les arcs de la voûte, les piliers
	for z in [-38.0, -45.0, -52.0]:
		for x in [1.0, 15.0]:
			bx("pierre_chateau_claire", Vector3(x, -3.0, z), Vector3(0.9, 10.0, 0.9), 0.0, true)
		bx("pierre_chateau_claire", Vector3(8.0, 1.4, z), Vector3(28.0, 1.2, 0.6))
	# le cercle de sable du duel
	cy("sac_sable", Vector3(8.0, -7.99, -46.0), 6.5, 6.5, 0.02, 32)
	# les râteliers d'armes, les armures, les bannières (rouge sombre)
	for x2 in [-5.3, 21.3]:
		for z2 in [-36.0, -42.0, -50.0]:
			bx("bois_sombre", Vector3(x2, -6.9, z2), Vector3(0.3, 2.2, 2.4), 0.0, true)
			for k in range(5):
				_b.tube("acier", O + Vector3(x2 + (0.12 if x2 < 0 else -0.12), -7.9, z2 - 1.0 + k * 0.5), O + Vector3(x2 + (0.18 if x2 < 0 else -0.18), -5.6, z2 - 1.0 + k * 0.5), 0.02, 5)
	for x3 in [2.0, 14.0]:
		armure_statue(Vector3(x3, -8.0, -58.0), 0.0)
	bx("tissu_rouge_sombre", Vector3(8.0, -2.5, -58.65), Vector3(3.0, 7.0, 0.04))
	bx("dorure_terne", Vector3(8.0, 1.05, -58.6), Vector3(3.4, 0.1, 0.1))
	for x4 in [-5.6, 21.6]:
		bx("tissu_rouge_sombre", Vector3(x4, -3.5, -46.0), Vector3(0.04, 5.0, 1.8))
	toile("armes", Vector3(-5.5, 1.5, -58.5), -PI * 0.25 + PI, 1.6)
	toile("armes", Vector3(21.5, 1.5, -31.5), PI * 0.25, 1.4)
	_commit("armes", "Salle_armes_v124")
	applique("armes", Vector3(8.0 - 2.6, -5.0, -31.6), Vector3(0, 0, -1))
	applique("armes", Vector3(8.0 + 2.6, -5.0, -31.6), Vector3(0, 0, -1))
	# les quatre braseros (éteints)
	kit.mats["fer124"] = SK.mat("fer_noir")
	kit.mats["pierre124"] = SK.mat("pierre_chateau_claire")
	for p in BRASEROS:
		var br: Dictionary = kit.brazier63(rooms["armes"]["root"], W(p), false, "fer124", 3.0, "pierre124")
		_braseros.append(br)


# =================================================================== la tour du comte (le début)

func _build_tour() -> void:
	_b = SK.Batch.new()
	floor_ceil(-3, 3, -22, -15, 6, 10, "dalles_int", "pierre_int")
	walls(-3, 3, -22, -15, 6, 10, "pierre_int", "pierre_int", [["s", 0, 8.0, 10.0]])
	# l'escalier en colimaçon qui monte… jusqu'à une porte de fer
	var c := Vector3(0, 6, -19.5)
	cy("pierre_chateau_claire", c, 0.35, 0.35, 8.0, 12)
	kit.col_cyl(W(c), 0.4, 8.0)
	var n: int = 22
	for i in range(n):
		var a: float = PI * 0.5 + i * (TAU * 0.9 / n)
		var y: float = 6.0 + (i + 1) * (5.4 / n)
		var p: Vector3 = c + Vector3(cos(a) * 1.3, 0, sin(a) * 1.3)
		bx("pierre_chateau_claire", Vector3(p.x, y - 0.1, p.z), Vector3(1.9, 0.2, 0.75), -a, true)
	# le palier du haut, la porte de fer (fermée)
	bx("pierre_chateau_claire", Vector3(-1.6, 11.35, -20.5), Vector3(2.6, 0.2, 2.6), 0.0, true)
	bx("fer_noir", Vector3(-2.85, 12.6, -20.5), Vector3(0.15, 2.4, 1.4), 0.0, true)
	for yy in [11.8, 12.6, 13.4]:
		bx("rouille", Vector3(-2.75, yy, -20.5), Vector3(0.06, 0.08, 1.5))
	_commit("tour", "Tour_v124")
	applique("tour", Vector3(2.95, 8.0, -18.5), Vector3(-1, 0, 0))
	light("tour", Vector3(-2.0, 12.8, -20.5), 0.6, 4.0, Color(1.0, 0.2, 0.1))


# =================================================================== les invites

func _register() -> void:
	var me = self
	ia("sortir", Vector3(0, 0, 14.2), 1.8, "E : sortir du château (dans la cour)", "Gâchette : sortir dans la cour", func(): me.leave("Tu refermes la porte du donjon derrière toi. Le vent, la cour… Tout là-haut, les fenêtres rouges."))
	ia("mortimer", Vector3(-3.2, 0, 4.0), 2.4, "E : parler à Mortimer, le majordome", "Gâchette : parler à Mortimer",
		func(): me._mortimer_talk(), func(): return me._mortimer != null and is_instance_valid(me._mortimer))
	ia("porte_tour", Vector3(0, 6.0, -13.4), 2.4, "E : examiner la porte de la Tour du Comte", "Gâchette : la porte de la tour",
		func(): me._porte_tour(), func(): return int(me.state["poses"]) < 3)
	ia("porte_fer", Vector3(-1.6, 11.45, -20.5), 2.2, "E : pousser la porte de fer", "Gâchette : pousser la porte de fer",
		func(): me._porte_fer(), func(): return int(me.state["poses"]) >= 3)
	ia("horloge", Vector3(-10.0, 0, -9.0), 1.8, "E : regarder l'horloge", "Gâchette : regarder l'horloge", func(): me._horloge_regard())
	ia("lutrin", Vector3(17.0, 0, 0.9), 1.8, "E : lire le parchemin du lutrin", "Gâchette : lire le parchemin", func(): me._lutrin())
	for e in LIVRES:
		var id: String = str(e[0])
		var f: Vector3 = e[3]
		var p: Vector3 = e[2] + f * 0.9
		p.y = 0.0
		ia("livre_" + id, p, 1.4, "E : tirer le livre « %s »" % str(e[1]), "Gâchette : tirer « %s »" % str(e[1]),
			func(): me._tirer(id), func(): return not bool(me.state["biblio_ouverte"]))
	ia("sigismund", Vector3(45.6, 0, 0), 2.6, "E : parler au baron Sigismund", "Gâchette : parler au baron",
		func(): me._sigismund_talk(), func(): return me._sigismund != null and is_instance_valid(me._sigismund) and str(me._sigismund.state) == "parle")
	ia("radu", Vector3(8.0, -8.0, -51.5), 3.2, "E : parler au chevalier Radu", "Gâchette : parler au chevalier Radu",
		func(): me._radu_talk(), func(): return me._radu != null and is_instance_valid(me._radu) and str(me._radu.state) == "parle")
	for i in range(BRASEROS.size()):
		var k: int = i
		var bp: Vector3 = BRASEROS[i]
		ia("brasero_%d" % i, bp + Vector3(0, 0, 1.1 if bp.z < -45.0 else -1.1), 1.8, "E : allumer le brasero", "Gâchette : allumer le brasero",
			func(): me._allumer(k), func(): return k < me._braseros.size() and not bool((me._braseros[k] as Dictionary)["lit"]))


func _apply_state() -> void:
	super._apply_state()
	_show_tower(int(state["poses"]) >= 3, false)
	_show_bookcase(bool(state["biblio_ouverte"]), false)
	for br in _braseros:
		kit.set_brazier(br, false)


# =================================================================== entrer, les salles

func _on_enter(first: bool) -> void:
	if first:
		_say("Le château du comte. La porte se referme toute seule derrière toi… Il fait froid. Quelque part, une horloge ne fait plus tic-tac.", 7.0)
	_sfx("porte_grince", W(Vector3(0, 2.0, 14.5)))
	if main.has_method("sfx"):
		get_tree().create_timer(3.0).timeout.connect(func(): if built and room != "": _sfx("orgue_accord", W(Vector3(0, 8.0, -12.0))))


func _enter_room(_old: String, r: String) -> void:
	match r:
		"hall":
			_once("hall", "Le Grand Vestibule. Un escalier de pierre monte vers une galerie ; tout en haut, un grand portrait… et deux yeux rouges qui ne te quittent pas.", 6.0)
		"galerie":
			_galerie_peur = 0
			_once("galerie", "La Galerie des Portraits. Des dizaines de visages… Ce sont les gens de Sombreval. Les disparus.", 6.0)
		"bal":
			if not bool(state["ilona"]) and not bool(state["bal_vu"]):
				state["bal_vu"] = true
		"biblio":
			_once("biblio", "La bibliothèque. Des milliers de livres… et certains volent, tout seuls, au-dessus des tables.", 5.0)
		"armes":
			_once("armes", "La salle d'armes. Il fait si noir… Les braseros sont éteints depuis longtemps.", 5.0)
		"tour":
			_once("tour", "La Tour du Comte. Un escalier en colimaçon monte dans le noir. Tout en haut… une lueur rouge.", 5.0)


## Les personnages du château (Mortimer, la comtesse et ses danseurs, le baron, le chevalier) :
## ils arrivent quand monstres_v36 a vu qu'on est descendu
func _spawn_people(r: String) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null or not bool(mo.get("_was_inside")):
		return
	if r == "hall" and (_mortimer == null or not is_instance_valid(_mortimer)):
		_mortimer = _npc("mortimer", Vector3(-3.2, 0.05, 4.0), Vector3(0.4, 0, 1))
		if not bool(state["mortimer"]):
			get_tree().create_timer(1.6).timeout.connect(func(): if _mortimer != null and is_instance_valid(_mortimer) and room == "hall": _mortimer_talk())
	if r == "bal" and not bool(state["ilona"]) and _danseurs.is_empty() and (_ilona == null or not is_instance_valid(_ilona)):
		_start_bal()
	if r == "cabinet" and not bool(state["sigismund"]) and (_sigismund == null or not is_instance_valid(_sigismund)):
		_sigismund = _npc("sigismund", Vector3(48.0, 0.05, 0), Vector3(-1, 0, 0))
		get_tree().create_timer(1.0).timeout.connect(func(): if _sigismund != null and is_instance_valid(_sigismund) and str(_sigismund.state) == "parle" and room == "cabinet": _sigismund_talk())
	if r == "armes" and not bool(state["radu"]) and (_radu == null or not is_instance_valid(_radu)):
		_radu = _npc("radu", Vector3(8.0, -7.95, -55.0), Vector3(0, 0, 1))
		_radu.invuln = true
		_radu.on_invuln_hit = Callable(self, "_radu_ombre")
		for br in _braseros:
			kit.set_brazier(br, false)


func _npc(kind_n: String, l: Vector3, face: Vector3) -> Node3D:
	var mo: Node = main.get("monstres_v36")
	var m: Node3D = mo.spawn_extra(kind_n, W(l))
	m.home = W(l)
	m.facing = face.normalized()
	m.rotation.y = atan2(face.x, face.z)
	m.talk()
	return m


func _free_people() -> void:
	var mo: Node = main.get("monstres_v36")
	for m in [_mortimer, _ilona, _sigismund, _radu] + _danseurs.map(func(e): return e[0]):
		if m != null and is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			(m as Node).queue_free()
	_mortimer = null
	_ilona = null
	_sigismund = null
	_radu = null
	_danseurs.clear()
	_bal_music = false


func _on_reset() -> void:
	_free_people()
	_pulled.clear()
	_riddle = 0
	for br in _braseros:
		kit.set_brazier(br, false)
	for e in _galerie_lights:
		if e[0] != null:
			(e[0] as OmniLight3D).visible = true


func _faint_text() -> String:
	return "Mortimer t'a traîné jusqu'ici. « Il ne faudrait pas abîmer les invités », a-t-il murmuré."


func _fall_text(_r: String) -> String:
	return "Tu glisses… et tu te retrouves, étourdi, à l'entrée de la salle."


# =================================================================== chaque image

func _tick(delta: float, p: Vector3, r: String) -> void:
	_spawn_people(r)
	var l: Vector3 = L(p)
	_flicker_tick(r)
	_mirror_tick(r == "bal")
	if r == "bal":
		_bal_tick(delta)
	if r == "galerie":
		_galerie_tick(l)
	if r == "biblio" or r == "cabinet":
		_books_tick(delta)
	if r == "armes":
		_armes_tick(delta, l)
	if r in ["hall", "tour"] and _comte_eyes != null:
		var on: float = 2.8 if l.y > 4.5 or rubis() > 0 else 0.9
		_comte_eyes.emission_energy_multiplier = on * (0.8 + 0.2 * sin(_clock * 2.3))
	_boss_phases()
	# des murmures, de temps en temps, tout près
	if randf() < delta / 38.0:
		var a: float = randf() * TAU
		_sfx("murmures", p + Vector3(cos(a) * 3.0, 1.6, sin(a) * 3.0))


func _flicker_tick(r: String) -> void:
	for e in _flick:
		var lt: OmniLight3D = e[0]
		if lt == null or not is_instance_valid(lt) or str(e[2]) != r:
			continue
		lt.light_energy = float(e[1]) * (0.85 + 0.1 * sin(_clock * 9.0 + lt.position.x * 3.0) + 0.05 * sin(_clock * 23.0 + lt.position.z))


## L'orage de Sombreval : les éclairs passent par les vitraux (appelé par sombreval_v121)
func flash(strong: bool) -> void:
	if room == "":
		return
	var e: float = 9.0 if strong else 6.0
	for w in _win_lights:
		var lt: OmniLight3D = w[0]
		if lt == null or not is_instance_valid(lt) or not lt.is_visible_in_tree():
			continue
		var base: float = float(w[1])
		var tw := create_tween()
		tw.tween_property(lt, "light_energy", e, 0.03)
		tw.tween_property(lt, "light_energy", base, 0.06)
		tw.tween_property(lt, "light_energy", e * 0.7, 0.04)
		tw.tween_property(lt, "light_energy", base, 0.25)


# ------------------------------------------------------------------- la galerie qui fait peur

## Les bougies s'éteignent derrière toi, une à une ; au bout, une silhouette passe
func _galerie_tick(l: Vector3) -> void:
	if _galerie_peur == 0 and l.x < -22.0:
		_galerie_peur = 1
		_sfx("bougies_soufflees", W(Vector3(-14.0, 2.5, 0)))
		for e in _galerie_lights:
			if float(e[1]) > l.x + 4.0 and e[0] != null:
				(e[0] as OmniLight3D).visible = false
		_sfx("murmures", W(l + Vector3(3.0, 1.6, 0)))
	if _galerie_peur == 1 and l.x < -34.0:
		_galerie_peur = 2
		_silhouette()
		get_tree().create_timer(9.0).timeout.connect(func():
			for e in _galerie_lights:
				if e[0] != null and is_instance_valid(e[0]):
					(e[0] as OmniLight3D).visible = true)


func _silhouette() -> void:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return
	var a: Vector3 = W(Vector3(-49.2, 0.05, -1.9))
	var b: Vector3 = W(Vector3(-49.2, 0.05, 1.9))
	var m: Node3D = mo.spawn_extra("vampire", a)
	m.state = "danse"
	m.dance_anim = "vp/glisse"
	m.collision_layer = 0
	m.facing = Vector3(0, 0, 1)
	m.rotation.y = 0.0
	_sfx("vampire_brume", a + Vector3.UP * 1.2)
	var tw := create_tween()
	tw.tween_property(m, "global_position", b, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if is_instance_valid(m):
			m.bats_burst(m.global_position + Vector3.UP * 1.3, 6)
			mo.monsters.erase(m)
			m.queue_free())
	get_tree().create_timer(0.8).timeout.connect(func(): _sfx("vampire_rire", W(Vector3(-50.0, 2.0, 0))))


# ------------------------------------------------------------------- le bal de la comtesse

func _start_bal() -> void:
	var c := Vector3(-67.0, 0.05, 0)
	var n: int = 7
	var who: int = 4
	for i in range(n):
		var kind_n: String = "ilona" if i == who else "vampire"
		var a: float = TAU * i / n
		var m: Node3D = main.monstres_v36.spawn_extra(kind_n, W(c + Vector3(cos(a), 0, sin(a)) * 4.6))
		m.state = "danse"
		m.on_hit = Callable(self, "_dance_hit")
		m.home = m.global_position
		m.collision_layer = 0
		if i == who:
			_ilona = m
			m.sans_reflet(LAYER_SANS_REFLET)
		_danseurs.append([m, a, 4.6, 0.32, randf() * TAU])
	_bal_music = true
	get_tree().create_timer(1.2).timeout.connect(func():
		if room == "bal" and not bool(state["ilona"]):
			_say("Une voix de femme, moqueuse, au-dessus de la musique : « Bienvenue à mon bal, petit voyageur ! Trouve-moi parmi mes invités… si tu peux. Un indice ? Je suis la seule qui ne s'admire jamais dans la glace. »", 9.0)
			_sfx("vampire_rire", W(c + Vector3.UP * 3.0)))


func _bal_tick(delta: float) -> void:
	var c: Vector3 = W(Vector3(-67.0, 0.05, 0))
	for e in _danseurs:
		var m: Node3D = e[0]
		if m == null or not is_instance_valid(m) or str(m.state) != "danse":
			continue
		e[1] = float(e[1]) + delta * float(e[3])
		var a: float = float(e[1])
		var spin: float = float(e[4]) + _clock * 2.6
		m.global_position = c + Vector3(cos(a), 0, sin(a)) * (float(e[2]) + 0.35 * sin(spin))
		m.rotation.y = spin
		m.facing = Vector3(sin(spin), 0, cos(spin))
	# on peut traverser la ronde (les danseurs s'écartent) : pas de collision pendant la valse


func _dance_hit(m: Node3D) -> void:
	if m == _ilona:
		_unmask()
		return
	# raté : ce n'était qu'un invité… qui se fâche
	for e in _danseurs:
		if e[0] == m:
			_danseurs.erase(e)
			break
	m.collision_layer = 1
	m.state = "chasse"
	m.home = m.global_position
	m.wake()
	(_room_monsters.get_or_add("bal", []) as Array).append(m)
	_say("La comtesse éclate de rire : « Raté ! Ce n'était pas moi… Regarde mieux ! »", 4.5)
	_sfx("vampire_rire", W(Vector3(-67.0, 4.0, 0)))


func _unmask() -> void:
	var mo: Node = main.get("monstres_v36")
	for e in _danseurs.duplicate():
		var m: Node3D = e[0]
		if m == _ilona or m == null or not is_instance_valid(m):
			continue
		if str(m.state) == "danse":
			m.bats_burst(m.global_position + Vector3.UP * 1.3, 5)
			if mo != null:
				mo.monsters.erase(m)
			m.queue_free()
	_danseurs.clear()
	_bal_music = false
	_ilona.collision_layer = 1
	_ilona.sans_reflet(1)
	_ilona.talk()
	_sfx("nuee_chauves_souris", _ilona.global_position + Vector3.UP * 2.0)
	_ask(_ilona.global_position + Vector3.UP * 1.7, "La comtesse Ilona", "amusée",
		"La musique s'arrête net. Tous les danseurs éclatent en chauves-souris… sauf elle. « Tu m'as trouvée. Personne ne me trouve jamais. » Elle ôte ses longs gants noirs, un doigt après l'autre. « Je danse dans ce château depuis deux cents ans. Toujours la même valse. Tu sais ce que c'est, l'ennui, quand on ne peut plus mourir ? »",
		[{"id": "rubis", "label": "Donne-moi ton rubis."}, {"id": "arreter", "label": "Tu pourrais arrêter tout ça, non ?"}, {"id": "danse", "label": "Je ne sais pas danser."}],
		Callable(self, "_ilona_answer"))


func _ilona_answer(id: String) -> void:
	var t: String = {"rubis": "« Mon rubis ? » Elle le fait briller au creux de sa main. « Il faudra me le prendre. Allez, dansons… à ma façon ! »",
		"arreter": "« Arrêter ? Et désobéir à Père ? » Ses yeux s'allument comme deux braises. « Tu es mignon. Tu feras un très joli invité… pour l'éternité ! »",
		"danse": "« Alors je vais t'apprendre ! Un, deux, trois… UN, DEUX, TROIS ! »"}.get(id, "« Assez parlé ! »")
	_ask(_ilona.global_position + Vector3.UP * 1.7, "La comtesse Ilona", "furieuse", t, [{"id": "combat", "label": "En garde !"}], Callable(self, "_ilona_fight"))


func _ilona_fight(_id: String) -> void:
	_close_dialog()
	if _ilona == null or not is_instance_valid(_ilona):
		return
	_ilona.home = _ilona.global_position
	_fight_with(_ilona, "La comtesse Ilona", Callable(self, "_ilona_dead"))
	_sfx("orgue_accord", W(Vector3(-67.0, 6.0, 0)))


func _ilona_dead() -> void:
	state["ilona"] = true
	_ilona = null
	_say("La comtesse Ilona tombe en poussière au milieu du damier… Un rubis roule jusqu'à tes pieds. Tu le ramasses : il est tiède, comme un cœur. (Rubis : %d sur 3)" % rubis(), 7.0)
	_after_rubis()


# ------------------------------------------------------------------- la bibliothèque

func _books_tick(delta: float) -> void:
	for e in _flying:
		var bk: Node3D = e[0]
		if bk == null or not is_instance_valid(bk):
			continue
		e[4] = float(e[4]) + delta * float(e[3])
		var a: float = float(e[4])
		var c: Vector3 = e[1]
		bk.global_position = c + Vector3(cos(a) * float(e[2]), float(e[5]) + sin(_clock * 0.8 + a * 3.0) * 0.3, sin(a) * float(e[2]) * 0.8)
		bk.rotation = Vector3(sin(_clock * 0.7 + a) * 0.5, -a, cos(_clock * 0.5 + a) * 0.3)


func _lutrin() -> void:
	_say("Sur le lutrin, un vieux parchemin, d'une écriture penchée : « Mon cabinet ne s'ouvre qu'à qui sait lire dans l'ordre. D'abord la Nuit, qui vient avant tout. Puis les Loups, qui chantent dans la Nuit. Enfin le Sang, qui coule quand les Loups ont chanté. » Signé : S.", 11.0)
	_sfx("ramasse", W(Vector3(17.0, 1.2, 0)))


func _tirer(id: String) -> void:
	if bool(state["biblio_ouverte"]):
		return
	var titre_l: String = ""
	for e in LIVRES:
		if str(e[0]) == id:
			titre_l = str(e[1])
	var lv: Node3D = rooms["biblio"]["root"].get_node_or_null("Livre_" + id)
	if lv != null:
		var tw := create_tween()
		tw.tween_property(lv, "scale", Vector3(1, 1, 1.25), 0.15)
		tw.tween_property(lv, "scale", Vector3.ONE, 0.3)
	_sfx("levier", W(Vector3(26.0, 1.5, 0)))
	_pulled.append(id)
	var k: int = _pulled.size() - 1
	if k >= ORDRE.size() or str(ORDRE[k]) != id:
		_pulled.clear()
		_say("Tu tires « %s »… Le livre se referme tout seul avec un claquement sec. Tous les livres tremblent sur les étagères — et quelques-uns te foncent dessus !" % titre_l, 6.0)
		_sfx("bougies_soufflees", _feet() + Vector3.UP * 1.5)
		_books_attack()
		return
	if _pulled.size() < ORDRE.size():
		_say("Tu tires « %s ». Clic ! Quelque part dans le mur, un mécanisme a bougé." % titre_l, 4.0)
		_sfx("dalle_clic", W(Vector3(39.5, 1.5, 0)))
		return
	state["biblio_ouverte"] = true
	_pulled.clear()
	_show_bookcase(true, true)
	_sfx("porte_grince", W(Vector3(39.6, 1.5, 0)))
	_sfx("pierre_glisse", W(Vector3(39.6, 1.0, 0)))
	_say("Tu tires « %s »… Tout un pan d'étagère pivote en grinçant : derrière, une petite pièce éclairée par une bougie. Le cabinet du baron." % titre_l, 6.0)


## Raté : des livres se jettent sur toi (ils piquent un peu), des chauves-souris s'envolent
func _books_attack() -> void:
	var p: Vector3 = _feet()
	Vamp._bats_burst_static(rooms["biblio"]["root"], p + Vector3.UP * 2.5, 6)
	for i in range(4):
		var bk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.2, 0.05, 0.28)
		bk.mesh = bm
		bk.material_override = SK.mat("cuir")
		(rooms["biblio"]["root"] as Node3D).add_child(bk)
		var a: float = TAU * i / 4.0
		bk.global_position = p + Vector3(cos(a) * 4.0, 2.5, sin(a) * 4.0)
		var tw := bk.create_tween()
		tw.tween_interval(0.2 * i)
		tw.tween_property(bk, "global_position", p + Vector3.UP * 1.3, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if built and room == "biblio" and i == 0:
				_hurt(1, bk.global_position + Vector3(0.01, 0, 0.01))
			bk.queue_free())


# ------------------------------------------------------------------- le baron Sigismund

func _sigismund_talk() -> void:
	if _sigismund == null or not is_instance_valid(_sigismund):
		return
	_riddle = 0
	_ask(_sigismund.global_position + Vector3.UP * 1.7, "Le baron Sigismund", "ravi",
		"« Un lecteur ! Enfin quelqu'un qui sait lire, dans cette maison. Mes frères et sœurs ne lisent que les menus. » Il referme un gros livre dans un nuage de poussière. « Tu veux mon rubis, je suppose. Je te propose un marché : trois devinettes. Trois bonnes réponses, et il est à toi : nous nous quitterons en gentlemen. Une seule erreur… et tu resteras ici pour toujours. Comme marque-page. »",
		[{"id": "oui", "label": "J'accepte tes devinettes."}, {"id": "combat", "label": "Pas de devinettes : battons-nous."}, {"id": "fermer", "label": "Je reviendrai."}],
		Callable(self, "_sigismund_answer"))


func _sigismund_answer(id: String) -> void:
	if _sigismund == null or not is_instance_valid(_sigismund):
		_close_dialog()
		return
	var at: Vector3 = _sigismund.global_position + Vector3.UP * 1.7
	if id == "combat":
		_sigismund_fight("« Quel manque d'éducation ! » Il se lève d'un bond ; ses yeux s'allument. « Tu feras un très beau marque-page ! »")
		return
	if id != "oui":
		var q0: Array = DEVINETTES[_riddle - 1] if _riddle > 0 else []
		if q0.is_empty() or id != str(q0[2]):
			_sigismund_fight("« Faux ! » Le baron se lève d'un bond, et ses yeux s'allument comme deux charbons. « Ignorant ! Tu feras un très beau marque-page ! »")
			return
	if _riddle >= DEVINETTES.size():
		_sigismund_paix()
		return
	var q: Array = DEVINETTES[_riddle]
	_riddle += 1
	var choices: Array = []
	for c in q[1]:
		choices.append({"id": str(c[0]), "label": str(c[1])})
	var pre: String = "" if _riddle == 1 else "« Juste. » Il tourne une page. "
	_ask(at, "Le baron Sigismund", "malicieux", pre + "Devinette %d : « %s »" % [_riddle, str(q[0])], choices, Callable(self, "_sigismund_answer"))


func _sigismund_paix() -> void:
	_close_dialog()
	state["sigismund"] = true
	state["sigismund_paix"] = true
	_say("« Bravo. Vraiment, bravo. » Le baron fait glisser un rubis sur le bureau. « Prends-le. Et si tu montes voir Père… dis-lui que je lisais. Il déteste ça. » Il s'incline — et se défait en une nuée de chauves-souris qui s'envolent entre les livres. (Rubis : %d sur 3)" % rubis(), 9.0)
	var m: Node3D = _sigismund
	_sigismund = null
	if m != null and is_instance_valid(m):
		m.bats_burst(m.global_position + Vector3.UP * 1.3, 10)
		var mo: Node = main.get("monstres_v36")
		if mo != null:
			mo.monsters.erase(m)
		m.queue_free()
	var pr: Node = main.get("progression_v63")
	if pr != null:
		pr.gain(60, "quetes", W(Vector3(47.0, 1.5, 0)))
	_after_rubis()


func _sigismund_fight(text: String) -> void:
	_close_dialog()
	_say(text, 5.0)
	_sfx("vampire_siffle", _sigismund.global_position + Vector3.UP * 1.6)
	# le combat se passe dans la bibliothèque (le cabinet est trop petit) : il y glisse
	_sigismund.home = W(Vector3(28.0, 0.05, 0))
	_fight_with(_sigismund, "Le baron Sigismund", Callable(self, "_sigismund_dead"))


func _sigismund_dead() -> void:
	state["sigismund"] = true
	_sigismund = null
	_say("Le baron Sigismund s'effondre en poussière au milieu de ses livres. Sur le parquet, un rubis brille encore. (Rubis : %d sur 3)" % rubis(), 7.0)
	_after_rubis()


# ------------------------------------------------------------------- le chevalier Radu

func _armes_tick(delta: float, l: Vector3) -> void:
	if _radu == null or not is_instance_valid(_radu):
		return
	if not bool(state["radu_vu"]) and str(_radu.state) == "parle" and l.distance_to(Vector3(8.0, -8.0, -55.0)) < 9.0:
		state["radu_vu"] = true
		_radu_talk()
	if str(_radu.state) in ["parle", "mort"]:
		return
	# il souffle un brasero de temps en temps (tant qu'ils ne sont pas tous allumés)
	var lit: int = _lit_count()
	_radu.invuln = lit < BRASEROS.size()
	if lit > 0 and lit < BRASEROS.size():
		_souffle_t -= delta
		if _souffle_t <= 0.0:
			_souffle_t = randf_range(24.0, 34.0)
			var ids: Array = []
			for i in range(_braseros.size()):
				if bool((_braseros[i] as Dictionary)["lit"]):
					ids.append(i)
			var k: int = ids[randi() % ids.size()]
			kit.set_brazier(_braseros[k], false)
			_sfx("bougies_soufflees", W(BRASEROS[k] + Vector3.UP * 1.3))
			_say("Radu tend la main : un souffle glacé traverse la salle… et un brasero s'éteint. « L'ombre est à moi ! »", 4.0)


func _lit_count() -> int:
	var n: int = 0
	for br in _braseros:
		if bool((br as Dictionary)["lit"]):
			n += 1
	return n


func _radu_talk() -> void:
	if _radu == null or not is_instance_valid(_radu):
		return
	_ask(_radu.global_position + Vector3.UP * 1.8, "Le chevalier Radu", "fier",
		"« Halte ! » Le chevalier plante son épée dans le sable. « Je suis Radu, premier chevalier de mon père. Tu viens chercher mon rubis ? Alors gagne-le, l'épée à la main. Comme un chevalier. »",
		[{"id": "duel", "label": "J'accepte le duel."}, {"id": "ombre", "label": "Pourquoi fait-il si noir, ici ?"}, {"id": "fermer", "label": "Une autre fois."}],
		Callable(self, "_radu_answer"))


func _radu_answer(id: String) -> void:
	if _radu == null or not is_instance_valid(_radu):
		_close_dialog()
		return
	if id == "ombre":
		_ask(_radu.global_position + Vector3.UP * 1.8, "Le chevalier Radu", "moqueur",
			"« Parce que l'ombre est mon armure, petit. » Il sourit. « Dans le noir, aucune lame ne me touche. Les braseros de cette salle sont éteints depuis cent ans… et ils le resteront. »",
			[{"id": "duel", "label": "J'accepte le duel."}, {"id": "fermer", "label": "Une autre fois."}], Callable(self, "_radu_answer"))
		return
	_close_dialog()
	_say("« Bien ! » Radu arrache son épée du sable et la lève. Les dernières bougies de la salle s'éteignent d'un coup.", 4.0)
	_sfx("bougies_soufflees", _radu.global_position + Vector3.UP * 2.0)
	_radu.home = W(Vector3(8.0, -7.95, -46.0))
	_souffle_t = 28.0
	_fight_with(_radu, "Le chevalier Radu", Callable(self, "_radu_dead"))


var _ombre_dit: bool = false


func _radu_ombre() -> void:
	if _ombre_dit:
		return
	_ombre_dit = true
	_say("Ta lame traverse Radu comme une fumée noire… Dans l'ombre, il est intouchable. Allume les quatre braseros de la salle (E) !", 7.0)


func _allumer(k: int) -> void:
	if k >= _braseros.size() or bool((_braseros[k] as Dictionary)["lit"]):
		return
	kit.set_brazier(_braseros[k], true)
	_sfx("brasero", W(BRASEROS[k] + Vector3.UP * 1.2))
	var n: int = _lit_count()
	if n >= BRASEROS.size():
		if _radu != null and is_instance_valid(_radu):
			_radu.invuln = false
			_say("Les quatre braseros flambent ! L'ombre qui protégeait Radu se déchire en lambeaux… Maintenant, il est vulnérable !", 6.0)
			_sfx("vampire_siffle", _radu.global_position + Vector3.UP * 1.6)
		else:
			_say("Les quatre braseros flambent. Pour la première fois depuis cent ans, la salle d'armes est éclairée.", 5.0)
	else:
		_say("Le brasero s'embrase. (%d sur %d)" % [n, BRASEROS.size()], 3.0)


func _radu_dead() -> void:
	state["radu"] = true
	_radu = null
	_say("Le chevalier Radu met un genou à terre. « Bien combattu… chevalier. » Puis il tombe en poussière. Son rubis brille dans le sable. (Rubis : %d sur 3)" % rubis(), 8.0)
	_after_rubis()


# ------------------------------------------------------------------- les combats

## Un des enfants du comte : la barre de vie en haut, un appel à l'aide à mi-vie
func _fight_with(m: Node3D, label: String, cb: Callable) -> void:
	fight = true
	_boss = m
	_boss_cb = cb
	m.set_meta("appel", false)
	m.wake()
	_show_bar(label, int(m.spec["pv"]))


func _boss_phases() -> void:
	if not fight or _boss == null or not is_instance_valid(_boss):
		return
	if bool(_boss.get_meta("appel", false)) or str(_boss.kind) == "radu":
		return
	if int(_boss.hp) < int(_boss.spec["pv"]) * 0.5:
		_boss.set_meta("appel", true)
		var at: Vector3 = L(_boss.global_position)
		_say("« À moi, mes enfants ! » Deux vampires sortent d'une nuée de chauves-souris !", 4.0)
		_sfx("nuee_chauves_souris", _boss.global_position + Vector3.UP * 2.0)
		for s in [-1.0, 1.0]:
			var p: Vector3 = at + Vector3(s * 2.2, 0.05, 1.5)
			var m: Node3D = spawn_in(room, "vampire", p, true)
			if m != null:
				m.bats_burst(m.global_position + Vector3.UP * 1.3, 4)


## Un rubis de plus : Mortimer le saura ; le carnet aussi
func _after_rubis() -> void:
	if main.has_method("jingle"):
		main.jingle("decouverte")
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()
	if rubis() >= 3:
		get_tree().create_timer(8.0).timeout.connect(func(): if room != "": _say("Les trois rubis… Sur la galerie du vestibule, la porte de la Tour du Comte t'attend.", 5.0))


# =================================================================== Mortimer

func _mortimer_talk() -> void:
	if _mortimer == null or not is_instance_valid(_mortimer):
		return
	var at: Vector3 = _mortimer.global_position + Vector3.UP * 1.7
	var t: String
	if not bool(state["mortimer"]):
		state["mortimer"] = true
		t = "« Ah… un visiteur. Cela faisait bien longtemps. » Le vieil homme s'incline, très bas. Sa peau est blanche comme la cire de ses bougies, et ses yeux luisent, un peu. « Mortimer, majordome de Monsieur le Comte depuis… oh, trois cent douze ans. Monsieur le Comte vous attend, naturellement. Il attend toujours. »"
		var j: Node = main.get("journal_v56")
		if j != null and j.has_method("refresh"):
			j.refresh()
	elif int(state["poses"]) >= 3:
		t = "« La porte de la tour est ouverte… » Mortimer regarde ses chaussures. « Monsieur le Comte vous recevra quand il le jugera bon. Il aime faire attendre. Moi, je garde le thé au chaud. »"
	else:
		var n: int = rubis()
		t = ["« Toujours là ? Les trois rubis, souvenez-vous : la comtesse au bal, le baron dans la bibliothèque, le chevalier dans la salle d'armes. »",
			"« Un rubis déjà… » Il soupire. « La maison est plus calme, d'un coup. Plus que deux. »",
			"« Deux rubis ! » Il lisse sa veste. « Je n'aurais jamais cru dire cela, mais… courage. Plus qu'un. »",
			"« Les trois rubis ! Posez-les sur la porte de la tour, là-haut, sur la galerie. Je… je ne vous ai rien dit. »"][clampi(n, 0, 3)]
	_ask(at, "Mortimer", "courtois", t,
		[{"id": "qui", "label": "Qui êtes-vous, au juste ?"}, {"id": "comte", "label": "Où est le comte ?"},
		{"id": "villageois", "label": "Et les gens de la ville ?"}, {"id": "aide", "label": "Vous allez m'aider ?"},
		{"id": "fermer", "label": "Merci, Mortimer."}],
		Callable(self, "_mortimer_answer"))


func _mortimer_answer(id: String) -> void:
	if _mortimer == null or not is_instance_valid(_mortimer):
		_close_dialog()
		return
	var t: String = {
		"qui": "« Un vampire, si le mot ne vous effraie pas. Un vieux. Je n'ai plus de dents pour mordre, voyez-vous : je sers le thé. Monsieur le Comte m'a gardé pour mes bonnes manières. »",
		"comte": "« Tout en haut de la Tour, derrière la grande porte de la galerie. Mais elle ne s'ouvre qu'avec les trois rubis de la famille, et ses trois enfants en portent chacun un : la comtesse Ilona danse dans la salle de bal, à l'ouest, au bout de la galerie des portraits ; le baron Sigismund lit dans la bibliothèque, à l'est ; le chevalier Radu s'entraîne dans la salle d'armes, en bas. Ils ne vous les donneront pas de bon cœur. »",
		"villageois": "« Ceux qui marchent dehors… ne sont plus vraiment des gens. Ceux qui ont résisté sont enfermés sous le château, dans les vieux souterrains. Monsieur le Comte garde la clé sur lui, nuit et jour. » Il baisse la voix. « Entre nous… je les entends pleurer, la nuit. Je n'aime pas ça. Je n'ai jamais aimé ça. »",
		"aide": "« Moi ? Je suis un majordome. Je ne prends pas parti. » Un long silence. « Mais si quelqu'un me demandait mon avis… je dirais que la comtesse ne se voit pas dans les miroirs, que le baron ne résiste jamais à une bonne devinette, et que le chevalier a peur de la lumière. »",
	}.get(id, "")
	if t == "":
		_close_dialog()
		return
	_ask(_mortimer.global_position + Vector3.UP * 1.7, "Mortimer", "courtois", t,
		[{"id": "qui", "label": "Qui êtes-vous, au juste ?"}, {"id": "comte", "label": "Où est le comte ?"},
		{"id": "villageois", "label": "Et les gens de la ville ?"}, {"id": "aide", "label": "Vous allez m'aider ?"},
		{"id": "fermer", "label": "Merci, Mortimer."}],
		Callable(self, "_mortimer_answer"))


# =================================================================== la porte de la tour

func _porte_tour() -> void:
	var n: int = rubis()
	var poses: int = int(state["poses"])
	if n <= poses:
		if poses == 0:
			_say("Une porte immense, cerclée de fer. Au-dessus, trois chatons d'or, vides, en forme de goutte… Il faut trois rubis. Mortimer en saura peut-être plus.", 6.0)
		else:
			_say("%d rubis sur 3 brillent déjà au-dessus de la porte. Il en manque encore." % poses, 4.0)
		return
	state["poses"] = n
	_show_tower(false, false)
	_sfx("sceau_pose", W(Vector3(0, 10.9, -14.5)))
	if n < 3:
		_say("Tu poses ton rubis dans son chaton d'or : il s'allume, rouge sang. (%d sur 3)" % n, 4.5)
		return
	_say("Le troisième rubis s'allume. Les trois brillent ensemble… La porte frémit, les verrous claquent un à un — et les deux battants s'ouvrent lentement sur un escalier qui monte dans le noir.", 8.0)
	_sfx("porte_grince", W(Vector3(0, 8.0, -14.5)))
	_show_tower(true, true)
	get_tree().create_timer(4.5).timeout.connect(func():
		if room != "":
			_sfx("vampire_rire", W(Vector3(0, 14.0, -18.0)))
			_say("Une voix grave, très lente, descend de la tour : « Mes enfants… Tu as tué mes enfants. » Un silence. « Monte, petit voyageur. Je t'attends. »", 8.0))
	var j: Node = main.get("journal_v56")
	if j != null and j.has_method("refresh"):
		j.refresh()


func _porte_fer() -> void:
	_sfx("grille", W(Vector3(-2.8, 12.6, -20.5)))
	if not bool(state["tour"]):
		state["tour"] = true
		if main.has_method("jingle"):
			main.jingle("decouverte")
		var j: Node = main.get("journal_v56")
		if j != null and j.has_method("refresh"):
			j.refresh()
	_say("La porte de fer ne bouge pas. De l'autre côté, la voix du comte, toute proche : « Pas encore, petit voyageur. La lune n'est pas encore pleine… Reviens bientôt. Je t'attendrai. » Puis un rire, qui roule dans toute la tour.", 9.0)
	get_tree().create_timer(1.0).timeout.connect(func(): _sfx("vampire_rire", W(Vector3(-3.5, 12.6, -20.5))))


func _horloge_regard() -> void:
	_say("La grande horloge est arrêtée sur minuit, comme toutes celles de la ville. Son balancier ne bouge plus… et pourtant, tu jurerais l'avoir entendu battre, il y a un instant.", 6.0)
	if _clock_pend != null:
		var tw := create_tween()
		for k in range(6):
			tw.tween_property(_clock_pend, "rotation:x", 0.18 if k % 2 == 0 else -0.18, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_clock_pend, "rotation:x", 0.0, 0.9)
		_sfx("cloche_cathedrale", W(Vector3(-10.9, 2.0, -9.0)))


# =================================================================== pour Sombreval

## La zone du joueur (pour la musique et les ambiances) : « chateau_<salle> »
func zone_name(p: Vector3) -> String:
	var r: String = _room_of(p)
	if r == "":
		return "chateau_hall"
	if r == "bal" and _bal_music:
		return "chateau_bal_valse"
	return "chateau_" + r


func trouvailles() -> Dictionary:
	return {"sv_chateau": 1 if bool(state["visite"]) else 0, "sv_mortimer": 1 if bool(state["mortimer"]) else 0,
		"sv_ilona": 1 if bool(state["ilona"]) else 0, "sv_sigismund": 1 if bool(state["sigismund"]) else 0,
		"sv_radu": 1 if bool(state["radu"]) else 0, "sv_rubis": 1 if int(state["poses"]) >= 3 else 0,
		"sv_tour": 1 if bool(state["tour"]) else 0}

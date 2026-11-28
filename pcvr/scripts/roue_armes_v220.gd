extends Node3D
## V220 : en VR, changer d'arme et de pouvoir d'un geste. Le casque a peu de boutons ; la magie avait déjà sa
## roue (V145 : gâchette gauche tenue, autour de la main gauche). Ici, la même chose pour la main droite :
##  - poignée droite tenue : la roue des armes s'ouvre autour de la main droite (tout ce qu'on peut tenir et
##    qu'on possède : les armes, la canne à pêche, la pelle, le pinceau ; et « mains nues », en haut) ; on
##    pousse la main vers une case (la manette vibre à chaque case survolée), on relâche : c'est en main ;
##  - poignée droite tapée : on reprend ce qu'on tenait juste avant (l'épée, les mains nues, l'épée…) ;
##    les mains nues et rien d'avant : la meilleure arme ;
##  - B tenu : la roue des pouvoirs des sceaux, de la même façon ; B tapé : lancer le pouvoir (comme avant).
## Une roue ouverte sans rien désigner, relâchée vite, compte pour un coup bref (personne n'est puni d'avoir
## appuyé un peu long). Dans l'eau, B garde son usage (plonger) : pas de roue des pouvoirs.
## La main doit être posée : beaucoup serrent la poignée par habitude en frappant. Si la main bouge pendant
## l'appui (un coup d'épée), la poignée ne fait rien du tout — ni roue, ni changement d'arme — et B lance
## simplement le pouvoir, aussi long que soit l'appui.
## Pour annuler : on éloigne la main de la roue (plus d'une trentaine de centimètres), elle se referme sans rien
## changer. Elle se referme de même si le jeu passe à autre chose (le sac, le menu, une conversation) ; et un
## bouton encore tenu quand le jeu revient (une conversation fermée avec B, un objet jeté avec la poignée) ne
## compte pas : il attend d'être relâché.
## Sur PC, rien : les touches suffisent. Le déplacement au joystick ne change pas.

const Langue := preload("res://scripts/langue_v104.gd")
const Roue145 := preload("res://scripts/roue_v145.gd")

const RAYON: float = 0.13              # m : le rayon de la roue autour de la main
const SEUIL: float = 0.045             # m : la main doit s'écarter d'autant du centre pour désigner une case
const TENIR: float = 0.25              # s : au-delà, le bouton tenu ouvre la roue
const BREF: float = 0.6                # s : une roue ouverte sans rien désigner, relâchée avant : un coup bref
const BOUGE: float = 0.07              # m : la main qui s'écarte d'autant pendant l'appui n'est pas « posée »
const LOIN: float = 0.34               # m : la main partie plus loin que ça de la roue ouverte : on annule
const PLACES_MAX: int = 12             # cases d'une roue, « mains nues » comprise
# le liseré d'une case (le disque, sombre, prend la même teinte) : une arme, un outil, les mains nues
const C_ARME := Color(1.0, 0.8, 0.5)
const C_OUTIL := Color(0.6, 0.95, 0.74)
const C_MAINS := Color(1.0, 0.94, 0.84)
const C_DORT := Color(0.55, 0.57, 0.62)
const FICHIER := "user://roue_v220.cfg"

var main: Node
var test_mode: bool = false            # les essais appellent tick eux-mêmes
var ouverte: String = ""               # "", "armes" ou "pouvoirs"
var survol: int = -1
var cases: Array = []                  # la roue ouverte : [{id, nom, detail, icone, couleur, teinte, ok}]
var avant: String = ""                 # ce qu'on tenait avant le dernier changement
var choix_faits: int = 0
var retours: int = 0                   # la poignée tapée a repris l'arme d'avant
var annulees: int = 0                  # une roue refermée sans rien prendre (la main partie loin, le jeu ailleurs)
var lances: int = 0                    # B tapé a lancé le pouvoir
var conseil_donne: bool = false
var prepare: bool = false              # les images des roues sont dessinées (au chargement, dans le casque)

var _t_poignee: float = -1.0
var _t_b: float = -1.0
var _poignee_muette: bool = false      # tenue, mais elle n'ouvrira plus rien avant d'être relâchée
var _b_muet: bool = false
var _depart_poignee := Vector3.ZERO
var _depart_b := Vector3.ZERO
var _ancre := Vector3.ZERO             # dans le repère du joueur (xr_origin)
var _plan := Basis()
var _t_ouverte: float = 0.0
var _roue3d: Node3D
var _slots3d: Array = []
var _label3d: Label3D
var _anneau3d: MeshInstance3D          # un second liseré autour de ce qu'on tient déjà
var _suivi: String = ""               # ce qui est en main (pour retenir « avant »)
var _conseil_t: float = 0.0
var _pas_tick: int = -1                # le dernier pas de physique où le jeu a donné la main à la roue

static var _icones: Dictionary = {}
static var _pastille: Texture2D
static var _anneau: Texture2D


func _ready() -> void:
	# (on ne veille que pendant qu'une roue est ouverte)
	set_physics_process(false)


func setup(main_node: Node) -> void:
	main = main_node
	name = "Roue_armes_v220"
	var inv: Node = _sac()
	if inv != null:
		_suivi = str(inv.equipped)
	var cf := ConfigFile.new()
	if cf.load(FICHIER) == OK:
		conseil_donne = bool(cf.get_value("conseil", "vu", false))
	# Dans le casque, les images des roues se dessinent pendant le chargement : la première roue s'ouvre sans
	# à-coup (sur PC, rien : ces roues ne s'y ouvrent pas).
	if bool(main.get("xr_active")):
		preparer()


## Les images dessinées des roues, une fois pour toutes : les pastilles, les icônes de la main droite, et
## celles de la roue des sorts (V145 : sept icônes, plus d'un tiers de seconde d'arrêt à sa première ouverture).
func preparer() -> void:
	pastille()
	anneau()
	for nom in ["main", "lune", "rouage", "vent"]:
		icone(nom)
	Roue145.pastille()
	var r145: Node = main.get("roue_v145") if main != null else null
	if r145 != null and r145.has_method("_ordre"):
		for id in r145._ordre():
			Roue145.icone(str(id))
	else:
		Roue145.icone("feu")
	prepare = true


func _sac() -> Node:
	return main.get("inventory_v28") if main != null else null


func _progression() -> Node:
	return main.get("progression_v63") if main != null else null


# =================================================================== les icônes (blanches, teintées à l'affichage)

static func icone(nom: String) -> Texture2D:
	if _icones.has(nom):
		return _icones[nom]
	var n: int = 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var p := Vector2((x + 0.5) / n * 2.0 - 1.0, 1.0 - (y + 0.5) / n * 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(_dessin(nom, p), 0.0, 1.0)))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_icones[nom] = tex
	return tex


## Un disque plein, au bord doux (1 dedans, 0 dehors).
static func _disque(p: Vector2, c: Vector2, r: float) -> float:
	return clampf((r - p.distance_to(c)) / 0.05 + 0.5, 0.0, 1.0)


## Un trait épais aux bouts ronds, de a à b.
static func _trait(p: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return clampf((r - p.distance_to(a + ab * t)) / 0.05 + 0.5, 0.0, 1.0)


## Une boîte aux coins ronds (c : le centre, demi : les demi-côtés, r : le rayon des coins).
static func _boite(p: Vector2, c: Vector2, demi: Vector2, r: float) -> float:
	var q: Vector2 = (p - c).abs() - (demi - Vector2(r, r))
	var d: float = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
	return clampf(-d / 0.05 + 0.5, 0.0, 1.0)


## La pastille d'une case : un disque sombre et plein (les objets du sac sont en couleurs : il leur faut un
## fond franc, devant le ciel comme devant la roche) et un liseré clair ; le tout est teinté à l'affichage.
static func pastille() -> Texture2D:
	if _pastille != null:
		return _pastille
	var n: int = 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var d: float = Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var disque: float = clampf((0.94 - d) * 24.0, 0.0, 1.0)
			var lisere: float = clampf(1.0 - absf(d - 0.87) / 0.075, 0.0, 1.0)
			# (un rien plus clair en haut : un bouton, pas un trou)
			var fond: float = 0.17 + 0.09 * (1.0 - float(y) / n)
			var clair: float = lerpf(fond, 1.0, lisere)
			img.set_pixel(x, y, Color(clair, clair, clair, maxf(disque * 0.82, lisere)))
	img.generate_mipmaps()
	_pastille = ImageTexture.create_from_image(img)
	return _pastille


## Un liseré seul, fin : il entoure la case de ce qu'on tient déjà.
static func anneau() -> Texture2D:
	if _anneau != null:
		return _anneau
	var n: int = 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var d: float = Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - absf(d - 0.9) / 0.05, 0.0, 1.0)))
	img.generate_mipmaps()
	_anneau = ImageTexture.create_from_image(img)
	return _anneau


## Ce que couvre le dessin en ce point (x à droite, y en haut, de -1 à 1).
static func _dessin(nom: String, p: Vector2) -> float:
	match nom:
		"main":
			# une main ouverte : la paume, quatre doigts séparés, le pouce écarté
			var a: float = _boite(p, Vector2(0.06, -0.38), Vector2(0.37, 0.3), 0.15)
			var hauts: Array = [0.5, 0.68, 0.62, 0.42]
			for i in range(4):
				var x: float = -0.225 + 0.19 * i
				a = maxf(a, _trait(p, Vector2(x, -0.2), Vector2(x, float(hauts[i])), 0.08))
			return maxf(a, _trait(p, Vector2(-0.26, -0.44), Vector2(-0.62, -0.04), 0.095))
		"lune":
			# un croissant : un disque, moins un disque décalé
			return _disque(p, Vector2(-0.05, 0.0), 0.68) * (1.0 - _disque(p, Vector2(0.28, 0.14), 0.56))
		"rouage":
			# une roue dentée : huit dents, un moyeu percé
			var ang: float = atan2(p.y, p.x)
			var r: float = 0.56 + 0.16 * clampf(cos(ang * 8.0) * 3.0 + 0.5, 0.0, 1.0)
			return clampf((r - p.length()) / 0.05 + 0.5, 0.0, 1.0) * (1.0 - _disque(p, Vector2.ZERO, 0.2))
		"vent":
			# trois souffles : des traits qui ondulent, le dernier se boucle un peu
			var a2: float = 0.0
			for i in range(3):
				var y0: float = 0.42 - 0.42 * i
				var x: float = clampf(p.x, -0.72, 0.6 - 0.14 * i)
				var y: float = y0 + 0.11 * sin(x * 4.2 + i * 1.3)
				a2 = maxf(a2, clampf((0.075 - p.distance_to(Vector2(x, y))) / 0.05 + 0.5, 0.0, 1.0))
			return a2
	return 0.0


# =================================================================== ce qu'on met dans les roues

## Peut-on tenir cet objet en main ?
func _se_tient(info: Dictionary) -> bool:
	var k: String = str(info.get("kind", ""))
	return k == "arme" or k == "canne" or (k == "outil" and bool(info.get("equip", false)))


## La roue des armes : « mains nues », puis ce qu'on possède et qu'on peut tenir, toujours dans le même ordre
## (celui de la liste des objets du jeu, pas celui des cases du sac : une arme ne change pas de place quand on
## range son sac). S'il y en a trop pour une roue, on laisse de côté les armes les plus faibles.
func liste_armes() -> Array:
	var inv: Node = _sac()
	var l: Array = [{"id": "", "nom": "Mains nues", "detail": "", "icone": icone("main"), "couleur": C_MAINS, "teinte": C_MAINS, "ok": true}]
	if inv == null:
		return l
	var tenus: Array = []
	for id in inv.ITEMS:
		if _se_tient(inv.ITEMS[id]) and int(inv.count(str(id))) > 0:
			tenus.append(str(id))
	while tenus.size() > PLACES_MAX - 1:
		var faible: int = -1
		var fd: int = 999999
		for i in range(tenus.size()):
			var info: Dictionary = inv.ITEMS[tenus[i]]
			if str(info.get("kind", "")) == "arme" and int(info.get("damage", 0)) < fd:
				fd = int(info.get("damage", 0))
				faible = i
		if faible < 0:
			faible = tenus.size() - 1
		tenus.remove_at(faible)
	for id in tenus:
		var info2: Dictionary = inv.ITEMS[id]
		var arme: bool = str(info2.get("kind", "")) == "arme"
		var detail: String = (Langue.t("dégâts : %d") % int(info2.get("damage", 0))) if arme else ""
		var ic: Variant = inv._icons.get(id) if inv.get("_icons") is Dictionary else null
		l.append({"id": id, "nom": str(info2.get("name", id)), "detail": detail, "icone": ic,
			"couleur": C_ARME if arme else C_OUTIL, "teinte": Color(1, 1, 1), "ok": true})
	return l


## La meilleure arme qu'on possède (« » : aucune).
func meilleure_arme() -> String:
	var inv: Node = _sac()
	var best: String = ""
	var bd: int = -1
	if inv == null:
		return best
	for id in inv.ITEMS:
		var info: Dictionary = inv.ITEMS[id]
		if str(info.get("kind", "")) == "arme" and int(inv.count(str(id))) > 0 and int(info.get("damage", 0)) > bd:
			bd = int(info.get("damage", 0))
			best = str(id)
	return best


## La roue des pouvoirs : les quatre pouvoirs des sceaux, ceux qu'on n'a pas encore en gris.
func liste_pouvoirs() -> Array:
	var pr: Node = _progression()
	var l: Array = []
	if pr == null:
		return l
	var fx: Node = main.get("combat_fx_v129")
	var dessins: Dictionary = {"vent": "vent", "rouage": "rouage", "lune": "lune"}
	for pid in pr.POWER_ORDER:
		var a_lui: bool = bool(pr.power_owned(str(pid)))
		var s: Dictionary = pr.SEALS[pr.POWER_OF[pid]]
		var col: Color = (fx.POUVOIRS.get(pid, Color(0.8, 0.8, 0.9)) as Color) if fx != null else Color(0.8, 0.8, 0.9)
		var ic: Texture2D = Roue145.icone("feu") if str(pid) == "flamme" else icone(str(dessins.get(pid, "lune")))
		l.append({"id": str(pid), "nom": str(s["pnom"]) if a_lui else "?", "detail": "", "icone": ic,
			"couleur": col.lightened(0.25) if a_lui else C_DORT, "teinte": col.lightened(0.6) if a_lui else C_DORT, "ok": a_lui})
	return l


# =================================================================== la roue : les places

## La direction d'une case (0 en haut, puis dans le sens des aiguilles d'une montre ; x à droite, y en haut).
func dir_case(i: int) -> Vector2:
	var a: float = PI * 0.5 - TAU * float(i) / float(maxi(cases.size(), 1))
	return Vector2(cos(a), sin(a))


## La case la plus proche d'une direction.
func _place(v: Vector2) -> int:
	var n: int = cases.size()
	if n == 0:
		return -1
	var a: float = atan2(v.y, v.x)
	var best: int = 0
	var bd: float = INF
	for i in range(n):
		var d: float = absf(wrapf(a - (PI * 0.5 - TAU * float(i) / float(n)), -PI, PI))
		if d < bd:
			bd = d
			best = i
	return best


func _vibre(amp: float, dur: float) -> void:
	if main == null or not bool(main.get("xr_active")) or main.get("right_hand") == null:
		return
	if main.right_hand.has_method("trigger_haptic_pulse"):
		main.right_hand.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)


func _survoler(i: int) -> void:
	if i == survol:
		return
	survol = i
	if i >= 0:
		main.sfx("roue_tic")
		_vibre(0.18, 0.03)


## La main droite choisit dans une roue : elle ne donne pas de coups pendant ce temps.
func main_droite_occupee() -> bool:
	return ouverte != ""


## Dans l'eau, B sert à plonger : la roue des pouvoirs ne s'ouvre pas, B garde son usage d'avant.
func b_comme_avant() -> bool:
	var mer: Node = main.get("mer_v55") if main != null else null
	return mer != null and bool(mer.get("swimming"))


# =================================================================== ouvrir, prendre, fermer

## Ouvre une roue autour de la main (ou : la main droite, tete : la tête, dans le repère du joueur).
func _ouvrir(quelle: String, tete: Vector3, ou: Vector3) -> bool:
	var l: Array = liste_armes() if quelle == "armes" else liste_pouvoirs()
	if quelle == "armes" and l.size() < 2:
		main._show_message_v28("Rien d'autre à tenir pour l'instant.")
		return false
	if quelle == "pouvoirs":
		var un: bool = false
		for c in l:
			un = un or bool(c["ok"])
		if not un:
			return false
	cases = l
	ouverte = quelle
	survol = -1
	_t_ouverte = 0.0
	# (autour de la main là où elle est maintenant : rien n'est désigné tant qu'elle ne bouge pas)
	_ancre = ou
	main.sfx("roue_ouvre")
	_vibre(0.3, 0.05)
	var vers_tete: Vector3 = tete - _ancre
	if vers_tete.length() < 0.05:
		vers_tete = Vector3.BACK
	var n: Vector3 = vers_tete.normalized()
	# (la roue fait face à la tête ; la main juste à la verticale de la tête : le haut de la roue part vers l'avant)
	_plan = Basis.looking_at(-n, Vector3.UP if absf(n.y) < 0.999 else Vector3.FORWARD)
	_construire_3d()
	_roue3d.transform = Transform3D(_plan, _ancre)
	_roue3d.scale = Vector3.ONE * 0.2
	_roue3d.visible = true
	_maj_3d(0.0)
	_pas_tick = Engine.get_physics_frames()
	set_physics_process(true)
	return true


func _fermer() -> void:
	ouverte = ""
	survol = -1
	if _roue3d != null:
		_roue3d.visible = false
	set_physics_process(false)


## La roue ouverte se referme sans rien prendre ; les boutons encore tenus attendent d'être relâchés.
func annuler() -> void:
	if ouverte == "":
		return
	_fermer()
	annulees += 1
	_t_poignee = -1.0
	_t_b = -1.0
	_poignee_muette = true
	_b_muet = true
	_vibre(0.12, 0.03)


## Une roue ouverte que le jeu n'écoute plus (le sac, le menu, une conversation, une échelle, un véhicule :
## main.gd ne passe plus par _vr_actions_v28) ne reste pas figée devant le joueur : elle se referme.
func _physics_process(_delta: float) -> void:
	if ouverte != "" and Engine.get_physics_frames() - _pas_tick > 3:
		annuler()


## On prend la case désignée. Renvoie vrai si quelque chose a changé.
func _prendre() -> bool:
	if survol < 0 or survol >= cases.size():
		return false
	var c: Dictionary = cases[survol]
	if ouverte == "armes":
		var inv: Node = _sac()
		if inv == null or str(inv.equipped) == str(c["id"]):
			return false
		main.sfx("equiper")
		inv.equip_item(str(c["id"]))
		if str(c["id"]) == "":
			main._show_message_v28("Mains nues.")
		choix_faits += 1
		_vibre(0.5, 0.06)
		return true
	var pr: Node = _progression()
	if pr == null:
		return false
	if not bool(c["ok"]):
		main.sfx("ui_erreur")
		main._show_message_v28("Ce pouvoir dort encore : un des quatre sceaux de la grande île le garde.")
		return false
	if pr.select_power(str(c["id"])):
		choix_faits += 1
		_vibre(0.5, 0.06)
		main._show_message_v28(Langue.t("Pouvoir choisi : %s (B pour le lancer)") % Langue.t(str(c["nom"])))
		return true
	return false


## La poignée tapée : on reprend ce qu'on tenait avant ; rien d'avant : les mains nues ou la meilleure arme.
func retour() -> bool:
	var inv: Node = _sac()
	if inv == null:
		return false
	var en_main: String = str(inv.equipped)
	var cible: String = avant
	if cible != "" and int(inv.count(cible)) <= 0:
		cible = ""
	if cible == en_main:
		cible = "" if en_main != "" else meilleure_arme()
	if cible == en_main:
		return false
	main.sfx("equiper")
	inv.equip_item(cible)
	if cible == "":
		main._show_message_v28("Mains nues.")
	retours += 1
	_vibre(0.4, 0.05)
	return true


func _lancer_pouvoir() -> void:
	var pr: Node = _progression()
	if pr != null:
		lances += 1
		pr.use_power()


# =================================================================== la roue dans le casque

func _quad(parent: Node3D, tex: Texture2D, taille: float, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(taille, taille)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.no_depth_test = true
	m.render_priority = prio
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# (une roue d'interface : toujours dessinée, quelle que soit la distance)
	mi.set_meta("portee_libre", true)
	parent.add_child(mi)
	return mi


## (Re)bâtit la roue pour les cases du moment (une douzaine d'objets au plus).
func _construire_3d() -> void:
	if _roue3d == null:
		_roue3d = Node3D.new()
		_roue3d.name = "Roue_main_droite_v220"
		var parent: Node3D = main.get("xr_origin")
		(parent if parent != null else self).add_child(_roue3d)
	for s in _slots3d:
		if is_instance_valid(s["node"]):
			(s["node"] as Node).queue_free()
	_slots3d.clear()
	var rayon: float = RAYON * (1.0 if cases.size() <= 8 else 1.25)
	for i in range(cases.size()):
		var slot := Node3D.new()
		_roue3d.add_child(slot)
		var d: Vector2 = dir_case(i)
		slot.position = Vector3(d.x, d.y, 0.0) * rayon
		var fond: MeshInstance3D = _quad(slot, pastille(), 0.072, 20)
		var ic: MeshInstance3D = null
		if cases[i]["icone"] is Texture2D:
			ic = _quad(slot, cases[i]["icone"], 0.05, 21)
			ic.position.z = 0.002
		_slots3d.append({"node": slot, "fond": fond, "icone": ic})
	if _anneau3d == null:
		_anneau3d = _quad(_roue3d, anneau(), 0.094, 19)
	if _label3d == null:
		_label3d = Label3D.new()
		_label3d.font_size = 36
		_label3d.pixel_size = 0.0006
		_label3d.outline_size = 10
		_label3d.no_depth_test = true
		_label3d.render_priority = 22
		_label3d.outline_render_priority = 21
		_roue3d.add_child(_label3d)


func _maj_3d(delta: float) -> void:
	if _roue3d == null or not _roue3d.visible:
		return
	if delta > 0.0:
		_roue3d.scale = _roue3d.scale.lerp(Vector3.ONE, clampf(delta * 14.0, 0.0, 1.0))
	var en_main: String = ""
	if ouverte == "armes" and _sac() != null:
		en_main = str(_sac().equipped)
	elif ouverte == "pouvoirs" and _progression() != null:
		en_main = str(_progression().power)
	var courant: int = -1
	for i in range(mini(_slots3d.size(), cases.size())):
		var s: Dictionary = _slots3d[i]
		var c: Dictionary = cases[i]
		var sur: bool = i == survol
		var actuel: bool = str(c["id"]) == en_main
		if actuel:
			courant = i
		var dort: bool = not bool(c["ok"])
		(s["node"] as Node3D).scale = Vector3.ONE * (1.3 if sur else 1.0)
		var fm: StandardMaterial3D = ((s["fond"] as MeshInstance3D).mesh as QuadMesh).material
		var col: Color = c["couleur"]
		if sur and not dort:
			col = col.lightened(0.45)
		fm.albedo_color = Color(col.r, col.g, col.b, 0.6 if dort else (1.0 if (sur or actuel) else 0.92))
		if s["icone"] != null:
			var im: StandardMaterial3D = ((s["icone"] as MeshInstance3D).mesh as QuadMesh).material
			var teinte: Color = c["teinte"]
			im.albedo_color = Color(teinte.r, teinte.g, teinte.b, 0.55 if dort else 1.0)
	# (ce qu'on tient déjà : un second liseré autour de sa case)
	if _anneau3d != null:
		_anneau3d.visible = courant >= 0
		if courant >= 0:
			var sc: Node3D = _slots3d[courant]["node"]
			_anneau3d.position = sc.position
			_anneau3d.scale = sc.scale
			var ca: Color = cases[courant]["couleur"]
			((_anneau3d.mesh as QuadMesh).material as StandardMaterial3D).albedo_color = ca.lightened(0.3)
	var i2: int = survol if survol >= 0 else courant
	if i2 >= 0 and i2 < cases.size():
		var c2: Dictionary = cases[i2]
		var texte: String = Langue.t(str(c2["nom"]))
		if str(c2["detail"]) != "":
			texte += "\n" + str(c2["detail"])
		_label3d.text = texte
		_label3d.modulate = (c2["teinte"] as Color).lerp(Color(1, 1, 1), 0.3)
		# (le nom se pose à côté de sa case, vers le dehors de la roue : au milieu, il tomberait sur la main et
		# sur l'arme qu'elle tient)
		var sn: Node3D = _slots3d[i2]["node"]
		var d: Vector2 = dir_case(i2)
		var bord: float = 0.036 * sn.scale.x + 0.012
		if absf(d.x) > 0.6:
			_label3d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if d.x > 0.0 else HORIZONTAL_ALIGNMENT_RIGHT
			_label3d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label3d.position = sn.position + Vector3(signf(d.x) * bord, 0.0, 0.004)
		else:
			_label3d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label3d.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if d.y > 0.0 else VERTICAL_ALIGNMENT_TOP
			_label3d.position = sn.position + Vector3(0.0, signf(d.y) * bord, 0.004)
	else:
		_label3d.text = ""


# =================================================================== chaque image, en VR

## Ce qu'on tient a changé (par la roue, le sac, une quête…) : on retient ce qu'on tenait avant.
func _suivre_main() -> void:
	var inv: Node = _sac()
	if inv == null:
		return
	var en_main: String = str(inv.equipped)
	if en_main != _suivi:
		avant = _suivi
		_suivi = en_main


## À chaque image en VR (main._vr_actions_v28) : la poignée droite, B, la main droite et la tête.
func vr_tick(delta: float) -> void:
	if main == null or test_mode:
		return
	var rh: XRController3D = main.right_hand
	tick(delta, rh.get_float("grip") > 0.6, rh.is_button_pressed("by_button"), rh.position, main.xr_camera.position)
	_conseil(delta)


## Le cœur (les essais l'appellent avec des gestes fabriqués) : poignee, b : les boutons tenus ; main_r, tete :
## la main droite et la tête dans le repère du joueur.
func tick(delta: float, poignee: bool, b: bool, main_r: Vector3, tete: Vector3) -> void:
	var pas: int = Engine.get_physics_frames()
	if _pas_tick < 0 or pas - _pas_tick > 3:
		# (le jeu était ailleurs — le sac, un menu, une conversation, un véhicule : un bouton encore tenu en
		# revenant ne compte pas, il attend d'être relâché)
		annuler()
		_t_poignee = -1.0
		_t_b = -1.0
		_poignee_muette = poignee
		_b_muet = b
	_pas_tick = pas
	_suivre_main()
	var eau: bool = b_comme_avant()
	if eau:
		# (dans l'eau, B plonge ; en sortant de l'eau B encore tenu, il attendra d'être relâché)
		_t_b = -1.0
		_b_muet = b
		b = false
		if ouverte == "pouvoirs":
			_fermer()
	# une roue ouverte : la main désigne, on relâche pour prendre
	if ouverte != "":
		_t_ouverte += delta
		var tenu: bool = poignee if ouverte == "armes" else b
		if tenu:
			var off: Vector3 = _plan.inverse() * (main_r - _ancre)
			if off.length() > LOIN:
				# (la main est partie loin de la roue — on y renonce, ou un coup d'épée la poignée serrée)
				annuler()
				return
			var v2 := Vector2(off.x, off.y)
			_survoler(_place(v2) if v2.length() > SEUIL else -1)
			_maj_3d(delta)
		else:
			var quelle: String = ouverte
			var rien: bool = survol < 0
			_prendre()
			_fermer()
			# (ouverte sans rien désigner et relâchée vite : c'était un coup bref un peu long)
			if rien and _t_ouverte + TENIR < BREF:
				if quelle == "armes":
					retour()
				else:
					_lancer_pouvoir()
			_t_poignee = -1.0
			_t_b = -1.0
			# (l'autre bouton, s'il est encore tenu, attend d'être relâché)
			_poignee_muette = poignee
			_b_muet = b
		return
	# la poignée droite
	if poignee:
		if _poignee_muette:
			pass
		elif _t_poignee < 0.0:
			_t_poignee = 0.0
			_depart_poignee = main_r
		elif main_r.distance_to(_depart_poignee) > BOUGE:
			# (la main bouge : on frappe, on ne choisit pas ; la poignée ne fera rien avant d'être relâchée)
			_poignee_muette = true
		else:
			_t_poignee += delta
			if _t_poignee >= TENIR:
				if _ouvrir("armes", tete, main_r):
					return
				# (rien d'autre à tenir : on attend qu'elle soit relâchée)
				_poignee_muette = true
	else:
		if _t_poignee >= 0.0 and not _poignee_muette:
			retour()
		_t_poignee = -1.0
		_poignee_muette = false
	# B (dans l'eau : rien, il plonge)
	if eau:
		pass
	elif b:
		if _b_muet:
			pass
		elif _t_b < 0.0:
			_t_b = 0.0
			_depart_b = main_r
		elif main_r.distance_to(_depart_b) > BOUGE:
			# (la main bouge : pas de roue ; au relâchement, le pouvoir part, comme un coup bref)
			_b_muet = true
		else:
			_t_b += delta
			if _t_b >= TENIR:
				if _ouvrir("pouvoirs", tete, main_r):
					return
				# (aucun pouvoir encore : au relâchement, le message d'avant)
				_b_muet = true
	else:
		if _t_b >= 0.0:
			_lancer_pouvoir()
		_t_b = -1.0
		_b_muet = false


## Une fois, la première fois dans le casque (après un moment de jeu) : le rappel des deux roues.
func _conseil(delta: float) -> void:
	if conseil_donne:
		return
	_conseil_t += delta
	if _conseil_t < 25.0 or ouverte != "":
		return
	conseil_donne = true
	main._show_message_v28("Dans le casque : gardez la poignée droite serrée pour changer d'arme (un coup bref : l'arme d'avant) ; gardez la gâchette gauche pour changer de sort ; gardez B pour changer de pouvoir.")
	var cf := ConfigFile.new()
	cf.set_value("conseil", "vu", true)
	cf.save(FICHIER)


func reset() -> void:
	_t_poignee = -1.0
	_t_b = -1.0
	_poignee_muette = false
	_b_muet = false
	_fermer()
	avant = ""
	var inv: Node = _sac()
	_suivi = str(inv.equipped) if inv != null else ""

extends Node
## V147 : les jeux de Pile-ou-Face : on s'assoit à une table, on mise, on joue, on se lève.
##  - la mise : en « Tout public », des jetons (la Caisse en donne chaque jour, on les échange contre des
##    lots) ; en « Public averti », des pièces, et l'on peut aussi miser un objet (le croupier l'estime) ;
##  - la réputation : de « pigeon » à « maître du jeu ». Elle monte quand on gagne, quand on sait
##    s'arrêter à temps (se lever avec un gain), quand on démasque un menteur ; elle baisse quand on se
##    fait plumer (trois coups perdus d'affilée), quand on s'acharne, quand on crie « Menteur ! » à tort ;
##  - les jeux de la Fosse aux Dés (V147) : le Grand Lancer (deux dés contre deux dés, face à Grand-Dé ;
##    le double six paie triple), le Sept (moins de sept, sept ou plus de sept, chez Monsieur Rouage,
##    l'automate de Gédéon), le Menteur (trois dés cachés chacun, contre Abélard Pépite, Hilda Enclume
##    et la Veuve Clou ; le dernier qui a des dés ramasse le pot).
## Les tables sont déclarées par le lieu (lieux_perchee_v147) quand on entre ; tapis_v147 est la fenêtre.

const Public = preload("res://scripts/public_v111.gd")
const Des = preload("res://scripts/des_v147.gd")
const Menteur = preload("res://scripts/menteur_v147.gd")
const Tapis = preload("res://scripts/tapis_v147.gd")

const TITRES := [[-45.0, "Pigeon"], [-15.0, "Bleu"], [15.0, "Joueur"], [45.0, "Fine lame"], [999.0, "Maître du jeu"]]
const MAX_MISE := 20
const BUYIN := 5
## Ce que vaut un objet misé (en pièces), en « Public averti ».
const VALEURS := {"pepite_or": 8, "rubis": 20, "perle": 12, "piece_or": 10, "eclat_cristal": 7, "obsidienne": 4, "cristal_soufre": 5,
	"chapeau_stetson": 15, "montre_envers": 9, "boussole": 6, "tarte_figue": 3, "haricots_ranch": 3, "salsepareille": 2, "miel": 3}
## Les lots de la Caisse (« Tout public ») : [objet, prix en jetons].
const LOTS := [["salsepareille", 15], ["haricots_ranch", 25], ["tarte_figue", 30], ["chapeau_stetson", 120], ["de_or", 250]]
const JETONS_JOUR := 30
## Les adversaires du Menteur : id du profil, nom court, caractère, répliques.
const ADVERSAIRES := [
	{"id": "pepite_pp", "nom": "Abélard", "prudence": 0.3, "bluff": 0.55, "alea": 0.15,
		"menteur": ["Menteur ! Ginette l'a vu !", "Hé hé… Menteur, jeunot !"], "perd": ["Ginette, tu m'avais dit cinq !", "Bah. Un dé de moins, une histoire de plus."], "gagne": ["De l'or, petit, de l'or ! Hé hé !"]},
	{"id": "hilda_pp", "nom": "Hilda", "prudence": 0.75, "bluff": 0.12, "alea": 0.05,
		"menteur": ["Menteur.", "Non. Menteur."], "perd": ["Hm. Bien joué.", "BANG. Raté."], "gagne": ["Solide."]},
	{"id": "veuve_clou_pp", "nom": "la Veuve Clou", "prudence": 0.5, "bluff": 0.35, "alea": 0.12,
		"menteur": ["Clic ! Menteur, mon petit !", "Ma main dit : menteur."], "perd": ["Clic… clac. Tant pis.", "De mon temps, les dés étaient plus polis."], "gagne": ["Clic ! Un clou chasse l'autre !"]},
]
const GRAND_DE := {"gagne": ["HA HA ! La maison gagne ! Ça roule !", "Pétula, ma belle ! Elle ne dit rien, mais elle gagne."],
	"perd": ["Aïe aïe aïe ! Bien lancé, toi !", "Gaston, tu m'as trahi !"], "egal": ["Égalité ! On reprend sa mise, on recommence !"],
	"double": ["DOUBLE SIX ! Triple mise ! Toute la Fosse t'applaudit !"]}
const ROUAGE := {"gagne": ["TIC. LA MAISON GAGNE. TAC.", "CALCUL TERMINÉ. VOUS AVEZ PERDU. BONNE JOURNÉE."],
	"perd": ["TIC ? … TAC. VOUS AVEZ GAGNÉ. FÉLICITATIONS MÉCANIQUES.", "ERREUR DE LA MAISON. VOUS GAGNEZ."], "sept": ["SEPT ! SEPT ! CLOCHETTE ! DRING !"]}

var main: Node
var tapis: Node3D
var assis: String = ""                 # la table où l'on est assis (« lancer », « sept », « menteur ») ; « » debout
var tables: Dictionary = {}            # id -> {centre, siege, regard, parent, croupier (Node), cote (Vector3), adversaires: [{node, siege}]}
var etat: Dictionary = {}
var mise: int = 5
var pari: int = 2                      # le Sept : 1 moins de sept, 2 sept, 3 plus de sept
var objet: int = 0                     # « Public averti » : l'objet misé (0 : des pièces)
var dernier: Array = []                # les lignes du dernier coup (pour l'écran)
var occupe: bool = false               # un lancer est en cours
var en_partie: bool = false            # une partie de Menteur est en cours
var menteur: RefCounted
var test_mode: bool = false            # les tests : pas d'attente (les dés se posent tout de suite)
var _session: Dictionary = {}
var _des: Array = []                   # les dés posés sur la table (on les efface au coup suivant)


func setup(main_node: Node) -> void:
	main = main_node
	tapis = Tapis.new()
	tapis.name = "Tapis_v147"
	add_child(tapis)
	tapis.choisi.connect(_choix)
	etat = _frais()


func _frais() -> Dictionary:
	return {"rep": 0.0, "jour": -1, "coups": 0, "gagnes": 0, "perdus": 0, "parties": 0, "menteur_gagnes": 0, "lots": 0, "meilleur_gain": 0, "serie": 0}


# =================================================================== la monnaie, la réputation

func monnaie() -> String:
	return "piece" if Public.averti() else "jeton"


func solde() -> int:
	var inv: Node = main.get("inventory_v28")
	return int(inv.count(monnaie())) if inv != null else 0


func _payer(n: int) -> void:
	if n > 0 and main.get("inventory_v28") != null:
		main.inventory_v28.remove(monnaie(), n)


func _gagner(n: int) -> void:
	if n > 0 and main.get("inventory_v28") != null:
		main.inventory_v28.add(monnaie(), n)
		main.sfx("jetons" if monnaie() == "jeton" else "ramasse_pieces")


func unite(n: int) -> String:
	if monnaie() == "jeton":
		return "%d jeton" % n if n <= 1 else "%d jetons" % n
	return "%d pièce" % n if n <= 1 else "%d pièces" % n


static func titre_de(rep: float) -> String:
	for t in TITRES:
		if rep <= float(t[0]):
			return str(t[1])
	return "Maître du jeu"


func titre() -> String:
	return titre_de(float(etat["rep"]))


func rep(delta: float) -> void:
	var avant: String = titre()
	etat["rep"] = clampf(float(etat["rep"]) + delta, -100.0, 100.0)
	var apres: String = titre()
	if apres != avant:
		var monte: bool = delta > 0.0
		main._show_message_v28(("Votre réputation grandit : à Pile-ou-Face, on vous appelle désormais « %s » !" if monte else "Votre réputation baisse : à Pile-ou-Face, on vous appelle désormais « %s »…") % apres)
		if monte and apres == "Maître du jeu":
			main.jingle("victoire")


## Un coup joué : « net » (ce qu'on a gagné ou perdu), « m » (la mise).
func _apres_coup(net: int, m: int) -> void:
	etat["coups"] = int(etat["coups"]) + 1
	_session["coups"] = int(_session.get("coups", 0)) + 1
	_session["net"] = int(_session.get("net", 0)) + net
	if net > 0:
		etat["gagnes"] = int(etat["gagnes"]) + 1
		etat["serie"] = 0
		etat["meilleur_gain"] = maxi(int(etat["meilleur_gain"]), net)
		rep(2.0 + (1.0 if m >= 10 else 0.0))
	elif net < 0:
		etat["perdus"] = int(etat["perdus"]) + 1
		etat["serie"] = int(etat["serie"]) + 1
		rep(-1.0)
		if int(etat["serie"]) >= 3:
			etat["serie"] = 0
			rep(-4.0)
			dernier.append("Trois coups perdus d'affilée… À la Fosse, on murmure le mot « pigeon ».")


# =================================================================== s'asseoir, se lever

## Une table du lieu (le lieu l'appelle en se construisant).
func table(id: String, data: Dictionary) -> void:
	tables[id] = data


func vider_tables() -> void:
	if assis != "":
		lever(true)
	tables.clear()
	_des.clear()


func asseoir(id: String) -> void:
	if not tables.has(id) or assis != "":
		return
	var t: Dictionary = tables[id]
	assis = id
	_session = {"coups": 0, "net": 0}
	dernier = []
	objet = 0
	main.place_player_v35(t["siege"], t["regard"])
	var titres := {"lancer": "Le Grand Lancer", "sept": "Le Sept de Monsieur Rouage", "menteur": "Le Menteur", "caisse": "La Caisse de la Fosse"}
	tapis.ouvrir(str(titres.get(id, id)), bool(main.xr_active))
	tapis.placer_vr((t["centre"] as Vector3) + Vector3.UP * 1.25 - (t["regard"] as Vector3) * 0.1, t["regard"])
	_menu()


## Se lever : on dit au revoir ; si l'on part avec un gain après quelques coups, la Fosse le remarque.
func lever(force: bool = false) -> void:
	if assis == "":
		return
	var net: int = int(_session.get("net", 0))
	var coups: int = int(_session.get("coups", 0))
	if not force and coups >= 3 and net > 0:
		rep(3.0)
		main._show_message_v28("Vous vous levez avec %s de gain. « Celui-là sait s'arrêter », murmure-t-on. Votre réputation grandit." % unite(net))
	elif not force and coups >= 3 and net <= -mise * 4:
		rep(-2.0)
		main._show_message_v28("Vous vous levez, les poches plus légères de %s. On vous regarde partir avec un petit sourire…" % unite(-net))
	assis = ""
	en_partie = false
	occupe = false
	tapis.fermer()


func _input(event: InputEvent) -> void:
	if assis == "" or not (event is InputEventKey) or main == null or main.xr_active:
		return
	tapis.touche(event)
	# assis, les autres touches du jeu (l'inventaire, les sorts…) attendent qu'on se lève
	get_viewport().set_input_as_handled()


func vr_tick(stick: Vector2, trig: float, b: bool) -> void:
	tapis.vr_tick(stick, trig, b)


func _process(_d: float) -> void:
	if assis == "" or main == null:
		return
	var mv: Node = main.get("maisons_v81")
	if mv == null or not bool(mv.inside):
		lever(true)


# =================================================================== les menus

func _lignes_base() -> Array:
	var l: Array = ["Votre bourse : %s" % unite(solde()), "Réputation : %s" % titre()]
	return l + dernier


func _rang_mise(maxi_: int) -> Dictionary:
	var hi: int = maxi(1, mini(maxi_, solde()))
	mise = clampi(mise, 1, hi)
	return {"id": "mise", "label": "Mise", "kind": "valeur", "value": mise, "min": 1, "max": hi, "change": func(v: int): mise = v; _menu()}


func _objets_misables() -> Array:
	var out: Array = []
	if not Public.averti():
		return out
	for id in VALEURS:
		if main.inventory_v28.count(id) > 0:
			out.append(id)
	return out


func _rang_objet() -> Dictionary:
	var objs: Array = _objets_misables()
	if objs.is_empty():
		objet = 0
		return {}
	var noms: Array = ["des pièces"]
	for id in objs:
		noms.append(str(main.inventory_v28.ITEMS[id]["name"]) + " (%d)" % int(VALEURS[id]))
	objet = clampi(objet, 0, objs.size())
	return {"id": "objet", "label": "Miser", "kind": "valeur", "value": objet, "min": 0, "max": objs.size(), "noms": noms, "change": func(v: int): objet = v; _menu()}


func _menu() -> void:
	if assis == "" or en_partie:
		return
	var l: Array = _lignes_base()
	var r: Array = []
	match assis:
		"lancer":
			var ro: Dictionary = _rang_objet()
			if not ro.is_empty():
				r.append(ro)
			if objet == 0:
				r.append(_rang_mise(MAX_MISE))
			r.append({"id": "lancer", "label": "Lancer les dés !", "off": objet == 0 and solde() < 1})
			l.insert(0, "Deux dés contre les deux dés de Grand-Dé : le plus haut gagne (la mise double). Égalité : on reprend sa mise. Double six : triple mise !")
		"sept":
			var ro2: Dictionary = _rang_objet()
			if not ro2.is_empty():
				r.append(ro2)
			if objet == 0:
				r.append(_rang_mise(MAX_MISE))
			r.append({"id": "pari", "label": "Pari", "kind": "valeur", "value": pari, "min": 1, "max": 3, "noms": ["Moins de 7 (×2)", "Sept (×5)", "Plus de 7 (×2)"], "change": func(v: int): pari = v; _menu()})
			r.append({"id": "lancer", "label": "Que l'automate lance !", "off": objet == 0 and solde() < 1})
			l.insert(0, "Deux dés : misez sur moins de sept, sur sept, ou sur plus de sept.")
		"menteur":
			l.insert(0, "Trois dés cachés chacun. On annonce combien il y a de dés d'une face sur toute la table ; on monte, ou l'on crie « Menteur ! ». Le dernier qui a des dés ramasse le pot.")
			l.append("La place : %s (le pot : %s)." % [unite(BUYIN), unite(BUYIN * 4)])
			r.append({"id": "prendre_place", "label": "Prendre place", "off": solde() < BUYIN})
		"caisse":
			l = _lignes_base()
			if monnaie() == "jeton":
				l.insert(0, "Ici, on joue avec des jetons de bois peint. Chaque jour, la Caisse en donne de quoi jouer ; on les échange contre des lots.")
				r.append({"id": "jetons_jour", "label": "Prendre les jetons du jour", "off": int(etat["jour"]) == _jour()})
				for lot in LOTS:
					var id: String = str(lot[0])
					if not main.inventory_v28.ITEMS.has(id):
						continue
					r.append({"id": "lot_" + id, "label": "Échanger %s contre : %s" % [unite(int(lot[1])), str(main.inventory_v28.ITEMS[id]["name"])], "off": solde() < int(lot[1])})
			else:
				l.insert(0, "Ici, on joue des pièces, et parfois plus. La Caisse ne fait pas crédit.")
			l.append("Coups joués : %d · gagnés : %d · perdus : %d" % [int(etat["coups"]), int(etat["gagnes"]), int(etat["perdus"])])
	r.append({"id": "lever", "label": "Se lever"})
	tapis.montrer(l, r)


func _jour() -> int:
	var t: Node = main.get("temps_v56")
	return int(t.day_count) if t != null else 0


func _choix(id: String, _v: Dictionary) -> void:
	if en_partie:
		return
	if id == "lever":
		lever()
		return
	if occupe:
		return
	match assis:
		"lancer":
			if id == "lancer":
				_jouer_lancer()
		"sept":
			if id == "lancer":
				_jouer_sept()
		"menteur":
			if id == "prendre_place":
				_partie_menteur()
		"caisse":
			_caisse(id)


func _caisse(id: String) -> void:
	if id == "jetons_jour" and monnaie() == "jeton":
		etat["jour"] = _jour()
		var n: int = maxi(0, JETONS_JOUR - solde())
		main.inventory_v28.add("jeton", n)
		main.sfx("jetons")
		dernier = ["La caissière vous glisse %s : « Bonne chance, et sachez vous arrêter ! »" % unite(n) if n > 0 else "« Vous avez déjà de quoi jouer », dit la caissière."]
	elif id.begins_with("lot_"):
		var it: String = id.substr(4)
		for lot in LOTS:
			if str(lot[0]) == it and solde() >= int(lot[1]):
				if main.inventory_v28.add(it, 1) <= 0:
					dernier = ["Votre sac est plein."]
					break
				_payer(int(lot[1]))
				etat["lots"] = int(etat["lots"]) + 1
				dernier = ["Échangé : %s contre %s." % [unite(int(lot[1])), str(main.inventory_v28.ITEMS[it]["name"])]]
				main.sfx("ramasse")
	_menu()


# =================================================================== la mise (pièces, jetons, ou un objet)

## Prend la mise ; rend [valeur, objet misé ou ""], ou [] si l'on ne peut pas.
func _prendre_mise() -> Array:
	var objs: Array = _objets_misables()
	if objet > 0 and objet <= objs.size():
		var id: String = objs[objet - 1]
		main.inventory_v28.remove(id, 1)
		return [int(VALEURS[id]), id]
	if solde() < mise or mise < 1:
		return []
	_payer(mise)
	return [mise, ""]


## Le gain : « mult » fois la mise (0 : perdu ; 1 : rendue). Rend le net.
func _regler(m: Array, mult: int) -> int:
	var v: int = int(m[0])
	var obj: String = str(m[1])
	if obj != "":
		if mult >= 1:
			main.inventory_v28.add(obj, 1)
			if mult > 1:
				main.inventory_v28.add("piece", v * (mult - 1))
				main.sfx("ramasse_pieces")
		else:
			objet = 0
		return v * (mult - 1)
	if mult > 0:
		_gagner(v * mult)
	return v * (mult - 1)


# =================================================================== les dés sur la table

func _effacer_des() -> void:
	for d in _des:
		if is_instance_valid(d):
			d.queue_free()
	_des.clear()


## Lance des dés de « depuis » vers un point du tapis (autour de « vers ») ; rend quand ils sont posés.
func _jeter(valeurs: Array, depuis: Vector3, vers: Vector3, genre: String = "ivoire") -> void:
	var t: Dictionary = tables[assis]
	var parent: Node3D = t["parent"]
	var tws: Array = []
	var dir: Vector3 = (vers - depuis)
	dir.y = 0
	var side: Vector3 = dir.normalized().cross(Vector3.UP)
	for i in range(valeurs.size()):
		var d: MeshInstance3D = Des.de(parent, depuis, int(valeurs[i]), 0.05, genre)
		_des.append(d)
		var cible: Vector3 = vers + side * (float(i) - (valeurs.size() - 1) * 0.5) * 0.11 + Vector3(randf_range(-0.03, 0.03), 0, randf_range(-0.03, 0.03))
		if test_mode:
			d.global_transform = Transform3D(Des.rot_face(int(valeurs[i]), randf() * TAU), cible + Vector3.UP * 0.025)
		else:
			tws.append(Des.lancer(d, depuis + side * (float(i) - 0.5) * 0.05, cible, int(valeurs[i]), randf_range(0.85, 1.1)))
	main.sfx("des_roule", vers)
	if not tws.is_empty():
		await (tws[0] as Tween).finished
		await get_tree().create_timer(0.25).timeout


func _dire(n: Variant, lignes: Array) -> void:
	if n != null and is_instance_valid(n) and n.has_method("say") and not lignes.is_empty():
		n.say(str(lignes[randi() % lignes.size()]), 3.5)


func _geste(n: Variant, g: String) -> void:
	if n != null and is_instance_valid(n) and n.has_method("gesture"):
		n.gesture(g)


# =================================================================== le Grand Lancer (face à Grand-Dé)

func _jouer_lancer() -> void:
	var m: Array = _prendre_mise()
	if m.is_empty():
		return
	occupe = true
	_effacer_des()
	main.sfx("jetons")
	var t: Dictionary = tables["lancer"]
	var c: Vector3 = t["centre"]
	var j: Array = [randi_range(1, 6), randi_range(1, 6)]
	var g: Array = [randi_range(1, 6), randi_range(1, 6)]
	var regard: Vector3 = t["regard"]
	await _jeter(j, c - regard * 0.55 + Vector3.UP * 0.35, c - regard * 0.12 + Vector3.UP * 0.0)
	await _jeter(g, c + regard * 0.55 + Vector3.UP * 0.35, c + regard * 0.16, "rouge")
	var sj: int = int(j[0]) + int(j[1])
	var sg: int = int(g[0]) + int(g[1])
	var mult: int = 0
	var cr: Variant = t.get("croupier")
	dernier = ["Vos dés : %d + %d = %d · Grand-Dé : %d + %d = %d" % [j[0], j[1], sj, g[0], g[1], sg]]
	if sj == 12:
		mult = 3
		_dire(cr, GRAND_DE["double"])
		_geste(cr, "rire")
		main.jingle("victoire")
	elif sj > sg:
		mult = 2
		_dire(cr, GRAND_DE["perd"])
	elif sj == sg:
		mult = 1
		_dire(cr, GRAND_DE["egal"])
	else:
		_dire(cr, GRAND_DE["gagne"])
		_geste(cr, "rire")
	var net: int = _regler(m, mult)
	dernier.append("Vous gagnez %s !" % unite(net) if net > 0 else ("Égalité : la mise vous revient." if net == 0 else "Vous perdez votre mise."))
	_apres_coup(net, int(m[0]))
	occupe = false
	_menu()


# =================================================================== le Sept (chez Monsieur Rouage)

func _jouer_sept() -> void:
	var m: Array = _prendre_mise()
	if m.is_empty():
		return
	occupe = true
	_effacer_des()
	main.sfx("jetons")
	var t: Dictionary = tables["sept"]
	var c: Vector3 = t["centre"]
	var regard: Vector3 = t["regard"]
	var d: Array = [randi_range(1, 6), randi_range(1, 6)]
	var anim: Variant = t.get("lancer", null)
	if anim is Callable and (anim as Callable).is_valid():
		(anim as Callable).call()
	await _jeter(d, c + regard * 0.5 + Vector3.UP * 0.5, c)
	var s: int = int(d[0]) + int(d[1])
	var gagne: bool = (pari == 1 and s < 7) or (pari == 2 and s == 7) or (pari == 3 and s > 7)
	var mult: int = (5 if pari == 2 else 2) if gagne else 0
	dernier = ["Les dés : %d + %d = %d" % [d[0], d[1], s]]
	var lignes: Array = ROUAGE["sept"] if s == 7 else (ROUAGE["perd"] if gagne else ROUAGE["gagne"])
	var dire: Variant = t.get("dire", null)
	if dire is Callable and (dire as Callable).is_valid():
		(dire as Callable).call(str(lignes[randi() % lignes.size()]))
	var net: int = _regler(m, mult)
	dernier.append("Vous gagnez %s !" % unite(net) if net > 0 else "Vous perdez votre mise.")
	if gagne and pari == 2:
		main.jingle("victoire")
	_apres_coup(net, int(m[0]))
	occupe = false
	_menu()


# =================================================================== le Menteur

func _nom(i: int) -> String:
	return "Vous" if i == 0 else str(ADVERSAIRES[i - 1]["nom"])


func _des_txt(a: Array) -> String:
	var s: Array = []
	for v in a:
		s.append(str(v))
	return " · ".join(s)


## Montre les dés : ceux du joueur face visible devant lui ; ceux des autres sous leur gobelet (ou
## retournés, « tout » : on soulève les gobelets).
func _poser_des_menteur(tout: bool) -> void:
	_effacer_des()
	var t: Dictionary = tables["menteur"]
	var parent: Node3D = t["parent"]
	var places: Array = t["places"]        # [position des dés de chacun] (0 : le joueur)
	for i in range(menteur.joueurs.size()):
		var des: Array = menteur.joueurs[i]["des"]
		var p: Vector3 = places[i]
		var dirc: Vector3 = ((t["centre"] as Vector3) - p)
		dirc.y = 0.0
		var side: Vector3 = dirc.normalized().cross(Vector3.UP)
		if i == 0 or tout:
			for k in range(des.size()):
				var dd: MeshInstance3D = Des.de(parent, p + side * (k - (des.size() - 1) * 0.5) * 0.08, int(des[k]))
				_des.append(dd)
		if i > 0:
			# le gobelet de cuir (soulevé quand on montre tout)
			var g := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.07
			cm.bottom_radius = 0.09
			cm.height = 0.14
			g.mesh = cm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.36, 0.2, 0.12)
			mat.roughness = 0.7
			g.material_override = mat
			parent.add_child(g)
			g.global_position = p + Vector3.UP * (0.07 if not tout else 0.0) + (-dirc.normalized() * 0.16 if tout else Vector3.ZERO)
			if tout:
				g.rotation.x = PI * 0.5
			_des.append(g)


func _specs() -> Array:
	var s: Array = [{"id": "joueur", "nom": "Vous", "humain": true}]
	for a in ADVERSAIRES:
		s.append({"id": a["id"], "nom": a["nom"], "prudence": a["prudence"], "bluff": a["bluff"], "alea": a["alea"]})
	return s


func _adv_node(i: int) -> Variant:
	var t: Dictionary = tables.get("menteur", {})
	var a: Array = t.get("adversaires", [])
	return a[i - 1] if i >= 1 and i - 1 < a.size() else null


func _pause(s: float) -> void:
	if test_mode:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(s).timeout


## Une partie de Menteur, du début à la fin (le joueur répond par le tapis).
func _partie_menteur() -> void:
	if solde() < BUYIN or en_partie:
		return
	_payer(BUYIN)
	main.sfx("jetons")
	en_partie = true
	etat["parties"] = int(etat["parties"]) + 1
	menteur = Menteur.new(_specs(), 3)
	var premier: int = randi() % 4
	var hist: Array = ["Chacun pose %s : le pot est de %s." % [unite(BUYIN), unite(BUYIN * 4)]]
	while en_partie and not menteur.fini() and int(menteur.joueurs[0]["n"]) > 0:
		menteur.nouvelle_manche(premier)
		main.sfx("gobelet", (tables["menteur"]["centre"] as Vector3))
		_poser_des_menteur(false)
		hist.append("Nouvelle manche : on secoue les gobelets.")
		var res: Dictionary = {}
		while en_partie and res.is_empty():
			var i: int = menteur.tour
			if i == 0:
				var choix: Array = await _tour_joueur(hist)
				if not en_partie:
					break
				if str(choix[0]) == "menteur":
					hist.append("Vous criez « Menteur ! »")
					res = menteur.menteur()
				else:
					var q: int = int((choix[1] as Dictionary).get("q", 1))
					var f: int = int((choix[1] as Dictionary).get("f", 1))
					if menteur.annoncer(q, f):
						hist.append("Vous annoncez : %d × %d" % [q, f])
			else:
				await _pause(1.0)
				var dec: Dictionary = menteur.decider(i)
				var n: Variant = _adv_node(i)
				if bool(dec.get("menteur", false)):
					_dire(n, ADVERSAIRES[i - 1]["menteur"])
					hist.append("%s crie « Menteur ! »" % _nom(i))
					res = menteur.menteur()
					if res.is_empty():
						menteur.annoncer(1, 1)
				else:
					menteur.annoncer(int(dec["q"]), int(dec["f"]))
					if n != null and is_instance_valid(n) and n.has_method("say"):
						n.say("%d × %d !" % [int(dec["q"]), int(dec["f"])], 3.0)
					hist.append("%s annonce : %d × %d" % [_nom(i), int(dec["q"]), int(dec["f"])])
					_ecran_menteur(hist, [])
		if not en_partie:
			break
		# on soulève les gobelets
		_poser_des_menteur(true)
		main.sfx("des_roule", (tables["menteur"]["centre"] as Vector3))
		var perd: int = int(res["perdant"])
		hist = ["Il y a %d dés de %d : l'annonce était %s !" % [int(res["compte"]), int(res["f"]), "vraie" if bool(res["vraie"]) else "fausse"]]
		hist.append(("Vous perdez un dé." if perd == 0 else "%s perd un dé." % _nom(perd)) + (" Éliminé !" if bool(res["elimine"]) else ""))
		# la réputation : démasquer un menteur, crier à tort, annoncer juste
		if int(res["crieur"]) == 0:
			rep(2.0 if not bool(res["vraie"]) else -2.0)
		elif int(res["par"]) == 0 and bool(res["vraie"]):
			rep(1.0)
		if perd > 0:
			_dire(_adv_node(perd), ADVERSAIRES[perd - 1]["perd"])
		premier = menteur.tour
		var c: Array = await _attendre_suite(hist)
		if str(c[0]) == "lever":
			break
		hist = []
	# la fin
	var fini_ok: bool = en_partie
	en_partie = false
	_effacer_des()
	if int(menteur.joueurs[0]["n"]) > 0 and menteur.fini():
		_gagner(BUYIN * 4)
		etat["menteur_gagnes"] = int(etat["menteur_gagnes"]) + 1
		rep(8.0)
		_apres_coup(BUYIN * 3, BUYIN)
		dernier = ["Vous êtes le dernier à avoir des dés : vous ramassez le pot (%s) !" % unite(BUYIN * 4)]
		main.jingle("victoire")
	else:
		var g: int = menteur.gagnant()
		if g < 0:
			# éliminé (ou levé) : les autres finissent sans nous ; on devine qui l'emporte
			g = 1 + randi() % 3
		if g > 0:
			_dire(_adv_node(g), ADVERSAIRES[g - 1]["gagne"])
		_apres_coup(-BUYIN, BUYIN)
		dernier = ["Vous perdez votre place. %s ramasse le pot." % (_nom(g) if g > 0 else "Quelqu'un")]
		if not fini_ok:
			dernier = ["Vous quittez la partie : votre place reste dans le pot."]
	_menu()


func _ecran_menteur(hist: Array, rangs: Array) -> void:
	var l: Array = []
	l.append("Vos dés : %s · dés en jeu : %d" % [_des_txt(menteur.joueurs[0]["des"]), menteur.total_des()])
	var adv: Array = []
	for i in range(1, menteur.joueurs.size()):
		adv.append("%s %d" % [_nom(i), int(menteur.joueurs[i]["n"])])
	l.append("Dés de chacun : " + ", ".join(adv))
	if not menteur.enchere.is_empty():
		l.append("Annonce de %s : %d × %d" % [_nom(int(menteur.enchere["par"])), int(menteur.enchere["q"]), int(menteur.enchere["f"])])
	var start: int = maxi(0, hist.size() - 4)
	for k in range(start, hist.size()):
		l.append(str(hist[k]))
	tapis.montrer(l, rangs if not rangs.is_empty() else [{"id": "attendre", "label": "…", "off": true}, {"id": "lever", "label": "Quitter la partie"}])


func _tour_joueur(hist: Array) -> Array:
	var f0: int = 1
	var mine: Dictionary = {}
	for v in menteur.joueurs[0]["des"]:
		mine[int(v)] = int(mine.get(int(v), 0)) + 1
	var best: int = 0
	for f in mine:
		if int(mine[f]) > best:
			best = int(mine[f])
			f0 = int(f)
	var q0: int = menteur.min_q(f0)
	if q0 > 0 and menteur.valide(maxi(q0, best), f0):
		q0 = maxi(q0, best)
	if q0 <= 0:
		f0 = 6
		q0 = maxi(1, menteur.min_q(6))
	var st := {"q": q0, "f": f0}
	var refaire := func() -> void:
		var ok: bool = menteur.valide(int(st["q"]), int(st["f"]))
		_ecran_menteur(hist + ["À vous !"], [
			{"id": "q", "label": "Combien", "kind": "valeur", "value": st["q"], "min": 1, "max": menteur.total_des(), "change": func(v: int): st["q"] = v; _tour_refaire.call()},
			{"id": "f", "label": "De quelle face", "kind": "valeur", "value": st["f"], "min": 1, "max": 6, "change": func(v: int): st["f"] = v; _tour_refaire.call()},
			{"id": "annoncer", "label": "Annoncer %d × %d" % [int(st["q"]), int(st["f"])], "off": not ok},
			{"id": "menteur", "label": "Menteur !", "off": menteur.enchere.is_empty()},
			{"id": "lever", "label": "Quitter la partie"}])
	_tour_refaire = refaire
	refaire.call()
	while true:
		var r: Array = await tapis.choisi
		var id: String = str(r[0])
		if id == "lever":
			en_partie = false
			return ["lever", {}]
		if id == "menteur" and not menteur.enchere.is_empty():
			return ["menteur", {}]
		if id == "annoncer" and menteur.valide(int(st["q"]), int(st["f"])):
			return ["annoncer", st.duplicate()]
	return ["lever", {}]


var _tour_refaire: Callable


func _attendre_suite(hist: Array) -> Array:
	_ecran_menteur(hist, [{"id": "suite", "label": "Manche suivante" if not menteur.fini() and int(menteur.joueurs[0]["n"]) > 0 else "Voir la fin"}, {"id": "lever", "label": "Quitter la partie"}])
	if test_mode:
		return ["suite", {}]
	var r: Array = await tapis.choisi
	if str(r[0]) == "lever":
		en_partie = false
	return r


# =================================================================== la sauvegarde

func serialize() -> Dictionary:
	return etat.duplicate(true)


func load_data(d: Dictionary) -> void:
	etat = _frais()
	for k in etat:
		if d.has(k):
			etat[k] = d[k]
	if assis != "":
		lever(true)

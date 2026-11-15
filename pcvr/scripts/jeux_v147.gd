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
##    et la Veuve Clou ; le dernier qui a des dés ramasse le pot) ;
##  - V148 : le blackjack du Tripot de la Dame de Pique (blackjack_v148, cartes_v148) : la Dame de Pique
##    donne, Gédéon Tic et Fanchon Fil-d'Or jouent à côté de nous ;
##  - V149 : le poker (poker_v149) : le Texas Hold'em ou le poker à cinq cartes, au choix, au Saloon du
##    Chien qui Mise et au Terrier (derrière le barbier), contre trois habitués.
## Les tables sont déclarées par le lieu (lieux_perchee_v147) quand on entre ; tapis_v147 est la fenêtre.

const Public = preload("res://scripts/public_v111.gd")
const Des = preload("res://scripts/des_v147.gd")
const Menteur = preload("res://scripts/menteur_v147.gd")
const Tapis = preload("res://scripts/tapis_v147.gd")
const BJ = preload("res://scripts/blackjack_v148.gd")
const Cartes = preload("res://scripts/cartes_v148.gd")
const Poker = preload("res://scripts/poker_v149.gd")

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
	return {"rep": 0.0, "jour": -1, "coups": 0, "gagnes": 0, "perdus": 0, "parties": 0, "menteur_gagnes": 0, "lots": 0, "meilleur_gain": 0, "serie": 0,
		"mains": 0, "blackjacks": 0, "mains_poker": 0}


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
	var titres := {"lancer": "Le Grand Lancer", "sept": "Le Sept de Monsieur Rouage", "menteur": "Le Menteur", "caisse": "La Caisse de la Fosse",
		"blackjack": "Le Blackjack de la Dame de Pique", "poker": "La table de poker"}
	if t.has("titre"):
		titres[id] = str(t["titre"])
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
	_gen += 1
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
		"blackjack":
			var ro3: Dictionary = _rang_objet()
			if not ro3.is_empty():
				r.append(ro3)
			if objet == 0:
				r.append(_rang_mise(MAX_MISE))
			r.append({"id": "distribuer", "label": "Distribuer !", "off": objet == 0 and solde() < 1})
			l.insert(0, "Approchez-vous le plus possible de 21, sans le dépasser. Les figures valent 10, l'as 1 ou 11. La Dame de Pique tire jusqu'à 17. Le blackjack paie trois pour deux.")
		"poker":
			var t_pk: Dictionary = tables["poker"]
			r.append({"id": "jeu", "label": "Jeu", "kind": "valeur", "value": 0 if pk_mode == "holdem" else 1, "min": 0, "max": 1,
				"noms": ["Texas Hold'em", "Poker à cinq cartes"], "change": func(v: int): pk_mode = "holdem" if v == 0 else "cinq"; _menu()})
			r.append({"id": "donner", "label": "Une main !", "off": solde() < PK_MIN})
			if pk_mode == "holdem":
				l.insert(0, "Le Texas Hold'em : deux cartes cachées chacun, cinq cartes communes. Les blindes : 1 et 2. On mise 2, puis 4 au tournant et à la rivière.")
			else:
				l.insert(0, "Le poker à cinq cartes : une mise d'entrée, cinq cartes, on mise, on échange jusqu'à trois cartes (quatre avec un as), on mise encore, on abat.")
			l.append("Contre : %s." % ", ".join(t_pk.get("noms", [])))
			if solde() < PK_MIN:
				l.append("Il faut au moins %s pour s'asseoir." % unite(PK_MIN))
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
		"blackjack":
			if id == "distribuer":
				_main_blackjack()
		"poker":
			if id == "donner":
				_main_poker()
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
	var gen0: int = _gen
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
				if gen0 != _gen:
					return
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
				if gen0 != _gen:
					return
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
		if gen0 != _gen:
			return
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


# =================================================================== le blackjack (V148, chez la Dame de Pique)

## Ce que disent la donneuse et ses voisins de table.
const DAME := {"bonjour": ["Faites vos jeux.", "Les cartes sont prêtes. Et vous ?", "Asseyez-vous. Le sabot ne mord pas."],
	"bj": ["Blackjack. Joli. Trois pour deux.", "Un as et une figure… Vous avez de la chance, ou du talent ?"],
	"saute": ["Vingt-deux… Dommage.", "Trop, c'est trop."], "gagne": ["La maison remercie.", "Merci pour votre contribution."],
	"perd": ["Bien joué.", "Vous me battez. Pour cette fois."], "egal": ["Égalité. Reprenez votre mise."],
	"rebat": ["Je rebats le sabot. Coupez, s'il vous plaît… Merci."], "dame_bj": ["Blackjack pour la maison. Navrée."]}
const VOISINS := [
	{"nom": "Gédéon", "audace": 0.2, "tire": ["Tic ! Carte.", "Une autre. Par calcul."], "reste": ["Tac. Je reste.", "Mes engrenages disent stop."],
		"gagne": ["Tic-tac, gagné !", "Le calcul paie !"], "perd": ["Erreur de calcul…", "Tic… tac… hélas."]},
	{"nom": "Fanchon", "audace": 0.7, "tire": ["Allez, une carte, pour le panache !", "Encore ! Le chapeau me le dit."], "reste": ["Je reste. Élégamment.", "Ça me suffit, chéri."],
		"gagne": ["Ha ! Je m'achète un ruban !", "Gagné, avec style !"], "perd": ["Tant pis, je coudrai un chapeau de plus.", "Oh, flûte."]},
]

var bj: RefCounted
var _cartes: Array = []               # les cartes posées sur la table (on les ramasse au coup suivant)
var _bj_mains: Array = []             # [joueur, voisin 1, voisin 2, donneuse] : les cartes (dictionnaires)
var _bj_noeuds: Array = []            # les mêmes, en nœuds
var _bj_mise: int = 0
var _gen: int = 0                     # change quand on se lève : une partie interrompue ne reprend pas


func _effacer_cartes() -> void:
	for c in _cartes:
		if is_instance_valid(c):
			c.queue_free()
	_cartes.clear()


func _bj_yaw() -> float:
	var r: Vector3 = tables["blackjack"]["regard"]
	return atan2(-r.x, -r.z)


## Pose une carte devant la main « i » (0 : le joueur, 1 et 2 : les voisins, 3 : la donneuse).
func _bj_donner(i: int, montrer: bool = true) -> void:
	var t: Dictionary = tables["blackjack"]
	var c: Dictionary = bj.tirer()
	(_bj_mains[i] as Array).append(c)
	var places: Array = t["mains"]
	var k: int = (_bj_mains[i] as Array).size() - 1
	var r: Vector3 = t["regard"]
	var side: Vector3 = r.cross(Vector3.UP).normalized()
	var at: Vector3 = (places[i] as Vector3) - side * (k * 0.028) - r * (k * 0.006) + Vector3.UP * (0.0012 * k)
	var n: Node3D = Cartes.carte(t["parent"], c, t["sabot"], _bj_yaw(), false)
	_cartes.append(n)
	(_bj_noeuds[i] as Array).append(n)
	main.sfx("carte", at, -4.0)
	if test_mode:
		n.global_transform = Transform3D(Basis(Vector3.UP, _bj_yaw()) * (Basis() if montrer else Basis(Vector3.BACK, PI)), at)
		return
	var tw: Tween = Cartes.distribuer(n, t["sabot"], at, _bj_yaw(), montrer)
	await tw.finished


func _bj_texte(i: int) -> String:
	var m: Array = _bj_mains[i]
	return "%s (%d)" % [BJ.texte_main(m), BJ.total(m)]


func _bj_ecran(lignes: Array, rangs: Array, cachee: bool) -> void:
	var l: Array = []
	var d: Array = _bj_mains[3]
	if cachee and d.size() >= 2:
		l.append("La Dame de Pique : %s ?" % Cartes.nom(d[0]))
	else:
		l.append("La Dame de Pique : %s" % _bj_texte(3))
	for v in range(2):
		l.append("%s : %s" % [str(VOISINS[v]["nom"]), _bj_texte(v + 1)])
	l.append("Vous : %s · mise : %s" % [_bj_texte(0), unite(_bj_mise)])
	tapis.montrer(l + lignes, rangs if not rangs.is_empty() else [{"id": "attendre", "label": "…", "off": true}])


func _main_blackjack() -> void:
	var gen0: int = _gen
	if not tables.has("blackjack") or en_partie:
		return
	var m: Array = _prendre_mise()
	if m.is_empty():
		return
	en_partie = true
	main.sfx("jetons")
	if bj == null:
		bj = BJ.new()
	var t: Dictionary = tables["blackjack"]
	var dame: Variant = t.get("croupier")
	_effacer_cartes()
	dernier = []
	if bj.a_rebattre():
		bj.rebattre()
		_dire(dame, DAME["rebat"])
		main.sfx("cartes_battre", t["sabot"])
		await _pause(1.2)
		if gen0 != _gen:
			return
	_bj_mains = [[], [], [], []]
	_bj_noeuds = [[], [], [], []]
	_bj_mise = int(m[0])
	var mises_v: Array = [0, 5, 5]
	var voisins: Array = t.get("adversaires", [])
	# la donne : un tour, puis un second (la seconde carte de la donneuse, cachée)
	for tour in range(2):
		for i in [1, 0, 2, 3]:
			await _bj_donner(i, not (i == 3 and tour == 1))
			if gen0 != _gen:
				return
			await _pause(0.12)
			if gen0 != _gen:
				return
	_bj_ecran([], [], true)
	var partir: bool = false
	var double: bool = false
	var dame_bj: bool = BJ.blackjack(_bj_mains[3])
	# le joueur
	if not BJ.blackjack(_bj_mains[0]) and not dame_bj:
		while BJ.total(_bj_mains[0]) < 21:
			var peut_doubler: bool = (_bj_mains[0] as Array).size() == 2 and str(m[1]) == "" and solde() >= _bj_mise
			_bj_ecran(["À vous !"], [{"id": "tirer", "label": "Tirer une carte"}, {"id": "rester", "label": "Rester"},
				{"id": "doubler", "label": "Doubler (une seule carte)", "off": not peut_doubler}, {"id": "lever", "label": "Rester, et se lever"}], true)
			var rr: Array = await tapis.choisi
			if gen0 != _gen:
				return
			var id: String = str(rr[0])
			if id == "lever":
				partir = true
				break
			if id == "rester":
				break
			if id == "doubler" and peut_doubler:
				_payer(_bj_mise)
				_bj_mise *= 2
				double = true
				main.sfx("jetons")
				await _bj_donner(0)
				if gen0 != _gen:
					return
				break
			if id == "tirer":
				await _bj_donner(0)
				if gen0 != _gen:
					return
		if BJ.saute(_bj_mains[0]):
			_dire(dame, DAME["saute"])
	# les voisins
	if not dame_bj:
		for v in range(2):
			var vn: Variant = voisins[v] if v < voisins.size() else null
			var garde: int = 0
			while BJ.total(_bj_mains[v + 1]) < 21 and garde < 8:
				garde += 1
				var c: String = BJ.conseil(_bj_mains[v + 1], (_bj_mains[3] as Array)[0], float(VOISINS[v]["audace"]), randf())
				if c == "rester":
					_dire(vn, VOISINS[v]["reste"])
					break
				_dire(vn, VOISINS[v]["tire"])
				if c == "doubler":
					mises_v[v + 1] = 10
					await _pause(0.5)
					if gen0 != _gen:
						return
					await _bj_donner(v + 1)
					if gen0 != _gen:
						return
					break
				await _pause(0.7)
				if gen0 != _gen:
					return
				await _bj_donner(v + 1)
				if gen0 != _gen:
					return
			_bj_ecran([], [], true)
			await _pause(0.4)
			if gen0 != _gen:
				return
	# la donneuse retourne sa carte, et tire jusqu'à 17
	var cachee: Node3D = (_bj_noeuds[3] as Array)[1]
	if not test_mode:
		await Cartes.retourner(cachee).finished
		if gen0 != _gen:
			return
	else:
		cachee.global_transform = Transform3D(Basis(Vector3.UP, _bj_yaw()), cachee.global_position)
	var quelqu_un: bool = false
	for i in range(3):
		if not BJ.saute(_bj_mains[i]):
			quelqu_un = true
	if dame_bj:
		_dire(dame, DAME["dame_bj"])
	elif quelqu_un:
		while BJ.donneuse_tire(_bj_mains[3]):
			_bj_ecran([], [], false)
			await _pause(0.7)
			if gen0 != _gen:
				return
			await _bj_donner(3)
			if gen0 != _gen:
				return
	# le règlement
	var mult: float = BJ.reglement(_bj_mains[0], _bj_mains[3])
	var v0: int = _bj_mise
	var net: int = 0
	var obj: String = str(m[1])
	if obj != "":
		if mult >= 1.0:
			main.inventory_v28.add(obj, 1)
			var plus: int = int(ceil(v0 * (mult - 1.0)))
			if plus > 0:
				main.inventory_v28.add("piece", plus)
				main.sfx("ramasse_pieces")
			net = plus
		else:
			objet = 0
			net = -v0
	else:
		var retour: int = int(ceil(v0 * mult))
		if retour > 0:
			_gagner(retour)
		net = retour - v0
	var lignes: Array = []
	if BJ.blackjack(_bj_mains[0]) and mult > 2.0:
		lignes.append("Blackjack ! Vous gagnez %s." % unite(net))
		_dire(dame, DAME["bj"])
		etat["blackjacks"] = int(etat.get("blackjacks", 0)) + 1
		rep(1.0)
		main.jingle("victoire")
	elif mult >= 2.0:
		lignes.append("Vous gagnez %s !" % unite(net))
		_dire(dame, DAME["perd"])
	elif mult >= 1.0:
		lignes.append("Égalité : la mise vous revient.")
		_dire(dame, DAME["egal"])
	else:
		lignes.append("Vous avez sauté : vous perdez votre mise." if BJ.saute(_bj_mains[0]) else "La Dame de Pique l'emporte : vous perdez votre mise.")
		if not BJ.saute(_bj_mains[0]):
			_dire(dame, DAME["gagne"])
	if double:
		lignes.append("(mise doublée)")
	for v in range(2):
		var vm: float = BJ.reglement(_bj_mains[v + 1], _bj_mains[3])
		var vn2: Variant = voisins[v] if v < voisins.size() else null
		if vm >= 2.0:
			_dire(vn2, VOISINS[v]["gagne"])
		elif vm < 1.0:
			_dire(vn2, VOISINS[v]["perd"])
	etat["mains"] = int(etat.get("mains", 0)) + 1
	_apres_coup(net, v0)
	dernier = lignes
	en_partie = false
	_bj_ecran(lignes, [], false)
	await _pause(0.1)
	if gen0 != _gen:
		return
	var resume: Array = ["La Dame de Pique : %s" % _bj_texte(3), "Vous : %s" % _bj_texte(0)] + lignes
	dernier = resume
	if partir:
		lever()
	else:
		_menu()


# =================================================================== le poker (V149)

const PK_MIN := 15
const PK_LIGNES := {"coucher": ["Je me couche.", "Sans moi.", "Trop cher pour moi."], "parler": ["Parole.", "Je passe.", "Je regarde."],
	"suivre": ["Je suis.", "Je paie pour voir.", "D'accord, je suis."], "relancer": ["Je relance !", "Et j'ajoute.", "Plus haut !"],
	"gagne": ["Le pot est à moi !", "Merci, merci.", "On ne bluffe pas un vieux renard."], "echange": ["Deux cartes.", "Trois, s'il vous plaît.", "Je garde tout."]}

var pk_mode: String = "holdem"
var pk: RefCounted
var _pk_noeuds: Array = []           # [joueur 0..3] -> les nœuds de ses cartes ; [4] -> les communes
var _pk_paye: int = 0                # ce que le joueur a déjà payé (jetons ou pièces) dans cette main
var _pk_jeter: Array = [false, false, false, false, false]


func _pk_specs() -> Array:
	var t: Dictionary = tables["poker"]
	var s: Array = [{"id": "joueur", "nom": "Vous", "humain": true}]
	var noms: Array = t.get("noms", ["A", "B", "C"])
	var car: Array = t.get("caracteres", [])
	for i in range(3):
		var c: Dictionary = car[i] if i < car.size() else {}
		s.append({"id": "pk%d" % i, "nom": str(noms[i]), "prudence": float(c.get("prudence", 0.5)), "bluff": float(c.get("bluff", 0.15)), "alea": float(c.get("alea", 0.08))})
	return s


func _pk_nom(i: int) -> String:
	return "Vous" if i == 0 else str(pk.joueurs[i]["nom"])


## Le joueur paie ce qu'il doit au pot (les blindes, l'ante, ses mises).
func _pk_payer() -> void:
	var du: int = int(pk.joueurs[0]["total"]) - _pk_paye
	if du > 0:
		_payer(du)
		_pk_paye += du
		main.sfx("jetons")


## Pose (ou repose) les cartes : celles du joueur face visible, celles des autres face cachée (ou
## visibles à l'abattage), les communes au milieu.
func _pk_poser(tout: bool) -> void:
	_effacer_cartes()
	_pk_noeuds = [[], [], [], [], []]
	var t: Dictionary = tables["poker"]
	var parent: Node3D = t["parent"]
	var places: Array = t["places"]
	var c0: Vector3 = t["centre"]
	for i in range(4):
		var cs: Array = pk.joueurs[i]["cartes"]
		var p: Vector3 = places[i]
		var dirc: Vector3 = c0 - p
		dirc.y = 0.0
		dirc = dirc.normalized()
		var side: Vector3 = dirc.cross(Vector3.UP)
		var yaw: float = atan2(-dirc.x, -dirc.z)
		var couche: bool = bool(pk.joueurs[i]["couche"])
		for k in range(cs.size()):
			var at: Vector3 = p - side * (k - (cs.size() - 1) * 0.5) * (0.07 if i == 0 else 0.03) + Vector3.UP * 0.0012 * k
			if i == 0 and pk.mode == "cinq" and bool(_pk_jeter[k]) and pk.etape == 0:
				at += dirc * 0.05 + Vector3.UP * 0.01
			var visible: bool = (i == 0 or (tout and not couche))
			var n: Node3D = Cartes.carte(parent, cs[k], at, yaw if i == 0 or tout else yaw, visible)
			if couche:
				n.position.y -= 0.0005
			_cartes.append(n)
			(_pk_noeuds[i] as Array).append(n)
	var yaw0: float = atan2(-(t["regard"] as Vector3).x, -(t["regard"] as Vector3).z)
	var side0: Vector3 = (t["regard"] as Vector3).cross(Vector3.UP).normalized()
	for k2 in range(pk.communes.size()):
		var n2: Node3D = Cartes.carte(parent, pk.communes[k2], c0 - side0 * (k2 - 2) * 0.075, yaw0, true)
		_cartes.append(n2)
		(_pk_noeuds[4] as Array).append(n2)


func _pk_carte_txt(cs: Array) -> String:
	var s: Array = []
	for c in cs:
		s.append(Cartes.nom(c))
	return " ".join(s)


func _pk_ecran(lignes: Array, rangs: Array) -> void:
	var l: Array = []
	var etapes: Array = ["Avant le flop", "Le flop", "Le tournant", "La rivière"] if pk.mode == "holdem" else ["Premier tour", "Après l'échange"]
	l.append("%s · pot : %s" % [str(etapes[clampi(pk.etape, 0, etapes.size() - 1)]), unite(pk.pot)])
	if pk.mode == "holdem":
		l.append("Sur la table : %s" % (_pk_carte_txt(pk.communes) if not pk.communes.is_empty() else "—"))
	var mv: Array = Poker.meilleure(pk.main_de(0))[0]
	l.append("Vos cartes : %s (%s)" % [_pk_carte_txt(pk.joueurs[0]["cartes"]), Poker.nom_combinaison(mv)])
	var adv: Array = []
	for i in range(1, 4):
		adv.append("%s %s" % [_pk_nom(i), "(couché)" if bool(pk.joueurs[i]["couche"]) else "· %d" % int(pk.joueurs[i]["mise_tour"])])
	l.append("Mises du tour : " + ", ".join(adv))
	tapis.montrer(l + lignes, rangs if not rangs.is_empty() else [{"id": "attendre", "label": "…", "off": true}])


func _pk_dire(i: int, cle: String) -> void:
	var t: Dictionary = tables["poker"]
	var a: Array = t.get("adversaires", [])
	if i >= 1 and i - 1 < a.size():
		_dire(a[i - 1], PK_LIGNES[cle])


## Un tour d'enchères ; rend false si le joueur a quitté la table.
func _pk_encheres(hist: Array) -> bool:
	var gen0: int = _gen
	var garde: int = 0
	while not pk.tour_fini() and garde < 60:
		garde += 1
		var i: int = pk.tour
		if i == 0:
			var du: int = pk.a_suivre(0)
			var rangs: Array = [{"id": "suivre", "label": ("Suivre (%s)" % unite(du)) if du > 0 else "Parler (ne rien miser)", "off": du > solde()},
				{"id": "relancer", "label": "Relancer (%s)" % unite(du + pk.taille()), "off": not pk.peut_relancer() or du + pk.taille() > solde()},
				{"id": "coucher", "label": "Se coucher", "off": du == 0},
				{"id": "lever", "label": "Se coucher et se lever"}]
			_pk_ecran(hist.slice(maxi(0, hist.size() - 3)) + ["À vous !"], rangs)
			var rr: Array = await tapis.choisi
			if gen0 != _gen:
				return false
			var id: String = str(rr[0])
			if id == "lever":
				pk.joueurs[0]["couche"] = true
				pk.agir("coucher")
				return false
			if id == "suivre" and du > solde():
				continue
			if id == "relancer" and (not pk.peut_relancer() or du + pk.taille() > solde()):
				continue
			if id == "coucher" and du == 0:
				continue
			if id in ["suivre", "relancer", "coucher"]:
				pk.agir(id)
				_pk_payer()
				hist.append(("Vous parlez." if du == 0 else "Vous suivez.") if id == "suivre" else ("Vous relancez." if id == "relancer" else "Vous vous couchez."))
				if id == "coucher":
					_pk_poser(false)
		else:
			await _pause(0.9)
			if gen0 != _gen:
				return false
			var du2: int = pk.a_suivre(i)
			var d: Array = pk.decider(i)
			var act: String = str(d[0])
			pk.agir(act)
			var cle: String = act if not (act == "suivre" and du2 == 0) else "parler"
			_pk_dire(i, cle)
			var txt := {"coucher": "%s se couche.", "parler": "%s parle.", "suivre": "%s suit.", "relancer": "%s relance !"}
			hist.append(str(txt[cle]) % _pk_nom(i))
			if act == "coucher":
				_pk_poser(false)
			_pk_ecran(hist.slice(maxi(0, hist.size() - 3)), [])
	return true


## L'échange (cinq) : le joueur choisit les cartes qu'il jette ; les adversaires aussi.
func _pk_echange_montrer(hist: Array) -> void:
	var n: int = 0
	for b in _pk_jeter:
		if b:
			n += 1
	var rangs: Array = []
	var cs: Array = pk.joueurs[0]["cartes"]
	for k in range(5):
		var kk: int = k
		rangs.append({"id": "c%d" % k, "label": Cartes.nom(cs[k]), "kind": "valeur", "value": 1 if _pk_jeter[k] else 0, "min": 0, "max": 1,
			"noms": ["Garder", "Changer"], "change": func(v: int): _pk_jeter[kk] = v == 1; _pk_poser(false); _pk_echange_montrer(hist)})
	rangs.append({"id": "echanger", "label": "Échanger %d carte(s)" % n if n > 0 else "Garder toutes mes cartes", "off": n > pk.max_echange(0)})
	rangs.append({"id": "lever", "label": "Se coucher et se lever"})
	_pk_ecran(hist.slice(maxi(0, hist.size() - 2)) + ["Choisissez les cartes à changer (jusqu'à %d)." % pk.max_echange(0)], rangs)


func _pk_echange(hist: Array) -> bool:
	var gen0: int = _gen
	_pk_jeter = [false, false, false, false, false]
	if not bool(pk.joueurs[0]["couche"]):
		while true:
			_pk_echange_montrer(hist)
			var rr: Array = await tapis.choisi
			if gen0 != _gen:
				return false
			var id: String = str(rr[0])
			if id == "lever":
				pk.joueurs[0]["couche"] = true
				return false
			var n: int = 0
			for b in _pk_jeter:
				if b:
					n += 1
			if id == "echanger" and n <= pk.max_echange(0):
				var idx: Array = []
				for k2 in range(5):
					if _pk_jeter[k2]:
						idx.append(k2)
				pk.echanger(0, idx)
				hist.append("Vous changez %d carte(s)." % idx.size() if not idx.is_empty() else "Vous gardez toutes vos cartes.")
				main.sfx("carte")
				break
	_pk_jeter = [false, false, false, false, false]
	for i in range(1, 4):
		if bool(pk.joueurs[i]["couche"]):
			continue
		await _pause(0.6)
		if gen0 != _gen:
			return false
		var j: Array = pk.a_jeter(i)
		pk.echanger(i, j)
		hist.append("%s change %d carte(s)." % [_pk_nom(i), j.size()] if not j.is_empty() else "%s garde ses cartes." % _pk_nom(i))
		main.sfx("carte")
		_pk_poser(false)
		_pk_ecran(hist.slice(maxi(0, hist.size() - 3)), [])
	return true




func _main_poker() -> void:
	if not tables.has("poker") or en_partie or solde() < PK_MIN:
		return
	var gen0: int = _gen
	en_partie = true
	_effacer_cartes()
	pk = Poker.new(_pk_specs(), pk_mode)
	pk.donneur = randi() % 4
	pk.petite = 2
	pk.grosse = 4
	pk.nouvelle_main(1)
	_pk_paye = 0
	_pk_payer()
	main.sfx("cartes_battre", tables["poker"]["centre"])
	_pk_poser(false)
	var hist: Array = ["Nouvelle main : %s donne." % _pk_nom(pk.donneur)]
	var reste: bool = true
	# les tours d'enchères, les étapes
	while true:
		reste = await _pk_encheres(hist)
		if gen0 != _gen:
			return
		if not reste or pk.actifs().size() <= 1 or bool(pk.joueurs[0]["couche"]):
			break
		if pk.mode == "cinq" and pk.etape == 0:
			reste = await _pk_echange(hist)
			if gen0 != _gen:
				return
			if not reste:
				break
		if not pk.etape_suivante():
			break
		if pk.mode == "holdem":
			main.sfx("carte", tables["poker"]["centre"])
			hist.append(["", "Le flop.", "Le tournant.", "La rivière."][pk.etape])
		else:
			hist.append("Second tour d'enchères.")
		_pk_poser(false)
	# l'abattage (ou le dernier qui reste ramasse le pot)
	var gain: int = 0
	var lignes: Array = []
	var a: Array = pk.actifs()
	# (le joueur s'est couché : les autres vont au bout sans lui ; les communes sortent toutes)
	if a.size() > 1 and pk.mode == "holdem":
		while pk.communes.size() < 5:
			pk.communes.append(pk.paquet.pop_back())
	if a.size() == 1:
		var w: int = int(a[0])
		lignes.append(("Tout le monde s'est couché : vous ramassez le pot (%s) !" % unite(pk.pot)) if w == 0 else "%s ramasse le pot (%s)." % [_pk_nom(w), unite(pk.pot)])
		if w == 0:
			gain = pk.pot
		else:
			_pk_dire(w, "gagne")
	else:
		_pk_poser(true)
		main.sfx("carte", tables["poker"]["centre"])
		var ab: Array = pk.abattage()
		var gagnants: Array = ab[0]
		var vals: Dictionary = ab[2]
		for i in a:
			lignes.append("%s : %s" % [_pk_nom(int(i)), Poker.nom_combinaison(vals[i])])
		var noms_g: Array = []
		for g in gagnants:
			noms_g.append(_pk_nom(int(g)))
		var part: int = int(ceil(float(pk.pot) / float(gagnants.size())))
		if 0 in gagnants:
			gain = part
		lignes.append(("%s gagne le pot (%s), avec : %s." if gagnants.size() == 1 else "%s se partagent le pot (%s), avec : %s.") % [" et ".join(noms_g), unite(pk.pot), Poker.nom_combinaison(ab[1])])
		for g2 in gagnants:
			if int(g2) != 0:
				_pk_dire(int(g2), "gagne")
	if gain > 0:
		_gagner(gain)
	var net: int = gain - _pk_paye
	if gain > 0 and a.size() == 1 and int(a[0]) == 0:
		# un pot gagné sans montrer ses cartes : la Fosse appelle ça du culot
		rep(1.0)
	_apres_coup(net, maxi(1, _pk_paye))
	etat["mains_poker"] = int(etat.get("mains_poker", 0)) + 1
	if net > 0:
		lignes.append("Vous gagnez %s." % unite(net))
		if net >= 10:
			main.jingle("victoire")
	elif net < 0:
		lignes.append("Vous perdez %s." % unite(-net))
	en_partie = false
	dernier = lignes
	var partir: bool = bool(pk.joueurs[0]["couche"]) and not reste
	if partir:
		lever()
	else:
		_menu()


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

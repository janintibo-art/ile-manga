extends Node3D
## Extension « Le Château d'Ombrelac » (v15) : les objets de l'Académie avec lesquels on fait quelque chose.
##  - s'asseoir : sur tous les bancs, chaises, fauteuils et canapés du château (le héros s'assied, on se
##    lève en marchant, en sautant ou avec E). Assis en classe pendant le cours, on écoute la leçon du
##    maître ; à table dans la Grande Salle à l'heure du repas, Mère Fournil vous sert ;
##  - lire : un livre au hasard dans les rayonnages (la Bibliothèque, la Salle des Astres, la Salle Commune,
##    l'Observatoire, le cabinet des Sortilèges, le Bureau du Recteur), les tableaux, les cartes du ciel,
##    les portraits des anciens Recteurs, les reliques, la devise des fondateurs, le grimoire, le registre
##    de l'horloge ;
##  - agir : faire tourner le Grand Astrolabe et les globes, regarder dans les lunettes (la nuit, on y
##    découvre les constellations), tirer la corde de la cloche, jeter une pièce dans la fontaine et
##    faire un vœu, dormir dans un lit des dortoirs, préparer un élixir aux paillasses (un par jour), jouer
##    aux échecs à la Salle Commune, regarder dans la sphère de cristal, s'entraîner sur les mannequins.
## Les objets sont posés par les intérieurs (interieurs_ombrelac.gd : « objets », « bancs ») ; ici, une
## seule entrée dans les interactions du jeu (donjon_v35._interactions) suit l'objet le plus proche.
## PC : E ; VR : la gâchette (on ne s'assied pas en VR). Ce qu'on a lu, vu, gagné : ombrelac.state["objets"].

const T = preload("res://scripts/ext_chateau/textes_ombrelac.gd")

## Les intérieurs, et le fonds de leurs rayonnages
const INTERIEURS := {"Ombrelac_interieurs": "bibliotheque", "Ombrelac_bibliotheque": "bibliotheque", "Ombrelac_salles": "astres",
	"Ombrelac_dortoirs": "commune", "Ombrelac_astrolabe_dedans": "observatoire", "Ombrelac_horloge_dedans": "bibliotheque",
	"Ombrelac_sortileges_dedans": "sortileges", "Ombrelac_grosse_tour_dedans": "bureau"}
## La portée de chaque sorte d'objet (à combien de mètres on s'en sert, depuis son segment)
const PORTEE := {"livres": 1.0, "tableau": 1.3, "carte_ciel": 1.1, "portrait": 1.3, "relique": 1.0, "lit": 1.1, "paillasse": 0.9,
	"echecs": 1.5, "astrolabe": 3.1, "lunette": 1.5, "globe": 1.3, "table_cartes": 1.2, "sphere": 1.4, "grimoire": 1.2,
	"mannequin": 1.5, "devise": 1.5, "cloche": 1.1, "registre": 1.0, "siege": 0.95, "fontaine": 5.2}
## Les maîtres des salles de cours
const MAITRES := {"astres": "fauconnier_om", "amphi": "equerre_om"}
const LECON_PAS := 13.0             # secondes entre deux phrases de la leçon
const REPAS := [[12.0, 13.5], [19.0, 20.5]]

var main: Node
var ombrelac: Node                  # (son « state » est enregistré avec la partie)
var chateau: Node3D
var vie: Node
var objets: Array = []              # {sorte, a, b, face, portee, …} (monde)
var courant: Dictionary = {}        # l'objet devant lequel on se tient
var assis: Dictionary = {}          # {siege (Transform3D), pied, regard, piece, spot, t, lecon, partie…}
var _ia: Dictionary = {}
var _inscrit: bool = false
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()


# =================================================================== construire

func build(the_main: Node, the_ombrelac: Node, the_chateau: Node3D, the_vie: Node) -> void:
	main = the_main
	ombrelac = the_ombrelac
	chateau = the_chateau
	vie = the_vie
	_rng.randomize()
	var xf: Transform3D = chateau.global_transform if chateau.is_inside_tree() else chateau.transform
	for nom in INTERIEURS:
		var n: Node = chateau.get_node_or_null(nom)
		if n == null:
			continue
		for o0 in (n.get("objets") if n.get("objets") != null else []):
			var o: Dictionary = (o0 as Dictionary).duplicate()
			o["a"] = xf * (o0["a"] as Vector3)
			o["b"] = xf * (o0["b"] as Vector3)
			o["face"] = (xf.basis * (o0["face"] as Vector3)).normalized() if (o0["face"] as Vector3).length() > 0.01 else Vector3.ZERO
			o["portee"] = float(PORTEE.get(str(o["sorte"]), 1.2))
			o["fonds"] = INTERIEURS[nom]
			o["noeud"] = nom
			objets.append(o)
		# les sièges (les mêmes que ceux des habitants)
		for b in (n.get("bancs") if n.get("bancs") != null else []):
			var t: Transform3D = xf * (b[0] as Transform3D)
			var lg: float = float(b[2])
			var mz: float = (float(b[3]) + float(b[4])) * 0.5
			var dx: float = maxf(lg * 0.5 - 0.3, 0.0)
			objets.append({"sorte": "siege", "a": t * Vector3(-dx, 0, mz), "b": t * Vector3(dx, 0, mz), "face": Vector3.ZERO,
				"portee": PORTEE["siege"], "banc": t, "dessus": float(b[1]), "largeur": lg, "arriere": float(b[3]), "avant": float(b[4]),
				"piece": str(b[6]), "noeud": nom, "n": objets.size()})
	# la fontaine du cloître (on se tient tout autour du bassin)
	var lieux: Variant = chateau.get("lieux")
	if lieux is Dictionary and (lieux as Dictionary).has("fontaine"):
		var fp: Vector3 = xf * ((lieux as Dictionary)["fontaine"] as Vector3)
		objets.append({"sorte": "fontaine", "a": fp, "b": fp, "face": Vector3.ZERO, "portee": PORTEE["fontaine"], "rmin": 3.2, "n": objets.size()})
	var me = self
	_ia = {"id": "ombrelac_objets", "pos": Vector3(0, -9999, 0), "radius": 0.1, "text": "", "vr": "",
		"call": func(): me.agir(), "when": func(): return not me.courant.is_empty() or not me.assis.is_empty()}


## Combien d'objets de cette sorte (pour les tests)
func nombre(sorte: String) -> int:
	return objets.filter(func(o): return str(o["sorte"]) == sorte).size()


# =================================================================== l'état (enregistré)

func _st() -> Dictionary:
	if ombrelac == null:
		return {}
	var s: Dictionary = ombrelac.state
	if not s.has("objets") or not (s["objets"] is Dictionary):
		s["objets"] = {}
	return s["objets"]


func _liste(cle: String) -> Array:
	var s: Dictionary = _st()
	if not s.has(cle) or not (s[cle] is Array):
		s[cle] = []
	return s[cle]


func _compte(cle: String, n: int = 1) -> int:
	var s: Dictionary = _st()
	s[cle] = int(s.get(cle, 0)) + n
	return int(s[cle])


# =================================================================== le jeu autour

func _heure() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _jour() -> int:
	return int(main.temps_v56.day_count) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 0


func _nuit() -> bool:
	var h: float = _heure()
	return h >= 20.0 or h < 5.5


func _xr() -> bool:
	return main != null and main.get("xr_active") == true


func _hero() -> Node:
	return main.get("hero_v28") if main != null else null


func _joueur() -> Vector3:
	return main._player_pos_v27() if main != null and main.has_method("_player_pos_v27") else Vector3(0, -9999, 0)


func _jouable() -> bool:
	if main == null or main.get("game_started") != true:
		return false
	for nom in ["game_menu", "inventory_v28", "dialogue_v31"]:
		var n: Variant = main.get(nom)
		if n != null and n.get("opened") == true:
			return false
	var j: Variant = main.get("jeux_v147")
	if j != null and j.get("assis") != null and str(j.get("assis")) != "":
		return false
	var d: Variant = main.get("donjon_v35")
	if d != null and d.get("_busy") == true:
		return false
	return true


func say(txt: String, s: float = 6.0) -> void:
	var d: Variant = main.get("donjon_v35") if main != null else null
	if d != null and d.has_method("_say"):
		d._say(txt, s)
	elif main != null and main.has_method("_show_message_v28"):
		main._show_message_v28(txt)


func sfx(nom: String, at: Variant = null) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(nom, at)


## Le point du segment [a, b] le plus proche de p (à plat)
static func _proche(a: Vector3, b: Vector3, p: Vector3) -> Vector3:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var l2: float = ab.length_squared()
	var t: float = 0.0
	if l2 > 1e-6:
		t = clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / l2, 0.0, 1.0)
	return a.lerp(b, t)


## L'objet devant lequel on se tient (ou {}) : le plus proche, de préférence celui qu'on regarde
func cherche(p: Vector3, regard: Vector3 = Vector3.ZERO) -> Dictionary:
	var best: Dictionary = {}
	var bs: float = INF
	for o in objets:
		var a: Vector3 = o["a"]
		var dy: float = p.y - a.y
		if dy < -0.6 or dy > 2.6:
			continue
		var q: Vector3 = _proche(a, o["b"], p)
		var off := Vector2(p.x - q.x, p.z - q.z)
		var d: float = off.length()
		if d > float(o["portee"]) or d < float(o.get("rmin", 0.0)):
			continue
		var f: Vector3 = o["face"]
		if f != Vector3.ZERO and off.dot(Vector2(f.x, f.z)) < -0.05:
			continue
		var s: float = d - float(o.get("prio", 0.0))
		if d > 0.05 and regard != Vector3.ZERO:
			s -= 0.35 * maxf(Vector2(regard.x, regard.z).dot(-off / d), 0.0)
		if s < bs:
			bs = s
			best = o
	return best


func _verbe(o: Dictionary) -> String:
	match str(o.get("sorte", "")):
		"livres":
			return "prendre un livre"
		"tableau":
			return "lire le tableau"
		"carte_ciel":
			return "regarder la carte du ciel"
		"portrait":
			return "regarder le portrait"
		"relique":
			return "regarder la relique"
		"lit":
			return "dormir" if _nuit() or _heure() >= 19.0 else "faire une sieste"
		"paillasse":
			return "préparer un élixir"
		"echecs":
			return "jouer aux échecs"
		"astrolabe":
			return "faire tourner l'astrolabe"
		"lunette":
			return "regarder dans la lunette"
		"globe":
			return "faire tourner le globe"
		"table_cartes":
			return "consulter les cartes du ciel"
		"sphere":
			return "regarder dans la sphère de cristal"
		"grimoire":
			return "ouvrir le grimoire"
		"mannequin":
			return "lancer un sort d'entraînement"
		"devise":
			return "lire la devise des fondateurs"
		"cloche":
			return "tirer la corde de la cloche"
		"registre":
			return "lire le registre de l'horloge"
		"siege":
			return "s'asseoir"
		"fontaine":
			return "jeter une pièce et faire un vœu"
	return "regarder"


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	if not _inscrit and main.get("donjon_v35") != null and main.donjon_v35 != null and main.donjon_v35.get("_interactions") != null:
		main.donjon_v35._interactions.append(_ia)
		_inscrit = true
	if not assis.is_empty():
		_assis_tick(delta)
	_t += delta
	if _t < 0.1:
		return
	_t = 0.0
	_suivre()


## L'objet courant, et l'invite (« E : … ») qui va avec
func _suivre() -> void:
	var p: Vector3 = _joueur()
	courant = {}
	if not assis.is_empty():
		_ia["pos"] = p
		_ia["radius"] = 1.0
		_ia["text"] = "E : se lever"
		_ia["vr"] = "Gâchette : se lever"
		return
	var loin: bool = chateau == null or Vector2(p.x - chateau.global_position.x, p.z - chateau.global_position.z).length() > 160.0
	var hero: Node = _hero()
	var regard: Vector3 = hero.facing if hero != null and not _xr() and hero.get("facing") != null else Vector3.ZERO
	var o: Dictionary = {} if loin else cherche(p, regard)
	# en VR, on ne s'assied pas (le corps du joueur, c'est lui-même)
	if not o.is_empty() and str(o["sorte"]) == "siege" and _xr():
		o = {}
	# un habitant plus près que l'objet : E lui parle (on n'affiche pas l'objet)
	if not o.is_empty() and main.has_method("_nearest_npc_v31"):
		var npc: Node3D = main._nearest_npc_v31()
		if npc != null:
			var q0: Vector3 = _proche(o["a"], o["b"], p)
			var dn: float = Vector2(npc.global_position.x - p.x, npc.global_position.z - p.z).length()
			if dn < Vector2(q0.x - p.x, q0.z - p.z).length():
				o = {}
	courant = o
	if o.is_empty():
		_ia["pos"] = Vector3(0, -9999, 0)
		_ia["text"] = ""
		_ia["vr"] = ""
		return
	var q: Vector3 = _proche(o["a"], o["b"], p)
	_ia["pos"] = Vector3(q.x, p.y, q.z)
	_ia["radius"] = Vector2(q.x - p.x, q.z - p.z).length() + 0.4
	_ia["text"] = "E : " + _verbe(o)
	_ia["vr"] = "Gâchette : " + _verbe(o)


## E (PC) : avant les habitants et le reste, quand on est devant un objet du château (ou assis)
func _unhandled_input(event: InputEvent) -> void:
	if main == null or _xr() or not (event is InputEventKey):
		return
	var e: InputEventKey = event
	if not e.pressed or e.echo or e.keycode != KEY_E:
		return
	if assis.is_empty() and courant.is_empty():
		return
	if not _jouable():
		return
	agir()
	get_viewport().set_input_as_handled()


## Faire ce que l'objet courant propose (E, la gâchette, ou les tests)
func agir() -> void:
	if not assis.is_empty():
		lever()
		return
	if courant.is_empty():
		_suivre()
	if courant.is_empty():
		return
	agir_sur(courant)


func agir_sur(o: Dictionary) -> void:
	var p: Vector3 = (o["a"] as Vector3).lerp(o["b"], 0.5)
	match str(o["sorte"]):
		"siege":
			asseoir(o)
		"livres":
			_livre(o)
		"tableau":
			var lt: Array = T.TABLEAUX.get(str(o.get("m", "tableau")), T.TABLEAUX["tableau"])
			say(str(lt[(_jour() + _compte("tableaux")) % lt.size()]), 9.0)
		"carte_ciel":
			say(str(T.CARTES_CIEL[int(o.get("n", 0)) % T.CARTES_CIEL.size()]), 8.0)
		"portrait":
			var r: Array = T.RECTEURS[int(o.get("portrait", 0)) % T.RECTEURS.size()]
			var vus: Array = _liste("portraits")
			if not vus.has(int(o.get("portrait", 0))):
				vus.append(int(o.get("portrait", 0)))
			say("%s. %s%s" % [r[0], r[1], "" if vus.size() < T.RECTEURS.size() else (" (Tu connais maintenant les %d anciens Recteurs.)" % T.RECTEURS.size())], 9.0)
		"relique":
			var rq: Array = T.RELIQUES[int(o.get("relique", 0)) % T.RELIQUES.size()]
			say("%s. %s" % [rq[0], rq[1]], 9.0)
			sfx("cristal_chante", p)
		"devise":
			say(T.DEVISE, 10.0)
		"grimoire":
			sfx("carte", p)
			say(str(T.GRIMOIRE[_rng.randi() % T.GRIMOIRE.size()]), 9.0)
		"registre":
			sfx("carte", p)
			say(str(T.REGISTRE_HORLOGE[_compte("registre") % T.REGISTRE_HORLOGE.size()]), 8.0)
		"sphere":
			sfx("cristal_chante", p)
			say(str(T.SPHERE[_rng.randi() % T.SPHERE.size()]), 7.0)
		"mannequin":
			sfx("geste_magie", p)
			sfx("impact_arcane", p)
			_compte("sorts")
			say(str(T.MANNEQUIN[_rng.randi() % T.MANNEQUIN.size()]), 6.0)
		"table_cartes":
			say(T.TABLE_CARTES + " (Dans ton carnet : %d constellation%s sur %d.)" % [_liste("constellations").size(), "s" if _liste("constellations").size() > 1 else "", T.CONSTELLATIONS.size()], 9.0)
		"globe":
			sfx("rouage", p)
			var c: Array = T.CONSTELLATIONS[_rng.randi() % T.CONSTELLATIONS.size()]
			say("Tu fais tourner le globe céleste… il ralentit, ralentit, et ton doigt s'arrête sur %s." % c[0], 6.0)
		"astrolabe":
			_astrolabe(p)
		"lunette":
			_lunette(o, p)
		"cloche":
			_cloche()
		"fontaine":
			_fontaine(p)
		"lit":
			_lit(o, p)
		"paillasse":
			_elixir(p)
		"echecs":
			_echecs(o)


# =================================================================== lire

func _livre(o: Dictionary) -> void:
	var fonds: String = str(o.get("fonds", "bibliotheque"))
	var liste: Array = {"bibliotheque": T.BIBLIOTHEQUE, "astres": T.ASTRES, "observatoire": T.OBSERVATOIRE, "commune": T.COMMUNE,
		"sortileges": T.SORTILEGES, "bureau": T.BUREAU}.get(fonds, T.BIBLIOTHEQUE)
	var lus: Array = _liste("livres")
	var pas_lus: Array = []
	for i in range(liste.size()):
		if not lus.has("%s:%d" % [fonds, i]):
			pas_lus.append(i)
	var k: int = int(pas_lus[_rng.randi() % pas_lus.size()]) if not pas_lus.is_empty() else _rng.randi() % liste.size()
	var nouveau: bool = not pas_lus.is_empty()
	if nouveau:
		lus.append("%s:%d" % [fonds, k])
	sfx("carte", (o["a"] as Vector3).lerp(o["b"], 0.5))
	var b: Array = liste[k]
	var fin: String = ""
	if nouveau and pas_lus.size() == 1:
		fin = " — Tu as lu tous les livres de ce rayon ! Dame Reliure serait fière de toi." if fonds != "bibliotheque" else \
			" — C'était le dernier : tu as lu tous les livres de la Bibliothèque ! Dame Reliure dit que la réserve t'attend. Un jour."
	say("Tu prends un livre : « %s ». %s%s" % [b[0], b[1], fin], 12.0)


# =================================================================== agir

func _astro() -> Node:
	return chateau.get_node_or_null("Ombrelac_astrolabe_dedans") if chateau != null else null


func _astrolabe(p: Vector3) -> void:
	var a: Node = _astro()
	if a != null:
		a.elan = maxf(float(a.elan), 1.0) + 6.0
	sfx("cliquet_roue", p)
	var n: int = _compte("astrolabe")
	say("Tu pousses le grand anneau d'or : les trois anneaux du Grand Astrolabe s'emballent dans un long chant de laiton, puis reprennent peu à peu le pas du ciel." if n == 1
		else "Les anneaux tournent, tournent… Le ciel, lui, ne s'en aperçoit pas. Heureusement.", 6.0)


func _lunette(o: Dictionary, p: Vector3) -> void:
	sfx("cliquet_roue", p)
	var grande: bool = bool(o.get("grande", false))
	var qui: String = "Tu colles ton œil à la Grande Lunette. " if grande else "Tu regardes dans la lunette de la Salle des Astres. "
	if not _nuit():
		say(qui + str(T.LUNETTE_JOUR[_rng.randi() % T.LUNETTE_JOUR.size()]), 7.0)
		return
	var vues: Array = _liste("constellations")
	var c: int = -1
	for i in range(T.CONSTELLATIONS.size()):
		if not vues.has(i):
			c = i
			break
	if c < 0:
		var cc: Array = T.CONSTELLATIONS[_rng.randi() % T.CONSTELLATIONS.size()]
		say(qui + "Tu reconnais %s. %s" % [cc[0], cc[1]], 8.0)
		return
	vues.append(c)
	var cn: Array = T.CONSTELLATIONS[c]
	var fin: String = " (Nouvelle constellation dans ton carnet : %d sur %d.)" % [vues.size(), T.CONSTELLATIONS.size()]
	if vues.size() == T.CONSTELLATIONS.size():
		fin = " Tu as trouvé toutes les constellations d'Ombrelac !"
		if main.has_method("jingle"):
			main.jingle("decouverte")
	say(qui + "Tu découvres %s. %s%s" % [cn[0], cn[1], fin], 9.0)


func _cloche() -> void:
	var h: Node = chateau.get_node_or_null("Ombrelac_horloge_dedans") if chateau != null else null
	var n: int = _compte("cloche")
	# (elle sonne déjà les heures : ton coup s'ajoute aux siens)
	if h != null and int(h.get("coups_a_sonner")) > 0:
		h.coups_a_sonner = int(h.coups_a_sonner) + 1
		say("Tu tires sur la corde… la cloche sonnait déjà l'heure : elle sonnera un coup de plus. Maître Rouage va devoir recompter.", 5.0)
		return
	if h != null and h.has_method("sonner"):
		h.sonner(1)
	if _nuit():
		say("Tu tires de toutes tes forces sur la corde… DONG ! La cloche roule dans la nuit. Quelque part dans le château, Maître Rouage soupire.", 6.0)
	elif n == 1:
		say("Tu tires de toutes tes forces sur la corde… DONG ! La cloche répond au-dessus de ta tête, et tout le château l'entend.", 6.0)
	else:
		say("DONG ! Les rouages en frémissent. Les pigeons de la tour, eux, ont l'habitude.", 5.0)


func _fontaine(p: Vector3) -> void:
	var inv: Node = main.get("inventory_v28")
	if inv == null or int(inv.count("piece")) <= 0:
		say("Tu n'as pas de pièce. Tu fais un vœu quand même, tout bas. La grenouille de la fontaine fait semblant de ne pas avoir entendu.", 6.0)
		return
	inv.remove("piece", 1)
	sfx("obole", p)
	sfx("plouf", p)
	var n: int = _compte("voeux")
	var txt: String = str(T.VOEUX[_rng.randi() % T.VOEUX.size()])
	# de temps en temps, la grenouille du cloître rend la pièce (elle sait des choses)
	if n % 5 == 3:
		inv.add("piece", 2)
		txt += " Soudain, une grenouille saute sur le bord du bassin, une pièce dans la bouche… elle t'en rend deux ! Elle a l'air de savoir quelque chose."
	say(txt, 8.0)


func _lit(o: Dictionary, p: Vector3) -> void:
	var tv: Node = main.get("temps_v56")
	if tv == null or not tv.has_method("sleep_until"):
		return
	if tv.get("_sleeping") == true:
		return
	var h: float = _heure()
	var nuit: bool = h >= 19.0 or h < 6.0
	var dortoir: String = "de l'Aube" if str(o.get("velours", "")).ends_with("bleu") else "du Crépuscule"
	sfx("lit_dodo", p)
	_compte("nuits" if nuit else "siestes")
	tv.sleep_until(7.0 if nuit else 19.0)
	say(("Tu te glisses sous l'édredon d'un lit du Dortoir %s. Les rideaux du baldaquin se referment, la cloche sonne au loin… Zzz…" if nuit
		else "Tu t'allonges un moment sur un lit du Dortoir %s. Juste cinq minutes. Le soleil, lui, continue sa route… Zzz…") % dortoir, 5.0)


func _elixir(p: Vector3) -> void:
	var s: Dictionary = _st()
	var j: int = _jour()
	if int(s.get("elixir_jour", -999)) == j:
		say("Maîtresse Alambic l'a bien dit : un élixir par jour, pas plus. « Les alambics ont besoin de souffler. Moi aussi. »", 6.0)
		return
	var inv: Node = main.get("inventory_v28")
	var r: float = _rng.randf()
	var id: String = "elixir_etoile" if r < 0.18 else ("potion_seve" if r < 0.6 else "potion_mana")
	if inv == null or int(inv.add(id, 1)) <= 0:
		say("Ton sac est plein : impossible d'y glisser une fiole de plus.", 4.0)
		return
	s["elixir_jour"] = j
	_compte("elixirs")
	sfx("vapeur", p)
	sfx("verser", p)
	var txt: Dictionary = {
		"elixir_etoile": "Tu verses, tu tournes, tu comptes jusqu'à sept… L'alambic s'illumine d'or : un élixir d'étoile ! Maîtresse Alambic, impressionnée, dit « intéressant ». Dans le bon sens, cette fois.",
		"potion_seve": "Les herbes frémissent dans le ballon, la vapeur sent la forêt après la pluie : une potion de sève, bien verte. Tu la glisses dans ton sac.",
		"potion_mana": "Une pincée de poudre bleue, trois gouttes d'eau du lac, et le liquide se met à briller : une potion de magie. Elle fait de toutes petites bulles qui chantent."}
	say(str(txt[id]), 8.0)


# =================================================================== s'asseoir

## La hauteur du bassin au-dessus des pieds du héros, dans la pose assise (pour la poser sur l'assise)
func _bassin_heros() -> float:
	var hero: Node = _hero()
	if hero == null:
		return 0.45
	var anim: AnimationPlayer = hero.get("anim")
	var skel: Skeleton3D = hero.get("skel")
	var vis: Node3D = hero.get("hero")
	if anim == null or skel == null or vis == null or not anim.has_animation("v28/sit") or not skel.is_inside_tree():
		return 0.45
	var a: Animation = anim.get_animation("v28/sit")
	for t in range(a.get_track_count()):
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and str(a.track_get_path(t)).ends_with(":Hips"):
			var v: Vector3 = a.position_track_interpolate(t, 0.0) * skel.motion_scale
			var h: float = (skel.global_transform * v).y - vis.global_position.y
			if h > 0.1 and h < 1.2:
				return h
	return 0.45


## La place du siège sous p : [repère pour le héros (regard -Z), le point de l'assise] ; la place
## libre la plus proche le long du banc
func place(o: Dictionary, p: Vector3) -> Array:
	var t: Transform3D = o["banc"]
	var l: Vector3 = t.affine_inverse() * p
	var demi: float = float(o["largeur"]) * 0.5 - 0.3
	var lx: float = clampf(l.x, -demi, demi) if demi > 0.0 else 0.0
	var s: Vector3 = t * Vector3(lx, float(o["dessus"]), lerpf(float(o["arriere"]), float(o["avant"]), 0.42))
	var b: Basis = t.basis.orthonormalized() * Basis(Vector3.UP, PI)
	return [Transform3D(b, s), s]


func asseoir(o: Dictionary, partie: bool = false) -> bool:
	var hero: Node = _hero()
	if hero == null or _xr() or not assis.is_empty():
		return false
	var p: Vector3 = _joueur()
	var pl: Array = place(o, p)
	var s: Vector3 = pl[1]
	# un habitant y est déjà assis ?
	if vie != null:
		for npc in vie.habitants:
			if is_instance_valid(npc) and (npc as Node3D).visible and Vector2(npc.global_position.x - s.x, npc.global_position.z - s.z).length() < 0.45 and absf(npc.global_position.y - s.y) < 1.5:
				say("La place est déjà prise par %s." % str(npc.get("display_name")) if str(npc.get("display_name")) != "" else "La place est déjà prise.", 3.0)
				return false
	var hh: float = _bassin_heros()
	var xf: Transform3D = pl[0]
	xf.origin = s + Vector3.UP * (0.37 + 0.1 - hh)
	var corps: Node3D = main.get("pc_body")
	var pied: Vector3 = corps.global_position if corps != null else p
	# la place des habitants à cet endroit : on la retient (ils iront ailleurs)
	var spot: String = ""
	if vie != null:
		for k in vie.spots:
			var e: Dictionary = vie.spots[k]
			if str(e.get("node", "")) != "" and (e["pos"] as Vector3).distance_to(Vector3(s.x, (e["pos"] as Vector3).y, s.z)) < 0.5 and absf((e["pos"] as Vector3).y - (o["banc"] as Transform3D).origin.y) < 1.0:
				if vie.spot_free(k, self):
					vie.claim_spot(k, self)
					spot = k
				break
	assis = {"siege": xf, "pied": pied, "racine": main.pc_root.global_position if main.get("pc_root") != null else p,
		"regard": -(xf.basis.z), "piece": str(o.get("piece", "")), "spot": spot, "t": 0.0, "lecon": 0, "dit": false}
	courant = {}
	hero.ride(xf)
	_compte("assis")
	if partie:
		assis["partie"] = {"t": 0.0, "etape": 0, "adversaire": _adversaire(s)}
	return true


func lever(silence: bool = false) -> void:
	if assis.is_empty():
		return
	var hero: Node = _hero()
	if hero != null and str(hero.get("state")) == "bateau":
		hero.leave_ride()
	if str(assis.get("spot", "")) != "" and vie != null:
		vie.release_spot(str(assis["spot"]), self)
	if assis.has("partie") and int(assis["partie"]["etape"]) < 3 and not silence:
		say("Tu te lèves : la partie est abandonnée. Les pièces, elles, restent en place, comme pour te dire « à plus tard ».", 4.0)
	var r: Vector3 = assis["racine"]
	var reg: Vector3 = assis["regard"]
	assis = {}
	if not silence and main.has_method("place_player_v35"):
		main.place_player_v35(r, reg)


func _assis_tick(delta: float) -> void:
	var hero: Node = _hero()
	var corps: CharacterBody3D = main.get("pc_body")
	if hero == null or corps == null or _xr():
		lever(true)
		return
	# on a été emporté ailleurs (un voyage, un évanouissement…) : on n'est plus assis
	if corps.global_position.distance_to(assis["pied"]) > 2.5 or str(hero.get("state")) not in ["bateau", "sol", "air"]:
		lever(true)
		return
	# marcher, sauter : on se lève
	var ax: Vector2 = hero._axis() if hero.has_method("_axis") else Vector2.ZERO
	if _jouable() and (ax.length() > 0.3 or Input.is_key_pressed(KEY_SPACE)):
		lever()
		return
	corps.global_position = assis["pied"]
	corps.velocity = Vector3.ZERO
	hero.ride(assis["siege"])
	assis["t"] = float(assis["t"]) + delta
	if assis.has("partie"):
		_partie_tick()
	else:
		_lecon_tick()
		_repas_tick()


## Assis dans une salle de cours, pendant le cours (le maître est à son tableau) : la leçon
func _lecon_tick() -> void:
	var pc: String = str(assis.get("piece", ""))
	if not MAITRES.has(pc) or vie == null:
		return
	var m: Node3D = vie.by_id.get(MAITRES[pc], null)
	var sp: Dictionary = vie.spots.get(pc + "_maitre", {})
	var la: bool = m != null and is_instance_valid(m) and not sp.is_empty() and m.global_position.distance_to(sp["pos"]) < 4.0
	var t: float = float(assis["t"])
	if not la:
		if not bool(assis["dit"]) and t > 1.0:
			assis["dit"] = true
			say("La salle est calme. Le maître n'est pas à son tableau : le cours n'a pas encore commencé (ou il est fini).", 4.0)
		return
	var lignes: Array = T.LECONS[pc]
	var i: int = int(assis["lecon"])
	if i < lignes.size() and t > 1.5 + i * LECON_PAS:
		assis["lecon"] = i + 1
		var fin: String = ""
		if i + 1 == lignes.size():
			var n: int = _compte("lecons_" + pc)
			fin = " (Leçon écoutée jusqu'au bout. Leçons de %s suivies : %d.)" % ["Maître Fauconnier" if pc == "astres" else "Maître Équerre", n]
		say(str(lignes[i]) + fin, LECON_PAS - 1.0)


## Assis à une table de la Grande Salle à l'heure du repas : Mère Fournil vous sert (une fois par repas)
func _repas_tick() -> void:
	if str(assis.get("piece", "")) != "grande_salle" or float(assis["t"]) < 5.0 or bool(assis.get("servi", false)):
		return
	var h: float = _heure()
	for k in range(REPAS.size()):
		if h >= float(REPAS[k][0]) and h < float(REPAS[k][1]):
			assis["servi"] = true
			var cle: int = _jour() * 2 + k
			if int(_st().get("repas", -1)) == cle:
				return
			_st()["repas"] = cle
			_compte("repas")
			var hero: Node = _hero()
			if hero != null and hero.has_method("set_health"):
				hero.set_health(int(hero.HP_MAX))
			sfx("manger", (assis["siege"] as Transform3D).origin)
			say(("Mère Fournil pose devant toi une assiette fumante : une soupe de potiron et une part de tarte aux myrtilles des falaises. Tous tes cœurs sont revenus." if k == 0
				else "Le dîner est servi : du pain chaud, un ragoût qui sent le thym, une compote. Mère Fournil te ressert sans demander. Tous tes cœurs sont revenus."), 8.0)
			return


# =================================================================== les échecs

func _adversaire(s: Vector3) -> String:
	if vie == null:
		return ""
	var best: String = ""
	var bd: float = 4.0
	for npc in vie.habitants:
		if is_instance_valid(npc) and (npc as Node3D).visible:
			var d: float = (npc as Node3D).global_position.distance_to(s)
			if d < bd:
				bd = d
				best = str(npc.get("display_name"))
	return best


func _echecs(o: Dictionary) -> void:
	# on s'assied sur la chaise libre la plus proche de l'échiquier
	var c: Vector3 = o["a"]
	var best: Dictionary = {}
	var bd: float = 1.6
	for s in objets:
		if str(s["sorte"]) != "siege":
			continue
		var d: float = Vector2((s["a"] as Vector3).x - c.x, (s["a"] as Vector3).z - c.z).length()
		if d < bd and absf((s["a"] as Vector3).y - c.y) < 0.5:
			bd = d
			best = s
	if not best.is_empty() and not _xr() and asseoir(best, true):
		var adv: String = str(assis["partie"]["adversaire"])
		say("Tu t'installes devant l'échiquier%s. Les blancs commencent : c'est toi." % ((" face à " + adv) if adv != "" else ""), 4.0)
		return
	# (en VR, ou les chaises sont prises) : une partie rapide, debout
	sfx("des_roule", c)
	say(_resultat(""), 7.0)


func _partie_tick() -> void:
	var pa: Dictionary = assis["partie"]
	var t: float = float(assis["t"])
	var e: int = int(pa["etape"])
	var adv: String = str(pa["adversaire"])
	if e == 0 and t > 5.0:
		pa["etape"] = 1
		say("Tu avances un pion. %s répond aussitôt. Les cavaliers sortent, les fous se croisent…" % (adv if adv != "" else "Le côté noir (toi aussi)"), 5.0)
	elif e == 1 and t > 11.0:
		pa["etape"] = 2
		say(["Ta dame s'aventure au milieu du plateau. C'est audacieux. C'est peut-être même une bonne idée.",
			"Un échange de tours. Un silence. Quelqu'un, derrière toi, retient son souffle.",
			"Tu roques. Tu ne sais pas très bien pourquoi, mais ça a l'air sérieux."][_rng.randi() % 3], 5.0)
	elif e == 2 and t > 17.0:
		pa["etape"] = 3
		say(_resultat(adv), 7.0)


func _resultat(adv: String) -> String:
	var r: float = _rng.randf()
	var n: int = _compte("parties")
	if r < 0.42:
		var g: int = _compte("parties_gagnees")
		return "Échec et mat ! Tu gagnes la partie%s. (Parties gagnées à Ombrelac : %d sur %d.)" % [(" contre " + adv) if adv != "" else "", g, n]
	elif r < 0.62:
		return "Pat : personne ne peut plus bouger. Match nul ! %s" % ("Vous vous serrez la main." if adv != "" else "Tu te serres la main à toi-même.")
	return "Échec et mat… pour toi. %s (Parties jouées : %d.)" % [(adv + " a l'air ravi" + ("e" if adv in ["Lison", "Nour", "Ombeline", "Sidonie"] else "") + ".") if adv != "" else "Les noirs ont gagné. Tu jouais aussi les noirs.", n]

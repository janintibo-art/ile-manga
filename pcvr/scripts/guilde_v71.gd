extends Node
## V71 : la Guilde des Aventuriers de Montjoie.
##  - l'inscription (la quête mj_inscription, chez Églantine) donne la Carte d'aventurier : on est
##    au rang F ;
##  - les rangs : F, E, D, C, B, A, S (points de guilde : 0, 30, 80, 160, 280, 450, 700). Les points
##    viennent des contrats du tableau, des quêtes de Montjoie et des alertes aux navets ;
##  - le TABLEAU DES QUÊTES (E devant le tableau, dans la Guilde) : quatre contrats chaque jour,
##    selon le rang (chasser, rapporter, descendre dans le donjon) ; on en accepte trois au plus ;
##    on les rend à Églantine (pièces, points, un coup de tampon) ; une montée de rang est criée
##    sur la Grand-Place par Mélusine ;
##  - la boule de cristal du comptoir (E) « mesure les aptitudes » (avec beaucoup d'imagination) ;
##  - les compagnons (compagnons_v71) : « Viens avec moi ! » (Pétronille, Violette, Tancrède,
##    après leur quête, pour un aventurier inscrit) ; « Va te reposer à la Guilde » (E près d'eux,
##    ou chez Églantine).

const RANGS := ["F", "E", "D", "C", "B", "A", "S"]
const SEUILS := [0, 30, 80, 160, 280, 450, 700]
const COMPAGNONS := {"petronille": ["mj_petronille", "Sœur Pétronille"], "violette": ["mj_violette", "Violette"], "tancrede": ["mj_tancrede", "Sire Tancrède"]}
## Les points de guilde des quêtes de Montjoie (à la fin de chacune).
const POINTS_QUETES := {"mj_inscription": 0, "mj_donjon": 120, "mj_petronille": 15, "mj_violette": 20, "mj_tancrede": 25, "mj_grenouilles": 15,
	"mj_navets": 10, "mj_chapeau": 10, "mj_maison": 10, "mj_grimoire": 12, "mj_pain": 8}
## Les contrats : [id, rang min (0 = F), type, cible, nombre, pièces, points, titre].
## type : « chasse » (cible : sortes de monstres séparées par des virgules), « objets » (un objet
## à rapporter), « etage » (descendre jusqu'à l'étage n du donjon).
const CONTRATS := [
	["slimes_5", 0, "chasse", "slime,slime_bleu,slime_rose", 5, 20, 10, "Chasser cinq slimes dans les prés"],
	["gelee_3", 0, "objets", "gelee_slime", 3, 15, 8, "Rapporter trois pots de gelée de slime (pour l'apothicaire)"],
	["navets_2", 0, "objets", "navet_dore", 2, 14, 8, "Rapporter deux navets dorés (Père Gaubert les veut empaillés)"],
	["bleus_3", 0, "chasse", "slime_bleu", 3, 18, 9, "Chasser trois slimes bleus (ils tachent les lessives du lavoir)"],
	["grenouilles_2", 1, "chasse", "grenouille_geante,grenouille_reine", 2, 30, 15, "Chasser deux grenouilles géantes au lac"],
	["gobelins_4", 1, "chasse", "gobelin,gobelin_chef", 4, 26, 14, "Chasser quatre gobelins au Bois des Lutins (ils volent les chaussettes)"],
	["cuisses_2", 1, "objets", "cuisse_grenouille", 2, 22, 12, "Rapporter deux cuisses de grenouille (commande de l'auberge)"],
	["crocs_3", 1, "objets", "croc_gobelin", 3, 24, 12, "Rapporter trois crocs de gobelin (pour le collier de Maître Hugues)"],
	["etage_2", 1, "etage", "", 2, 30, 18, "Descendre jusqu'au 2e étage du Donjon des Mille Marches"],
	["loups_3", 2, "chasse", "loup", 3, 36, 20, "Chasser trois loups au Bois des Lutins (la nuit)"],
	["squelettes_4", 2, "chasse", "squelette", 4, 40, 22, "Chasser quatre squelettes dans le donjon (ils font peur aux mimiques)"],
	["mimiques_2", 2, "chasse", "mimique", 2, 45, 24, "Chasser deux mimiques (les vrais coffres vous remercient)"],
	["etage_4", 2, "etage", "", 4, 50, 30, "Descendre jusqu'au 4e étage du Donjon des Mille Marches"],
	["slimes_15", 3, "chasse", "slime,slime_bleu,slime_rose", 15, 45, 25, "Grand nettoyage : chasser quinze slimes"],
	["reine_1", 3, "chasse", "grenouille_reine", 1, 60, 35, "Chasser la Duchesse, la Grenouille Reine du lac (elle a mangé une barque)"],
	["chef_1", 3, "chasse", "gobelin_chef", 1, 60, 35, "Vaincre le chef gobelin (encore lui ? oui, encore lui)"],
	["etage_5", 3, "etage", "", 5, 80, 45, "Atteindre la salle du trône, au 5e étage du donjon"],
	["gelee_8", 4, "objets", "gelee_slime", 8, 70, 40, "Rapporter huit pots de gelée (Madame Olga prépare un bain)"],
	["gobelins_10", 4, "chasse", "gobelin,gobelin_chef", 10, 80, 45, "Chasser dix gobelins (la Guilde a besoin de chaussettes)"],
	["grenouilles_8", 5, "chasse", "grenouille_geante,grenouille_reine", 8, 110, 60, "Chasser huit grenouilles géantes (le lac déborde de coassements)"],
]
## Ce que dit la boule de cristal (les aptitudes « mesurées »).
const APTITUDES := ["Force", "Agilité", "Chance", "Magie", "Courage", "Prudence", "Sens de l'orientation", "Appétit"]
const NOTES := ["phénoménale", "très bonne", "correcte", "honnête", "timide", "en vacances", "« euh… »", "hors de l'échelle (vers le haut)", "hors de l'échelle (vers le bas)", "en cours de chargement"]
const CONCLUSIONS := [
	"Classe conseillée : aventurier. (La boule conseille ça à tout le monde.)",
	"La boule ajoute : « Évitez les grenouilles. » Personne ne sait pourquoi. Tout le monde l'écoute.",
	"La boule fait un petit bruit satisfait. Églantine note : « La boule est contente. »",
	"La boule devient rose une seconde. D'après Églantine, ça veut dire « talent caché ». Très caché.",
	"La boule embue sa propre vitre. Elle a besoin d'un moment.",
]

var main: Node
var mj: Node                              # montjoie_v71
var state := {}
var _ally_ia: Dictionary = {}
var _board_ia: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _quest_seen: Dictionary = {}
var _tick_t: float = 0.0


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	mj = manager
	_rng.randomize()
	state = _fresh()


func _fresh() -> Dictionary:
	return {"points": 0, "rang": 0, "jour": -1, "tableau": [], "acceptes": {}, "rendus": 0, "quetes_payees": {}, "mesures": 0, "compagnon": false}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary or d[k] is Array) else d[k].duplicate(true)


func trouvailles() -> Dictionary:
	var ever: bool = bool(state.get("compagnon", false))
	if not ever and mj.compagnons != null and not mj.compagnons.active_ids().is_empty():
		state["compagnon"] = true
		ever = true
	return {"inscription": 1 if inscrit() else 0, "compagnon": 1 if ever else 0, "guilde_inscrit": 1 if inscrit() else 0, "rang_guilde": int(state["rang"]), "contrats_rendus": int(state["rendus"]),
		"rang_d": 1 if int(state["rang"]) >= 2 else 0, "rang_s": 1 if int(state["rang"]) >= 6 else 0}


# =================================================================== le rang

func inscrit() -> bool:
	var j: Node = main.get("journal_v56") if main != null else null
	if j != null and str(j.state("mj_inscription")) == "finie":
		return true
	return main != null and main.get("inventory_v28") != null and main.inventory_v28.count("carte_aventurier") > 0


func rang() -> String:
	return RANGS[int(state["rang"])]


## Le rang (lettre) atteint : pour les conditions des quêtes (« rang D au moins »).
func rang_au_moins(lettre: String) -> bool:
	return inscrit() and int(state["rang"]) >= RANGS.find(lettre)


func add_points(n: int, why: String = "") -> void:
	if n <= 0 or not inscrit():
		return
	state["points"] = int(state["points"]) + n
	var r: int = int(state["rang"])
	while r + 1 < SEUILS.size() and int(state["points"]) >= SEUILS[r + 1]:
		r += 1
	main._show_message_v28("+%d points de guilde%s" % [n, (" (" + why + ")") if why != "" else ""])
	if r > int(state["rang"]):
		state["rang"] = r
		_rank_up()


func _rank_up() -> void:
	var at: Vector3 = mj.city.lieux.crier_bell if mj.city != null else main._player_pos_v27()
	mj.sfx("rang_monte", main._player_pos_v27())
	mj.sfx("alerte_cloche", at)
	var lines := {
		"E": "Oyez, oyez ! Par décision de la Guilde, notre aventurier passe au RANG E ! Il a vaincu des slimes ! Plusieurs ! Applaudissez, s'il vous plaît, même les poules !",
		"D": "Oyez, oyez ! RANG D ! Notre aventurier a survécu aux grenouilles, aux gobelins et au formulaire de Mademoiselle Églantine ! Maître Hugues a des choses sérieuses à lui confier !",
		"C": "Oyez, oyez ! RANG C ! Montjoie a désormais un vrai héros… presque ! Les enfants, vous pouvez demander des autographes. Pas plus de trois chacun !",
		"B": "Oyez, oyez ! RANG B ! Les bardes composent déjà une chanson ! Elle rime mal, mais elle est très longue !",
		"A": "Oyez, oyez ! RANG A ! Le Baron en a fait tomber son chapeau ! Encore ! Quelqu'un peut aller le chercher ?",
		"S": "Oyez, oyez, OYEZ ! RANG S ! LÉGENDE DE LA GUILDE ! Maître Hugues pleure de joie dans sa tourte ! On fermera les boutiques une heure ! Non, dix minutes ! Bon, cinq !"}
	mj.say("Mélusine, la crieuse, sur la Grand-Place : « %s »" % str(lines.get(rang(), "Oyez, oyez ! Un nouveau rang !")), 9.0)


# =================================================================== le tableau des quêtes

func _today() -> int:
	return int(main.temps_v56.day_count) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 1


func _contract(id: String) -> Array:
	for c in CONTRATS:
		if str(c[0]) == id:
			return c
	return []


## Les quatre contrats du jour (renouvelés chaque jour de jeu, selon le rang).
func _refresh_board() -> void:
	if int(state["jour"]) == _today() and not (state["tableau"] as Array).is_empty():
		return
	state["jour"] = _today()
	var r: int = int(state["rang"])
	var pool: Array = []
	for c in CONTRATS:
		if int(c[1]) <= r and not (state["acceptes"] as Dictionary).has(str(c[0])):
			pool.append(str(c[0]))
	var rng := RandomNumberGenerator.new()
	rng.seed = _today() * 7919 + r
	var pick: Array = []
	# les contrats de son rang d'abord (s'il y en a), puis les autres
	var mine: Array = pool.filter(func(id): return int(_contract(id)[1]) == r)
	var rest: Array = pool.filter(func(id): return int(_contract(id)[1]) != r)
	for src in [mine, rest]:
		var a: Array = (src as Array).duplicate()
		while not a.is_empty() and pick.size() < 4:
			var i: int = rng.randi() % a.size()
			pick.append(a[i])
			a.remove_at(i)
	state["tableau"] = pick


func _kills(sortes: String) -> int:
	var pr: Node = main.get("progression_v63") if main != null else null
	if pr == null:
		return 0
	var n: int = 0
	for s in sortes.split(","):
		n += int((pr.kills_kind as Dictionary).get(s, 0))
	return n


func _deepest() -> int:
	if mj.dungeon == null:
		return 0
	return int((mj.dungeon.state as Dictionary).get("profond", 0))


## Où en est un contrat accepté : [fait, objectif].
func progress(id: String) -> Array:
	var c: Array = _contract(id)
	if c.is_empty():
		return [0, 1]
	var n: int = int(c[4])
	match str(c[2]):
		"chasse":
			var base: int = int((state["acceptes"] as Dictionary).get(id, 0))
			return [mini(_kills(str(c[3])) - base, n), n]
		"objets":
			return [mini(main.inventory_v28.count(str(c[3])), n), n]
		"etage":
			return [mini(_deepest(), n), n]
	return [0, n]


func _label(c: Array) -> String:
	return "[%s] %s — %d pièces, %d points" % [RANGS[int(c[1])], str(c[7]), int(c[5]), int(c[6])]


func open_board() -> void:
	if main == null or not main.has_method("ask_v69"):
		return
	if not inscrit():
		mj.say("Le tableau est couvert d'affiches : slimes, grenouilles, gobelins, un chapeau à plume… Une pancarte : « Contrats réservés aux aventuriers inscrits. Voir Églantine, au comptoir. (Elle ne mord pas.) »", 7.0)
		return
	_refresh_board()
	var choices: Array = []
	var acc: Dictionary = state["acceptes"]
	for id in state["tableau"]:
		var c: Array = _contract(str(id))
		if c.is_empty():
			continue
		choices.append({"id": "mj_tab:" + str(id), "label": "✦ " + _label(c)})
	for id2 in acc:
		var c2: Array = _contract(str(id2))
		if c2.is_empty():
			continue
		var pg: Array = progress(str(id2))
		choices.append({"id": "mj_tab_info:" + str(id2), "label": "✔ (accepté) %s — %d/%d" % [str(c2[7]), int(pg[0]), int(pg[1])]})
	choices.append({"id": "mj_tab:fermer", "label": "(Laisser le tableau)"})
	var txt: String = "Le Tableau des Quêtes. Rang %s, %d points de guilde (prochain rang à %s). Contrats acceptés : %d sur 3. Les contrats changent chaque matin." % [rang(), int(state["points"]),
		(str(SEUILS[int(state["rang"]) + 1]) if int(state["rang"]) + 1 < SEUILS.size() else "—"), acc.size()]
	if (state["tableau"] as Array).is_empty():
		txt += " (Plus rien aujourd'hui : revenez demain, de nouvelles affiches seront punaisées.)"
	main.ask_v69(_board_speaker(), "Tableau des Quêtes", "", txt, choices, Callable(self, "_board_pick"))


var _speaker: Node3D

func _board_speaker() -> Node3D:
	if _speaker == null:
		_speaker = Node3D.new()
		_speaker.name = "Tableau_quetes_v71"
		mj.add_child(_speaker)
		_speaker.global_position = mj.city.lieux.guild_board + Vector3.UP * 1.6
	return _speaker


func _board_pick(id: String) -> void:
	if id == "mj_tab:fermer" or not id.contains(":"):
		_close_board()
		return
	var cid: String = id.split(":")[1]
	if id.begins_with("mj_tab_info:"):
		open_board()
		return
	var acc: Dictionary = state["acceptes"]
	if acc.size() >= 3:
		mj.say("Trois contrats à la fois, pas plus : c'est le règlement (et Églantine le connaît par cœur).", 5.0)
		open_board()
		return
	var c: Array = _contract(cid)
	if c.is_empty():
		_close_board()
		return
	acc[cid] = _kills(str(c[3])) if str(c[2]) == "chasse" else 0
	(state["tableau"] as Array).erase(cid)
	mj.sfx("guilde_tampon", main._player_pos_v27())
	main._show_message_v28("Contrat accepté : " + str(c[7]))
	open_board()


func _close_board() -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()


# =================================================================== la boule de cristal

func _crystal() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(state["mesures"])) + _today()
	state["mesures"] = int(state["mesures"]) + 1
	mj.sfx("cristal_mesure", mj.city.lieux.guild_crystal)
	var a: Array = APTITUDES.duplicate()
	var lines: Array = []
	for i in range(3):
		var k: int = r.randi() % a.size()
		lines.append("%s : %s" % [a[k], NOTES[r.randi() % NOTES.size()]])
		a.remove_at(k)
	mj.say("La boule de cristal s'illumine, ronronne, réfléchit… « %s. » %s" % [" ; ".join(lines), CONCLUSIONS[r.randi() % CONCLUSIONS.size()]], 9.0)


# =================================================================== les services (Églantine, les compagnons)

func register_services(journal: Node) -> void:
	journal.lieux["guilde_tableau"] = mj.city.lieux.guild_board
	journal.lieux["guilde_cristal"] = mj.city.lieux.guild_crystal
	_wrap(journal, "eglantine", Callable(self, "_egl_topics"), Callable(self, "_egl_choose"))
	for id in COMPAGNONS:
		_wrap(journal, str(id), Callable(self, "_comp_topics"), Callable(self, "_comp_choose"))


## Notre service s'ajoute à celui qui existe déjà (comme objets_v66._wrap).
func _wrap(journal: Node, pid: String, topics: Callable, choose: Callable) -> void:
	var prev: Variant = journal.services.get(pid, null)
	journal.add_service(pid, Callable(self, "_wrapped_topics").bind(topics, prev), Callable(self, "_wrapped_choose").bind(choose, prev))


func _wrapped_topics(npc: Node, topics: Callable, prev: Variant) -> Array:
	var out: Array = topics.call(npc)
	if prev != null:
		out += (prev[0] as Callable).call(npc)
	return out


func _wrapped_choose(npc: Node, choice: String, choose: Callable, prev: Variant) -> Dictionary:
	if choice.begins_with("q56:service:mj71_"):
		return choose.call(npc, choice)
	if prev != null:
		return (prev[1] as Callable).call(npc, choice)
	return {}


func _egl_topics(_npc: Node) -> Array:
	var out: Array = []
	if not inscrit():
		return out
	for id in state["acceptes"]:
		var c: Array = _contract(str(id))
		if c.is_empty():
			continue
		var pg: Array = progress(str(id))
		if int(pg[0]) >= int(pg[1]):
			out.append({"id": "q56:service:mj71_rendre_" + str(id), "label": "★ Rendre le contrat : " + str(c[7])})
	if not (state["acceptes"] as Dictionary).is_empty():
		out.append({"id": "q56:service:mj71_contrats", "label": "✎ Où en sont mes contrats ?"})
	out.append({"id": "q56:service:mj71_rang", "label": "✎ Mon rang à la Guilde"})
	if mj.compagnons != null:
		for cid in mj.compagnons.active_ids():
			if COMPAGNONS.has(str(cid)):
				out.append({"id": "q56:service:mj71_repos_" + str(cid), "label": "☾ Envoyer %s se reposer à la Guilde" % str(COMPAGNONS[str(cid)][1])})
	return out


func _egl_choose(_npc: Node, choice: String) -> Dictionary:
	var key: String = choice.trim_prefix("q56:service:mj71_")
	if key.begins_with("rendre_"):
		return _turn_in(key.trim_prefix("rendre_"))
	if key == "contrats":
		var parts: Array = []
		for id in state["acceptes"]:
			var c: Array = _contract(str(id))
			if c.is_empty():
				continue
			var pg: Array = progress(str(id))
			parts.append("« %s » : %d sur %d" % [str(c[7]), int(pg[0]), int(pg[1])])
		return {"texte": "Je regarde vos fiches… " + " ; ".join(parts) + ". Tout est noté. Clac attend son tour.", "geste": "parle"}
	if key == "rang":
		var nxt: String = ("encore %d points pour le rang %s" % [SEUILS[int(state["rang"]) + 1] - int(state["points"]), RANGS[int(state["rang"]) + 1]]) if int(state["rang"]) + 1 < SEUILS.size() else "plus rien au-dessus : vous êtes une légende"
		return {"texte": "Rang %s, %d points de guilde : %s. Contrats rendus : %d. Et votre carte est impeccablement tamponnée." % [rang(), int(state["points"]), nxt, int(state["rendus"])], "geste": "parle"}
	if key.begins_with("repos_"):
		var cid: String = key.trim_prefix("repos_")
		if mj.compagnons != null:
			mj.compagnons.dismiss(cid)
		return {"texte": "Je note : « %s, repos à la Guilde ». Une tasse de tisane l'attend à la table du fond. Vous pourrez revenir la chercher quand vous voudrez." % str(COMPAGNONS.get(cid, ["", cid])[1]), "geste": "salut"}
	return {}


func _turn_in(id: String) -> Dictionary:
	var c: Array = _contract(id)
	if c.is_empty() or not (state["acceptes"] as Dictionary).has(id):
		return {}
	var pg: Array = progress(id)
	if int(pg[0]) < int(pg[1]):
		return {"texte": "Pas encore tout à fait : %d sur %d. La fiche est patiente. Moi aussi. Presque." % [int(pg[0]), int(pg[1])], "geste": "parle"}
	(state["acceptes"] as Dictionary).erase(id)
	state["rendus"] = int(state["rendus"]) + 1
	var r := {"texte": "Contrat rempli ! (CLAC ! fait le tampon.) Voici votre récompense : %d pièces. Et %d points de guilde, notés dans la marge. La Guilde vous remercie ; les habitants aussi ; Clac aussi." % [int(c[5]), int(c[6])],
		"geste": "salut", "donner": [["piece", int(c[5])]]}
	if str(c[2]) == "objets":
		r["prendre"] = [[str(c[3]), int(c[4])]]
	mj.sfx("guilde_tampon", mj.city.lieux.guild_counter)
	# les points après la réplique (la montée de rang se crie sur la place)
	var pts: int = int(c[6])
	get_tree().create_timer(0.6).timeout.connect(func(): add_points(pts, "contrat"))
	return r


func _comp_topics(npc: Node) -> Array:
	var id: String = str(npc.profile.get("id", ""))
	if not COMPAGNONS.has(id) or mj.compagnons == null:
		return []
	var j: Node = main.get("journal_v56")
	if j == null or str(j.state(str(COMPAGNONS[id][0]))) != "finie":
		return []
	if mj.compagnons.is_active(id):
		return []
	return [{"id": "q56:service:mj71_viens", "label": "★ Viens avec moi !"}]


func _comp_choose(npc: Node, _choice: String) -> Dictionary:
	var id: String = str(npc.profile.get("id", ""))
	if not inscrit():
		return {"texte": "Je ne pars qu'avec un aventurier inscrit à la Guilde. C'est le règlement ! (Églantine me l'a fait signer. Deux fois.)", "geste": "parle"}
	if mj.compagnons.active_ids().size() >= 3:
		return {"texte": "Trois compagnons, c'est déjà une petite foule ! Il faudra en renvoyer un se reposer à la Guilde d'abord.", "geste": "parle"}
	var lines := {"petronille": "Avec joie ! Que l'Aube nous garde… et qu'elle garde aussi mes pieds, je trébuche souvent. En route !",
		"violette": "Enfin quelqu'un qui reconnaît le génie ! Je viens. Restez derrière moi quand je lance un éclair. Ou devant. Enfin, pas trop près.",
		"tancrede": "Moi, Sire Tancrède de Tournevent, je vous suis ! Non, je vous précède ! Non, je marche à côté ! En avant !"}
	mj.compagnons.recruit(id)
	return {"texte": str(lines.get(id, "En route !")), "geste": "salut", "fin": true}


# =================================================================== les invites, le temps qui passe

func register_interactions(d: Node) -> void:
	var me = self
	var l = mj.city.lieux
	_board_ia = {"id": "mj_tableau", "pos": l.guild_board, "radius": 2.0, "text": "E : consulter le Tableau des Quêtes", "vr": "Gâchette : consulter le Tableau des Quêtes",
		"call": func(): me.open_board(), "when": func(): return true}
	mj._ia(d, _board_ia)
	mj._ia(d, {"id": "mj_cristal", "pos": l.guild_crystal, "radius": 1.6, "text": "E : poser la main sur la boule de cristal", "vr": "Gâchette : toucher la boule de cristal",
		"call": func(): me._crystal(), "when": func(): return true})
	_ally_ia = {"id": "mj_compagnon", "pos": Vector3(0, -9999, 0), "radius": 1.3, "text": "E : dire à votre compagnon d'aller se reposer à la Guilde",
		"vr": "Gâchette : renvoyer votre compagnon se reposer", "call": func(): me._dismiss_near(), "when": func(): return me._near_ally() != ""}
	mj._ia(d, _ally_ia)


func _near_ally() -> String:
	if mj.compagnons == null or main == null or main.get("donjon_v35") == null:
		return ""
	return str(mj.compagnons.nearest_ally(1.3))


func _dismiss_near() -> void:
	var id: String = _near_ally()
	if id == "":
		return
	mj.compagnons.dismiss(id)
	mj.say("%s rentre se reposer à la Guilde. (Églantine lui gardera une tasse de tisane.)" % str(COMPAGNONS.get(id, ["", id])[1]), 4.0)


func on_camp_cleared() -> void:
	pass


## Les quêtes de Montjoie achevées rapportent des points de guilde (une fois chacune).
func _check_quests() -> void:
	var j: Node = main.get("journal_v56")
	if j == null or not inscrit():
		return
	var paid: Dictionary = state["quetes_payees"]
	for q in POINTS_QUETES:
		if not paid.has(q) and str(j.state(str(q))) == "finie":
			paid[q] = true
			if int(POINTS_QUETES[q]) > 0:
				add_points(int(POINTS_QUETES[q]), "quête")


func after_reply(_r: Dictionary, _npc: Node) -> void:
	_check_quests()


func _process(delta: float) -> void:
	if main == null or mj == null:
		return
	# l'invite « renvoyer le compagnon » suit le compagnon le plus proche
	if not _ally_ia.is_empty() and mj.compagnons != null:
		var id: String = _near_ally()
		var a: Node3D = mj.compagnons.get_ally(id) if id != "" else null
		_ally_ia["pos"] = a.global_position if a != null else Vector3(0, -9999, 0)
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = 3.0
		_check_quests()

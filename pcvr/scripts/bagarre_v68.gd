extends Node
## V68 : une bagarre à Port-Coutelas. Un mot de travers, une partie de dés qui tourne mal, un
## coup de poing : c'est parti.
##  - celui qui se fâche attaque ; ses compagnons d'équipage tout proches s'en mêlent (pas dans un
##    duel « à la loyale ») ; deux au plus frappent en même temps, les autres tournent autour ;
##  - un ami du joueur (quelqu'un qui l'aime bien, d'un autre équipage) peut venir l'aider ;
##  - dans une taverne, ça dégénère : des pirates de deux équipages rivaux en profitent pour
##    régler leurs comptes entre eux ;
##  - les autres regardent, acclament, crient des encouragements (et des insultes) ;
##  - aux poings : sortir une lame, c'est tricher (les autres cognent plus fort, et une victoire
##    à la lame ne compte pas pour le titre de Roi de la Bagarre) ; le poing de fer de Brutus
##    rend les coups de poing plus lourds ;
##  - on gagne quand tous les attaquants sont au tapis (on ramasse quelques pièces tombées de
##    leurs poches) ; on perd si l'on tombe soi-même (on se réveille sur le quai, la bourse plus
##    légère) ; on peut aussi s'enfuir (loin, longtemps) : ils s'en souviendront.
## Personne ne meurt : on se relève, on se frotte la mâchoire, et on en reparle au comptoir.

const FLEE_DIST: float = 26.0
const FLEE_TIME: float = 2.5
const JOIN_DIST: float = 16.0
const WATCH_DIST: float = 22.0
const MAX_ATTACK: int = 2

var mgr: Node                      # pirates_v68.gd
var main: Node
var active: bool = false
var leader: Node3D
var motif: String = ""
var loyal: bool = false
var lame: bool = false
var attackers: Array = []          # contre le joueur
var allies: Array = []             # avec le joueur
var brawlers: Array = []           # la mêlée entre équipages rivaux
var spectators: Array = []
var down: Array = []               # mis au tapis par le joueur pendant cette bagarre
var coins: int = 0
var center: Vector3 = Vector3.ZERO
var result: String = ""            # le dernier résultat (pour les tests) : victoire, defaite, fuite
var _flee_t: float = 0.0
var _shout_t: float = 0.0
var _crowd_t: float = 0.0
var _t: float = 0.0
var _rng := RandomNumberGenerator.new()

const SHOUTS := ["Bagarre ! BAGARRE !", "Cogne-le !", "Vas-y, mets-lui en une !", "Dans les dents !", "Pas dans les verres !",
	"Hé, ma chope !", "Ha ha ! Joli coup !", "Relève-toi, mauviette !", "Deux pièces sur le terrien !", "Cinq pièces sur le pirate !",
	"Ouh, ça a dû faire mal !", "Plus fort !", "Allez, allez !", "Je parie ma jambe de bois… euh, non."]
const SHOUTS_PORT := ["Pas devant mon étal !", "Pas sur mes perroquets !", "Le Gouverneur interdit les bagarres ! … le dimanche.", "Doc ! Prépare ton fil !"]


func setup(m: Node, main_node: Node) -> void:
	mgr = m
	main = main_node
	_rng.seed = 6868


func fighters() -> Array:
	return attackers + allies + brawlers


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


## Un habitant libre de se joindre (visible, debout, pas en train de parler ou de se battre).
func _free(n: Node) -> bool:
	return is_instance_valid(n) and not bool(n.hidden_home) and float(n.ko_left) <= 0.0 and str(n.get("_ko_phase")) == "" \
		and (n.fight as Dictionary).is_empty() and str(n.state) != "parle" and n.visible


func _crew(n: Node) -> String:
	return str(n.brain.pir().get("equipage", "port"))


## Une bagarre commence (ou celui-ci rejoint celle qui a lieu).
func start(npc: Node3D, why: String, fair: bool) -> void:
	if active:
		if npc.brain.can_fight() and not attackers.has(npc):
			_unwatch(npc)
			allies.erase(npc)
			brawlers.erase(npc)
			attackers.append(npc)
			npc.start_fight("attaquant", null, self)
		return
	active = true
	result = ""
	leader = npc
	motif = why
	loyal = fair
	lame = false
	attackers.clear()
	allies.clear()
	brawlers.clear()
	spectators.clear()
	down.clear()
	coins = 0
	_flee_t = 0.0
	_t = 0.0
	_shout_t = 1.2
	_crowd_t = 0.0
	center = npc.global_position
	var near: Array = []
	for n in mgr.habitants:
		if n != npc and _free(n) and n.global_position.distance_to(center) < WATCH_DIST and absf(n.global_position.y - center.y) < 4.0:
			near.append(n)
	near.sort_custom(func(a, b): return a.global_position.distance_to(center) < b.global_position.distance_to(center))
	if npc.brain.can_fight():
		attackers.append(npc)
		npc.start_fight("attaquant", null, self)
	else:
		# un pacifique qu'on frappe appelle à l'aide : les plus costauds autour s'en chargent
		npc.say_bubble(["À l'aide ! On m'attaque !", "Au secours ! Brutus ! Quelqu'un !", "Il m'a frappé ! Vous avez vu ?!"][_rng.randi() % 3], 3.5)
		loyal = false
	var crew: String = _crew(npc)
	if not loyal:
		for n2 in near:
			if attackers.size() >= 3:
				break
			if not n2.brain.can_fight() or n2.global_position.distance_to(center) > JOIN_DIST:
				continue
			var same: bool = crew != "port" and _crew(n2) == crew
			var defend: bool = not npc.brain.can_fight() and attackers.size() < 2
			if (same and _rng.randf() < 0.8) or defend:
				attackers.append(n2)
				n2.start_fight("attaquant", null, self)
				n2.say_bubble(["On touche pas à un gars du %s !" % _ship_name(crew), "Je m'en mêle !", "Attends, j'arrive !", "À moi !"][_rng.randi() % 4] if same else "Laisse-le tranquille !", 2.5)
		# un ami du joueur, d'un autre équipage, vient l'aider
		for n3 in near:
			if allies.size() >= 1 or attackers.has(n3):
				continue
			if n3.brain.can_fight() and _crew(n3) != crew and float(n3.brain.affinite) >= 55.0 and n3.global_position.distance_to(center) < JOIN_DIST and not attackers.is_empty():
				allies.append(n3)
				n3.start_fight("allie", _nearest_attacker(n3), self)
				n3.say_bubble("Tiens bon, %s, j'arrive !" % str(n3.brain.surnom()), 2.5)
		# dans une taverne (ou s'il y a du monde), ça dégénère : deux équipages règlent leurs comptes
		var crowded: bool = mgr.inside_tavern(center) or near.size() >= 6
		if crowded and _rng.randf() < 0.75:
			var pool: Array = near.filter(func(n4): return not attackers.has(n4) and not allies.has(n4) and n4.brain.can_fight() and _crew(n4) != "port")
			var pairs: int = 0
			for a in pool:
				if pairs >= 2 or brawlers.has(a):
					continue
				for b in pool:
					if b == a or brawlers.has(b) or _crew(b) == _crew(a):
						continue
					if a.global_position.distance_to(b.global_position) > 9.0:
						continue
					brawlers.append(a)
					brawlers.append(b)
					a.start_fight("melee", b, self)
					b.start_fight("melee", a, self)
					a.say_bubble(["Et toi, tu rigoles ?!", "Toi, ça fait longtemps que je voulais te le dire !", "Le %s, c'est un rafiot !" % _ship_name(_crew(b))][_rng.randi() % 3], 2.5)
					pairs += 1
					break
	# personne pour se battre (un pacifique seul, sans personne autour) : pas de bagarre
	if attackers.is_empty():
		active = false
		result = "personne"
		for x in allies + brawlers:
			if is_instance_valid(x):
				x.stop_fight()
		allies.clear()
		brawlers.clear()
		return
	# les autres regardent
	for n5 in near:
		if attackers.has(n5) or allies.has(n5) or brawlers.has(n5):
			continue
		spectators.append(n5)
		n5.watch(center, 9999.0)
	if main.has_method("sfx"):
		main.sfx("foule_bagarre", center + Vector3.UP * 1.5)
	if loyal:
		main._show_message_v28("Duel à la loyale ! Aux poings, et personne ne s'en mêle. (F : garde · Ctrl : roulade)")
	else:
		main._show_message_v28("BAGARRE ! %s" % ("(F : garde · Ctrl : roulade · éloigne-toi pour fuir)" if not main.xr_active else "(lève les poings !)"))


func _ship_name(crew: String) -> String:
	return {"requin": "Requin Borgne", "veuve": "Veuve Écarlate", "morue": "Morue Enragée"}.get(crew, "port")


func _nearest_attacker(from: Node3D) -> Node3D:
	var best: Node3D = null
	var bd: float = INF
	for a in attackers:
		if is_instance_valid(a) and not (a.fight as Dictionary).is_empty():
			var d: float = from.global_position.distance_to(a.global_position)
			if d < bd:
				bd = d
				best = a
	return best


## Seuls les deux attaquants les plus proches frappent en même temps ; les autres tournent autour.
func can_attack(npc: Node) -> bool:
	var role: String = str((npc.fight as Dictionary).get("role", ""))
	if role != "attaquant":
		return true
	var p: Vector3 = main._player_pos_v27()
	var order: Array = attackers.filter(func(a): return is_instance_valid(a) and not (a.fight as Dictionary).is_empty())
	order.sort_custom(func(a, b): return a.global_position.distance_to(p) < b.global_position.distance_to(p))
	var i: int = order.find(npc)
	return i >= 0 and i < MAX_ATTACK


## Sa cible est tombée : une autre, ou il s'arrête (et regarde la suite).
func retarget(npc: Node) -> void:
	var role: String = str((npc.fight as Dictionary).get("role", ""))
	if role == "allie":
		var t: Node3D = _nearest_attacker(npc)
		if t != null:
			npc.fight["target"] = t
			return
		allies.erase(npc)
	elif role == "melee":
		brawlers.erase(npc)
		npc.say_bubble(["Et voilà ! Qui d'autre ?", "Ha ! Au tapis !", "Ça t'apprendra !"][_rng.randi() % 3], 2.5)
	else:
		attackers.erase(npc)
	npc.stop_fight()
	if active:
		spectators.append(npc)
		npc.watch(center, 9999.0)


## Le joueur a frappé un allié ou un bagarreur de la mêlée : il se retourne contre lui.
func turn_on_player(npc: Node) -> void:
	allies.erase(npc)
	brawlers.erase(npc)
	if not attackers.has(npc):
		attackers.append(npc)
	npc.say_bubble("Hé ! Je suis de ton côté, imbécile ! … Plus maintenant !", 2.8)


## Les dégâts d'un coup du joueur, aux poings (le poing de fer) ou… avec une lame.
func player_damage(raw: int) -> int:
	var inv: Node = main.get("inventory_v28")
	var eq: String = str(inv.equipped) if inv != null else ""
	if eq == "":
		return raw + (1 if inv != null and inv.count("poing_fer") > 0 else 0)
	var kind: String = str(inv.ITEMS.get(eq, {}).get("kind", ""))
	if kind == "arme" and not lame:
		lame = true
		main._show_message_v28("Une lame dans une bagarre aux poings ?! Les pirates sont furieux : ils cognent plus fort.")
		for a in attackers:
			if is_instance_valid(a):
				a.say_bubble(["Il sort une lame ! Le lâche !", "Une lame ?! Tricheur !", "Range ça, ou je te le fais avaler !"][_rng.randi() % 3], 2.5)
				break
	return mini(raw, 4)


## Quelqu'un est au tapis.
func on_ko(npc: Node, by_player: bool) -> void:
	var now: float = _now()
	var role: String = "attaquant" if attackers.has(npc) else ("allie" if allies.has(npc) else "melee")
	attackers.erase(npc)
	allies.erase(npc)
	brawlers.erase(npc)
	if role == "attaquant":
		npc.brain.after_fight("perdue", now)
		if by_player:
			down.append(npc)
			var costaud: bool = bool(npc.brain.pir().get("costaud", false))
			coins += _rng.randi_range(4, 8) if costaud else _rng.randi_range(2, 5)
			mgr.on_npc_down(npc, loyal and not lame)
	elif role == "allie":
		npc.brain.after_fight("perdue", now)
	# la foule réagit
	if main.has_method("sfx"):
		main.sfx("foule_bagarre", npc.global_position + Vector3.UP * 1.5)
	var sp: Array = spectators.filter(func(s): return is_instance_valid(s))
	if not sp.is_empty():
		var who: Node = sp[_rng.randi() % sp.size()]
		who.say_bubble(["OUAIIIS !", "Au tapis !", "Ha ! Il a son compte !", "Quelqu'un appelle le Doc !", "Il ne s'est pas vu tomber !"][_rng.randi() % 5], 2.2)


func _process(delta: float) -> void:
	if not active or main == null:
		return
	_t += delta
	var p: Vector3 = main._player_pos_v27()
	attackers = attackers.filter(func(a): return is_instance_valid(a) and not (a.fight as Dictionary).is_empty())
	allies = allies.filter(func(a): return is_instance_valid(a) and not (a.fight as Dictionary).is_empty())
	brawlers = brawlers.filter(func(a): return is_instance_valid(a) and not (a.fight as Dictionary).is_empty())
	center = center.lerp(p, clampf(delta * 2.0, 0.0, 1.0))
	for s in spectators:
		if is_instance_valid(s):
			s.set("_watch_center", center)
	if attackers.is_empty():
		end("victoire")
		return
	# s'enfuir : loin de tous les attaquants, assez longtemps (ou quitter l'île, ou monter en barque)
	var nearest: float = INF
	for a in attackers:
		nearest = minf(nearest, (a as Node3D).global_position.distance_to(p))
	var gone: bool = not mgr.contains(p) or (main.get("boat_v29") != null and main.boat_v29 != null and bool(main.boat_v29.driving))
	if nearest > FLEE_DIST or gone:
		_flee_t += delta
		if _flee_t > FLEE_TIME or gone:
			end("fuite")
			return
	else:
		_flee_t = 0.0
	# les cris de la foule
	_shout_t -= delta
	if _shout_t <= 0.0:
		_shout_t = _rng.randf_range(2.0, 4.0)
		var sp: Array = spectators.filter(func(s): return is_instance_valid(s) and s.global_position.distance_to(p) < 30.0)
		if not sp.is_empty():
			var who: Node = sp[_rng.randi() % sp.size()]
			var pool: Array = SHOUTS + (SHOUTS_PORT if _crew(who) == "port" else [])
			var line: String = str(pool[_rng.randi() % pool.size()])
			if _rng.randf() < 0.3 and not attackers.is_empty():
				line = "Allez, %s !" % str(attackers[0].display_name).split(" ")[0]
			who.say_bubble(line, 2.0)
	_crowd_t -= delta
	if _crowd_t <= 0.0:
		_crowd_t = _rng.randf_range(5.0, 8.0)
		if main.has_method("sfx") and not spectators.is_empty():
			main.sfx("foule_bagarre", center + Vector3.UP * 1.5)


## La bagarre est finie : victoire (tous au tapis), defaite (le joueur est tombé), fuite.
func end(res: String) -> void:
	if not active:
		return
	active = false
	result = res
	var now: float = _now()
	var standing: Array = attackers.duplicate()
	match res:
		"victoire":
			if coins > 0:
				main.inventory_v28.add("piece", coins)
			main._show_message_v28("Tu as gagné la bagarre !%s" % ("  (+%d pièces ramassées par terre)" % coins if coins > 0 else ""))
			if main.has_method("jingle"):
				main.jingle("victoire")
			mgr.on_brawl_won(down, loyal and not lame, motif, leader)
		"defaite":
			for a in standing:
				a.brain.after_fight("gagnee", now)
				a.say_bubble(["Et reste par terre !", "Ha ! Qui c'est le patron ?", "Allez, quelqu'un le ramène sur le quai.", "La prochaine fois, tu tiendras ta langue."][_rng.randi() % 4], 3.0)
		"fuite":
			for a2 in standing:
				a2.brain.after_fight("fuite", now)
				a2.say_bubble(["C'est ça, cours !", "Reviens, froussard !", "Ha ! Regardez-le filer !", "On se reverra, terrien !"][_rng.randi() % 4], 3.0)
			main._show_message_v28("Tu as pris la fuite… Ils s'en souviendront.")
			mgr.state["fuites"] = int(mgr.state.get("fuites", 0)) + 1
	for n in attackers + allies + brawlers:
		if is_instance_valid(n):
			n.stop_fight()
	for s in spectators:
		if is_instance_valid(s):
			s.stop_watch()
			if res == "victoire" and _rng.randf() < 0.35:
				s.say_bubble(["Bravo, terrien !", "Ha ! Quel spectacle !", "Tu me dois deux pièces, Tonneau !", "Tom va en faire une chanson !"][_rng.randi() % 4], 2.5)
	attackers.clear()
	allies.clear()
	brawlers.clear()
	spectators.clear()


func _unwatch(n: Node) -> void:
	spectators.erase(n)
	n.stop_watch()

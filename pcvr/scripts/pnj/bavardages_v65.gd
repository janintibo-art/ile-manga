extends Node
## V65 : quand deux habitants qui se connaissent se croisent près du joueur, ils s'arrêtent, se
## tournent l'un vers l'autre et échangent quelques mots (des bulles au-dessus de leur tête).
## Les répliques viennent de leurs fiches (societe_v65.gd, lien « bavardage ») : elles parlent de
## leur histoire commune. Une même paire ne rebavarde pas avant quelques minutes.

const Societe = preload("res://scripts/pnj/societe_v65.gd")
const PORTEE: float = 24.0          # autour du joueur (au-delà, on ne les entendrait pas)
const PROCHE: float = 5.0           # distance maximale entre les deux
const PAUSE_PAIRE: float = 240.0    # secondes avant qu'une même paire rebavarde

var main: Node
var busy: bool = false
var said: int = 0                   # nombre de bavardages joués (tests)
var _clock: float = 5.0
var _recent: Dictionary = {}        # "a|b" -> Time.get_ticks_msec() du dernier bavardage
var _rng := RandomNumberGenerator.new()


func setup(m: Node) -> void:
	main = m
	_rng.randomize()


func _process(delta: float) -> void:
	if main == null or busy or not bool(main.get("game_started")):
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = _rng.randf_range(6.0, 11.0)
	var pair: Array = find_pair()
	if not pair.is_empty():
		play(pair[0], pair[1])


static func _num(n: Object, prop: String) -> float:
	var v: Variant = n.get(prop)
	return float(v) if v is float or v is int else 0.0


static func _flag(n: Object, prop: String) -> bool:
	var v: Variant = n.get(prop)
	return v is bool and v


## Libre de bavarder : au repos, visible, pas déjà en train de parler ou de courir.
func _free(n: Variant) -> bool:
	if not is_instance_valid(n) or not (n is Node3D) or not (n as Node3D).is_visible_in_tree():
		return false
	if str(n.get("state")) != "repos" or n.get("brain") == null:
		return false
	if _num(n, "bubble_clock") > 0.0 or _num(n, "chat_hold") > 0.0:
		return false
	if _flag(n, "hidden_home") or _flag(n, "racing"):
		return false
	var run: Variant = n.get("_run_loop")
	if run is Array and not (run as Array).is_empty():
		return false
	return true


func _id(n: Node) -> String:
	var p: Variant = n.get("profile")
	return str((p as Dictionary).get("id", "")) if p is Dictionary else ""


## Deux habitants proches du joueur, proches l'un de l'autre, qui se connaissent.
func find_pair() -> Array:
	var p: Vector3 = main._player_pos_v27()
	var near: Array = []
	for n in main.npcs_v31:
		if _free(n) and (n as Node3D).global_position.distance_to(p) < PORTEE:
			near.append(n)
	near.shuffle()
	var now: int = Time.get_ticks_msec()
	for a in near:
		var ida: String = _id(a)
		var la: Dictionary = Societe.fiche(ida).get("liens", {})
		if la.is_empty():
			continue
		for b in near:
			if a == b:
				continue
			var idb: String = _id(b)
			if not la.has(idb) or ((la[idb] as Dictionary).get("bavardage", []) as Array).is_empty():
				continue
			if (a as Node3D).global_position.distance_to((b as Node3D).global_position) > PROCHE:
				continue
			if absf((a as Node3D).global_position.y - (b as Node3D).global_position.y) > 2.0:
				continue
			if now - int(_recent.get(_key(ida, idb), -10000000)) < int(PAUSE_PAIRE * 1000.0):
				continue
			return [a, b]
	return []


static func _key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


## Joue l'échange : l'un des deux bavardages de la paire (celui de A, ou celui de B s'il le connaît
## aussi), réplique après réplique.
func play(a: Node3D, b: Node3D) -> void:
	var ida: String = _id(a)
	var idb: String = _id(b)
	var lines: Array = (Societe.lien(ida, idb).get("bavardage", []) as Array)
	var other: Array = (Societe.lien(idb, ida).get("bavardage", []) as Array)
	if not other.is_empty() and (lines.is_empty() or _rng.randf() < 0.5):
		lines = other
		var t: Node3D = a
		a = b
		b = t
	if lines.is_empty():
		return
	busy = true
	said += 1
	_recent[_key(ida, idb)] = Time.get_ticks_msec()
	var total: float = 1.0
	for l in lines:
		total += _secs(str(l[1]))
	for n in [a, b]:
		if n.has_method("chat_with"):
			n.chat_with(b if n == a else a, total + 1.5)
	await get_tree().create_timer(0.6).timeout
	for l in lines:
		var who: Node3D = a if str(l[0]) == "a" else b
		if not is_instance_valid(who) or str(who.get("state")) == "parle":
			break
		var secs: float = _secs(str(l[1]))
		if who.has_method("chat_say"):
			who.chat_say(str(l[1]), secs)
		elif who.has_method("say_bubble"):
			who.say_bubble(str(l[1]), secs)
		await get_tree().create_timer(secs - 0.3).timeout
	busy = false


static func _secs(text: String) -> float:
	return clampf(1.8 + text.length() * 0.055, 2.6, 6.5)

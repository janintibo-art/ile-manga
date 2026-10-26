extends Node
## V75 : la vie de Port-Boucan (l'Île du Boucan).
##  - LES CONCERTS du soir (21 h – 23 h 30) à la Halle Hurlante : les Rats de Cale jouent, les
##    projecteurs tournent, la foule danse le pogo ; le joueur aussi (E dans la fosse : on saute avec
##    la foule) ; un batteur de remplacement différent chaque soir (une catastrophe différente
##    chaque soir) ; le GRAND BOUCAN (la quête bo_concert) ; GÉDÉON, enfin, à la batterie
##    (bo_gedeon) : ensuite, c'est lui, tous les soirs ;
##  - LA DESCENTE DES DÉMÉNAGEURS : le jour, en ville, de temps en temps, la sirène, le Sergent qui
##    crie à la radio ; six robots sortent d'un squat avec les meubles dans les bras et filent vers
##    les quais ; on les arrête avant qu'ils n'arrivent (bo_robots) ; les habitants font la chaîne ;
##  - LE MUR D'EXPRESSION (et les autres murs peignables) : avec une bombe de peinture, on choisit
##    un graffiti ; il reste peint (sauvegardé) ; trois graffitis pour bo_mur ;
##  - LA GRATUITERIE (on dépose un objet ; on en prend un par jour) et LA CANTINE À PRIX LIBRE (un
##    bol de soupe par jour, on paie ce qu'on veut, même rien) ;
##  - RADIO BOUCAN : une fois l'antenne remontée (bo_radio), le Sergent parle dans les haut-parleurs
##    de la ville ;
##  - SARDINE : le chien de Tornade attend à la Casse (bo_sardine) ; trouvé, il suit le joueur ;
##  - MONSIEUR LISSE fait l'article devant son bureau de vente ; et il change de ton, après.

const RB = preload("res://scripts/ile_boucan_v75.gd")
const Mats = preload("res://scripts/boucan_mats_v75.gd")
const TEXTES := "res://scripts/pnj/boucan_textes_v75.gd"
const ANIMAUX := "res://scripts/animaux_v75.gd"
const RAID_TIME: float = 150.0
const RAID_ROBOTS: int = 6
## Les graffitis qu'on sait peindre (les numéros des textures graffiti_N).
const GRAFFITIS := [[1, "« BOUCAN »"], [2, "« LIBRE »"], [3, "« DIY »"], [4, "« ENTRAIDE »"], [5, "« RATS DE CALE »"], [6, "« PORT-BOUCAN »"],
	[7, "une sardine qui sourit"], [8, "un champignon féerique"], [9, "une étoile"], [10, "un cœur"], [11, "un rat à crête"], [12, "une mouette à bandana"]]
## Ce que la Gratuiterie a sur sa table (on en prend un par jour).
const DONS := ["fanzine", "limonade_boucan", "sirop_menthe", "boulon", "ressort", "bombe_peinture", "os_sardine", "soupe_prix_libre"]

var main: Node
var bo: Node                              # boucan_v75
var T                                     # les textes (boucan_textes_v75), s'ils sont là
var state := {}
var raid_on: bool = false
var _raid_left: float = 0.0
var _raid_wait: float = 420.0
var _raid_robots: Array = []
var _raid_arrived: int = 0
var _raid_killed: int = 0
var _raid_at := Vector3.ZERO
var _raid_talk: float = 0.0
var _tick_t: float = 0.0
var _concert_was: bool = false
var _concert_said: bool = false
var _foule_t: float = 0.0
var _pogo_left: float = 0.0
var _pogo_hop: float = 0.0
var _radio_t: float = 120.0
var _lisse_t: float = 0.0
var _light_t: float = 0.0
var _wash: Array = []
var _paint_root: Node3D
var _painted: Dictionary = {}             # clé -> MeshInstance3D
var _walls: Array = []                    # [clé, Transform3D, w, h]
var _paint_key: String = ""
var _dog: Node3D                          # Sardine, qui attend à la Casse
var _dog_clock: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	bo = manager
	_rng.randomize()
	state = _fresh()
	_raid_wait = _rng.randf_range(360.0, 600.0)
	if ResourceLoader.exists(TEXTES):
		T = load(TEXTES)
	_paint_root = Node3D.new()
	_paint_root.name = "Graffitis_v75"
	bo.add_child(_paint_root)
	_collect_walls()


func _fresh() -> Dictionary:
	return {"concerts": 0, "pogo": 0, "grand_boucan": false, "gedeon": false, "descentes": 0, "descente_ok": false, "robots_arretes": 0,
		"graffitis": {}, "dons": 0, "pris_jour": -1, "soupe_jour": -1, "soupes": 0, "donne_pieces": 0, "sardine": false, "lisse_vaincu_dit": false}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh()
	for k in state:
		if d.has(k):
			state[k] = d[k]
	if typeof(state["graffitis"]) != TYPE_DICTIONARY:
		state["graffitis"] = {}
	_end_raid(true)
	_pogo_left = 0.0
	_apply_paint()


func trouvailles() -> Dictionary:
	return {"boucan_concert": 1 if int(state["pogo"]) > 0 else 0, "grand_boucan": 1 if bool(state["grand_boucan"]) else 0,
		"gedeon_batteur": 1 if bool(state["gedeon"]) else 0, "descente_repoussee": 1 if bool(state["descente_ok"]) else 0,
		"graffitis_3": 1 if (state["graffitis"] as Dictionary).size() >= 3 else 0, "graffitis": (state["graffitis"] as Dictionary).size(),
		"sardine_trouvee": 1 if bool(state["sardine"]) else 0, "concerts": int(state["concerts"]), "robots_arretes": int(state["robots_arretes"])}


func _line(group: String, key: String = "") -> String:
	if T == null:
		return ""
	var src: Variant = (T.get_script_constant_map() as Dictionary).get(group, null)
	if key != "" and src is Dictionary:
		src = (src as Dictionary).get(key, null)
	if src is Array and not (src as Array).is_empty():
		return str(src[_rng.randi() % (src as Array).size()])
	return ""


func _say(group: String, key: String, fallback: String, seconds: float = 7.0) -> void:
	var t: String = _line(group, key)
	bo.say(t if t != "" else fallback, seconds)


func _quest(id: String) -> String:
	var j: Node = main.get("journal_v56") if main != null else null
	return str(j.state(id)) if j != null else ""


## La quête est-elle à l'étape « etat » de cette clé ?
func _at_step(qid: String, cle: String) -> bool:
	var j: Node = main.get("journal_v56") if main != null else null
	if j == null or _quest(qid) != "en_cours":
		return false
	var st: Dictionary = (j.states as Dictionary).get(qid, {})
	var q: Dictionary = j.quest(qid)
	var steps: Array = q.get("etapes", [])
	var i: int = int(st.get("etape", 0))
	return i >= 0 and i < steps.size() and str((steps[i] as Dictionary).get("cle", "")) == cle


func _day() -> int:
	var t: Node = main.get("temps_v56") if main != null else null
	return int(t.day_count) if t != null else 1


func _player() -> Vector3:
	return main._player_pos_v27()


# =================================================================== les concerts

func concert_on() -> bool:
	var h: float = bo.hour()
	return h >= 21.0 and h < 23.5


func in_halle(p: Vector3) -> bool:
	return bo.city != null and bo.city.zone_at(p) == "bo_halle"


func zone_override(p: Vector3) -> String:
	if raid_on and Vector2(p.x - _raid_at.x, p.z - _raid_at.z).length() < 90.0:
		return "bo_descente"
	if concert_on() and in_halle(p):
		if bool(state["gedeon"]):
			return "bo_concert_gedeon"
		return "bo_concert_%d" % (1 + posmod(_day(), 3))
	return ""


func _concert_tick(delta: float) -> void:
	var on: bool = concert_on()
	var p: Vector3 = _player()
	if on and not _concert_was:
		_concert_said = false
		state["concerts"] = int(state["concerts"]) + 1
	_concert_was = on
	_light_t -= delta
	if _light_t <= 0.0:
		_light_t = 0.1
		_stage_lights(on, p)
	if not on:
		return
	if not in_halle(p):
		return
	if not _concert_said:
		_concert_said = true
		bo.sfx("foule_acclame", bo.city.lieux.halle_scene)
		if bool(state["gedeon"]):
			_say("CONCERT", "gedeon", "Ce soir à la batterie : Gédéon Lisse ! Le roulement d'entrée fait trembler la verrière. Rouille hurle de joie.", 8.0)
		else:
			bo.say(_line("CONCERT", "annonce") + "  " + _sub_line(), 10.0)
		if _at_step("bo_concert", "grand_boucan"):
			bo.say("C'EST LE GRAND BOUCAN ! La Halle est pleine à craquer : Paulo et sa marmite, Ulric et ses grenouilles, Tom le Violoneux sur un tonneau… Rouille te montre la fosse du doigt : « Toi ! Dans la fosse ! MAINTENANT ! »", 10.0)
	_foule_t -= delta
	if _foule_t <= 0.0:
		_foule_t = _rng.randf_range(25.0, 45.0)
		var f: String = _line("CONCERT", "foule")
		if f != "":
			main._show_message_v28(f)
	_gedeon_tick()
	if not bool(state["gedeon"]):
		var sub: Node = bo.by_id.get(substitute(), null)
		if sub != null and is_instance_valid(sub):
			_force_drummer(sub)


## Le batteur de remplacement du soir (un autre chaque soir, jusqu'à Gédéon).
const SUBS := [["tapage", "Tapage"], ["boulon", "Boulon"], ["cradoc", "Cradoc"], ["fusible", "Fusible"], ["copeau", "Copeau"], ["larsen", "Larsen"]]

func substitute() -> String:
	return str(SUBS[posmod(_day(), SUBS.size())][0])


func _sub_line() -> String:
	var nom: String = str(SUBS[posmod(_day(), SUBS.size())][1])
	if T != null:
		var c: Dictionary = (T.get_script_constant_map() as Dictionary).get("CONCERT", {})
		var mine: Array = (c.get("remplacant", []) as Array).filter(func(x): return str(x).contains(nom))
		if not mine.is_empty():
			return str(mine[_rng.randi() % mine.size()])
	return "Ce soir à la batterie : %s ! On croise les doigts." % nom


## Les projecteurs tournent et changent de couleur pendant le concert ; la salle s'assombrit.
func _stage_lights(on: bool, p: Vector3) -> void:
	var l = bo.city.lieux if bo.city != null else null
	if l == null:
		return
	var near: bool = p.distance_to(l.halle_fosse) < 90.0
	var t: float = bo._clock
	var cols := [Color(1.0, 0.2, 0.3), Color(0.25, 0.5, 1.0), Color(0.3, 1.0, 0.4), Color(1.0, 0.8, 0.2), Color(0.9, 0.3, 1.0)]
	for i in range((l.stage_lights as Array).size()):
		var s: Light3D = l.stage_lights[i]
		if not is_instance_valid(s):
			continue
		s.visible = on and near
		if not s.visible:
			continue
		var beat: float = fmod(t * 2.2 + i * 0.37, 1.0)
		if i < 4:
			s.light_color = cols[(int(t * 0.5) + i) % cols.size()]
		if not s.has_meta("e0"):
			s.set_meta("e0", s.light_energy)
		s.light_energy = float(s.get_meta("e0")) * (0.7 + 0.6 * (1.0 - beat))
		if s.has_meta("base"):
			var b: Transform3D = s.get_meta("base")
			s.transform = b * Transform3D(Basis(Vector3.UP, sin(t * 0.9 + i) * 0.45) * Basis(Vector3.RIGHT, sin(t * 1.3 + i * 2.0) * 0.25), Vector3.ZERO)
		else:
			s.set_meta("base", s.transform)
	# la lumière de scène : un grand bain chaud sur les musiciens, un plus doux sur la fosse
	if _wash.is_empty() and on and near:
		for k in range(2):
			var w := OmniLight3D.new()
			w.light_color = [Color(1.0, 0.78, 0.55), Color(0.75, 0.55, 1.0)][k]
			w.light_energy = [2.6, 1.4][k]
			w.omni_range = [12.0, 16.0][k]
			w.shadow_enabled = false
			bo.add_child(w)
			w.global_position = (l.halle_scene + Vector3(0, 4.5, 0)) if k == 0 else (l.halle_fosse + Vector3(0, 6.0, 0))
			_wash.append(w)
	for w2 in _wash:
		(w2 as Light3D).visible = on and near
	for hl in l.halle_lights:
		if is_instance_valid(hl) and hl is Light3D:
			if not (hl as Light3D).has_meta("e0"):
				(hl as Light3D).set_meta("e0", (hl as Light3D).light_energy)
			(hl as Light3D).light_energy = float((hl as Light3D).get_meta("e0")) * (0.8 if on else 1.0)


func can_pogo() -> bool:
	return concert_on() and _pogo_left <= 0.0


## E dans la fosse : on saute avec la foule pendant quelques secondes.
func pogo() -> void:
	if not concert_on():
		bo.say("La fosse est vide. Un gobelet en plastique roule tout seul. Revenez ce soir, à partir de 21 heures : c'est là que ça se passe.", 5.0)
		return
	_pogo_left = 8.0
	_pogo_hop = 0.0
	state["pogo"] = int(state["pogo"]) + 1
	bo.sfx("pogo", _player())
	_say("CONCERT", "pogo", "Tu sautes avec la foule ! Boïng ! Boïng !", 5.0)
	if int(state["pogo"]) == 1 and main.has_method("jingle"):
		main.jingle("decouverte")
	if _at_step("bo_concert", "grand_boucan"):
		state["grand_boucan"] = true
		get_tree().create_timer(6.0).timeout.connect(func(): bo.say("Le Grand Boucan restera dans les mémoires : Mamie Barricade lève le poing sur la mezzanine, Clou sourit (si, si), et toute la fosse scande ton nom. Va voir Rouille, après !", 9.0))


var _was_air: bool = false

## Le pogo, c'est sauter : pendant le concert, un saut dans la fosse, et on part avec la foule.
func _pogo_watch() -> void:
	var h: Node = main.get("hero_v28")
	if h == null or h.get("body") == null or bo.city == null:
		return
	var air: bool = str(h.state) == "air" and (h.body as CharacterBody3D).velocity.y > 2.5
	if air and not _was_air and _pogo_left <= 0.0 and concert_on():
		var p: Vector3 = _player()
		if Vector2(p.x - bo.city.lieux.halle_fosse.x, p.z - bo.city.lieux.halle_fosse.z).length() < 7.0:
			pogo()
	_was_air = air


func _pogo_tick(delta: float) -> void:
	_pogo_watch()
	if _pogo_left <= 0.0:
		return
	_pogo_left -= delta
	_pogo_hop -= delta
	var h: Node = main.get("hero_v28")
	if h == null or h.get("body") == null or _pogo_hop > 0.0:
		return
	# on saute comme le héros saute (la touche de saut, enfoncée pour lui), en rythme
	if str(h.state) == "sol":
		_pogo_hop = 0.6
		h.jump_buffer = 0.16


## Gédéon à la batterie : la première fois (bo_gedeon), puis tous les soirs.
func _gedeon_tick() -> void:
	var g: Node = bo.by_id.get("gedeon", null)
	if g == null or not is_instance_valid(g):
		return
	if not bool(state["gedeon"]):
		if not _at_step("bo_gedeon", "gedeon_batteur"):
			return
		var e: Dictionary = bo.spot("halle_entree")
		var p: Vector3 = _player()
		if e.is_empty() or (p.distance_to(e["pos"]) > 8.0 and p.distance_to((g as Node3D).global_position) > 4.0):
			return
		state["gedeon"] = true
		bo.say("Gédéon respire un grand coup, traverse la fosse (la foule s'écarte, intriguée), monte sur scène, prend la place du remplaçant, et fait tourner ses baguettes. Un roulement. La Halle Hurlante se tait. Puis elle HURLE.", 10.0)
		get_tree().create_timer(10.0).timeout.connect(func(): _say("CONCERT", "gedeon", "Gédéon joue ! Et il joue JUSTE !", 8.0))
	_force_drummer(g)


func _force_drummer(g: Node) -> void:
	if str(g.get("target_spot")) == "halle_scene_batterie":
		return
	var sp: Dictionary = bo.spot("halle_scene_batterie")
	if sp.is_empty():
		return
	# le remplaçant descend danser dans la fosse
	for n in bo.habitants:
		if is_instance_valid(n) and n != g and str(n.get("target_spot")) == "halle_scene_batterie":
			n.call("_free_spot")
			for k in range(1, 13):
				if bo.spot_free("halle_fosse_%d" % k, n):
					n.set("target_spot", "halle_fosse_%d" % k)
					bo.claim_spot("halle_fosse_%d" % k, n)
					n.call("_jump_to", str(bo.spot("halle_fosse_%d" % k).get("node", "")))
					n.call("_arrive")
					break
	g.call("_free_spot")
	g.set("target_spot", "halle_scene_batterie")
	bo.claim_spot("halle_scene_batterie", g)
	g.call("_set_hidden", false)
	g.call("_jump_to", str(sp.get("node", "")))
	g.call("_arrive")


# =================================================================== la Descente des Déménageurs

func _raid_candidates() -> Array:
	var out: Array = []
	if bo.city == null:
		return out
	var quay: Vector3 = _quay()
	var p: Vector3 = _player()
	for hs in bo.city.houses:
		var d: Vector3 = hs.get("door", Vector3.ZERO)
		var dq: float = d.distance_to(quay)
		if dq > 45.0 and dq < 150.0 and d.distance_to(p) < 80.0:
			out.append(d)
	return out


func _quay() -> Vector3:
	var q: Dictionary = bo.spot("quai_2")
	if not q.is_empty():
		return q["pos"]
	var d: Array = bo.dock()
	return d[0]


func _start_raid() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null or raid_on:
		return
	var cands: Array = _raid_candidates()
	if cands.is_empty():
		_raid_wait = 120.0
		return
	var door: Vector3 = cands[_rng.randi() % cands.size()]
	raid_on = true
	_raid_left = RAID_TIME
	_raid_arrived = 0
	_raid_killed = 0
	_raid_at = door
	_raid_talk = 6.0
	state["descentes"] = int(state["descentes"]) + 1
	bo.sfx("sirene_alerte", door)
	bo.sfx("sirene_alerte", _player())
	_say("DESCENTE", "debut", "Pschhh… ALERTE ! ALERTE ! Ici Radio Boucan : les robots de Lisse débarquent ! Tout le monde dehors, on fait la chaîne !", 9.0)
	var quay: Vector3 = _quay()
	for i in range(RAID_ROBOTS):
		var a: float = TAU * float(i) / RAID_ROBOTS
		var at: Vector3 = door + Vector3(cos(a), 0, sin(a)) * 2.5
		at.y = main._height_at(at.x, at.z) + 0.2
		var m: Node3D = ms.spawn_extra("robot_demenageur", at)
		if m == null:
			continue
		m.set("home", at)
		if m.has_method("porter"):
			m.call("porter", quay + Vector3(_rng.randf_range(-6.0, 6.0), 0, _rng.randf_range(-2.0, 2.0)))
		_raid_robots.append(m)


func _raid_tick(delta: float) -> void:
	_raid_left -= delta
	var alive: Array = []
	for m in _raid_robots:
		if not is_instance_valid(m) or str(m.get("state")) == "mort":
			_raid_killed += 1
			state["robots_arretes"] = int(state["robots_arretes"]) + 1
			continue
		if bool(m.get("arrive")):
			_raid_arrived += 1
			bo.say("Un robot est arrivé au quai avec un canapé dans les bras : « Merci de votre compréhension. » Le canapé part sur une barge grise. (%d meuble%s perdu%s)" % [_raid_arrived, "s" if _raid_arrived > 1 else "", "s" if _raid_arrived > 1 else ""], 5.0)
			m.queue_free()
			continue
		alive.append(m)
	_raid_robots = alive
	_raid_talk -= delta
	if _raid_talk <= 0.0 and not alive.is_empty():
		_raid_talk = _rng.randf_range(14.0, 22.0)
		var t: String = _line("DESCENTE", "habitants")
		if t != "":
			main._show_message_v28(t)
	if _raid_left <= 0.0 or _raid_robots.is_empty():
		_end_raid(false)


func _end_raid(silent: bool) -> void:
	for m in _raid_robots:
		if is_instance_valid(m):
			m.queue_free()
	_raid_robots.clear()
	if not raid_on:
		return
	raid_on = false
	_raid_wait = _rng.randf_range(900.0, 1500.0)
	if silent:
		return
	if _raid_killed >= 4 and _raid_arrived <= 1:
		state["descente_ok"] = true
		_say("DESCENTE", "fin", "Les robots repartent vers l'Usine Grise, en file indienne, en s'excusant. Le Boucan applaudit ! Les meubles restent à leur place.", 9.0)
		if main.has_method("jingle"):
			main.jingle("victoire")
	else:
		bo.say("Fin de l'alerte. Les robots ont emporté %d meuble%s… Mamie Barricade soupire : « On en retrouvera d'autres à la Gratuiterie. Mais la prochaine fois, on les arrête TOUS. »" % [maxi(_raid_arrived, RAID_ROBOTS - _raid_killed), "s" if maxi(_raid_arrived, RAID_ROBOTS - _raid_killed) > 1 else ""], 8.0)


func hostile_zone(p: Vector3) -> bool:
	return raid_on and Vector2(p.x - _raid_at.x, p.z - _raid_at.z).length() < 140.0


## La mort d'un robot de la Descente : on regarde la liste (rien d'autre à faire).
func _raid_process(delta: float) -> void:
	if raid_on:
		_raid_tick(delta)
		return
	var p: Vector3 = _player()
	if bo.city == null or not bool(main.get("game_started")) or bo.city.zone_at(p) == "" or p.y < -20.0:
		return
	var h: float = bo.hour()
	if h < 9.0 or h > 18.0:
		return
	_raid_wait -= delta
	if _raid_wait <= 0.0:
		_start_raid()


# =================================================================== les graffitis

func _collect_walls() -> void:
	_walls.clear()
	if bo.city == null:
		return
	var all: Array = []
	if bo.city.lieux != null:
		all += bo.city.lieux.mur_points
	all += bo.city.walls_paint
	for w in all:
		var xf: Transform3D = w[0]
		_walls.append(["%d,%d" % [roundi(xf.origin.x), roundi(xf.origin.z)], xf, float(w[1]), float(w[2])])


func _nearest_wall(p: Vector3, r: float) -> Array:
	var best: Array = []
	var bd: float = r
	for w in _walls:
		var d: float = p.distance_to((w[1] as Transform3D).origin)
		if d < bd:
			bd = d
			best = w
	return best


func can_paint() -> bool:
	var inv: Node = main.get("inventory_v28")
	if inv == null or inv.count("bombe_peinture") <= 0:
		return false
	var w: Array = _nearest_wall(_player(), 3.6)
	return not w.is_empty()


func paint_text() -> String:
	var w: Array = _nearest_wall(_player(), 3.6)
	if not w.is_empty() and (state["graffitis"] as Dictionary).has(str(w[0])):
		return "E : repeindre ce mur (bombe de peinture)"
	return "E : peindre un graffiti (bombe de peinture)"


func open_paint() -> void:
	var w: Array = _nearest_wall(_player(), 3.6)
	if w.is_empty():
		return
	_paint_key = str(w[0])
	var choices: Array = []
	for g in GRAFFITIS:
		choices.append({"id": "bo_graf:%d" % int(g[0]), "label": "✦ " + str(g[1])})
	choices.append({"id": "bo_graf:0", "label": "(Ranger la bombe)"})
	main.ask_v69(_speaker(w[1]), "Le mur", "", "Tu secoues la bombe : clic-clic-clic ! Le mur attend. Qu'est-ce que tu peins ?", choices, Callable(self, "_paint_pick"))


var _spk: Node3D

func _speaker(xf: Transform3D) -> Node3D:
	if _spk == null:
		_spk = Node3D.new()
		_spk.name = "Mur_v75"
		bo.add_child(_spk)
	_spk.global_position = xf.origin + Vector3.UP * 0.4
	return _spk


func _paint_pick(id: String) -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()
	var n: int = int(id.trim_prefix("bo_graf:"))
	if n <= 0 or _paint_key == "":
		return
	var inv: Node = main.get("inventory_v28")
	if inv == null or inv.count("bombe_peinture") <= 0:
		return
	inv.remove("bombe_peinture", 1)
	var before: int = (state["graffitis"] as Dictionary).size()
	state["graffitis"][_paint_key] = n
	_apply_paint()
	bo.sfx("bombe_peinture", _player())
	var after: int = (state["graffitis"] as Dictionary).size()
	var msg: String = "Pschhhhht ! Pschht ! Tu recules d'un pas : %s, tout frais, qui brille encore. Un passant siffle d'admiration." % str(GRAFFITIS[n - 1][1])
	if after >= 3 and before < 3:
		msg += " Trois graffitis ! Pigment va être fière de toi."
	bo.say(msg, 7.0)


func _apply_paint() -> void:
	if _paint_root == null:
		return
	var g: Dictionary = state["graffitis"]
	for k in _painted.keys():
		if not g.has(k):
			(_painted[k] as Node).queue_free()
			_painted.erase(k)
	for w in _walls:
		var key: String = str(w[0])
		if not g.has(key):
			continue
		var n: int = int(g[key])
		var mi: MeshInstance3D = _painted.get(key, null)
		if mi == null:
			mi = MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(float(w[2]), float(w[3]))
			mi.mesh = q
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_paint_root.add_child(mi)
			mi.global_transform = (w[1] as Transform3D) * Transform3D(Basis(), Vector3(0, 0, 0.04))
			_painted[key] = mi
		if mi.get_meta("n", -1) != n:
			mi.set_meta("n", n)
			mi.material_override = Mats.make("graffiti75_%d" % n)


# =================================================================== la Gratuiterie, la Cantine

func open_gratuiterie() -> void:
	var choices: Array = []
	if int(state["pris_jour"]) != _day():
		choices.append({"id": "bo_grat:prendre", "label": "✦ Prendre un objet sur la table (un par jour)"})
	var inv: Node = main.get("inventory_v28")
	if inv != null:
		var n: int = 0
		var counts: Dictionary = inv.counts()
		for id in counts:
			var info: Dictionary = inv.ITEMS.get(str(id), {})
			if str(id) == "piece" or str(info.get("kind", "")) in ["quete", "arme", "canne", "outil"] or int(counts[id]) <= 0:
				continue
			choices.append({"id": "bo_grat:donner:" + str(id), "label": "♥ Déposer : " + str(info.get("name", id))})
			n += 1
			if n >= 6:
				break
	choices.append({"id": "bo_grat:fermer", "label": "(Laisser la table)"})
	var txt: String = "La Gratuiterie : une longue table couverte d'objets, une pancarte peinte à la main : « RIEN NE SE JETTE, TOUT SE DONNE. Un objet par jour et par personne, merci ! — Trocante ». "
	if int(state["pris_jour"]) == _day():
		txt += "(Tu as déjà pris quelque chose aujourd'hui.)"
	main.ask_v69(_speaker(Transform3D(Basis(), bo.city.lieux.gratuiterie)), "La Gratuiterie", "", txt, choices, Callable(self, "_grat_pick"))


func _grat_pick(id: String) -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()
	var inv: Node = main.get("inventory_v28")
	if inv == null or id == "bo_grat:fermer":
		return
	if id == "bo_grat:prendre":
		if int(state["pris_jour"]) == _day():
			_say("GRATUITERIE", "deja", "Tu as déjà pris un objet aujourd'hui. Demain, la table aura changé !", 5.0)
			return
		var pick: String = ""
		var r := RandomNumberGenerator.new()
		r.seed = _day() * 7 + 75
		var pool: Array = DONS.filter(func(x): return inv.ITEMS.has(str(x)))
		if pool.is_empty():
			return
		pick = str(pool[r.randi() % pool.size()])
		if inv.add(pick, 1) <= 0:
			bo.say("Ton sac est plein ! Trocante rit : « Alors donne d'abord ! »", 5.0)
			return
		state["pris_jour"] = _day()
		bo.sfx("ui_quete", _player())
		var t: String = _line("GRATUITERIE", "prendre")
		bo.say((t + "  " if t != "" else "") + "(Tu prends : %s.)" % str(inv.ITEMS[pick].get("name", pick)), 7.0)
		return
	if id.begins_with("bo_grat:donner:"):
		var item: String = id.trim_prefix("bo_grat:donner:")
		if inv.count(item) <= 0:
			return
		inv.remove(item, 1)
		state["dons"] = int(state["dons"]) + 1
		bo.sfx("ui_choix", _player())
		_say("GRATUITERIE", "donner", "Trocante pose ton objet sur la table, bien en vue : « Merci ! Quelqu'un va être tellement content. »", 6.0)


func open_cantine() -> void:
	var choices: Array = []
	var txt: String
	if int(state["soupe_jour"]) == _day():
		txt = "Lentille agite sa louche géante : « Tu as déjà eu ton bol aujourd'hui ! Reviens demain, il y aura une autre soupe. Enfin, la même, avec d'autres légumes. »"
		choices.append({"id": "bo_soupe:fermer", "label": "(D'accord !)"})
	else:
		txt = "La Cantine à prix libre. Une grande marmite fume, une ardoise dit : « SOUPE DU JOUR : SOUPE DE TOUT LE MONDE. Prix : ce que tu veux. Même rien. Surtout si tu as faim. » Une boîte en fer attend les pièces."
		for n in [0, 1, 5, 10]:
			choices.append({"id": "bo_soupe:%d" % n, "label": "✦ Un bol de soupe — %s" % ("je n'ai rien, merci !" if n == 0 else "je donne %d pièce%s" % [n, "s" if n > 1 else ""])})
		choices.append({"id": "bo_soupe:fermer", "label": "(Pas faim pour l'instant)"})
	main.ask_v69(_speaker(Transform3D(Basis(), bo.city.lieux.cantine_comptoir)), "Cantine à prix libre", "", txt, choices, Callable(self, "_soupe_pick"))


func _soupe_pick(id: String) -> void:
	if main.has_method("_close_dialogue_v31"):
		main._close_dialogue_v31()
	var inv: Node = main.get("inventory_v28")
	if inv == null or id == "bo_soupe:fermer" or int(state["soupe_jour"]) == _day():
		return
	var n: int = int(id.trim_prefix("bo_soupe:"))
	if n > 0 and inv.count("piece") < n:
		bo.say("Tu fouilles tes poches… pas assez de pièces. Lentille rit : « Alors c'est zéro ! Zéro, c'est un prix aussi ! »", 5.0)
		n = 0
	if not inv.ITEMS.has("soupe_prix_libre") or inv.add("soupe_prix_libre", 1) <= 0:
		bo.say("Ton sac est plein : Lentille te fait boire la soupe sur place, à la louche. Ça fait du bien.", 5.0)
	if n > 0:
		inv.remove("piece", n)
		state["donne_pieces"] = int(state["donne_pieces"]) + n
	state["soupe_jour"] = _day()
	state["soupes"] = int(state["soupes"]) + 1
	bo.sfx("ui_quete", _player())
	_say("CANTINE", "payer_0" if n == 0 else ("payer_peu" if n < 5 else "payer_beaucoup"), "Lentille remplit un bocal de soupe fumante. « Bon appétit ! »", 7.0)


# =================================================================== Radio Boucan, Monsieur Lisse

func _radio_tick(delta: float) -> void:
	if _quest("bo_radio") != "finie":
		return
	var p: Vector3 = _player()
	if bo.city == null or bo.city.zone_at(p) == "":
		return
	_radio_t -= delta
	if _radio_t > 0.0:
		return
	_radio_t = _rng.randf_range(110.0, 200.0)
	var t: String = _line("RADIO")
	if t == "":
		return
	var j: Node = main.get("journal_v56")
	var who: String = "notre voyageur préféré"
	if j != null and not (j.titres as Array).is_empty():
		who = "« %s »" % str(j.titres[-1])
	bo.sfx("radio_jingle", p)
	main._show_message_v28("📻 " + t.replace("{joueur}", who))


func _lisse_tick(delta: float) -> void:
	_lisse_t -= delta
	if _lisse_t > 0.0 or bo.city == null or bo.city.lieux == null:
		return
	_lisse_t = 3.0
	var p: Vector3 = _player()
	if p.distance_to(bo.city.lieux.bureau_vente) > 9.0:
		return
	var beaten: bool = bo.dungeon != null and bool(bo.dungeon.state.get("boss", false))
	if beaten and not bool(state["lisse_vaincu_dit"]):
		state["lisse_vaincu_dit"] = true
		_say("LISSE", "defaite", "Monsieur Lisse range ses panneaux « BIENTÔT ICI ». Il regarde la Halle. Il tape du pied. En rythme.", 9.0)
		_lisse_t = 90.0
		return
	if not beaten:
		_say("LISSE", "bureau", "« Bienvenue au Bureau de vente Lisse & Fils ! Le Lisse-Center : quatre cents boutiques, zéro squat ! »", 7.0)
		_lisse_t = 75.0


# =================================================================== Sardine

func _sardine_tick(delta: float) -> void:
	var waiting: bool = not bool(state["sardine"]) and _quest("bo_sardine") == "en_cours"
	var at: Vector3 = bo.dehors.objets.get("sardine", Vector3.ZERO) if bo.dehors != null else Vector3.ZERO
	if not waiting or at == Vector3.ZERO:
		if _dog != null:
			_dog.queue_free()
			_dog = null
		return
	var p: Vector3 = _player()
	if _dog == null and p.distance_to(at) < 120.0 and ResourceLoader.exists(ANIMAUX):
		var A = load(ANIMAUX)
		_dog = A.build("chien", {"taille": 1.0, "sardine": true, "base": Color(0.72, 0.55, 0.36), "bandana": Color(0.8, 0.1, 0.1)})
		if _dog != null:
			bo.add_child(_dog)
			_dog.global_position = at
	if _dog != null:
		_dog_clock += delta
		var to_p: Vector3 = p - _dog.global_position
		to_p.y = 0.0
		if to_p.length() > 0.1:
			_dog.rotation.y = atan2(to_p.x, to_p.z)
		var A2 = load(ANIMAUX)
		A2.animate(_dog, _dog_clock, 0.0, "aboie" if fmod(_dog_clock, 4.0) < 1.5 else "assis", delta)
		if fmod(_dog_clock, 4.0) < delta and p.distance_to(at) < 40.0:
			bo.sfx("aboiement", at)
	if p.distance_to(at) < 5.0:
		state["sardine"] = true
		if _dog != null:
			_dog.queue_free()
			_dog = null
		bo.say("Un bâtard au bandana rouge sort de sous une carcasse de voiture, une oreille levée, une oreille baissée. Il te renifle, éternue, et se met à remuer la queue si fort que tout son derrière remue. SARDINE ! Il te suit maintenant : ramène-le à Tornade !", 9.0)
		bo.sfx("aboiement", at)
		if bo.chien != null and bo.chien.has_method("spawn_near_player"):
			bo.chien.spawn_near_player()


# =================================================================== les invites, les services

func register_interactions(d: Node) -> void:
	var me = self
	var l = bo.city.lieux
	bo._ia(d, {"id": "bo_pogo", "pos": l.halle_fosse, "radius": 5.0, "text": "Sauter (ou E) : danser le pogo avec la foule !", "vr": "Gâchette : danser le pogo",
		"call": func(): me.pogo(), "when": func(): return me.can_pogo()})
	bo._ia(d, {"id": "bo_gratuiterie", "pos": l.gratuiterie, "radius": 1.8, "text": "E : regarder la table de la Gratuiterie", "vr": "Gâchette : la Gratuiterie",
		"call": func(): me.open_gratuiterie(), "when": func(): return true})
	bo._ia(d, {"id": "bo_cantine", "pos": l.cantine_comptoir, "radius": 1.8, "text": "E : un bol de soupe à prix libre", "vr": "Gâchette : un bol de soupe",
		"call": func(): me.open_cantine(), "when": func(): return true})
	# un seul invite pour tous les murs peignables : il suit le joueur (le mur le plus proche)
	_paint_ia = {"id": "bo_graffiti", "pos": Vector3(0, -9999, 0), "radius": 1.6, "text": "E : peindre un graffiti", "vr": "Gâchette : peindre un graffiti",
		"call": func(): me.open_paint(), "when": func(): return me.can_paint()}
	bo._ia(d, _paint_ia)


var _paint_ia: Dictionary = {}


func register_services(journal: Node) -> void:
	journal.lieux["gratuiterie"] = bo.city.lieux.gratuiterie
	journal.lieux["cantine"] = bo.city.lieux.cantine_comptoir


func after_reply(_r: Dictionary, npc: Node) -> void:
	# Sardine devient le compagnon pour de bon quand on le ramène à Tornade (et s'il n'est pas là)
	if npc != null and str(npc.get("profile").get("id", "")) == "tornade" and _quest("bo_sardine") == "finie":
		if bo.chien != null and bo.chien.has_method("is_active") and not bo.chien.is_active():
			bo.chien.spawn_near_player()


func _process(delta: float) -> void:
	if main == null or bo == null or bo.ile == null or bo.city == null:
		return
	var p: Vector3 = _player()
	_concert_tick(delta)
	_pogo_tick(delta)
	if not bo.ile.contains(p.x, p.z) and not raid_on:
		return
	_raid_process(delta)
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = 0.5
		_radio_tick(0.5)
		_lisse_tick(0.5)
		if not _paint_ia.is_empty():
			var w: Array = _nearest_wall(p, 4.0)
			_paint_ia["pos"] = (w[1] as Transform3D).origin + (w[1] as Transform3D).basis.z * 1.0 - Vector3.UP * 1.2 if not w.is_empty() else Vector3(0, -9999, 0)
			_paint_ia["text"] = paint_text()
	_sardine_tick(delta)

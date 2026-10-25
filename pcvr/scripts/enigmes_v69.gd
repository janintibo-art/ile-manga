extends Node3D
## V69 : le socle commun des trois grands donjons de l'Île des Trois Soleils (la Pyramide de Rê,
## Xibalba, les Cinq Soleils). Chaque donjon (pyramide_v69, xibalba_v69, cinq_soleils_v69) hérite
## d'ici et ne décrit que ses salles, ses énigmes et ses combats.
##  - Le donjon n'est construit qu'à la première descente (ou au chargement d'une partie sauvée
##    dedans) : il ne coûte rien tant qu'on reste à la surface.
##  - Repère : O (un point du monde, loin sous l'île : y < -40, c'est « sous terre » pour
##    donjon_v35 : pénombre, monstres éveillés) ; les positions des salles sont locales (l = p - O).
##  - Les salles (rooms) : une boîte locale, un nœud racine (on ne dessine que la salle où l'on est
##    et ses voisines), un point de reprise (une chute ou un évanouissement y ramène).
##  - Les portes de pierre (gates) : elles s'enfoncent dans le sol quand une énigme est résolue
##    (sauvegardé dans state["portes"]).
##  - Les invites « E » passent par donjon_v35._interactions ; les devinettes des statues par
##    main.ask_v69 (le dialogue des habitants, les réponses reviennent ici).
##  - Les monstres d'une salle arrivent la première fois qu'on y entre (à chaque descente) ; les
##    gardiens (bosses) restent vaincus une fois pour toutes ; leur barre de vie s'affiche en haut.

const Kit = preload("res://scripts/donjon_kit_v69.gd")

var main: Node
var sol: Node                                   # soleils_v69
var O := Vector3.ZERO
var key: String = ""                            # "egypte" | "maya" | "azteque"
var titre: String = ""
var built: bool = false
var state: Dictionary = {}
var kit
var pc: bool = true
var rooms: Dictionary = {}                      # nom -> {a, b, root, cp, face, voisins}
var room: String = ""
var checkpoint: Array = []                      # [position (monde), regard]
var fight: bool = false
var gates: Dictionary = {}                      # nom -> Node3D
var room_spawns: Dictionary = {}                # salle -> [[sorte, x, y, z], …] (local)
var bbox := AABB()                              # l'emprise du donjon (locale), même avant sa construction
var _boss: Node3D
var _boss_cb: Callable
var _bar_vr: Label3D
var _room_monsters: Dictionary = {}
var _pending_spawns: Array = []
var _said: Dictionary = {}
var _was_in: bool = false
var _clock: float = 0.0
var _fall_cd: float = 0.0
var _ia: Array = []
var _speaker: Node3D


func setup(main_node: Node, soleils: Node) -> void:
	main = main_node
	sol = soleils
	pc = OS.has_feature("ile_manga_pc")
	state = _fresh()


## L'état sauvegardé (à compléter par chaque donjon : _defaults()).
func _fresh() -> Dictionary:
	var d: Dictionary = {"visite": false, "portes": {}, "coffres": {}, "boss": false, "fini": false}
	d.merge(_defaults(), true)
	return d


func _defaults() -> Dictionary:
	return {}


# =================================================================== repère, salles

func W(l: Vector3) -> Vector3:
	return O + l


func L(p: Vector3) -> Vector3:
	return p - O


func X(l: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), O + l)


## Une salle : boîte locale [a, b] (a = coin bas, b = coin haut), point de reprise local et regard.
func add_room(n: String, a: Vector3, b: Vector3, cp: Vector3, face: Vector3, voisins: Array) -> Node3D:
	var r := Node3D.new()
	r.name = "Salle_" + n
	add_child(r)
	rooms[n] = {"a": a, "b": b, "root": r, "cp": cp, "face": face, "voisins": voisins}
	return r


## Ce point est-il dans l'emprise du donjon (même pas encore construit) ?
func near(p: Vector3) -> bool:
	return bbox.has_point(L(p))


## Ce point est-il dans le donjon (une salle, ou juste sous l'une d'elles) ?
func contains(p: Vector3) -> bool:
	if not built:
		return false
	var l: Vector3 = L(p)
	for n in rooms:
		var R: Dictionary = rooms[n]
		var a: Vector3 = R["a"]
		var b: Vector3 = R["b"]
		if l.x > a.x - 1.5 and l.x < b.x + 1.5 and l.z > a.z - 1.5 and l.z < b.z + 1.5 and l.y > a.y - 30.0 and l.y < b.y + 2.0:
			return true
	return false


func _room_of(p: Vector3) -> String:
	if not built:
		return ""
	var l: Vector3 = L(p)
	var best: String = ""
	for n in rooms:
		var R: Dictionary = rooms[n]
		var a: Vector3 = R["a"]
		var b: Vector3 = R["b"]
		if l.x >= a.x and l.x <= b.x and l.z >= a.z and l.z <= b.z and l.y >= a.y - 1.0 and l.y <= b.y:
			return n
		if l.x > a.x - 1.5 and l.x < b.x + 1.5 and l.z > a.z - 1.5 and l.z < b.z + 1.5 and l.y > a.y - 30.0 and l.y < b.y + 2.0:
			best = n
	return best


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
	print("ILE_MANGA_V69: %s construit en %d ms" % [titre, Time.get_ticks_msec() - t0])


## À écrire par chaque donjon : la géométrie (kit.root = rooms[n].root, …, kit.commit()).
func _build() -> void:
	pass


## À écrire par chaque donjon : les invites, les énigmes.
func _register() -> void:
	pass


## L'état sauvé appliqué aux salles (portes ouvertes, coffres ouverts, mécanismes…).
func _apply_state() -> void:
	for g in gates:
		_set_gate(str(g), bool((state["portes"] as Dictionary).get(g, false)), false)


## Passe au nœud d'une salle pour y dessiner (un maillage par matière et par salle).
func _in_room(n: String) -> void:
	if kit.root != null and not kit.batch.is_empty():
		kit.commit()
	kit.root = rooms[n]["root"]


# =================================================================== portes, coffres, invites

## Une porte de pierre (une dalle qui s'enfonce dans le sol) : position locale du bas-centre,
## largeur, hauteur, épaisseur, orientation (yaw).
func gate(n: String, room_n: String, l: Vector3, w: float, h: float, t: float, yaw: float, k: String = "calc69", face_k: String = "") -> Node3D:
	var g := Node3D.new()
	g.name = "Porte_" + n
	(rooms[room_n]["root"] as Node3D).add_child(g)
	g.global_transform = X(l, yaw)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, t)
	mi.mesh = bm
	mi.material_override = kit.mat(k)
	mi.position = Vector3(0, h * 0.5, 0)
	g.add_child(mi)
	if face_k != "":
		for s in [-1.0, 1.0]:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(minf(w, h) * 0.7, minf(w, h) * 0.7)
			q.mesh = qm
			q.material_override = kit.mat(face_k)
			q.position = Vector3(0, h * 0.55, s * (t * 0.5 + 0.01))
			q.rotation.y = 0.0 if s > 0 else PI
			g.add_child(q)
	var sb := StaticBody3D.new()
	sb.name = "Corps"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(w, h, t)
	cs.shape = sh
	cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs)
	g.add_child(sb)
	g.set_meta("h", h)
	g.set_meta("y0", g.position.y)
	gates[n] = g
	return g


func _set_gate(n: String, open: bool, animate: bool) -> void:
	var g: Node3D = gates.get(n, null)
	if g == null:
		return
	var y0: float = float(g.get_meta("y0"))
	var target: float = y0 - float(g.get_meta("h")) - 0.05 if open else y0
	var sb: StaticBody3D = g.get_node("Corps")
	if animate:
		var tw := create_tween()
		tw.tween_property(g, "position:y", target, 2.2).set_trans(Tween.TRANS_SINE)
		if open:
			tw.tween_callback(func(): sb.collision_layer = 0)
		else:
			sb.collision_layer = 1
	else:
		g.position.y = target
		sb.collision_layer = 0 if open else 1
	g.visible = not open or animate


func open_gate(n: String, text: String = "") -> void:
	if bool((state["portes"] as Dictionary).get(n, false)):
		return
	state["portes"][n] = true
	_set_gate(n, true, true)
	var g: Node3D = gates.get(n, null)
	if g != null:
		_sfx("pierre_glisse", g.global_position + Vector3.UP)
		var hide_later := get_tree().create_timer(2.4)
		hide_later.timeout.connect(func(): if is_instance_valid(g) and bool((state["portes"] as Dictionary).get(n, false)): g.visible = false)
	if text != "":
		_say(text, 6.0)


func gate_open(n: String) -> bool:
	return bool((state["portes"] as Dictionary).get(n, false))


## Une invite « E » (position locale).
func ia(id: String, l: Vector3, radius: float, text: String, vr: String, call: Callable, when: Callable = Callable()) -> Dictionary:
	var d: Node = main.get("donjon_v35")
	var it := {"id": key + "_" + id, "pos": W(l), "radius": radius, "text": text, "vr": vr, "call": call}
	var me = self
	if when.is_valid():
		it["when"] = func(): return me.built and me.room != "" and bool(when.call())
	else:
		it["when"] = func(): return me.built and me.room != ""
	if d != null:
		d._interactions.append(it)
	_ia.append(it)
	return it


## Un coffre (contenu : [[objet, nombre], …]), ouvert une fois pour toutes.
func chest(n: String, room_n: String, l: Vector3, yaw: float, contents: Array, text: String, when: Callable = Callable()) -> void:
	var r: Node3D = rooms[room_n]["root"]
	var c := Node3D.new()
	c.name = "Coffre_" + n
	r.add_child(c)
	c.global_transform = X(l, yaw)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.6, 0.62)
	body.mesh = bm
	body.material_override = kit.mat("bois69")
	body.position = Vector3(0, 0.3, 0)
	c.add_child(body)
	for s in [-0.38, 0.38]:
		var band := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.08, 0.62, 0.64)
		band.mesh = bb
		band.material_override = kit.mat("bronze69")
		band.position = Vector3(s, 0.31, 0)
		c.add_child(band)
	var lid := Node3D.new()
	lid.name = "Couvercle"
	lid.position = Vector3(0, 0.6, -0.31)
	c.add_child(lid)
	var lm := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(1.02, 0.14, 0.64)
	lm.mesh = lb
	lm.material_override = kit.mat("bois69")
	lm.position = Vector3(0, 0.07, 0.32)
	lid.add_child(lm)
	var lock := MeshInstance3D.new()
	var lk := BoxMesh.new()
	lk.size = Vector3(0.12, 0.14, 0.04)
	lock.mesh = lk
	lock.material_override = kit.mat("or69")
	lock.position = Vector3(0, 0.0, 0.64)
	lid.add_child(lock)
	kit.col_box(X(l + Vector3(0, 0.3, 0), yaw), Vector3(1.0, 0.6, 0.62))
	c.set_meta("lid", lid)
	if bool((state["coffres"] as Dictionary).get(n, false)):
		lid.rotation.x = -1.6
	var front: Vector3 = l + Basis(Vector3.UP, yaw) * Vector3(0, 0, 1.0)
	var me = self
	ia("coffre_" + n, front, 1.5, "E : ouvrir le coffre", "Gâchette : ouvrir le coffre",
		func(): me._open_chest(n, c, contents, text),
		func(): return not bool((me.state["coffres"] as Dictionary).get(n, false)) and (not when.is_valid() or bool(when.call())))


func _open_chest(n: String, c: Node3D, contents: Array, text: String) -> void:
	state["coffres"][n] = true
	var lid: Node3D = c.get_meta("lid")
	create_tween().tween_property(lid, "rotation:x", -1.6, 0.6).set_trans(Tween.TRANS_BACK)
	_sfx("coffre", c.global_position + Vector3.UP * 0.5)
	var parts: Array = []
	var inv: Node = main.inventory_v28
	for g in contents:
		var got: int = inv.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append("%d × %s" % [got, str(inv.ITEMS[str(g[0])]["name"])] if got > 1 else str(inv.ITEMS[str(g[0])]["name"]))
		if got < int(g[1]):
			inv.spawn_pickup(key + "_" + n + "_" + str(g[0]), str(g[0]), int(g[1]) - got, c.global_position + Vector3(0, 0.3, 1.2))
	var t: String = text
	if not parts.is_empty():
		t += " (" + ", ".join(parts) + ")"
	_say(t, 6.0)


# =================================================================== paroles

func _say(text: String, seconds: float = 5.0) -> void:
	main.donjon_v35._say(text, seconds)


func _once(k: String, text: String, seconds: float = 6.0) -> void:
	if _said.has(k):
		return
	_said[k] = true
	_say(text, seconds)


func _sfx(n: String, at: Vector3) -> void:
	if main.has_method("sfx"):
		main.sfx(n, at)


## Une question posée par une statue (le dialogue des habitants, sans habitant) : « at » est le
## visage de la statue. Les réponses vont à cb(id).
func _ask(at: Vector3, who: String, mood: String, text: String, choices: Array, cb: Callable) -> void:
	if _speaker == null:
		_speaker = Node3D.new()
		_speaker.name = "Voix_" + key
		add_child(_speaker)
	_speaker.global_position = at + Vector3.DOWN * 1.0
	main.ask_v69(_speaker, who, mood, text, choices, cb)


func _close_dialog() -> void:
	main._close_dialogue_v31()


## Le joueur (les pieds).
func _feet() -> Vector3:
	if main.xr_active:
		return main.vr_body.global_position
	return main.pc_body.global_position


func _inv() -> Node:
	return main.inventory_v28


# =================================================================== entrer, sortir

## Où l'on arrive en descendant, où l'on ressort (à écrire par chaque donjon).
func entry() -> Array:
	return [W(Vector3.ZERO), Vector3(0, 0, 1)]


func exit_point() -> Array:
	return [Vector3.ZERO, Vector3(0, 0, 1)]


func enter() -> void:
	ensure_built()
	var first: bool = not bool(state["visite"])
	state["visite"] = true
	var e: Array = entry()
	await main.donjon_v35._travel(e[0], e[1])
	checkpoint = e
	_on_enter(first)


func _on_enter(_first: bool) -> void:
	pass


func leave(text: String = "") -> void:
	_reset_fight()
	var e: Array = exit_point()
	await main.donjon_v35._travel(e[0], e[1])
	_hide_all(false)
	room = ""
	if text != "":
		_say(text, 5.0)


# =================================================================== chaque image

func _physics_process(delta: float) -> void:
	if main == null or not built or not bool(main.get("game_started")):
		return
	_clock += delta
	var p: Vector3 = _feet()
	var r: String = _room_of(p)
	if r == "":
		if _was_in:
			_was_in = false
			_reset_fight()
			_hide_all(false)
			room = ""
			_said.clear()
		return
	_was_in = true
	if r != room:
		var old: String = room
		room = r
		var R: Dictionary = rooms[r]
		checkpoint = [W(R["cp"]), R["face"]]
		_visibility(r)
		if room_spawns.has(r) and not _room_monsters.has(r):
			_pending_spawns.append(r)
		_enter_room(old, r)
	_spawn_pending()
	_tick(delta, p, r)
	_tick_falls(delta, p, r)
	_tick_room_monsters()
	_tick_boss()


func _enter_room(_old: String, _r: String) -> void:
	pass


func _tick(_delta: float, _p: Vector3, _r: String) -> void:
	pass


## Les salles qu'on ne voit pas ne sont pas dessinées (la salle, ses voisines).
func _visibility(r: String) -> void:
	var vis: Array = [r]
	vis.append_array(rooms[r]["voisins"])
	for n in rooms:
		(rooms[n]["root"] as Node3D).visible = vis.has(n)


func _hide_all(on: bool) -> void:
	for n in rooms:
		(rooms[n]["root"] as Node3D).visible = on


# =================================================================== monstres

func _spawn_pending() -> void:
	if _pending_spawns.is_empty():
		return
	var mo: Node = main.get("monstres_v36")
	# monstres_v36 vide sa liste à chaque descente : on attend qu'il ait vu qu'on est descendu
	if mo == null or not bool(mo.get("_was_inside")):
		return
	for r in _pending_spawns:
		_room_monsters[r] = []
		for e in room_spawns[r]:
			if e.size() > 4 and not bool((e[4] as Callable).call()):
				continue
			var at: Vector3 = W(Vector3(float(e[1]), float(e[2]) + 0.1, float(e[3])))
			var m: Node3D = mo.spawn_extra(str(e[0]), at)
			m.home = at
			m.state = "veille"
			(_room_monsters[r] as Array).append(m)
	_pending_spawns.clear()


func room_alive(r: String) -> int:
	var n: int = 0
	for m in _room_monsters.get(r, []):
		if is_instance_valid(m) and str(m.get("state")) != "mort":
			n += 1
	return n


func room_spawned(r: String) -> bool:
	return _room_monsters.has(r)


func _tick_room_monsters() -> void:
	for r in _room_monsters:
		for m in _room_monsters[r]:
			if not is_instance_valid(m) or str(m.get("state")) == "mort":
				continue
			var mm: Node3D = m
			var home: Vector3 = mm.get("home")
			if mm.global_position.y < home.y - 3.0:
				mm.global_position = home
				mm.set("velocity", Vector3.ZERO)
				mm.set("state", "veille")


## Un monstre de plus, lié à une salle (il disparaîtra si l'on sort).
func spawn_in(r: String, kind: String, l: Vector3, awake: bool = true) -> Node3D:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return null
	var at: Vector3 = W(l + Vector3(0, 0.1, 0))
	var m: Node3D = mo.spawn_extra(kind, at)
	m.home = at
	m.state = "chasse" if awake else "veille"
	if not _room_monsters.has(r):
		_room_monsters[r] = []
	(_room_monsters[r] as Array).append(m)
	return m


# =================================================================== les gardiens

func _start_boss(kind: String, l: Vector3, label: String, on_dead: Callable) -> Node3D:
	var mo: Node = main.get("monstres_v36")
	if mo == null:
		return null
	fight = true
	var at: Vector3 = W(l + Vector3(0, 0.1, 0))
	var b: Node3D = mo.spawn_extra(kind, at)
	b.home = at
	b.state = "chasse"
	_boss = b
	_boss_cb = on_dead
	if main.combat_v28 != null:
		main.combat_v28.puff(at + Vector3.UP, Color(0.9, 0.8, 0.5))
	_show_bar(label, int(b.spec["pv"]))
	return b


func _show_bar(label: String, hp_max: int) -> void:
	var d: Node = main.donjon_v35
	d._bar_name = label
	d._bar_label.text = label
	d._bar_layer.visible = not main.xr_active
	if main.xr_active and _boss != null:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.004
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(1.0, 0.75, 0.5)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, float(_boss.hit_height) * 2.0 + 2.4, 0)
		_boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(hp_max, hp_max)


func _hide_bar() -> void:
	var d: Node = main.donjon_v35
	d._bar_layer.visible = false
	d._bar_vr = null
	if _bar_vr != null and is_instance_valid(_bar_vr):
		_bar_vr.queue_free()
	_bar_vr = null


func _tick_boss() -> void:
	if not fight or _boss == null:
		return
	if not is_instance_valid(_boss):
		_boss = null
		fight = false
		_hide_bar()
		return
	main.donjon_v35._update_bar(maxi(int(_boss.hp), 0), int(_boss.spec["pv"]))
	if str(_boss.state) == "mort":
		fight = false
		_boss = null
		_hide_bar()
		_kill_room()
		if main.has_method("jingle"):
			main.jingle("victoire")
		if _boss_cb.is_valid():
			_boss_cb.call()


func _kill_room() -> void:
	for m in _room_monsters.get(room, []):
		if is_instance_valid(m) and str(m.state) != "mort":
			m.take_hit(99, (m as Node3D).global_position + Vector3.UP)


## Évanoui, ou sorti du donjon : les combats reprendront à zéro (les gardiens vaincus le restent).
func _reset_fight() -> void:
	var mo: Node = main.get("monstres_v36")
	if fight:
		_hide_bar()
	fight = false
	_boss = null
	for r in _room_monsters:
		for m in _room_monsters[r]:
			if is_instance_valid(m):
				if mo != null:
					mo.monsters.erase(m)
				(m as Node).queue_free()
	_room_monsters.clear()
	_pending_spawns.clear()
	_on_reset()


func _on_reset() -> void:
	pass


# =================================================================== chutes, reprise

func _tick_falls(delta: float, p: Vector3, r: String) -> void:
	_fall_cd = maxf(_fall_cd - delta, 0.0)
	if _fall_cd > 0.0 or checkpoint.is_empty() or r == "":
		return
	var a: Vector3 = rooms[r]["a"]
	if L(p).y < a.y - 4.0:
		_fall_cd = 1.5
		_fall_back(_fall_text(r), 2)


func _fall_text(_r: String) -> String:
	return "Tu tombes… et tu te retrouves, étourdi, à l'entrée de la salle."


func _fall_back(text: String, dmg: int) -> void:
	if checkpoint.is_empty():
		return
	main.place_player_v35(checkpoint[0], checkpoint[1])
	if dmg > 0:
		var hero: Node = main.get("hero_v28")
		if hero != null:
			hero.hurt_cooldown = 0.0
		_hurt(dmg, (checkpoint[0] as Vector3) + Vector3(0, 1.0, 0.01))
	_say(text, 3.5)


## Évanoui dans le donjon : au point de reprise de la salle, les cœurs pleins.
func respawn() -> void:
	ensure_built()
	_reset_fight()
	var at: Array = checkpoint if not checkpoint.is_empty() else entry()
	main.place_player_v35(at[0], at[1])
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.hp = hero.HP_MAX
		hero.stamina = hero.STAMINA_MAX
		hero.state = "sol"
		hero.hurt_cooldown = 0.0
		hero.health_changed.emit(hero.hp, hero.HP_MAX)
	main.donjon_v35.update_inside(true)
	main._show_message_v28("Vous vous êtes évanoui… et réveillé à l'entrée de la salle. %s" % _faint_text())
	room = ""


func _faint_text() -> String:
	return ""


func _hurt(dmg: int, from: Vector3) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.hurt_player(dmg, from)


## Pousse le joueur (le vent, une vague…) sans traverser les murs.
func push_player(offset: Vector3) -> void:
	var body: CharacterBody3D = main.vr_body if main.xr_active else main.pc_body
	if body == null:
		return
	if main.xr_active:
		var head: Vector3 = main.xr_camera.global_position
		var off := Vector3(head.x - main.xr_origin.global_position.x, 0.0, head.z - main.xr_origin.global_position.z)
		body.move_and_collide(offset)
		main.xr_origin.position = Vector3(body.global_position.x - off.x, body.global_position.y, body.global_position.z - off.z)
	else:
		body.move_and_collide(offset)
		main.pc_root.position = body.global_position


# =================================================================== récompense, sauvegarde

## La relique du donjon : dans le sac (ou à terre si le sac est plein), un titre, un cœur de plus.
func _reward(item: String, title: String, coins: int, at: Vector3) -> void:
	var inv: Node = main.inventory_v28
	if inv.add(item, 1) <= 0:
		inv.spawn_pickup(key + "_relique", item, 1, at)
	inv.add("piece", coins)
	var j: Node = main.get("journal_v56")
	if j != null:
		if not (j.titres as Array).has(title):
			j.titres.append(title)
		j.bonus["coeur"] = int(j.bonus.get("coeur", 0)) + 1
		j.apply_bonuses()
	var hero: Node = main.get("hero_v28")
	if hero != null:
		hero.set_health(int(hero.HP_MAX))
	if main.has_method("jingle"):
		main.jingle("decouverte")


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	state = _fresh()
	for k in state:
		if d.has(k):
			var v: Variant = d[k]
			state[k] = (v as Dictionary).duplicate(true) if v is Dictionary else ((v as Array).duplicate(true) if v is Array else v)
	if built:
		_reset_fight()
		_apply_state()
	_apply_outdoor()
	_said.clear()


## Ce qui, dehors, dépend de l'état du donjon (le calendrier du temple, les offrandes…).
func _apply_outdoor() -> void:
	pass

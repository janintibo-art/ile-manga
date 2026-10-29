extends Node3D
## V81 : on peut entrer dans TOUTES les maisons décoratives des villes. Devant une porte :
## « E : entrer » ; un fondu, et l'on est dedans. Chaque maison a son histoire (une famille à
## table qui rit, un bonhomme en pyjama furieux qu'on soit chez lui, une maison abandonnée
## pleine de toiles d'araignée et son coffre oublié, une cave secrète sous le tapis, une
## bibliothèque qui pivote…) : le scénario est tiré au sort une fois pour toutes pour chaque
## maison (la même maison raconte toujours la même chose, et se souvient de notre passage).
##
## Une seule maison est construite à la fois, loin sous la mer (STAGE) : sous terre, le jeu
## éteint le soleil et le ciel (donjon_v35.update_inside), la pièce a ses propres lumières.
## Les portes sont notées par les boîtes à outils des villes (azur_kit_v56.PORTES_V81).

const Kit = preload("res://scripts/azur_kit_v56.gd")
const Pieces = preload("res://scripts/maisons_pieces_v81.gd")
const Scenes = preload("res://scripts/maisons_scenes_v81.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const STAGE := Vector3(6000.0, -260.0, 6000.0)
const CAVE_DY: float = -7.0              # la cave, sous la pièce
const SECRET_DX: float = 14.0            # la pièce secrète, à côté

var main: Node
var portes: Array = []                   # {id, door, out, style, w, d, floors, owner}
var etat: Dictionary = {}                # id -> {vu, ...} (sauvegardé)
var inside: bool = false
var busy: bool = false
var cur: Dictionary = {}                 # la porte de la maison où l'on est
var room: Node3D                         # tout ce qui est construit (pièce, cave, gens)
var R                                    # maisons_pieces_v81 (la pièce)
var ctx: Dictionary = {}                 # scénario en cours (voir maisons_scenes_v81)
var people: Array = []                   # Figurant (contrôleurs) de la maison
var scenario: String = ""
var _its: Array = []                     # interactions de la maison (retirées en sortant)
var _it_door: Dictionary = {}            # « E : entrer » (suit la porte la plus proche)
var _grid: Dictionary = {}
var _collect_t: float = 1.0
var _n_seen: int = -1
var _near_t: float = 0.0
var _t: float = 0.0
var _talk_with: Node = null              # Figurant qui parle (pour end_talk)
var _exit_cb: Callable
var visits: int = 0                      # maisons visitées pendant la partie (tests)
var force_scenario: String = ""          # mode testeur : imposer l'histoire de la prochaine maison
var pending: Array = []                  # V83 : [[id, n], …] reçus quand le sac était plein (sauvegardé)
var _pending_t: float = 3.0


func setup(main_node: Node) -> void:
	main = main_node
	name = "Maisons_v81"


# =================================================================== les portes

## Récupère les portes notées par les villes (une fois le monde construit) ; les rangs dans une
## grille de 16 m pour trouver vite la plus proche.
func collect() -> void:
	portes.clear()
	_grid.clear()
	var seen: Dictionary = {}
	for e in Kit.PORTES_V81:
		var door: Vector3 = e["door"]
		var id: String = "m81_%d_%d" % [roundi(door.x * 2.0), roundi(door.z * 2.0)]
		if seen.has(id):
			continue
		seen[id] = true
		var p: Dictionary = (e as Dictionary).duplicate()
		p["id"] = id
		portes.append(p)
	_owners()
	for i in range(portes.size()):
		var d: Vector3 = portes[i]["door"]
		var key := Vector2i(floori(d.x / 16.0), floori(d.z / 16.0))
		if not _grid.has(key):
			_grid[key] = []
		(_grid[key] as Array).append(i)
	print("ILE_MANGA_V81: %d maisons où l'on peut entrer" % portes.size())


## Les maisons des habitants connus : la porte où il rentre le soir (son point « maison »).
func _owners() -> void:
	for n in main.get("npcs_v31"):
		if not is_instance_valid(n):
			continue
		var home: Variant = n.get("home")
		var pts: Variant = n.get("points")
		if home == null or str(home) == "" or not (pts is Dictionary) or not (pts as Dictionary).has(str(home)):
			continue
		var hp: Variant = pts[str(home)]
		if not (hp is Vector3):
			continue
		var best: int = -1
		var bd: float = 2.5
		for i in range(portes.size()):
			var dd: float = (portes[i]["door"] as Vector3).distance_to(hp)
			if dd < bd:
				bd = dd
				best = i
		if best >= 0:
			portes[best]["owner"] = str((n.get("profile") as Dictionary).get("id", ""))
			portes[best]["owner_node"] = n
	# V82 : les maisons dont la ville connaît déjà l'habitant (les fées, Mathurin, Khéti…)
	var by_id: Dictionary = {}
	for n2 in main.get("npcs_v31"):
		if is_instance_valid(n2) and n2.get("profile") is Dictionary:
			by_id[str((n2.get("profile") as Dictionary).get("id", ""))] = n2
	for e in portes:
		var ow: String = str(e.get("owner", ""))
		if ow != "" and e.get("owner_node", null) == null and by_id.has(ow):
			e["owner_node"] = by_id[ow]


func nearest(p: Vector3, radius: float = 1.8) -> int:
	var key := Vector2i(floori(p.x / 16.0), floori(p.z / 16.0))
	var best: int = -1
	var bd: float = radius
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for i in _grid.get(key + Vector2i(dx, dz), []):
				var d: Vector3 = portes[i]["door"]
				if absf(d.y - p.y) > 2.2:
					continue
				var dist: float = Vector2(d.x - p.x, d.z - p.z).length()
				if dist < bd:
					bd = dist
					best = i
	return best


func _process(delta: float) -> void:
	if main == null or not main.game_started:
		return
	_t += delta
	_pending_tick(delta)
	_collect_t -= delta
	if _collect_t <= 0.0:
		_collect_t = 5.0
		# une ville construite plus tard ajoute ses portes : on recompte
		if Kit.PORTES_V81.size() != _n_seen and not inside:
			_n_seen = Kit.PORTES_V81.size()
			collect()
			if _it_door.is_empty():
				_register_door()
	if portes.is_empty():
		return
	if inside:
		if R != null:
			R.tick(_t)
		# on est sorti par un autre chemin (téléportation, mode testeur…) : on démonte
		var pp: Vector3 = main._player_pos_v27()
		if not busy and pp.distance_to(STAGE) > 120.0:
			_teardown()
		return
	_near_t -= delta
	if _near_t <= 0.0:
		_near_t = 0.2
		_update_door_prompt()


func _register_door() -> void:
	var dj: Node = main.get("donjon_v35")
	if dj == null:
		return
	_it_door = {"id": "maisons_v81_porte", "pos": Vector3(0, -9999, 0), "radius": 1.6, "text": "E : entrer", "vr": "Gâchette : entrer",
		"call": func(): enter_nearest(), "when": func(): return not inside and not busy and _door_ok()}
	dj._interactions.append(_it_door)


func _door_ok() -> bool:
	if main.get("aeronef_v76") != null and bool(main.aeronef_v76.get("riding")):
		return false
	return true


func _update_door_prompt() -> void:
	var p: Vector3 = main._player_pos_v27()
	var i: int = nearest(p, 2.4)
	if i < 0:
		_it_door["pos"] = Vector3(0, -9999, 0)
		return
	var e: Dictionary = portes[i]
	_it_door["pos"] = e["door"]
	_it_door["porte"] = i
	var who: String = owner_name(e)
	var st: Dictionary = etat.get(str(e["id"]), {})
	if who != "":
		_it_door["text"] = "E : entrer chez %s" % who
	elif bool(st.get("chasse", false)):
		_it_door["text"] = "E : entrer (on t'a déjà mis dehors…)"
	elif bool(st.get("vu", false)):
		_it_door["text"] = "E : entrer (déjà visitée)"
	else:
		_it_door["text"] = "E : frapper et entrer"
	_it_door["vr"] = "Gâchette : entrer"


func owner_name(e: Dictionary) -> String:
	var n: Variant = e.get("owner_node", null)
	if n != null and is_instance_valid(n):
		return str(n.get("display_name")).split(" ")[0]
	return ""


# =================================================================== entrer, sortir

func enter_nearest() -> void:
	var i: int = int(_it_door.get("porte", -1))
	if i < 0 or i >= portes.size():
		return
	enter(i)


func enter(i: int) -> void:
	if busy or inside:
		return
	busy = true
	cur = portes[i]
	var dj: Node = main.get("donjon_v35")
	if main.get("fishing_v32") != null:
		main.fishing_v32.cancel("")
	main.sfx("porte_ouvre", cur["door"])
	dj._busy = true
	await dj._fade_to(1.0, 0.4)
	var arrive: Array = _build()
	main.place_player_v35(arrive[0], arrive[1])
	inside = true
	dj.update_inside(true)
	main.sfx("porte_ferme")
	await get_tree().create_timer(0.3).timeout
	await dj._fade_to(0.0, 0.5)
	dj._busy = false
	busy = false
	visits += 1
	var st: Dictionary = state()
	var first: bool = not bool(st.get("vu", false))
	st["vu"] = true
	Scenes.on_enter(self, first)


## Sortir par la porte (ou être mis dehors) : retour devant la porte, dehors.
func leave(text: String = "") -> void:
	if busy or not inside:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	if main.dialogue_v31 != null and main.dialogue_v31.opened:
		main._close_dialogue_v31()
	dj._busy = true
	main.sfx("porte_ouvre")
	await dj._fade_to(1.0, 0.4)
	var out: Vector3 = cur["out"]
	var at: Vector3 = (cur["door"] as Vector3) + out * 0.35
	_teardown()
	main.place_player_v35(at + Vector3.UP * 0.1, out)
	dj.update_inside(true)
	main.sfx("porte_ferme", at)
	await get_tree().create_timer(0.25).timeout
	await dj._fade_to(0.0, 0.5)
	dj._busy = false
	busy = false
	if text != "":
		say(text, 5.0)


## Aller ailleurs dans la maison (descendre à la cave, passer dans la pièce secrète…).
func go(to: Vector3, face: Vector3) -> void:
	if busy:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	dj._busy = true
	await dj._fade_to(1.0, 0.35)
	main.place_player_v35(to, face)
	await get_tree().create_timer(0.2).timeout
	await dj._fade_to(0.0, 0.45)
	dj._busy = false
	busy = false


## Là où l'on se réveillera si l'on sauvegarde dans une maison : devant sa porte.
func outside_pos() -> Vector3:
	if cur.is_empty():
		return main._player_pos_v27()
	return (cur["door"] as Vector3) + (cur["out"] as Vector3) * 0.35 + Vector3.UP * 0.1


func inside_stage(p: Vector3) -> bool:
	return inside and p.distance_to(STAGE) < 120.0


func _teardown() -> void:
	var dj: Node = main.get("donjon_v35")
	for it in _its:
		if dj != null:
			dj._interactions.erase(it)
	_its.clear()
	for f in people:
		if is_instance_valid(f) and f.get("npc") != null and is_instance_valid(f.npc):
			var rid: RID = (f.npc.get("_body") as AnimatableBody3D).get_rid() if f.npc.get("_body") != null else RID()
			var PnjV31: Script = load("res://scripts/pnj/pnj_v31.gd")
			if rid.is_valid():
				PnjV31._npc_bodies.erase(rid)
	people.clear()
	if room != null and is_instance_valid(room):
		room.queue_free()
	room = null
	R = null
	ctx = {}
	inside = false


# =================================================================== construire

## Construit la pièce et son scénario ; renvoie [où l'on arrive, regard].
func _build() -> Array:
	if room != null:
		_teardown()
		inside = true
	var t0: int = Time.get_ticks_msec()
	room = Node3D.new()
	room.name = "Maison_v81"
	add_child(room)
	var id: String = str(cur["id"])
	var seed_v: int = hash(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var style: String = str(cur.get("style", "montjoie"))
	var hour: float = float(main.temps_v56.hour) if main.get("temps_v56") != null else 12.0
	# la taille de la pièce suit (un peu) celle de la maison
	var w: float = clampf(float(cur.get("w", 7.0)) * 0.85, 5.6, 9.5)
	var d: float = clampf(float(cur.get("d", 7.0)) * 0.85, 5.0, 8.5)
	if style == "boucan_conteneur":
		w = 9.0
		d = 3.4
	elif style == "boucan_entrepot":
		w = clampf(w, 8.0, 11.0)
		d = clampf(d, 7.0, 10.0)
	R = Pieces.new()
	R.setup(room, main, STAGE, w, d, style, seed_v, hour)
	R.door_x = rng.randf_range(-w * 0.2, w * 0.2)
	ctx = {"id": id, "style": style, "rng": rng, "hour": hour, "owner": str(cur.get("owner", "")), "owner_node": cur.get("owner_node", null),
		"revisite": bool(state().get("vu", false)), "W": w, "D": d}
	# V83 : la maison retient son histoire (ajouter des histoires plus tard ne la change pas)
	var st0: Dictionary = state()
	if force_scenario != "":
		scenario = force_scenario
		# V84 : l'histoire imposée par le testeur reste aussi (on peut tester « ENCORE TOI ?! »)
		if scenario != "chez" and scenario != "fee" and Scenes.has_scenario(scenario):
			st0["scenario"] = scenario
	elif str(st0.get("scenario", "")) != "" and (Scenes.has_scenario(str(st0["scenario"]))):
		scenario = str(st0["scenario"])
	else:
		scenario = Scenes.pick(self)
		if scenario != "chez" and scenario != "fee":
			st0["scenario"] = scenario
	force_scenario = ""
	ctx["scenario"] = scenario
	R.shell()
	# la porte, de l'intérieur
	var door_in: Vector3 = R.P(R.door_x, 0, d * 0.5 - 0.6)
	act(door_in, "E : sortir", func(): leave(), 1.3)
	Scenes.build(self)
	R.commit()
	print("ILE_MANGA_V81: maison %s (%s, %s) construite en %d ms" % [id, style, scenario, Time.get_ticks_msec() - t0])
	return [R.P(R.door_x, 0.05, d * 0.5 - 1.1), Vector3(0, 0, -1)]


func state() -> Dictionary:
	var id: String = str(cur.get("id", ""))
	if not etat.has(id):
		etat[id] = {}
	return etat[id]


# =================================================================== ce que les scénarios utilisent

## Une interaction dans la maison (pos : dans le monde).
func act(pos: Vector3, text: String, cb: Callable, radius: float = 1.3, when: Callable = Callable(), vr: String = "") -> Dictionary:
	var it := {"id": "m81_%d" % _its.size(), "pos": pos, "radius": radius, "text": text, "vr": vr if vr != "" else text.replace("E : ", "Gâchette : "), "call": cb}
	if when.is_valid():
		it["when"] = when
	_its.append(it)
	var dj: Node = main.get("donjon_v35")
	if dj != null:
		dj._interactions.append(it)
	return it


## Un habitant de la maison. role : "homme", "femme", "vieux", "vieille", "garcon", "fille"
## (ou un id de fiche) ; x, z, yaw en repère de la pièce.
func person(role: String, x: float, z: float, yaw: float, pose: String, nom: String = "") -> Node:
	var prof: Dictionary = Gens.pick(str(ctx["style"]), role, ctx["rng"])
	if nom == "":
		nom = Gens.prenom(str(ctx["style"]), role, ctx["rng"])
	prof["nom"] = nom
	var face: Vector3 = Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 1)
	var y: float = 0.0
	var f: Node = Figurant.spawn(room, main, prof, R.P(x, y, z), face, pose)
	people.append(f)
	return f


## Parler à un habitant : la fenêtre de dialogue (cb reçoit l'id du choix).
func talk(f: Node, text: String, choices: Array, cb: Callable, mood: String = "de bonne humeur") -> void:
	if _talk_with != null and is_instance_valid(_talk_with) and _talk_with != f:
		_talk_with.end_talk()
	_talk_with = f
	f.begin_talk()
	var who: String = str(f.npc.get("display_name"))
	main.ask_v69(f.npc, who, mood, text, choices, cb)


## Fin de conversation (le bouton « Au revoir » ou un choix qui ferme).
func close_talk() -> void:
	main._close_dialogue_v31()
	if _talk_with != null and is_instance_valid(_talk_with):
		_talk_with.end_talk()
	_talk_with = null


## L'interaction « parler » au-dessus d'un habitant.
func talk_spot(f: Node, cb: Callable, text: String = "") -> Dictionary:
	var nm: String = str(f.npc.get("display_name")).split(" ")[0]
	var it: Dictionary = act(f.npc.global_position + Vector3.UP * 0.05, text if text != "" else "E : parler à " + nm, cb, 1.7)
	it["suit"] = f.npc
	return it


func say(text: String, seconds: float = 5.0) -> void:
	var dj: Node = main.get("donjon_v35")
	if dj != null:
		dj._say(text, seconds)
	else:
		main._show_message_v28(text)


## Donner des objets au joueur (avec le message qui va bien).
func give(items: Array, intro: String = "") -> void:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return
	var names: Array = []
	var lost: bool = false
	for e in items:
		var id: String = str(e[0])
		var n: int = int(e[1])
		if not inv.ITEMS.has(id):
			continue
		var got: int = int(inv.add(id, n))
		if got < n:
			lost = true
			# V83 : ce qui ne rentre pas dans le sac est gardé de côté (rendu dès qu'il y a de la place)
			pending.append([id, n - got])
		if got <= 0:
			continue
		var nm: String = str(inv.ITEMS[id]["art"]) if got <= 1 else ("%d pièces" % got if id == "piece" else "%d × %s" % [got, str(inv.ITEMS[id]["name"]).to_lower()])
		names.append(nm)
	if names.is_empty() and not lost:
		return
	main.sfx("ramasse")
	var msg: String = intro + ("Tu reçois : " + ", ".join(names) + "." if not names.is_empty() else "")
	if lost:
		msg += " (Ton sac est plein : le reste t'attend, tu le récupéreras dès qu'il y aura de la place.)"
	say(msg.strip_edges(), 6.0)


## Un vrai coffre (il s'ouvre, une fois pour toutes) ; loot : [[id, n], …].
func chest(x: float, z: float, yaw: float, loot: Array, key: String = "coffre", text: String = "E : ouvrir le coffre", piece: Variant = null) -> Node3D:
	# V84 : `piece` = la pièce où poser le coffre (la cave, la pièce secrète) ; sinon la pièce principale
	var PR = piece if piece != null else R
	var ob: Node = main.get("objets_v66")
	var root := Node3D.new()
	root.name = "Coffre_v81"
	room.add_child(root)
	root.global_transform = PR.L(x, 0, z, yaw)
	var body := MeshInstance3D.new()
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.46, -0.275)
	root.add_child(hinge)
	var lid := MeshInstance3D.new()
	if ob != null and ob.has_method("_chest_mesh"):
		body.mesh = ob._chest_mesh("corps")
		lid.mesh = ob._chest_mesh("couvercle")
	root.add_child(body)
	hinge.add_child(lid)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.92, 0.72, 0.57)
	cs.shape = bs
	cs.position = Vector3(0, 0.36, 0)
	sb.add_child(cs)
	root.add_child(sb)
	PR.reserve(x, z, 1.1, 0.8)
	var st: Dictionary = state()
	if bool(st.get(key, false)):
		hinge.rotation.x = -1.95
		return root
	var front: Vector3 = root.global_transform * Vector3(0, 0, 0.95)
	var open_cb := func() -> void:
		if bool(state().get(key, false)):
			return
		state()[key] = true
		main.sfx("coffre", root.global_position)
		var tw := room.create_tween()
		tw.tween_property(hinge, "rotation:x", -1.95, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if main.has_method("jingle"):
			main.jingle("decouverte")
		if ob != null and ob.has_method("_sparkle"):
			ob._sparkle(root.global_transform * Vector3(0, 0.6, 0))
		give(loot, "")
		var pr: Node = main.get("progression_v63")
		if pr != null and pr.has_method("on_chest"):
			pr.on_chest(root.global_position + Vector3.UP * 0.6)
	var still := func() -> bool:
		return not bool(state().get(key, false))
	act(front, text, open_cb, 1.4, still)
	return root


## Le butin d'une maison (toujours le même pour une maison donnée) : des pièces, un objet de
## la région, parfois une petite clé ou un trésor.
func loot(rich: float = 1.0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(ctx.get("id", "")) + "butin")
	var reg: String = Scenes.region(str(ctx.get("style", "")))
	var ob: Node = main.get("objets_v66")
	var table: Array = [[10, 20], ["pomme", "baies"]]
	if ob != null:
		table = ob.COFFRE_BUTIN.get(reg, ob.COFFRE_BUTIN["village"])
	var out: Array = [["piece", int(rng.randi_range(int(table[0][0]), int(table[0][1])) * rich)]]
	var items: Array = table[1]
	out.append([str(items[rng.randi() % items.size()]), rng.randi_range(1, 2)])
	var r: float = rng.randf()
	if r < 0.18 * rich:
		out.append(["petite_cle", 1])
	elif r < 0.3 * rich:
		out.append([["perle", "rubis", "piece_or", "bague"][rng.randi() % 4], 1])
	return out


## Mis dehors (« Allez, ouste ! ») : on ressort, et la maison s'en souvient.
func expel(text: String = "") -> void:
	state()["chasse"] = true
	await get_tree().create_timer(0.8).timeout
	leave(text)


## Ne fait rien (sert à clore proprement un bloc de lambda avant d'autres arguments).
func noop() -> void:
	pass


func end_talk_hook() -> void:
	if _talk_with != null and is_instance_valid(_talk_with):
		_talk_with.end_talk()
	_talk_with = null


# =================================================================== sauvegarde

## V83 : rendre ce qui attendait (sac plein), dès qu'il y a de la place.
func _pending_tick(delta: float) -> void:
	if pending.is_empty() or busy:
		return
	_pending_t -= delta
	if _pending_t > 0.0:
		return
	_pending_t = 3.0
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return
	var names: Array = []
	var still: Array = []
	for e in pending:
		var id: String = str(e[0])
		var n: int = int(e[1])
		var got: int = int(inv.add(id, n)) if inv.ITEMS.has(id) else n
		if got > 0 and inv.ITEMS.has(id):
			names.append(str(inv.ITEMS[id]["art"]) if got <= 1 else ("%d pièces" % got if id == "piece" else "%d × %s" % [got, str(inv.ITEMS[id]["name"]).to_lower()]))
		if got < n:
			still.append([id, n - got])
	pending = still
	if not names.is_empty():
		main.sfx("ramasse")
		say("Tu récupères ce que tu n'avais pas pu porter : " + ", ".join(names) + ".", 5.0)


func serialize() -> Dictionary:
	return {"etat": etat.duplicate(true), "en_attente": pending.duplicate(true)}


func load_data(d: Dictionary) -> void:
	etat = (d.get("etat", {}) as Dictionary).duplicate(true)
	pending = (d.get("en_attente", []) as Array).duplicate(true)

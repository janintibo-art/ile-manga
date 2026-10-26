extends Node3D
## V75 : les animaux de Port-Boucan (pas des monstres : le décor vivant de la ville).
##  - chiens (plusieurs allures : tailles, pelages, des bandanas) : ils flânent, s'assoient, se
##    couchent ; quand on passe près d'eux, ils viennent renifler et remuent la queue ;
##  - chats : sur les murets, les rebords de fenêtres, les toits ; ils nous ignorent royalement ;
##  - rats apprivoisés (sur les caisses) : petits, mignons, curieux ;
##  - pigeons : en bandes sur les places ; ils s'envolent si l'on court vers eux, puis reviennent ;
##  - mouettes : sur les quais et les toits ; certaines tournent en planant au-dessus du port.
## Avec le Babillard (set_babil(true)), les animaux proches du joueur parlent (bulles).
##
## API :
##   setup(main_node, island)          island : le nœud de l'île (son « ile.height(x, z) » si présent)
##   populate([[espece, Vector3 au sol (monde), rayon_de_balade], …])   (60 animaux au plus)
##   set_babil(on)                     clear()        count(espece := "") -> int
## Les sons : main.sfx(nom, position) : aboiement, aboiement_petit, chat_miaou, pigeon.

const A = preload("res://scripts/animaux_v75.gd")
const TEXTES_PATH := "res://scripts/pnj/boucan_textes_v75.gd"
const MAX_ANIMAUX: int = 60
const ACTIVE_R: float = 70.0
const BABIL_R: float = 8.0
const SEA_Y: float = -0.42

const FALLBACK := {
	"chien": ["Tu sens le saucisson. Je dis ça, je dis rien.", "On joue ? On joue ? On joue ?", "Ce poteau, c'est mon journal du matin.",
		"J'ai enterré un os en 2019. Je cherche encore.", "Gratte derrière l'oreille. Non, l'autre. VOILÀ."],
	"chat": ["Tu peux passer. Je t'autorise.", "Je ne dors pas. Je surveille la ville avec les yeux fermés.", "Ce muret est à moi. La ville aussi.",
		"Un humain. Encore un. Soupir.", "Si tu as du poisson, on peut discuter."],
	"rat": ["Bonjour ! Tu as un bout de fromage ? Même un petit ?", "On n'est pas des rats d'égout, nous. On est des rats de CALE.",
		"Je fais partie du groupe, moi aussi. Je joue du triangle.", "Ma moustache me dit que tu es gentil."],
	"pigeon": ["Rou-rou. Traduction : donne du pain.", "On s'envole pas, on fait une pause aérienne.", "Ce banc, c'est notre salle de réunion.",
		"Rou ? Rou. Rouuu. (C'est très profond, en pigeon.)"],
	"mouette": ["C'EST À MOI ! Ah non, c'est un caillou.", "Je vole, je crie, je repars. Métier : mouette.", "Les frites, c'est par où ?",
		"Le port, c'est mon royaume. Les poubelles, mon garde-manger."],
}

const BANDANAS := [Color(0.78, 0.08, 0.06), Color(0.08, 0.08, 0.09), Color(0.12, 0.28, 0.72), Color(0.12, 0.5, 0.2),
	Color(0.5, 0.15, 0.6), Color(0.95, 0.75, 0.1), Color(0.9, 0.35, 0.55)]
const DOG_COATS := [
	{"base": Color(0.55, 0.38, 0.22), "tache": Color(0.93, 0.9, 0.84), "taches": 0.3, "ventre": Color(0.92, 0.88, 0.8)},
	{"base": Color(0.08, 0.07, 0.07), "ventre": Color(0.55, 0.36, 0.2), "museau_c": Color(0.55, 0.36, 0.2), "museau_k": 0.8},
	{"base": Color(0.92, 0.9, 0.85), "tache": Color(0.3, 0.2, 0.13), "taches": 0.28, "taches_f": 5.0},
	{"base": Color(0.42, 0.4, 0.38), "ventre": Color(0.75, 0.73, 0.7), "hirsute": 0.7},
	{"base": Color(0.78, 0.58, 0.3), "ventre": Color(0.92, 0.82, 0.62)},
	{"base": Color(0.1, 0.09, 0.09), "tache": Color(0.95, 0.94, 0.92), "taches": 0.18, "ventre": Color(0.95, 0.94, 0.92), "chaussettes": true},
	{"base": Color(0.68, 0.32, 0.12), "ventre": Color(0.88, 0.62, 0.4), "hirsute": 0.4},
	{"base": Color(0.3, 0.22, 0.16), "tache": Color(0.12, 0.09, 0.07), "taches": 0.4, "taches_f": 9.0, "ventre": Color(0.5, 0.38, 0.26)},
]
const CAT_COATS := [
	{"base": Color(0.75, 0.48, 0.22), "tigre": 0.8, "rayure": Color(0.5, 0.28, 0.1), "ventre": Color(0.95, 0.88, 0.75)},
	{"base": Color(0.45, 0.45, 0.44), "tigre": 0.8, "rayure": Color(0.18, 0.18, 0.18), "ventre": Color(0.8, 0.78, 0.74), "oeil": Color(0.4, 0.75, 0.3)},
	{"base": Color(0.06, 0.06, 0.07), "ventre": Color(0.08, 0.08, 0.09), "oeil": Color(0.95, 0.75, 0.15)},
	{"base": Color(0.07, 0.07, 0.08), "tache": Color(0.95, 0.95, 0.93), "chaussettes": true, "ventre": Color(0.95, 0.95, 0.93), "museau_c": Color(0.95, 0.95, 0.93), "oeil": Color(0.85, 0.8, 0.2)},
	{"base": Color(0.94, 0.93, 0.9), "ventre": Color(0.97, 0.96, 0.94), "oeil": Color(0.35, 0.6, 0.95)},
	{"base": Color(0.95, 0.93, 0.88), "tache": Color(0.85, 0.5, 0.2), "taches": 0.35, "taches_f": 6.0, "bout_blanc": false},
]
const RAT_COATS := [
	{"base": Color(0.95, 0.94, 0.92), "tache": Color(0.32, 0.27, 0.24), "capuche": true},
	{"base": Color(0.5, 0.48, 0.47), "ventre": Color(0.85, 0.83, 0.8)},
	{"base": Color(0.52, 0.4, 0.28), "ventre": Color(0.85, 0.8, 0.72)},
	{"base": Color(0.97, 0.96, 0.95), "albinos": true},
	{"base": Color(0.95, 0.94, 0.92), "tache": Color(0.08, 0.08, 0.08), "capuche": true},
]
const PIGEON_COATS := [
	{},
	{"base": Color(0.32, 0.33, 0.38), "aile": Color(0.38, 0.38, 0.42)},
	{"base": Color(0.45, 0.33, 0.26), "aile": Color(0.55, 0.42, 0.33), "tete": Color(0.42, 0.3, 0.24)},
	{"base": Color(0.8, 0.8, 0.8), "aile": Color(0.85, 0.85, 0.84), "tete": Color(0.75, 0.75, 0.76)},
]

static var _textes: Dictionary = {}
static var _textes_loaded: bool = false

var main: Node
var island: Node
var babil: bool = false
var animals: Array = []
var _rng := RandomNumberGenerator.new()
var _say_t: float = 0.0
var _excl: Array[RID] = []
var _excl_t: float = 0.0
var _last_pp: Vector3 = Vector3.INF
var _player_speed: float = 0.0
var _flap_t: float = 0.0


func setup(main_node: Node, island_node: Node = null) -> void:
	main = main_node
	island = island_node
	name = "Faune_v75"
	_rng.seed = 7500


func set_babil(on: bool) -> void:
	babil = on
	if not on:
		for a in animals:
			var b: Label3D = a.get("bubble")
			if b != null:
				b.visible = false


func clear() -> void:
	for a in animals:
		if is_instance_valid(a["node"]):
			(a["node"] as Node3D).queue_free()
	animals.clear()


func count(espece: String = "") -> int:
	var n: int = 0
	for a in animals:
		if espece == "" or str(a["esp"]) == espece:
			n += 1
	return n


## Les animaux : [espece, position au sol (monde), rayon de balade].
func populate(list: Array) -> void:
	for e in list:
		if animals.size() >= MAX_ANIMAUX:
			push_warning("faune_v75 : plus de %d animaux, le reste est ignoré" % MAX_ANIMAUX)
			break
		if not (e is Array) or (e as Array).size() < 2:
			continue
		var esp: String = str(e[0])
		var at: Vector3 = e[1]
		var r: float = float(e[2]) if (e as Array).size() > 2 else 3.0
		_add(esp, at, r)


func _add(esp: String, at: Vector3, r: float) -> void:
	var v: Dictionary = _variant(esp, at)
	var node: Node3D = A.build(esp, v)
	add_child(node)
	var gy: float = _terrain(at.x, at.z)
	var perched: bool = gy > -1e8 and at.y - gy > 0.6
	if esp == "mouette" and r >= 12.0:
		perched = false
	node.global_position = at
	var yaw: float = _rng.randf() * TAU
	node.rotation.y = yaw
	var a := {"node": node, "esp": esp, "home": at, "r": r, "pos": at, "yaw": yaw, "goal": at, "state": "idle", "t": _rng.randf_range(0.5, 4.0),
		"clock": _rng.randf() * 10.0, "speed": 0.0, "bubble": null, "bubble_t": 0.0, "say_cd": _rng.randf_range(2.0, 8.0), "wag": 0.0,
		"perch": perched, "cd": 0.0, "size": float(v.get("taille", 1.0)), "fly_from": at, "fly_to": at, "fly_t": 0.0, "fly_T": 1.0, "circle": false}
	match esp:
		"chien":
			a["state"] = ["idle", "assis", "couche", "marche"][_rng.randi() % 4]
		"chat":
			a["state"] = "assis" if _rng.randf() < 0.55 else "couche"
		"mouette":
			if r >= 12.0:
				# elle tourne au-dessus du port
				a["circle"] = true
				a["state"] = "plane"
				a["home"] = at + Vector3.UP * (0.0 if at.y - maxf(gy, SEA_Y) > 6.0 else 14.0)
				a["t"] = _rng.randf() * TAU
		"pigeon":
			a["state"] = "picore" if _rng.randf() < 0.5 else "idle"
	animals.append(a)


func _variant(esp: String, at: Vector3) -> Dictionary:
	var seed_i: int = int(absf(at.x * 13.1 + at.z * 7.7)) % 997 + animals.size() * 31
	_rng.seed = seed_i + 7500
	var v: Dictionary = {}
	match esp:
		"chien":
			v = (DOG_COATS[_rng.randi() % DOG_COATS.size()] as Dictionary).duplicate()
			v["taille"] = snappedf(_rng.randf_range(0.6, 1.25), 0.05)
			v["oreilles"] = ["dresse", "tombante", "mixte", "tombante"][_rng.randi() % 4]
			v["queue"] = ["courbe", "droite", "enroulee"][_rng.randi() % 3]
			v["museau"] = snappedf(_rng.randf_range(0.8, 1.25), 0.05)
			v["pattes"] = snappedf(_rng.randf_range(0.8, 1.1), 0.05)
			if _rng.randf() < 0.55:
				v["bandana"] = BANDANAS[_rng.randi() % BANDANAS.size()]
			v["seed"] = _rng.randi() % 50
		"chat":
			v = (CAT_COATS[_rng.randi() % CAT_COATS.size()] as Dictionary).duplicate()
			v["taille"] = snappedf(_rng.randf_range(0.85, 1.1), 0.05)
			v["seed"] = _rng.randi() % 50
		"rat":
			v = (RAT_COATS[_rng.randi() % RAT_COATS.size()] as Dictionary).duplicate()
			v["taille"] = snappedf(_rng.randf_range(0.85, 1.1), 0.05)
		"pigeon":
			v = (PIGEON_COATS[_rng.randi() % PIGEON_COATS.size()] as Dictionary).duplicate()
		"mouette":
			v = {}
	_rng.randomize()
	return v


# =================================================================== sol et joueur

func _terrain(x: float, z: float) -> float:
	if island != null and island.get("ile") != null and island.ile != null and island.ile.has_method("height"):
		if not island.ile.has_method("contains") or bool(island.ile.contains(x, z)):
			return float(island.ile.height(x, z))
	if main != null and main.has_method("_height_at"):
		return float(main._height_at(x, z))
	return -1e9


## Le sol sous un point (les caisses, les quais, les toits comptent) ; à défaut, le terrain.
func _ground(p: Vector3, ref_y: float) -> float:
	if is_inside_tree():
		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, ref_y + 0.8, p.z), Vector3(p.x, ref_y - 2.5, p.z), 1, _excl)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			return float((hit.position as Vector3).y)
	var g: float = _terrain(p.x, p.z)
	if g > -1e8 and absf(g - ref_y) < 1.5:
		return g
	return -1e9


func _player_feet() -> Vector3:
	if main == null:
		return Vector3.ZERO
	if main.xr_active:
		if main.get("vr_body") != null and main.vr_body != null:
			return main.vr_body.global_position
		return main._player_pos_v27() + Vector3.DOWN * 1.6
	return main.pc_root.global_position


func _refresh_excl(delta: float) -> void:
	_excl_t -= delta
	if _excl_t > 0.0:
		return
	_excl_t = 1.0
	_excl.clear()
	for b in [main.get("pc_body"), main.get("vr_body")]:
		if b != null and is_instance_valid(b):
			_excl.append((b as CollisionObject3D).get_rid())


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or animals.is_empty():
		return
	var pp: Vector3 = _player_feet()
	if _last_pp != Vector3.INF and delta > 0.0:
		var mv: float = Vector2(pp.x - _last_pp.x, pp.z - _last_pp.z).length() / delta
		_player_speed = lerpf(_player_speed, minf(mv, 20.0), clampf(delta * 6.0, 0.0, 1.0))
	_last_pp = pp
	_refresh_excl(delta)
	_say_t = maxf(_say_t - delta, 0.0)
	_flap_t = maxf(_flap_t - delta, 0.0)
	var paused: bool = not bool(main.get("game_started")) or (main.get("game_menu") != null and main.game_menu != null and bool(main.game_menu.opened))
	for a in animals:
		var node: Node3D = a["node"]
		if not is_instance_valid(node):
			continue
		var pos: Vector3 = a["pos"]
		var d: float = pos.distance_to(pp)
		if d > ACTIVE_R:
			if node.visible:
				node.visible = false
			continue
		if not node.visible:
			node.visible = true
		if paused:
			continue
		a["clock"] = float(a["clock"]) + delta
		match str(a["esp"]):
			"chien":
				_tick_dog(a, delta, pp, d)
			"chat":
				_tick_cat(a, delta, pp, d)
			"rat":
				_tick_rat(a, delta, pp, d)
			"pigeon", "mouette":
				_tick_bird(a, delta, pp, d)
		node.global_position = a["pos"]
		node.rotation.y = lerp_angle(node.rotation.y, float(a["yaw"]), clampf(delta * 8.0, 0.0, 1.0))
		A.animate(node, float(a["clock"]), float(a["speed"]), _pose(a), float(a["wag"]), delta)
		_bubble_tick(a, delta, d)


func _pose(a: Dictionary) -> String:
	match str(a["state"]):
		"assis":
			return "assis"
		"couche":
			return "couche"
		"renifle":
			return "renifle"
		"aboie":
			return "aboie"
		"picore":
			return "picore"
		"envol", "vol", "retour":
			return "vol"
		"plane":
			return "plane" if sin(float(a["clock"]) * 0.7) > -0.3 else "vol"
	return ""


## Un pas vers « goal » (au sol) ; renvoie false s'il est bloqué (mur, trou, eau profonde).
func _step(a: Dictionary, goal: Vector3, sp: float, delta: float) -> bool:
	var pos: Vector3 = a["pos"]
	var to: Vector3 = goal - pos
	to.y = 0.0
	var dist: float = to.length()
	if dist < 0.05:
		a["speed"] = 0.0
		return true
	var dir: Vector3 = to / dist
	var stepv: float = minf(sp * delta, dist)
	var np: Vector3 = pos + dir * stepv
	var h: float = 0.25 * float(a["size"])
	if is_inside_tree():
		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * h, pos + Vector3.UP * h + dir * (0.3 + stepv), 1, _excl)
		if not space.intersect_ray(q).is_empty():
			a["speed"] = 0.0
			return false
	var gy: float = _ground(np, pos.y)
	if gy < -1e8 or gy - pos.y > 0.35 or pos.y - gy > 0.6:
		a["speed"] = 0.0
		return false
	if SEA_Y - gy > 0.3 and gy < SEA_Y:
		a["speed"] = 0.0
		return false
	a["pos"] = Vector3(np.x, gy, np.z)
	a["yaw"] = atan2(dir.x, dir.z)
	a["speed"] = sp
	return true


func _pick_goal(a: Dictionary) -> void:
	var home: Vector3 = a["home"]
	var r: float = float(a["r"])
	var ang: float = randf() * TAU
	var k: float = sqrt(randf()) * r
	a["goal"] = home + Vector3(cos(ang) * k, 0, sin(ang) * k)


# --------------------------------------------------------------- les chiens

func _tick_dog(a: Dictionary, delta: float, pp: Vector3, d: float) -> void:
	a["t"] = float(a["t"]) - delta
	a["cd"] = maxf(float(a["cd"]) - delta, 0.0)
	var st: String = a["state"]
	a["wag"] = lerpf(float(a["wag"]), 1.0 if st in ["renifle", "approche", "aboie"] else 0.25, clampf(delta * 2.0, 0.0, 1.0))
	var home: Vector3 = a["home"]
	var near_home: bool = Vector2(pp.x - home.x, pp.z - home.z).length() < float(a["r"]) + 7.0
	# le joueur passe près : on vient le renifler
	if st in ["idle", "assis", "couche", "marche"] and d < 6.0 and float(a["cd"]) <= 0.0 and near_home and not bool(a["perch"]):
		a["state"] = "approche"
		a["t"] = 6.0
		st = "approche"
	match st:
		"approche":
			var to: Vector3 = pp - (a["pos"] as Vector3)
			to.y = 0.0
			if to.length() < 1.0 or float(a["t"]) <= 0.0:
				a["state"] = "renifle"
				a["t"] = randf_range(2.0, 3.5)
				a["speed"] = 0.0
				a["yaw"] = atan2(to.x, to.z)
				if randf() < 0.5:
					_bark(a, false)
			else:
				var ok: bool = _step(a, pp - to.normalized() * 0.8, 2.6 * float(a["size"]), delta)
				if not ok:
					a["state"] = "idle"
					a["t"] = 2.0
					a["cd"] = 20.0
		"renifle":
			var to2: Vector3 = pp - (a["pos"] as Vector3)
			a["yaw"] = atan2(to2.x, to2.z)
			a["speed"] = 0.0
			if float(a["t"]) <= 0.0 or d > 3.5:
				a["state"] = "marche" if randf() < 0.5 else "assis"
				a["t"] = randf_range(3.0, 7.0)
				a["cd"] = randf_range(25.0, 45.0)
				_pick_goal(a)
		"aboie":
			a["speed"] = 0.0
			if float(a["t"]) <= 0.0:
				a["state"] = "idle"
				a["t"] = randf_range(2.0, 5.0)
		"marche":
			if bool(a["perch"]):
				a["state"] = "idle"
			else:
				var ok2: bool = _step(a, a["goal"], 0.95 * sqrt(float(a["size"])), delta)
				var reached: bool = Vector2((a["goal"] as Vector3).x - (a["pos"] as Vector3).x, (a["goal"] as Vector3).z - (a["pos"] as Vector3).z).length() < 0.3
				if reached or not ok2 or float(a["t"]) <= -12.0:
					a["state"] = ["idle", "assis", "couche", "idle"][randi() % 4]
					a["t"] = randf_range(4.0, 12.0)
					a["speed"] = 0.0
		_:
			a["speed"] = 0.0
			if float(a["t"]) <= 0.0:
				var r: float = randf()
				if r < 0.45:
					a["state"] = "marche"
					a["t"] = 0.0
					_pick_goal(a)
				elif r < 0.65:
					a["state"] = "assis"
					a["t"] = randf_range(5.0, 12.0)
				elif r < 0.85:
					a["state"] = "couche"
					a["t"] = randf_range(8.0, 20.0)
				else:
					a["state"] = "aboie"
					a["t"] = 1.2
					if d < 25.0:
						_bark(a, true)


func _bark(a: Dictionary, solo: bool) -> void:
	var small: bool = float(a["size"]) < 0.85
	if main != null and main.has_method("sfx"):
		main.sfx("aboiement_petit" if small else "aboiement", (a["pos"] as Vector3) + Vector3.UP * 0.5, -4.0 if solo else -2.0)


# --------------------------------------------------------------- les chats

func _tick_cat(a: Dictionary, delta: float, pp: Vector3, d: float) -> void:
	a["t"] = float(a["t"]) - delta
	a["cd"] = maxf(float(a["cd"]) - delta, 0.0)
	a["wag"] = 0.0
	var st: String = a["state"]
	# il nous ignore… mais il miaule parfois quand on passe
	if d < 4.0 and float(a["cd"]) <= 0.0:
		a["cd"] = randf_range(25.0, 50.0)
		if randf() < 0.6 and main != null and main.has_method("sfx"):
			main.sfx("chat_miaou", (a["pos"] as Vector3) + Vector3.UP * 0.3, -6.0)
	match st:
		"marche":
			var ok: bool = _step(a, a["goal"], 0.6, delta)
			var reached: bool = Vector2((a["goal"] as Vector3).x - (a["pos"] as Vector3).x, (a["goal"] as Vector3).z - (a["pos"] as Vector3).z).length() < 0.2
			if reached or not ok or float(a["t"]) <= -10.0:
				a["state"] = "assis" if randf() < 0.5 else "couche"
				a["t"] = randf_range(10.0, 30.0)
				a["speed"] = 0.0
		_:
			a["speed"] = 0.0
			if float(a["t"]) <= 0.0:
				if not bool(a["perch"]) and randf() < 0.4:
					a["state"] = "marche"
					a["t"] = 0.0
					_pick_goal(a)
				else:
					a["state"] = "couche" if st == "assis" else "assis"
					a["t"] = randf_range(10.0, 30.0)
					# un regard ailleurs, très digne
					a["yaw"] = float(a["yaw"]) + randf_range(-1.2, 1.2)


# --------------------------------------------------------------- les rats

func _tick_rat(a: Dictionary, delta: float, pp: Vector3, d: float) -> void:
	a["t"] = float(a["t"]) - delta
	a["wag"] = 0.0
	var st: String = a["state"]
	match st:
		"marche":
			var lim: float = 0.35 if bool(a["perch"]) else float(a["r"])
			var ok: bool = _step(a, a["goal"], 0.45, delta)
			var reached: bool = Vector2((a["goal"] as Vector3).x - (a["pos"] as Vector3).x, (a["goal"] as Vector3).z - (a["pos"] as Vector3).z).length() < 0.05
			if reached or not ok or float(a["t"]) <= -4.0 or Vector2((a["pos"] as Vector3).x - (a["home"] as Vector3).x, (a["pos"] as Vector3).z - (a["home"] as Vector3).z).length() > lim + 0.2:
				a["state"] = "idle"
				a["t"] = randf_range(0.8, 3.0)
				a["speed"] = 0.0
		_:
			a["speed"] = 0.0
			if d < 3.0:
				# curieux : il se tourne vers nous et se dresse un peu
				var to: Vector3 = pp - (a["pos"] as Vector3)
				a["yaw"] = atan2(to.x, to.z)
			if float(a["t"]) <= 0.0:
				a["state"] = "marche"
				a["t"] = 0.0
				var home: Vector3 = a["home"]
				var r: float = 0.3 if bool(a["perch"]) else float(a["r"])
				var ang: float = randf() * TAU
				a["goal"] = home + Vector3(cos(ang), 0, sin(ang)) * randf() * r


# --------------------------------------------------------------- les oiseaux

func _tick_bird(a: Dictionary, delta: float, pp: Vector3, d: float) -> void:
	a["t"] = float(a["t"]) - delta
	var gull: bool = str(a["esp"]) == "mouette"
	var st: String = a["state"]
	if bool(a["circle"]):
		# la mouette qui plane en rond au-dessus du port
		var home: Vector3 = a["home"]
		var r: float = float(a["r"])
		var w: float = 6.5 / maxf(r, 1.0)
		var ph: float = float(a["clock"]) * w + home.x * 0.1
		var p := home + Vector3(cos(ph) * r, sin(float(a["clock"]) * 0.4) * 1.5, sin(ph) * r)
		var vel: Vector3 = Vector3(-sin(ph), 0, cos(ph))
		a["pos"] = p
		a["yaw"] = atan2(vel.x, vel.z)
		a["speed"] = 0.0
		var node: Node3D = a["node"]
		node.rotation.z = lerpf(node.rotation.z, -0.35, clampf(delta * 2.0, 0.0, 1.0))
		return
	match st:
		"envol":
			# décollage : vers le haut et au loin
			a["fly_t"] = float(a["fly_t"]) + delta
			var k: float = clampf(float(a["fly_t"]) / float(a["fly_T"]), 0.0, 1.0)
			var from: Vector3 = a["fly_from"]
			var to: Vector3 = a["fly_to"]
			var p2: Vector3 = from.lerp(to, k)
			p2.y = lerpf(from.y, to.y, sqrt(k)) + sin(k * PI) * 1.0
			var dv: Vector3 = to - from
			a["yaw"] = atan2(dv.x, dv.z)
			a["pos"] = p2
			a["speed"] = 0.0
			if k >= 1.0:
				a["state"] = "vol"
				a["t"] = randf_range(4.0, 8.0)
		"vol":
			# il tourne en l'air un moment
			var c: Vector3 = a["fly_to"]
			var ph2: float = float(a["clock"]) * (1.3 if not gull else 0.8)
			var p3: Vector3 = c + Vector3(cos(ph2) * 3.0, sin(ph2 * 0.7) * 0.4, sin(ph2) * 3.0)
			a["yaw"] = atan2(-sin(ph2), cos(ph2))
			a["pos"] = (a["pos"] as Vector3).lerp(p3, clampf(delta * 2.0, 0.0, 1.0))
			if float(a["t"]) <= 0.0:
				# retour près de la place
				a["state"] = "retour"
				a["fly_from"] = a["pos"]
				var home2: Vector3 = a["home"]
				var ang2: float = randf() * TAU
				var land: Vector3 = home2 + Vector3(cos(ang2), 0, sin(ang2)) * randf() * float(a["r"])
				var gy: float = _ground(land, home2.y)
				land.y = gy if gy > -1e8 else home2.y
				a["goal"] = land
				a["fly_t"] = 0.0
				a["fly_T"] = maxf((a["pos"] as Vector3).distance_to(land) / 5.0, 1.0)
		"retour":
			a["fly_t"] = float(a["fly_t"]) + delta
			var k2: float = clampf(float(a["fly_t"]) / float(a["fly_T"]), 0.0, 1.0)
			var from2: Vector3 = a["fly_from"]
			var to2: Vector3 = a["goal"]
			var p4: Vector3 = from2.lerp(to2, k2)
			p4.y = lerpf(from2.y, to2.y, k2 * k2)
			var dv2: Vector3 = to2 - from2
			a["yaw"] = atan2(dv2.x, dv2.z)
			a["pos"] = p4
			if k2 >= 1.0:
				a["state"] = "idle"
				a["t"] = randf_range(1.0, 3.0)
		_:
			# au sol : marcher, picorer, regarder ; s'envoler si on court vers lui
			var scared: bool = (d < 3.5 and _player_speed > 3.0) or d < 1.3
			if scared and not (main != null and bool(main.get("xr_active")) and d > 1.0 and _player_speed < 1.0):
				_take_off(a, pp)
				return
			if st == "marche":
				var ok: bool = _step(a, a["goal"], 0.35 if not gull else 0.5, delta)
				var reached: bool = Vector2((a["goal"] as Vector3).x - (a["pos"] as Vector3).x, (a["goal"] as Vector3).z - (a["pos"] as Vector3).z).length() < 0.08
				if reached or not ok or float(a["t"]) <= -6.0:
					a["state"] = "picore" if randf() < 0.55 else "idle"
					a["t"] = randf_range(1.5, 5.0)
					a["speed"] = 0.0
			else:
				a["speed"] = 0.0
				if float(a["t"]) <= 0.0:
					if randf() < 0.6:
						a["state"] = "marche"
						a["t"] = 0.0
						var home3: Vector3 = a["home"]
						var r3: float = minf(float(a["r"]), 4.0) if not bool(a["perch"]) else 0.4
						var ang3: float = randf() * TAU
						a["goal"] = home3 + Vector3(cos(ang3), 0, sin(ang3)) * randf() * r3
					else:
						a["state"] = "picore" if randf() < 0.5 else "idle"
						a["t"] = randf_range(1.5, 4.0)


func _take_off(a: Dictionary, pp: Vector3) -> void:
	var pos: Vector3 = a["pos"]
	var away: Vector3 = pos - pp
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	away = away.rotated(Vector3.UP, randf_range(-0.6, 0.6))
	a["state"] = "envol"
	a["fly_from"] = pos
	a["fly_to"] = pos + away * randf_range(9.0, 15.0) + Vector3.UP * randf_range(4.0, 8.0)
	a["fly_t"] = 0.0
	a["fly_T"] = randf_range(1.6, 2.4)
	# tout le groupe s'envole (les voisins proches), un seul bruit d'ailes
	if _flap_t <= 0.0 and main != null and main.has_method("sfx"):
		_flap_t = 1.5
		main.sfx("pigeon", pos + Vector3.UP * 0.3, -2.0)
	for b in animals:
		if is_same(b, a) or str(b["esp"]) != str(a["esp"]) or not (str(b["state"]) in ["idle", "picore", "marche"]) or bool(b["circle"]):
			continue
		if (b["pos"] as Vector3).distance_to(pos) < 4.0:
			_take_off_one(b, pp)


func _take_off_one(b: Dictionary, pp: Vector3) -> void:
	var pos: Vector3 = b["pos"]
	var away: Vector3 = pos - pp
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	away = away.rotated(Vector3.UP, randf_range(-0.7, 0.7))
	b["state"] = "envol"
	b["fly_from"] = pos
	b["fly_to"] = pos + away * randf_range(9.0, 15.0) + Vector3.UP * randf_range(4.0, 8.0)
	b["fly_t"] = -randf_range(0.0, 0.35)
	b["fly_T"] = randf_range(1.6, 2.4)


# =================================================================== le Babillard

static func _all_texts() -> Dictionary:
	if _textes_loaded:
		return _textes
	_textes_loaded = true
	if ResourceLoader.exists(TEXTES_PATH):
		var scr: Script = load(TEXTES_PATH)
		if scr != null:
			_textes = scr.get_script_constant_map()
	return _textes


## Une réplique d'animal (boucan_textes_v75.gd : ANIMAUX[espece]) ou une réplique de secours.
static func line_for(espece: String) -> String:
	var all: Dictionary = _all_texts()
	var arr: Array = []
	var an: Variant = all.get("ANIMAUX", {})
	if an is Dictionary and (an as Dictionary).has(espece):
		var v: Variant = (an as Dictionary)[espece]
		if v is Array:
			arr = v
		elif v is String:
			arr = [v]
	if arr.is_empty():
		arr = FALLBACK.get(espece, [])
	if arr.is_empty():
		return ""
	var e: Variant = arr[randi() % arr.size()]
	if e is Dictionary:
		return str((e as Dictionary).get("texte", (e as Dictionary).get("text", "")))
	if e is Array and not (e as Array).is_empty():
		return str((e as Array)[(e as Array).size() - 1])
	return str(e)


func _bubble_tick(a: Dictionary, delta: float, d: float) -> void:
	var b: Label3D = a.get("bubble")
	if b != null and float(a["bubble_t"]) > 0.0:
		a["bubble_t"] = float(a["bubble_t"]) - delta
		b.modulate.a = clampf(float(a["bubble_t"]), 0.0, 1.0)
		if float(a["bubble_t"]) <= 0.0:
			b.visible = false
	if not babil:
		return
	a["say_cd"] = maxf(float(a["say_cd"]) - delta, 0.0)
	if d > BABIL_R or float(a["say_cd"]) > 0.0 or _say_t > 0.0:
		return
	if str(a["state"]) in ["envol", "vol", "retour"] or bool(a["circle"]):
		return
	var t: String = line_for(str(a["esp"]))
	if t == "":
		return
	say(a, t)


func say(a: Dictionary, text: String) -> void:
	var b: Label3D = a.get("bubble")
	if b == null:
		b = Label3D.new()
		b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b.font_size = 32
		b.pixel_size = 0.0024
		b.outline_size = 10
		b.width = 520
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.no_depth_test = true
		b.modulate = Color(1.0, 0.95, 0.8)
		b.outline_modulate = Color(0.12, 0.08, 0.05)
		var hh: float = {"chien": 1.0, "chat": 0.65, "rat": 0.35, "pigeon": 0.5, "mouette": 0.7}.get(str(a["esp"]), 0.8)
		b.position = Vector3(0, hh * maxf(float(a["size"]), 0.8), 0)
		(a["node"] as Node3D).add_child(b)
		a["bubble"] = b
	b.text = text.replace("{joueur}", "toi")
	b.visible = true
	b.modulate.a = 1.0
	a["bubble_t"] = clampf(1.8 + text.length() * 0.055, 3.0, 7.0)
	a["say_cd"] = randf_range(14.0, 24.0)
	_say_t = randf_range(3.0, 5.0)

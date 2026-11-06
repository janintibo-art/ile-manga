extends Node3D
## V103 : la vie sur la mer. Des navettes font la tournée des îles (cinq lignes), avec un
## capitaine à la barre et des passagers assis à l'arrière ; à chaque escale, elles s'amarrent
## le long du ponton (côté opposé à la barque du joueur), les passagers descendent, ceux qui
## attendaient sur le ponton montent, et le bateau repart en marche arrière avant de virer.
## Sur les pontons, des gens attendent le bateau (ils regardent au loin, bavardent) ; d'autres
## rentrent chez eux ou arrivent de l'île. Des voiliers de plaisance tirent des bords au large.
## La nuit, les navettes restent à quai (feux allumés) et les pontons se vident.
##
## Les bateaux évitent les côtes : une grille de la mer (15 m) est mesurée au démarrage, les
## routes sont cherchées (A*) puis lissées. Les personnages ne sont créés que près du joueur
## (les échanges loin de lui se font sans qu'on les voie).
##
## API : setup(main) ; boats (les navettes et les voiliers) ; docks_ok (les pontons desservis) ;
##       people_count() ; force_near(on) pour les essais.

const Kit = preload("res://scripts/azur_kit_v56.gd")
const Figurant = preload("res://scripts/pnj/figurant_v81.gd")
const Gens = preload("res://scripts/pnj/maisons_habitants_v81.gd")

const WATER: float = -0.42
const DECK_Y: float = 1.0
const NEAR: float = 220.0
const FAR: float = 260.0
const CRUISE: float = 7.0
const TURN: float = 0.45
const ACC: float = 1.4
const L: float = 10.0
const B: float = 3.2
const DECK: float = 0.95                       # le pont, au-dessus de la ligne de flottaison
const SEATS := [Vector3(-0.72, DECK, 1.75), Vector3(0.72, DECK, 1.75), Vector3(-0.72, DECK, 3.15), Vector3(0.72, DECK, 3.15)]
const GANG_Z: float = 0.1
const GRID_N: int = 200
const GRID_CELL: float = 15.0
const GRID_O := Vector2(-1500.0, -1100.0)

const LIGNES := [
	{"nom": "La Libellule", "coque": "turquoise", "toile": "turquoise", "escales": ["Ponton_village", "Ponton_elfes", "Ponton_village", "Ponton_nains"]},
	{"nom": "Le Goéland", "coque": "rouge", "toile": "rouge", "escales": ["Ponton_azur", "Ponton_carene", "Ponton_montjoie"]},
	{"nom": "La Sterne", "coque": "vert", "toile": "vert", "escales": ["Ponton_arcanelle", "Ponton_larsen", "Ponton_astralys"]},
	{"nom": "Le Pélican", "coque": "orange", "toile": "jaune", "escales": ["Ponton_boucan", "Ponton_braise", "Ponton_hautefond"]},
	{"nom": "La Mouette", "coque": "bleu", "toile": "bleu", "escales": ["Ponton_tazira", "Ponton_ramure", "Ponton_cliquetis"]},
]
const VOILIERS := [
	{"nom": "Brise", "coque": "blanc", "tour": ["Ponton_village", "Ponton_azur", "Ponton_elfes"]},
	{"nom": "Alizé", "coque": "bleu", "tour": ["Ponton_arcanelle", "Ponton_nains", "Ponton_moai"]},
	{"nom": "Zéphyr", "coque": "creme", "tour": ["Ponton_boucan", "Ponton_montjoie", "Ponton_neo"]},
]
const STYLE_QUAI := {"Ponton_village": ["azur"], "Ponton_elfes": ["elfe"], "Ponton_nains": ["nain"], "Ponton_azur": ["azur"],
	"Ponton_carene": ["carene"], "Ponton_montjoie": ["montjoie"], "Ponton_arcanelle": ["arcanelle"], "Ponton_larsen": ["yourte_fleurs", "yourte_rainville"],
	"Ponton_astralys": ["astralys"], "Ponton_boucan": ["boucan"], "Ponton_braise": ["braise"],
	"Ponton_tazira": ["tazira"], "Ponton_ramure": ["ramure"], "Ponton_cliquetis": ["cliquetis"], "Ponton_hautefond": ["montjoie"]}
const ROLES := ["homme", "femme", "vieux", "vieille", "garcon", "fille", "homme", "femme"]

const PHRASES_QUAI := ["Il arrive quand, ce bateau ?", "Je vais voir ma sœur sur l'autre île.", "Le capitaine est toujours à l'heure. Enfin, presque.",
	"J'ai le mal de mer rien qu'en le regardant.", "Regarde, il arrive ! Ah non, c'est une mouette.", "J'emporte des confitures pour ma tante.",
	"La dernière fois, on a vu des dauphins.", "Une petite traversée, ça fait du bien.", "J'ai oublié mon chapeau. Tant pis !",
	"Il y a du vent aujourd'hui, ça va secouer.", "On s'assoit devant ou derrière ?", "J'adore attendre le bateau. C'est déjà le voyage."]
const PHRASES_BORD := ["Le vent dans les cheveux, c'est le bonheur !", "On arrive bientôt ?", "Regarde comme l'eau est claire !",
	"Je crois que j'ai vu un dauphin.", "Capitaine, on peut aller plus vite ?", "Quelle belle journée pour naviguer.",
	"Je ne me lasse pas de cette vue.", "Tiens bon, on tangue un peu !"]
const PHRASES_ARRIVEE := ["Ah, la terre ferme !", "Merci capitaine !", "Ça, c'était une belle traversée.", "Bon, par où on va maintenant ?"]

var main: Node
var kit
var boats: Array = []                 # navettes et voiliers
var docks: Dictionary = {}            # nom -> état du ponton
var docks_ok: Array = []
var _rng := RandomNumberGenerator.new()
var _grid := PackedByteArray()        # 1 = terre (élargie d'une case)
var _grid_row: int = 0
var _grid_ready: bool = false
var _jobs: Array = []                 # routes à chercher : [bateau, fonction(chemin)]
var _vis_t: float = 0.0
var _force_near: bool = false
var _night: bool = false
var _people: Array = []               # toutes les personnes (données)
var _soft: Texture2D


func setup(main_node: Node) -> void:
	main = main_node
	name = "Trafic_v103"
	_rng.seed = 103
	kit = Kit.new()
	kit.setup(self, main.get("temps_v56"))
	_soft = main._soft_dot_v24() if main.has_method("_soft_dot_v24") else null
	_grid.resize(GRID_N * GRID_N)
	if main.boat_v29 == null:
		return
	for d in main.boat_v29.docks:
		var nm: String = str(d["name"])
		if not STYLE_QUAI.has(nm):
			continue
		var st: Dictionary = _dock_state(d)
		if st.is_empty():
			print("ILE_MANGA_V103: ponton trop peu profond pour une navette : ", nm)
			continue
		docks[nm] = st
		docks_ok.append(nm)
	for li in LIGNES:
		var esc: Array = []
		for e in li["escales"]:
			if docks.has(e):
				esc.append(e)
		if esc.size() < 2:
			continue
		_make_ferry(li, esc)
	for vi in VOILIERS:
		var tour: Array = []
		for e2 in vi["tour"]:
			var p: Vector3 = _offshore(str(e2))
			if p != Vector3.INF:
				tour.append(p)
		if tour.size() >= 2:
			_make_sailboat(vi, tour)
	# les gens qui attendent sur les pontons
	for nm2 in docks:
		var n0: int = 1 + _rng.randi() % 2
		for k in range(n0):
			var p0: Dictionary = _new_person(nm2)
			_put_on_dock(p0, nm2, -1)
	print("ILE_MANGA_V103: ", boats.size(), " bateaux, ", docks.size(), " pontons desservis")


# =================================================================== les pontons

func _find_dock(nm: String) -> Dictionary:
	if main.boat_v29 == null:
		return {}
	for d in main.boat_v29.docks:
		if str(d["name"]) == nm:
			return d
	return {}


func _deep(p: Vector3, lim: float = -1.0) -> bool:
	return main._height_at(p.x, p.z) < lim


## Le poste d'amarrage d'une navette (côté opposé à la barque du joueur si c'est assez profond).
func _dock_state(d: Dictionary) -> Dictionary:
	var axis: Vector3 = d["axis"]
	var side: Vector3 = d["side"]
	var end: Vector3 = d["end"]
	var yaw: float = atan2(axis.x, axis.z)          # l'avant vers la terre
	# le bateau s'amarre l'avant vers la terre, la passerelle (juste derrière la timonerie) au bout
	# du ponton ; s'il n'y a pas assez de fond, il se met un peu plus au large
	for cand in [[-1.0, -1.0], [-1.0, 1.0], [-0.4, -1.0], [-0.4, 1.0], [0.3, -1.0], [0.3, 1.0], [1.0, -1.0], [1.0, 1.0]]:
		var s: float = cand[1]
		var c: Vector3 = end + axis * float(cand[0]) + side * s * (1.2 + B * 0.5 + 0.25)
		if not _deep(c, -0.8) or not _deep(c + axis * 3.5, -0.8) or not _deep(c - axis * 4.0, -0.25):
			continue
		var app: Vector3 = c + axis * 26.0
		var dep: Vector3 = c + axis * 16.0
		if not _deep(app, -2.0) or not _deep(dep, -1.5):
			continue
		c.y = WATER
		app.y = WATER
		dep.y = WATER
		var slots: Array = []
		for k in range(4):
			var along: float = minf(1.6 + float(k / 2) * 1.3, float(d["length"]) - 1.0)
			var lat: float = 0.62 if k % 2 == 0 else -0.62
			slots.append(Vector3(d["start"].x, DECK_Y, d["start"].z) + axis * along + side * lat)
		return {"name": str(d["name"]), "d": d, "s": s, "berth": c, "yaw": yaw, "app": app, "dep": dep, "slots": slots,
			"who": [null, null, null, null], "near": false, "boat": null}
	return {}


func _offshore(nm: String) -> Vector3:
	var d: Dictionary = _find_dock(nm)
	if d.is_empty():
		return Vector3.INF
	for k in [70.0, 55.0, 90.0, 110.0, 40.0]:
		var p: Vector3 = d["end"] + d["axis"] * k
		if _deep(p, -4.0):
			return Vector3(p.x, WATER, p.z)
	return Vector3.INF


# =================================================================== les personnes

func _new_person(dock_name: String) -> Dictionary:
	var styles: Array = STYLE_QUAI.get(dock_name, ["azur"])
	var style: String = str(styles[_rng.randi() % styles.size()])
	var role: String = str(ROLES[_rng.randi() % ROLES.size()])
	var prof: Dictionary = Gens.pick(style, role, _rng).duplicate(true)
	prof["nom"] = Gens.prenom(style, role, _rng)
	var p := {"prof": prof, "ctl": null, "lieu": "", "slot": -1, "seat": -1, "boat": null, "walk": [], "fin": Callable(), "pose": "debout", "speed": 1.15}
	_people.append(p)
	return p


func _forget(p: Dictionary) -> void:
	for i in range(_people.size()):
		if is_same(_people[i], p):
			_people.remove_at(i)
			return


func people_count() -> int:
	var n: int = 0
	for p in _people:
		if p["ctl"] != null and is_instance_valid(p["ctl"]):
			n += 1
	return n


func _npc(p: Dictionary) -> Node3D:
	if p["ctl"] == null or not is_instance_valid(p["ctl"]):
		return null
	return (p["ctl"] as Node).get("npc")


## Crée le corps d'une personne (près du joueur seulement).
func _spawn(p: Dictionary, parent: Node3D, pos: Vector3, face: Vector3, pose: String, lines: Array) -> void:
	if p["ctl"] != null and is_instance_valid(p["ctl"]):
		return
	var ctl: Node = Figurant.spawn(parent, main, p["prof"], pos, face, pose)
	if ctl == null:
		return
	var npc: Node3D = ctl.get("npc")
	# pas d'obstacle : ils ne gênent ni le joueur sur le ponton, ni sa barque
	var body: Node = npc.get_node_or_null("Corps_collision")
	if body != null:
		for c in body.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
	ctl.set("follow", false)
	ctl.set("lines", lines)
	ctl.set("line_every", Vector2(10.0, 20.0))
	npc.visible = not _night
	p["ctl"] = ctl
	p["pose"] = pose


func _despawn(p: Dictionary) -> void:
	if not (p["walk"] as Array).is_empty():
		_finish_walk(p)
	var npc: Node3D = _npc(p)
	if npc != null:
		npc.queue_free()
	p["ctl"] = null


func _put_on_dock(p: Dictionary, dock_name: String, slot: int) -> bool:
	var st: Dictionary = docks[dock_name]
	if slot < 0:
		for k in range(4):
			if st["who"][k] == null:
				slot = k
				break
	if slot < 0:
		return false
	st["who"][slot] = p
	p["lieu"] = dock_name
	p["slot"] = slot
	p["seat"] = -1
	p["boat"] = null
	return true


func _slot_face(st: Dictionary, slot: int) -> Vector3:
	var axis: Vector3 = st["d"]["axis"]
	var side: Vector3 = st["d"]["side"]
	var lat: float = 1.0 if slot % 2 == 0 else -1.0
	# on regarde vers la mer, un peu de biais (vers le voisin d'en face)
	return (axis * 0.8 - side * lat * 0.6).normalized()


func _dock_pose() -> String:
	return ["debout", "bras_croises", "mains_dos", "debout", "bras_croises"][_rng.randi() % 5]


# =================================================================== les bateaux

func _make_ferry(li: Dictionary, esc: Array) -> void:
	var b := {"kind": "navette", "nom": li["nom"], "esc": esc, "i": 0, "etat": "quai", "t": _rng.randf_range(0.0, 22.0),
		"pos": Vector3.ZERO, "yaw": 0.0, "speed": 0.0, "wp": [], "wi": 0, "seats": [null, null, null, null], "captain": null,
		"bob": _rng.randf() * 10.0, "blocked": 0.0, "ignore": 0.0, "near": false, "xchg": 0, "honk": false}
	b["hull"] = _build_ferry_model(li)
	add_child(b["hull"])
	var st: Dictionary = docks[esc[0]]
	b["pos"] = st["berth"]
	b["yaw"] = st["yaw"]
	st["boat"] = b
	b["captain_prof"] = _new_person(esc[0])
	(b["captain_prof"] as Dictionary)["lieu"] = "barre"
	# quelques passagers au départ
	for k in range(_rng.randi() % 3):
		var p: Dictionary = _new_person(esc[0])
		p["lieu"] = "bord"
		p["seat"] = k
		p["boat"] = b
		b["seats"][k] = p
	_apply_boat(b, 0.0)
	boats.append(b)


func _make_sailboat(vi: Dictionary, tour: Array) -> void:
	var b := {"kind": "voilier", "nom": vi["nom"], "tour": tour, "i": 0, "etat": "attend", "t": 0.0, "pos": tour[0], "yaw": _rng.randf() * TAU,
		"speed": 0.0, "wp": [], "wi": 0, "bob": _rng.randf() * 10.0, "blocked": 0.0, "ignore": 0.0, "near": false}
	b["hull"] = _build_sail_model(vi)
	add_child(b["hull"])
	b["skipper_prof"] = _new_person("Ponton_azur")
	(b["skipper_prof"] as Dictionary)["lieu"] = "barre"
	_apply_boat(b, 0.0)
	boats.append(b)
	_ask_path(b, tour[0], tour[1 % tour.size()])


func _forward(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _apply_boat(b: Dictionary, delta: float) -> void:
	b["bob"] = float(b["bob"]) + delta
	var t: float = float(b["bob"])
	var sp: float = float(b["speed"])
	var heel: float = 0.0
	if str(b["kind"]) == "voilier":
		heel = 0.12 + 0.03 * sin(t * 0.5)
	var hull: Node3D = b["hull"]
	var pitch: float = sin(t * 0.9) * 0.012 - clampf(sp / CRUISE, -1.0, 1.0) * 0.02
	var roll: float = sin(t * 0.7 + 1.0) * 0.02 + heel
	var y: float = WATER + sin(t * 1.1) * 0.05
	hull.global_transform = Transform3D(Basis.from_euler(Vector3(pitch, float(b["yaw"]), roll)), Vector3(b["pos"].x, y, b["pos"].z))


# =================================================================== la grille de la mer et les routes

func _grid_step(rows: int) -> void:
	var stop: int = mini(GRID_N, _grid_row + rows)
	for zi in range(_grid_row, stop):
		for xi in range(GRID_N):
			var wx: float = GRID_O.x + (xi + 0.5) * GRID_CELL
			var wz: float = GRID_O.y + (zi + 0.5) * GRID_CELL
			if main._height_at(wx, wz) > -2.5:
				_grid[zi * GRID_N + xi] = 1
	_grid_row = stop
	if _grid_row >= GRID_N:
		# on élargit la terre d'une case (les bateaux restent à distance des côtes)
		var g2 := _grid.duplicate()
		for zi2 in range(GRID_N):
			for xi2 in range(GRID_N):
				if _grid[zi2 * GRID_N + xi2] == 1:
					for dz in [-1, 0, 1]:
						for dx in [-1, 0, 1]:
							var x3: int = xi2 + dx
							var z3: int = zi2 + dz
							if x3 >= 0 and x3 < GRID_N and z3 >= 0 and z3 < GRID_N:
								g2[z3 * GRID_N + x3] = 1
		_grid = g2
		_grid_ready = true


func _cell(p: Vector3) -> int:
	var xi: int = clampi(int((p.x - GRID_O.x) / GRID_CELL), 0, GRID_N - 1)
	var zi: int = clampi(int((p.z - GRID_O.y) / GRID_CELL), 0, GRID_N - 1)
	return zi * GRID_N + xi


func _cell_pos(c: int) -> Vector3:
	return Vector3(GRID_O.x + (c % GRID_N + 0.5) * GRID_CELL, WATER, GRID_O.y + (c / GRID_N + 0.5) * GRID_CELL)


## Peut-on aller tout droit de a à b sans toucher le fond ?
func clear_line(a: Vector3, b: Vector3) -> bool:
	var d: float = Vector2(b.x - a.x, b.z - a.z).length()
	var n: int = maxi(1, int(d / 5.0))
	for i in range(1, n):
		var p: Vector3 = a.lerp(b, float(i) / n)
		if main._height_at(p.x, p.z) > -2.0:
			return false
	return true


func _ask_path(b: Dictionary, from: Vector3, to: Vector3) -> void:
	_jobs.append([b, from, to])
	if str(b["kind"]) == "voilier":
		b["etat"] = "attend"


## A* sur la grille (8 voisins), puis on tend la corde (lignes droites dégagées).
func find_path(from: Vector3, to: Vector3) -> Array:
	if clear_line(from, to):
		return [to]
	var s: int = _cell(from)
	var g: int = _cell(to)
	var n: int = GRID_N * GRID_N
	var cost := PackedFloat32Array()
	cost.resize(n)
	cost.fill(1e20)
	var came := PackedInt32Array()
	came.resize(n)
	came.fill(-1)
	var closed := PackedByteArray()
	closed.resize(n)
	var free_r: float = 3.0
	var heap_f := PackedFloat32Array()
	var heap_c := PackedInt32Array()
	cost[s] = 0.0
	_hpush(heap_f, heap_c, 0.0, s)
	var gx: int = g % GRID_N
	var gz: int = g / GRID_N
	var sx: int = s % GRID_N
	var sz: int = s / GRID_N
	var found: bool = false
	var iters: int = 0
	while heap_c.size() > 0 and iters < 60000:
		iters += 1
		var c: int = _hpop(heap_f, heap_c)
		if closed[c] == 1:
			continue
		closed[c] = 1
		if c == g:
			found = true
			break
		var cx: int = c % GRID_N
		var cz: int = c / GRID_N
		for dz in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				var nx: int = cx + dx
				var nz: int = cz + dz
				if nx < 0 or nz < 0 or nx >= GRID_N or nz >= GRID_N:
					continue
				var nc: int = nz * GRID_N + nx
				if closed[nc] == 1:
					continue
				if _grid[nc] == 1:
					# près du départ et de l'arrivée (au pied des pontons), on passe quand même
					if Vector2(nx - sx, nz - sz).length() > free_r and Vector2(nx - gx, nz - gz).length() > free_r:
						continue
				var step: float = 1.4142 if dx != 0 and dz != 0 else 1.0
				var nv: float = cost[c] + step
				if nv < cost[nc]:
					cost[nc] = nv
					came[nc] = c
					var h: float = Vector2(nx - gx, nz - gz).length() * 1.2
					_hpush(heap_f, heap_c, nv + h, nc)
	if not found:
		return [to]
	var cells: Array = []
	var k: int = g
	while k != -1 and k != s:
		cells.push_front(k)
		k = came[k]
	var pts: Array = [from]
	for c2 in cells:
		pts.append(_cell_pos(c2))
	pts[pts.size() - 1] = to
	# la corde tendue
	var out: Array = []
	var i: int = 0
	while i < pts.size() - 1:
		var j: int = i + 1
		while j + 1 < pts.size() and clear_line(pts[i], pts[j + 1]):
			j += 1
		out.append(pts[j])
		i = j
	return out


func _hpush(f: PackedFloat32Array, c: PackedInt32Array, v: float, id: int) -> void:
	f.append(v)
	c.append(id)
	var i: int = f.size() - 1
	while i > 0:
		var pa: int = (i - 1) / 2
		if f[pa] <= f[i]:
			break
		var tf: float = f[pa]
		f[pa] = f[i]
		f[i] = tf
		var tc: int = c[pa]
		c[pa] = c[i]
		c[i] = tc
		i = pa


func _hpop(f: PackedFloat32Array, c: PackedInt32Array) -> int:
	var top: int = c[0]
	var last: int = f.size() - 1
	f[0] = f[last]
	c[0] = c[last]
	f.resize(last)
	c.resize(last)
	var i: int = 0
	var n: int = f.size()
	while true:
		var l: int = i * 2 + 1
		var r: int = l + 1
		var m: int = i
		if l < n and f[l] < f[m]:
			m = l
		if r < n and f[r] < f[m]:
			m = r
		if m == i:
			break
		var tf: float = f[m]
		f[m] = f[i]
		f[i] = tf
		var tc: int = c[m]
		c[m] = c[i]
		c[i] = tc
		i = m
	return top


# =================================================================== la boucle

func force_near(on: bool) -> void:
	_force_near = on


func _hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _process(delta: float) -> void:
	if main == null:
		return
	delta = minf(delta, 0.1)
	if not _grid_ready:
		_grid_step(3)
	elif not _jobs.is_empty():
		var job: Array = _jobs.pop_front()
		var b: Dictionary = job[0]
		var path: Array = find_path(job[1], job[2])
		_on_path(b, path)
	var h: float = _hour()
	var night: bool = h < 6.0 or h >= 22.0
	if night != _night:
		_night = night
		for p in _people:
			var npc: Node3D = _npc(p)
			if npc != null:
				npc.visible = not _night
	_vis_t -= delta
	if _vis_t <= 0.0:
		_vis_t = 0.5
		_update_visuals()
	for b2 in boats:
		if str(b2["kind"]) == "navette":
			_tick_ferry(b2, delta, h)
		else:
			_tick_sail(b2, delta)
		_apply_boat(b2, delta)
	for p2 in _people:
		if not (p2["walk"] as Array).is_empty():
			_walk_tick(p2, delta)


func _on_path(b: Dictionary, path: Array) -> void:
	if str(b["kind"]) == "voilier":
		b["wp"] = path
		b["wi"] = 0
		b["etat"] = "route"
		return
	var st: Dictionary = docks[b["esc"][int(b["i"])]]
	var wp: Array = path.duplicate()
	wp.append(st["app"])
	wp.append(st["berth"])
	b["wp"] = wp
	b["wi"] = 0
	b["etat"] = "route"


func _player() -> Vector3:
	return main._player_pos_v27()


## Les obstacles devant le bateau : la barque du joueur, L'Hirondelle, le joueur à la nage, les autres
## bateaux. Après 8 s d'attente, on ne s'arrête plus que pour le joueur à la nage (6 s), pour ne
## jamais rester bloqué (un bateau amarré tout près, deux navettes face à face).
func _blocked(b: Dictionary) -> bool:
	var fwd: Vector3 = _forward(float(b["yaw"])) * signf(float(b["speed"]) + 0.01)
	var me: Vector3 = b["pos"]
	var obs: Array = []
	var pl: Vector3 = _player()
	if pl.y < 0.6:
		obs.append([pl, 0.8])
	if float(b["ignore"]) <= 0.0:
		var bt: Node = main.get("boat_v29")
		if bt != null and bt.get("hull") != null:
			obs.append([(bt.hull as Node3D).global_position, float(bt.get("beam")) * 0.5 if bt.get("beam") != null else 1.0])
		var az: Node = main.get("azur_v56")
		if az != null and az.get("ferry") != null and az.ferry != null and az.ferry.get("hull") != null:
			obs.append([(az.ferry.hull as Node3D).global_position, 3.4])
		for o in boats:
			if not is_same(o, b):
				obs.append([o["pos"], B * 0.5])
	for e in obs:
		var rel: Vector3 = (e[0] as Vector3) - me
		rel.y = 0.0
		var ahead: float = rel.dot(fwd)
		if ahead <= 0.0 or ahead > 16.0:
			continue
		var lat: float = (rel - fwd * ahead).length()
		if lat < float(e[1]) + B * 0.5 + 0.5:
			return true
	return false


func _depth_ahead(me: Vector3, yaw: float, dist: float) -> float:
	var p: Vector3 = me + _forward(yaw) * dist
	return main._height_at(p.x, p.z)


func _steer(b: Dictionary, delta: float, cruise: float) -> bool:
	var wp: Array = b["wp"]
	var wi: int = int(b["wi"])
	if wi >= wp.size():
		return true
	var tgt: Vector3 = wp[wi]
	var me: Vector3 = b["pos"]
	var to: Vector3 = tgt - me
	to.y = 0.0
	var d: float = to.length()
	var last: bool = wi == wp.size() - 1 and str(b["kind"]) == "navette"
	if d < (2.0 if last else 9.0):
		b["wi"] = wi + 1
		return b["wi"] >= wp.size()
	var yaw: float = float(b["yaw"])
	var want: float = atan2(-to.x, -to.z)
	var diff: float = wrapf(want - yaw, -PI, PI)
	var sp: float = absf(float(b["speed"]))
	# loin du poste, on garde de l'eau sous la coque : si le fond remonte devant, on vire du côté
	# le plus profond (et on ralentit)
	var shallow: bool = false
	if not last and wi < wp.size() - 2:
		if _depth_ahead(me, yaw, 6.0 + sp * 1.5) > -1.6:
			shallow = true
			var dl: float = _depth_ahead(me, yaw + 0.7, 8.0)
			var dr: float = _depth_ahead(me, yaw - 0.7, 8.0)
			diff = 1.2 if dl < dr else -1.2
	var turn: float = TURN * (1.0 + 0.8 * (1.0 - clampf(sp / cruise, 0.0, 1.0)))
	b["yaw"] = yaw + clampf(diff, -turn * delta, turn * delta)
	# un grand virage se fait presque sur place
	var target: float = cruise * clampf(1.0 - absf(diff) / 1.2, 0.06, 1.0)
	if shallow:
		target = minf(target, 1.2)
	if last:
		target = minf(target, maxf(0.6, d * 0.3))
	elif wi == wp.size() - 2 and str(b["kind"]) == "navette":
		target = minf(target, maxf(2.0, d * 0.25 + 1.5))
	b["ignore"] = maxf(0.0, float(b["ignore"]) - delta)
	if _blocked(b):
		target = 0.0
		b["blocked"] = float(b["blocked"]) + delta
		if float(b["blocked"]) > 1.0 and not bool(b.get("honk", true)):
			b["honk"] = true
			if _player().distance_to(me) < 90.0:
				main.sfx("cloche_bateau", me + Vector3.UP * 2.0, -6.0)
		if float(b["blocked"]) > 8.0:
			b["ignore"] = 6.0
			b["blocked"] = 0.0
	else:
		b["blocked"] = 0.0
		b["honk"] = false
	b["speed"] = move_toward(float(b["speed"]), target, ACC * delta)
	b["pos"] = me + _forward(float(b["yaw"])) * float(b["speed"]) * delta
	return false


func _tick_sail(b: Dictionary, delta: float) -> void:
	if str(b["etat"]) != "route":
		b["speed"] = move_toward(float(b["speed"]), 0.0, delta)
		return
	if _steer(b, delta, 4.2):
		var tour: Array = b["tour"]
		b["i"] = (int(b["i"]) + 1) % tour.size()
		var nxt: Vector3 = tour[(int(b["i"]) + 1) % tour.size()]
		b["etat"] = "attend"
		_ask_path(b, b["pos"], nxt)


func _tick_ferry(b: Dictionary, delta: float, h: float) -> void:
	var service: bool = h >= 6.5 and h < 21.5
	var etat: String = str(b["etat"])
	match etat:
		"quai":
			b["t"] = float(b["t"]) + delta
			b["speed"] = 0.0
			var st: Dictionary = docks[b["esc"][int(b["i"])]]
			# on se cale doucement au poste
			b["pos"] = (b["pos"] as Vector3).lerp(st["berth"], clampf(delta * 1.5, 0.0, 1.0))
			b["yaw"] = lerp_angle(float(b["yaw"]), float(st["yaw"]), clampf(delta * 1.5, 0.0, 1.0))
			if int(b["xchg"]) == 0 and float(b["t"]) > 1.5:
				_exchange(b, st)
			if float(b["t"]) > 24.0 and service and _walkers_of(b) == 0 and _grid_ready:
				b["etat"] = "recule"
				b["t"] = 0.0
				if _player().distance_to(b["pos"]) < 90.0:
					main.sfx("cloche_bateau", (b["pos"] as Vector3) + Vector3.UP * 2.0, -4.0)
		"recule":
			var st2: Dictionary = docks[b["esc"][int(b["i"])]]
			b["speed"] = move_toward(float(b["speed"]), -2.2, ACC * delta)
			b["pos"] = (b["pos"] as Vector3) + _forward(float(b["yaw"])) * float(b["speed"]) * delta
			if (b["pos"] as Vector3).distance_to(st2["berth"]) > 15.0 or not _deep((b["pos"] as Vector3) + _forward(float(b["yaw"])) * -6.0, -1.2):
				st2["boat"] = null
				b["i"] = (int(b["i"]) + 1) % (b["esc"] as Array).size()
				b["etat"] = "calcul"
				b["xchg"] = 0
				var nxt: Dictionary = docks[b["esc"][int(b["i"])]]
				_jobs.append([b, b["pos"], nxt["app"]])
		"calcul":
			b["speed"] = move_toward(float(b["speed"]), 0.0, ACC * delta)
			b["pos"] = (b["pos"] as Vector3) + _forward(float(b["yaw"])) * float(b["speed"]) * delta
		"route":
			if _steer(b, delta, CRUISE):
				var st3: Dictionary = docks[b["esc"][int(b["i"])]]
				b["etat"] = "quai"
				b["t"] = 0.0
				b["xchg"] = 0
				st3["boat"] = b
				if _player().distance_to(b["pos"]) < 90.0:
					main.sfx("cloche_bateau", (b["pos"] as Vector3) + Vector3.UP * 2.0, -4.0)
	var hull: Node3D = b["hull"]
	var wake: GPUParticles3D = hull.get_node_or_null("Sillage")
	if wake != null:
		wake.emitting = absf(float(b["speed"])) > 1.5 and bool(b["near"])
	var eng: AudioStreamPlayer3D = hull.get_node_or_null("Moteur")
	if eng != null:
		var want_on: bool = bool(b["near"]) and _player().distance_to(b["pos"]) < 100.0 and etat != "quai"
		if want_on and not eng.playing and eng.stream != null:
			eng.play()
		elif not want_on and eng.playing:
			eng.stop()
		eng.pitch_scale = 0.8 + absf(float(b["speed"])) / CRUISE * 0.4


# =================================================================== l'escale : on descend, on monte

func _walkers_of(b: Dictionary) -> int:
	var n: int = 0
	for p in _people:
		if is_same(p.get("xboat"), b) and not (p["walk"] as Array).is_empty():
			n += 1
	return n


func _gang(b: Dictionary, st: Dictionary) -> Array:
	var hull: Node3D = b["hull"]
	var axis: Vector3 = st["d"]["axis"]
	var side: Vector3 = st["d"]["side"]
	var dock_dir: Vector3 = -side * float(st["s"])
	var right: Vector3 = hull.global_transform.basis.x
	var gx: float = (B * 0.5 - 0.35) * signf(dock_dir.dot(right))
	var g_boat: Vector3 = Vector3(gx, DECK, GANG_Z)
	var gw: Vector3 = hull.to_global(g_boat)
	var start: Vector3 = st["d"]["start"]
	var along: float = clampf((gw - start).dot(axis), 1.0, float(st["d"]["length"]) - 0.4)
	var dock_pt: Vector3 = start + axis * along - dock_dir * 0.55
	dock_pt.y = DECK_Y
	var center: Vector3 = start + axis * along
	center.y = DECK_Y
	return [g_boat, dock_pt, center, along]


func _exchange(b: Dictionary, st: Dictionary) -> void:
	b["xchg"] = 1
	var animate: bool = bool(st["near"]) and bool(b["near"]) and not _night
	var g: Array = _gang(b, st)
	var axis: Vector3 = st["d"]["axis"]
	var start: Vector3 = Vector3(st["d"]["start"].x, DECK_Y, st["d"]["start"].z)
	# ceux qui descendent
	var off: Array = []
	for k in range(4):
		if b["seats"][k] != null:
			off.append(b["seats"][k])
			b["seats"][k] = null
	# ceux qui montent (on en laisse parfois un sur le ponton)
	var waiting: Array = []
	for k2 in range(4):
		if st["who"][k2] != null and (st["who"][k2] as Dictionary)["walk"].is_empty():
			waiting.append(st["who"][k2])
	waiting.shuffle()
	var n_on: int = mini(waiting.size(), _rng.randi_range(maxi(1, waiting.size() - 1), 3))
	var on: Array = waiting.slice(0, n_on)
	for p in on:
		st["who"][int(p["slot"])] = null
	var delay: float = 0.0
	for p2 in off:
		var slot: int = -1
		for k3 in range(4):
			if st["who"][k3] == null:
				slot = k3
				break
		p2["xboat"] = b
		if slot >= 0:
			st["who"][slot] = p2
		if not animate or _npc(p2) == null:
			_despawn(p2)
			if slot >= 0:
				_put_on_dock(p2, st["name"], slot)
			else:
				_forget(p2)
			continue
		var seat: Vector3 = SEATS[int(p2["seat"])]
		var pts: Array = [[seat + Vector3(0, 0, -0.35), true], [Vector3(0, DECK, seat.z - 0.35), true], [Vector3(0, DECK, GANG_Z), true],
			[g[0], true], [g[1], false], [g[2], false]]
		if slot >= 0:
			var sp: Vector3 = st["slots"][slot]
			pts.append([start + axis * (sp - start).dot(axis), false])
			pts.append([sp, false])
		else:
			pts.append([start - axis * 1.5, false])
		p2["delay"] = delay
		delay += 1.3
		_start_walk(p2, b, pts, func() -> void:
			if slot >= 0:
				_put_on_dock(p2, st["name"], slot)
				_settle_on_dock(p2)
				if _rng.randf() < 0.5 and _npc(p2) != null:
					(p2["ctl"] as Node).call("say", str(PHRASES_ARRIVEE[_rng.randi() % PHRASES_ARRIVEE.size()]), 3.5)
			else:
				_despawn(p2)
				_forget(p2))
	# ceux qui montent, un peu après
	delay = maxf(delay, 1.0) + 1.0
	var seat_i: int = 0
	for p3 in on:
		var k4: int = seat_i
		seat_i += 1
		b["seats"][k4] = p3
		p3["xboat"] = b
		p3["lieu"] = "bord"
		p3["boat"] = b
		var slot2: int = int(p3["slot"])
		p3["slot"] = -1
		p3["seat"] = k4
		if not animate or _npc(p3) == null:
			_despawn(p3)
			continue
		var sp2: Vector3 = st["slots"][slot2]
		var seat2: Vector3 = SEATS[k4]
		var pts2: Array = [[start + axis * (sp2 - start).dot(axis), false], [g[2], false], [g[1], false], [g[0], true],
			[Vector3(0, DECK, GANG_Z), true], [Vector3(0, DECK, seat2.z - 0.35), true], [seat2 + Vector3(0, 0, -0.35), true]]
		p3["delay"] = delay
		delay += 1.3
		_start_walk(p3, b, pts2, func() -> void:
			_sit_on_boat(p3, b))
	# parfois, quelqu'un arrive de l'île pour attendre le prochain bateau
	var free_n: int = 0
	for k5 in range(4):
		if st["who"][k5] == null:
			free_n += 1
	if free_n >= 3 or (free_n >= 2 and _rng.randf() < 0.5):
		var p4: Dictionary = _new_person(st["name"])
		_put_on_dock(p4, st["name"], -1)
		if animate and _player().distance_to(start) > 14.0:
			_spawn(p4, self, start - axis * 2.0, axis, "debout", PHRASES_QUAI)
			var sp3: Vector3 = st["slots"][int(p4["slot"])]
			p4["delay"] = delay + 2.0
			_start_walk(p4, null, [[start + axis * (sp3 - start).dot(axis), false], [sp3, false]], func() -> void:
				_settle_on_dock(p4))


## Un trajet à pied : des points [position, à bord ?] (à bord : repère du bateau).
func _start_walk(p: Dictionary, b, pts: Array, fin: Callable) -> void:
	p["walk"] = pts
	p["wb"] = b
	p["fin"] = fin
	p["wi"] = 0
	var ctl: Node = p["ctl"]
	if ctl != null and is_instance_valid(ctl):
		ctl.set_process(false)


func _walk_tick(p: Dictionary, delta: float) -> void:
	if float(p.get("delay", 0.0)) > 0.0:
		p["delay"] = float(p["delay"]) - delta
		return
	var npc: Node3D = _npc(p)
	if npc == null:
		_finish_walk(p)
		return
	var pts: Array = p["walk"]
	var wi: int = int(p["wi"])
	if wi >= pts.size():
		_finish_walk(p)
		return
	var b = p.get("wb")
	var aboard: bool = bool(pts[wi][1])
	var goal: Vector3 = pts[wi][0]
	if aboard and b != null:
		goal = (b["hull"] as Node3D).to_global(goal)
	# sur le bateau, on reste dans le repère du bateau ; sur le ponton, dans le monde
	var want_parent: Node = (b["hull"] if aboard and b != null else self)
	if npc.get_parent() != want_parent:
		npc.reparent(want_parent, true)
	var pos: Vector3 = npc.global_position
	var to: Vector3 = goal - pos
	var flat := Vector3(to.x, 0.0, to.z)
	var d: float = flat.length()
	if d < 0.08:
		npc.global_position = goal
		p["wi"] = wi + 1
		return
	var step: float = minf(float(p["speed"]) * delta, d)
	var np: Vector3 = pos + flat.normalized() * step
	np.y = lerpf(pos.y, goal.y, clampf(step / maxf(d, 0.01), 0.0, 1.0))
	npc.global_position = np
	var face: Vector3 = flat.normalized()
	var gb: Basis = npc.global_transform.basis
	var cur: float = atan2(gb.z.x, gb.z.z)
	var tgt: float = atan2(face.x, face.z)
	var ny: float = lerp_angle(cur, tgt, clampf(delta * 8.0, 0.0, 1.0))
	npc.global_transform = Transform3D(Basis(Vector3.UP, ny).scaled(gb.get_scale()), npc.global_position)
	if npc.has_method("_play"):
		npc.call("_play", "Walking", 0.3, float(p["speed"]) / 1.05)


func _finish_walk(p: Dictionary) -> void:
	var fin: Callable = p["fin"]
	p["walk"] = []
	p["fin"] = Callable()
	var ctl = p["ctl"]
	if ctl != null and is_instance_valid(ctl):
		(ctl as Node).set_process(true)
	if fin.is_valid():
		fin.call()


func _settle_on_dock(p: Dictionary) -> void:
	var npc: Node3D = _npc(p)
	if npc == null or str(p["lieu"]) == "" or not docks.has(str(p["lieu"])):
		return
	var st: Dictionary = docks[str(p["lieu"])]
	if npc.get_parent() != self:
		npc.reparent(self, true)
	npc.global_position = st["slots"][int(p["slot"])]
	npc.rotation = Vector3.ZERO
	var pose: String = _dock_pose()
	(p["ctl"] as Node).call("set_pose", pose, _slot_face(st, int(p["slot"])))
	(p["ctl"] as Node).set("follow", false)
	(p["ctl"] as Node).set("lines", PHRASES_QUAI)
	p["pose"] = pose


func _sit_on_boat(p: Dictionary, b: Dictionary) -> void:
	var npc: Node3D = _npc(p)
	if npc == null:
		return
	var hull: Node3D = b["hull"]
	if npc.get_parent() != hull:
		npc.reparent(hull, false)
	npc.transform = Transform3D(Basis(), SEATS[int(p["seat"])])
	(p["ctl"] as Node).call("set_pose", "assis", Vector3(0, 0, -1))
	(p["ctl"] as Node).set("follow", false)
	(p["ctl"] as Node).set("lines", PHRASES_BORD)
	p["pose"] = "assis"


# =================================================================== près du joueur : les corps

func _update_visuals() -> void:
	var pl: Vector3 = _player()
	for nm in docks:
		var st: Dictionary = docks[nm]
		var dd: float = pl.distance_to(st["d"]["end"])
		var near: bool = _force_near or dd < (FAR if bool(st["near"]) else NEAR)
		st["near"] = near
		for k in range(4):
			var p = st["who"][k]
			if p == null or not (p["walk"] as Array).is_empty():
				continue
			if near and p["ctl"] == null:
				var pose: String = _dock_pose()
				_spawn(p, self, st["slots"][k], _slot_face(st, k), pose, PHRASES_QUAI)
			elif not near and p["ctl"] != null:
				_despawn(p)
	for b in boats:
		var db: float = pl.distance_to(b["pos"])
		var near2: bool = _force_near or db < (FAR if bool(b["near"]) else NEAR)
		b["near"] = near2
		var hull: Node3D = b["hull"]
		if str(b["kind"]) == "navette":
			var cap: Dictionary = b["captain_prof"]
			if near2 and cap["ctl"] == null:
				_spawn(cap, hull, hull.to_global(Vector3(0.0, DECK, -2.1)), Vector3(0, 0, -1), "debout", [])
				_local_fix(cap, Vector3(0.0, DECK, -2.1))
			elif not near2 and cap["ctl"] != null:
				_despawn(cap)
			for k2 in range(4):
				var p2 = b["seats"][k2]
				if p2 == null or not (p2["walk"] as Array).is_empty():
					continue
				if near2 and p2["ctl"] == null:
					_spawn(p2, hull, hull.to_global(SEATS[k2]), Vector3(0, 0, -1), "assis", PHRASES_BORD)
					_local_fix(p2, SEATS[k2])
				elif not near2 and p2["ctl"] != null:
					_despawn(p2)
		else:
			var sk: Dictionary = b["skipper_prof"]
			if near2 and sk["ctl"] == null:
				_spawn(sk, hull, hull.to_global(Vector3(0.0, 0.64, 3.2)), Vector3(0, 0, -1), "debout", [])
				_local_fix(sk, Vector3(0.0, 0.64, 3.2))
			elif not near2 and sk["ctl"] != null:
				_despawn(sk)
	# de temps en temps, quelqu'un sur un ponton proche fait un geste (il regarde au loin, s'étire)
	for nm2 in docks:
		var st2: Dictionary = docks[nm2]
		if not bool(st2["near"]) or _rng.randf() > 0.12:
			continue
		var k3: int = _rng.randi() % 4
		var p3 = st2["who"][k3]
		if p3 == null or p3["ctl"] == null or not (p3["walk"] as Array).is_empty() or str(p3["pose"]) == "assis":
			continue
		var npc: Node3D = _npc(p3)
		var g: String = ["visiere", "regarder", "etirer", "gratter_tete", "visiere"][_rng.randi() % 5]
		var an: AnimationPlayer = npc.get("anim")
		if an != null and an.has_animation("v102/" + g):
			npc.call("_play", "v102/" + g, 0.3, 1.0, 0.0)
			(p3["ctl"] as Node).set("_gest", 3.5)


## Un corps posé dans le repère du bateau (position et regard locaux).
func _local_fix(p: Dictionary, local: Vector3) -> void:
	var npc: Node3D = _npc(p)
	if npc == null:
		return
	npc.transform = Transform3D(Basis(Vector3.UP, PI), local)
	(p["ctl"] as Node).set("face_dir", Vector3(0, 0, -1))


# =================================================================== les modèles

func _hull_mesh(length: float, beam: float, depth: float, sheer0: float, band: Color, top: Color, sharp: float = 0.7) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 20
	var segs := 12
	var sections: Array = []
	for i in range(rings + 1):
		var t: float = float(i) / rings
		var z: float = (0.5 - t) * length
		var wf: float
		if t > sharp:
			wf = sqrt(clampf(1.0 - pow((t - sharp) / (1.0 - sharp), 2.0), 0.0, 1.0)) * 0.96 + 0.04
		else:
			wf = 0.82 + 0.18 * sin(t / sharp * PI * 0.5)
		var sheer: float = sheer0 + 0.4 * pow(maxf(t - 0.6, 0.0) / 0.4, 2.0)
		var ring: Array = []
		for k in range(segs + 1):
			var a: float = PI * float(k) / segs
			var x: float = -cos(a) * beam * 0.5 * wf
			var y: float = sheer - sin(a) * depth * (0.7 + 0.3 * wf) - (1.0 - wf) * 0.2
			ring.append(Vector3(x, y, z))
		sections.append(ring)
	for i in range(rings):
		for k in range(segs):
			var a0: Vector3 = sections[i][k]
			var a1: Vector3 = sections[i][k + 1]
			var b0: Vector3 = sections[i + 1][k]
			var b1: Vector3 = sections[i + 1][k + 1]
			var c: Vector3 = (a0 + a1 + b0 + b1) * 0.25
			var n: Vector3 = (a1 - a0).cross(b0 - a0).normalized()
			if n.dot(Vector3(c.x, c.y - 0.3, 0.0)) < 0.0:
				n = -n
			var col: Color = Color(0.55, 0.12, 0.1) if c.y < 0.04 else (band if c.y < 0.4 else top)
			for tri in [[a0, b0, a1], [a1, b0, b1]]:
				var tn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
				var order: Array = tri if tn.dot(n) < 0.0 else [tri[0], tri[2], tri[1]]
				for p in order:
					st.set_color(col)
					st.set_normal(n)
					st.set_uv(Vector2(p.z, p.y))
					st.add_vertex(p)
	var back: Array = sections[0]
	for k in range(segs):
		var p0: Vector3 = back[k]
		var p1: Vector3 = back[k + 1]
		var t0 := Vector3(p0.x, sheer0, p0.z)
		var t1 := Vector3(p1.x, sheer0, p1.z)
		var nn := Vector3(0, 0, 1)
		for tri2 in [[p0, t0, p1], [p1, t0, t1]]:
			var tn2: Vector3 = (tri2[1] - tri2[0]).cross(tri2[2] - tri2[0])
			var order2: Array = tri2 if tn2.dot(nn) < 0.0 else [tri2[0], tri2[2], tri2[1]]
			for p2 in order2:
				st.set_color(top if p2.y > 0.4 else band)
				st.set_normal(nn)
				st.set_uv(Vector2(p2.x, p2.y))
				st.add_vertex(p2)
	return st.commit()


const PAINT := {"blanc": Color(0.95, 0.95, 0.93), "rouge": Color(0.72, 0.12, 0.1), "bleu": Color(0.12, 0.28, 0.55),
	"vert": Color(0.15, 0.42, 0.28), "jaune": Color(0.95, 0.72, 0.15), "turquoise": Color(0.1, 0.55, 0.58), "orange": Color(0.9, 0.42, 0.12),
	"creme": Color(0.94, 0.9, 0.8)}


func _hull_node(parent: Node3D, mesh: ArrayMesh) -> void:
	var hm := MeshInstance3D.new()
	hm.name = "Coque"
	hm.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.38
	m.clearcoat_enabled = true
	m.clearcoat = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	hm.material_override = m
	hm.visibility_range_end = 900.0
	parent.add_child(hm)


func _name_labels(parent: Node3D, text: String, z: float, x: float, y: float) -> void:
	for sx in [-1.0, 1.0]:
		var lb := Label3D.new()
		lb.text = text
		lb.font_size = 64
		lb.pixel_size = 0.004
		lb.outline_size = 0
		lb.modulate = Color(0.08, 0.1, 0.16)
		lb.double_sided = false
		lb.position = Vector3(sx * x, y, z)
		lb.rotation.y = sx * PI / 2.0
		lb.visibility_range_end = 120.0
		parent.add_child(lb)


func _build_ferry_model(li: Dictionary) -> Node3D:
	var hull := Node3D.new()
	hull.name = "Navette_" + str(li["nom"]).replace(" ", "_").replace("é", "e")
	var band: Color = PAINT.get(str(li["coque"]), Color(0.2, 0.3, 0.6))
	_hull_node(hull, _hull_mesh(L, B, 1.35, 1.3, band, PAINT["blanc"]))
	var parts := Node3D.new()
	parts.name = "Pont"
	hull.add_child(parts)
	var k = Kit.new()
	k.setup(parts, main.get("temps_v56"))
	k.mats = kit.mats
	var c: String = str(li["coque"])
	var toile: String = str(li["toile"])
	# le pont en teck
	k.box(Transform3D(Basis(), Vector3(0, DECK - 0.04, 0.3)), Vector3(B * 0.84, 0.08, L * 0.86), "planches", 1.5, 4)
	# le pavois (avec une ouverture à la passerelle)
	for sx in [-1.0, 1.0]:
		k.box(Transform3D(Basis(), Vector3(sx * B * 0.44, DECK + 0.22, -2.6)), Vector3(0.08, 0.44, 4.6), "peinture_blanc", 1.0)
		k.box(Transform3D(Basis(), Vector3(sx * B * 0.44, DECK + 0.22, 2.75)), Vector3(0.08, 0.44, 4.1), "peinture_blanc", 1.0)
		k.box(Transform3D(Basis(), Vector3(sx * B * 0.42, DECK + 0.9, 2.45)), Vector3(0.05, 0.05, 3.7), "chrome", 1.0)
		for z in [0.65, 1.85, 3.05, 4.25]:
			k.cyl(Transform3D(Basis(), Vector3(sx * B * 0.42, DECK + 0.44, z)), 0.025, 0.025, 0.46, "chrome", 6)
	k.box(Transform3D(Basis(), Vector3(0, DECK + 0.22, L * 0.5 - 0.15)), Vector3(B * 0.82, 0.44, 0.08), "peinture_blanc", 1.0)
	# la timonerie vitrée
	var cz: float = -2.1
	var cw: float = 2.3
	var cl: float = 2.6
	k.box(Transform3D(Basis(), Vector3(0, DECK + 0.5, cz)), Vector3(cw, 1.0, cl), "peinture_" + c, 1.0)
	for sx2 in [-1.0, 1.0]:
		k.quad(Transform3D(Basis(Vector3.UP, sx2 * PI / 2.0), Vector3(sx2 * cw * 0.5, DECK + 1.45, cz)), cl - 0.2, 0.9, "verre", Vector2.ZERO, Vector2.ONE, true)
		k.box(Transform3D(Basis(), Vector3(sx2 * cw * 0.5, DECK + 1.45, cz - cl * 0.5 + 0.05)), Vector3(0.08, 0.9, 0.08), "peinture_blanc", 1.0)
		k.box(Transform3D(Basis(), Vector3(sx2 * cw * 0.5, DECK + 1.45, cz + cl * 0.5 - 0.05)), Vector3(0.08, 0.9, 0.08), "peinture_blanc", 1.0)
	k.quad(Transform3D(Basis(), Vector3(0, DECK + 1.45, cz - cl * 0.5)), cw - 0.1, 0.9, "verre", Vector2.ZERO, Vector2.ONE, true)
	k.quad(Transform3D(Basis(Vector3.UP, PI), Vector3(0, DECK + 1.45, cz + cl * 0.5)), cw - 0.1, 0.9, "verre", Vector2.ZERO, Vector2.ONE, true)
	k.box(Transform3D(Basis(), Vector3(0, DECK + 1.95, cz)), Vector3(cw + 0.2, 0.1, cl + 0.2), "peinture_blanc", 1.0)
	# la barre et le tableau de bord
	k.box(Transform3D(Basis(), Vector3(0, DECK + 0.55, cz - 1.0)), Vector3(1.6, 1.1, 0.4), "bois", 1.0)
	k.ring(Transform3D(Basis(Vector3.RIGHT, PI / 2.0 - 0.4), Vector3(0, DECK + 1.15, cz - 0.82)), 0.2, 0.25, 0.04, "bois", 16)
	# le mât de signaux sur la timonerie
	k.cyl(Transform3D(Basis(), Vector3(0, DECK + 2.0, cz + 0.5)), 0.04, 0.03, 1.3, "chrome", 6)
	# l'arrière : bancs et taud
	for z2 in [1.75, 3.15]:
		for sx3 in [-1.0, 1.0]:
			var bx: float = sx3 * 0.72
			k.box(Transform3D(Basis(), Vector3(bx, DECK + 0.42, z2 + 0.18)), Vector3(0.95, 0.06, 0.42), "bois", 1.0)
			k.box(Transform3D(Basis(), Vector3(bx, DECK + 0.2, z2 + 0.32)), Vector3(0.9, 0.4, 0.06), "peinture_blanc", 1.0)
			k.box(Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(bx, DECK + 0.72, z2 + 0.4)), Vector3(0.95, 0.5, 0.05), "bois", 1.0)
	for px in [-1.0, 1.0]:
		for pz in [0.6, 4.4]:
			k.cyl(Transform3D(Basis(), Vector3(px * (B * 0.42), DECK, pz)), 0.035, 0.035, 2.1, "chrome", 6)
	k.box(Transform3D(Basis(), Vector3(0, DECK + 2.12, 2.5)), Vector3(B * 0.9, 0.05, 4.2), "tissu_" + toile, 1.0)
	for sx4 in [-1.0, 1.0]:
		k.quad(Transform3D(Basis(Vector3.UP, sx4 * PI / 2.0), Vector3(sx4 * B * 0.45, DECK + 1.98, 2.5)), 4.2, 0.25, "tissu_" + toile, Vector2.ZERO, Vector2.ONE, true)
	# les bouées
	for sx5 in [-1.0, 1.0]:
		k.ring(Transform3D(Basis(Vector3.BACK, PI / 2.0 * sx5), Vector3(sx5 * (cw * 0.5 + 0.03), DECK + 0.55, cz + 0.6)), 0.17, 0.27, 0.09, "peinture_orange", 14)
	k.commit()
	_name_labels(hull, str(li["nom"]), -3.2, B * 0.47, 0.75)
	# les feux de navigation
	for nl in [[Vector3(cw * 0.52, DECK + 1.75, cz - 1.0), Color(0.2, 1.0, 0.35)], [Vector3(-cw * 0.52, DECK + 1.75, cz - 1.0), Color(1.0, 0.2, 0.15)], [Vector3(0, DECK + 3.3, cz + 0.5), Color(1.0, 0.95, 0.8)]]:
		var l := OmniLight3D.new()
		l.light_color = nl[1]
		l.omni_range = 3.5
		l.light_energy = 0.0
		l.position = nl[0]
		l.distance_fade_enabled = true
		l.distance_fade_begin = 120.0
		l.distance_fade_length = 30.0
		hull.add_child(l)
		if main.get("temps_v56") != null:
			main.temps_v56.register_lamp(l, 1.4)
	_add_wake(hull, B)
	var eng := AudioStreamPlayer3D.new()
	eng.name = "Moteur"
	var snd: String = "res://assets/sons/sfx/moteur_bateau_1.ogg"
	if ResourceLoader.exists(snd):
		var s: AudioStream = load(snd)
		if s is AudioStreamOggVorbis:
			s = (s as AudioStreamOggVorbis).duplicate()
			(s as AudioStreamOggVorbis).loop = true
		eng.stream = s
		eng.unit_size = 6.0
		eng.volume_db = -12.0
		eng.max_distance = 80.0
		eng.bus = "Bruitages" if AudioServer.get_bus_index("Bruitages") >= 0 else "Master"
	hull.add_child(eng)
	return hull


func _add_wake(hull: Node3D, beam: float) -> void:
	var wake := GPUParticles3D.new()
	wake.name = "Sillage"
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.3, 1)
	pm.spread = 22.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, -1.5, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(beam * 0.35, 0.05, 0.4)
	wake.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.7, 0.7)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1, 1, 1, 0.55)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if _soft != null:
		fm.albedo_texture = _soft
	qm.material = fm
	wake.draw_pass_1 = qm
	wake.amount = 60
	wake.lifetime = 2.0
	wake.local_coords = false
	wake.position = Vector3(0, 0.25, L * 0.5)
	wake.emitting = false
	hull.add_child(wake)


func _sail_mesh(pts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a: Vector3 = pts[0]
	var b: Vector3 = pts[1]
	var c: Vector3 = pts[2]
	# une voile gonflée : un triangle subdivisé, poussé sur le côté au milieu
	var n: int = 8
	var verts: Array = []
	for i in range(n + 1):
		var row: Array = []
		for j in range(n + 1 - i):
			var u: float = float(i) / n
			var v: float = float(j) / n
			var w: float = 1.0 - u - v
			var p: Vector3 = a * w + b * u + c * v
			p.x += sin(PI * clampf(u + v, 0.0, 1.0)) * sin(PI * clampf(w + v, 0.0, 1.0)) * 0.35 * (1.0 - v)
			row.append([p, Vector2(u, v)])
		verts.append(row)
	for i2 in range(n):
		for j2 in range(n - i2):
			var tri: Array = [verts[i2][j2], verts[i2 + 1][j2], verts[i2][j2 + 1]]
			for e in tri:
				st.set_uv(e[1])
				st.add_vertex(e[0])
			if j2 < n - i2 - 1:
				var tri2: Array = [verts[i2 + 1][j2], verts[i2 + 1][j2 + 1], verts[i2][j2 + 1]]
				for e2 in tri2:
					st.set_uv(e2[1])
					st.add_vertex(e2[0])
	st.generate_normals()
	return st.commit()


func _build_sail_model(vi: Dictionary) -> Node3D:
	var hull := Node3D.new()
	hull.name = "Voilier_" + str(vi["nom"]).replace("é", "e")
	var band: Color = PAINT.get(str(vi["coque"]), Color(0.9, 0.9, 0.9))
	var ln: float = 8.5
	_hull_node(hull, _hull_mesh(ln, 2.6, 1.1, 0.9, band, PAINT["blanc"] if str(vi["coque"]) != "blanc" else Color(0.12, 0.2, 0.42), 0.6))
	var parts := Node3D.new()
	parts.name = "Pont"
	hull.add_child(parts)
	var k = Kit.new()
	k.setup(parts, main.get("temps_v56"))
	k.mats = kit.mats
	k.box(Transform3D(Basis(), Vector3(0, 0.62, 0.0)), Vector3(2.1, 0.06, 7.2), "planches", 1.5, 4)
	# le roof (la petite cabine) et le cockpit
	k.box(Transform3D(Basis(), Vector3(0, 0.85, -0.6)), Vector3(1.7, 0.5, 2.6), "peinture_blanc", 1.0)
	for sx in [-1.0, 1.0]:
		k.quad(Transform3D(Basis(Vector3.UP, sx * PI / 2.0), Vector3(sx * 0.86, 0.9, -0.6)), 1.6, 0.18, "verre", Vector2.ZERO, Vector2.ONE, true)
		k.box(Transform3D(Basis(), Vector3(sx * 0.85, 0.55, 2.6)), Vector3(0.25, 0.1, 1.8), "bois", 1.0)
	# le mât, la bôme, les haubans
	k.cyl(Transform3D(Basis(), Vector3(0, 0.65, -1.2)), 0.07, 0.05, 9.0, "chrome", 8)
	k.cyl(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 1.8, -1.2)), 0.05, 0.05, 3.8, "chrome", 6)
	for sx2 in [-1.0, 1.0]:
		var top := Vector3(0, 9.6, -1.2)
		var bot := Vector3(sx2 * 1.15, 0.7, -1.0)
		var dir: Vector3 = (top - bot).normalized()
		var bas := Basis(Quaternion(Vector3.UP, dir))
		k.cyl(Transform3D(bas, bot), 0.008, 0.008, top.distance_to(bot), "fer", 4)
	k.commit()
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.96, 0.95, 0.9)
	sm.roughness = 0.85
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.backlight_enabled = true
	sm.backlight = Color(0.35, 0.34, 0.3)
	var main_sail := MeshInstance3D.new()
	main_sail.name = "Grand_voile"
	main_sail.mesh = _sail_mesh([Vector3(0, 1.85, -1.1), Vector3(0, 1.85, 2.5), Vector3(0, 9.4, -1.1)])
	main_sail.material_override = sm
	main_sail.visibility_range_end = 900.0
	hull.add_child(main_sail)
	var jib := MeshInstance3D.new()
	jib.name = "Foc"
	jib.mesh = _sail_mesh([Vector3(0, 1.0, -4.1), Vector3(0, 1.1, -1.5), Vector3(0, 8.6, -1.25)])
	jib.material_override = sm
	jib.visibility_range_end = 900.0
	hull.add_child(jib)
	_name_labels(hull, str(vi["nom"]), -2.6, 1.32, 0.55)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.95, 0.8)
	l.omni_range = 3.0
	l.light_energy = 0.0
	l.position = Vector3(0, 9.8, -1.2)
	l.distance_fade_enabled = true
	l.distance_fade_begin = 120.0
	l.distance_fade_length = 30.0
	hull.add_child(l)
	if main.get("temps_v56") != null:
		main.temps_v56.register_lamp(l, 1.2)
	return hull

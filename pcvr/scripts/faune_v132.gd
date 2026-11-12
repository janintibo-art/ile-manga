extends Node3D
## V132 : la faune sauvage des îles. Loin des villages et des habitants (dans les plaines, les
## forêts, sur les chemins entre deux hameaux), des bêtes vivent leur vie : elles apparaissent
## hors de vue, à bonne distance du héros, et s'en vont quand il s'éloigne.
## Chaque île a sa faune, plus nombreuse et plus dangereuse la nuit :
##  - l'île du village reste paisible : des crabes des sables sur les plages et des mouettes
##    chapardeuses (elles volent à manger, on peut les faire lâcher en les frappant) ;
##  - le Bois-Doré des elfes : sangliers qui chargent, ronceux cachés dans les fourrés, et la
##    nuit, des loups en meute ;
##  - la Montagne de Feu : salamandres de braise qui crachent du feu, boucs des roches qui
##    défendent leur coin, et la nuit, des nuées de chauves-souris des cendres.
## Les bêtes ont leur propre gestionnaire (pas celui des donjons) : elles ne se mêlent pas aux
## monstres des quêtes. Dans les tests sans écran, la faune dort (enabled = false), sauf si
## une suite la réveille.

const Bete := preload("res://scripts/monstre_v132.gd")

## île -> {"jour": [[espèce, nombre max, milieu, taille du groupe]…], "nuit": […]}
const ILES := {
	"village": {"jour": [["crabe_plage", 4, "plage", 1], ["mouette", 2, "air", 1]],
		"nuit": [["crabe_plage", 3, "plage", 1]]},
	"elfes": {"jour": [["sanglier", 3, "sol", 1], ["ronceux_sauvage", 3, "sol", 1]],
		"nuit": [["sanglier", 2, "sol", 1], ["ronceux_sauvage", 2, "sol", 1], ["loup_bois", 3, "sol", 3]]},
	"nains": {"jour": [["salamandre", 3, "sol", 1], ["bouc", 2, "sol", 1]],
		"nuit": [["salamandre", 3, "sol", 1], ["chauve_souris_mont", 4, "air", 4]]},
}
const MAX_TOTAL: int = 11
const LOIN: float = 120.0                # au-delà, la bête s'en va

var main: Node
var enabled: bool = true
var active: bool = false
var donjon: Node
var betes: Array = []
var iles: Dictionary = {}                # id -> {"c": Vector3, "r": float}
var ile_joueur: String = ""
var spawned: Dictionary = {}             # tests : espèce -> nombre d'apparitions
var vols: int = 0                        # tests : mouettes qui ont chipé quelque chose
var rendus: int = 0
var _rng := RandomNumberGenerator.new()
var _tick: float = 1.0
var _npc_pos: Array = []
var _npc_t: float = 0.0
var _cool: Dictionary = {}               # espèce -> temps avant de revenir
var _token: Node = null
var _token_t: float = 0.0
var _steal_cd: float = 240.0
var _swoop_t: float = 60.0
var _spits: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	name = "Faune_v132"
	donjon = main.get("donjon_v35")
	_rng.randomize()
	enabled = DisplayServer.get_name() != "headless"


# =================================================================== les îles

func _resolve_iles() -> void:
	if not iles.is_empty():
		return
	var centres := {"village": Vector3.ZERO}
	var e: Node = main.get("elfes_v41")
	if e != null and e.get("ile") != null:
		centres["elfes"] = e.ile.CENTER
	var n: Node = main.get("nains_v46")
	if n != null and n.get("ile") != null:
		centres["nains"] = n.ile.CENTER
	for id in centres:
		var c: Vector3 = centres[id]
		iles[id] = {"c": c, "r": _rayon(c)}
	print("ILE_MANGA_V132: faune sauvage sur ", iles.keys(), " ", iles)


## Le rayon d'une île : on marche du centre vers le large jusqu'à la mer, dans 16 directions.
func _rayon(c: Vector3) -> float:
	var rs: Array = []
	for k in range(16):
		var a: float = TAU * k / 16.0
		var last: float = 0.0
		var wet: int = 0
		var r: float = 8.0
		while r < 420.0:
			var h: float = main._height_at(c.x + cos(a) * r, c.z + sin(a) * r)
			if h < -0.3:
				wet += 1
				if wet >= 3:
					break
			else:
				wet = 0
				last = r
			r += 4.0
		rs.append(last)
	rs.sort()
	return float(rs[int(rs.size() * 0.8)])


func ile_de(p: Vector3) -> String:
	var best: String = ""
	var bk: float = 1.0
	for id in iles:
		var e: Dictionary = iles[id]
		var d: float = Vector2(p.x - (e["c"] as Vector3).x, p.z - (e["c"] as Vector3).z).length() / maxf(float(e["r"]), 1.0)
		if d < bk:
			bk = d
			best = id
	return best


# =================================================================== chaque instant

func _process(delta: float) -> void:
	if main == null:
		return
	var started: bool = bool(main.get("game_started"))
	var menu: Node = main.get("game_menu")
	var dlg: Node = main.get("dialogue_v31")
	active = enabled and started and (menu == null or not bool(menu.opened)) and (dlg == null or not bool(dlg.opened))
	_tick_spits(delta)
	if _token != null and (not is_instance_valid(_token) or _token_t <= 0.0):
		_token = null
	_token_t -= delta
	for k in _cool.keys():
		_cool[k] = float(_cool[k]) - delta
	_steal_cd -= delta
	if not enabled or not started:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 2.0
	_resolve_iles()
	var p: Vector3 = main._player_pos_v27()
	ile_joueur = ile_de(p)
	_npc_t -= 2.0
	if _npc_t <= 0.0:
		_npc_t = 6.0
		_refresh_npcs(p)
	# celles qui sont trop loin s'en vont
	for b in betes.duplicate():
		if not is_instance_valid(b):
			betes.erase(b)
		elif b.state != "mort" and (b as Node3D).global_position.distance_to(p) > LOIN:
			betes.erase(b)
			b.queue_free()
	if ile_joueur == "" or not active or _blocked(p):
		return
	_maybe_spawn(p)
	if ile_joueur == "village":
		_gulls(p)


func _blocked(p: Vector3) -> bool:
	var mv: Node = main.get("maisons_v81")
	if mv != null and bool(mv.get("inside")):
		return true
	if donjon != null and bool(donjon.get("inside")):
		return true
	# en vol (l'aigle, l'aéronef) : rien ne naît sous les ailes
	if p.y - float(main._height_at(p.x, p.z)) > 8.0:
		return true
	return false


func _refresh_npcs(p: Vector3) -> void:
	_npc_pos.clear()
	for n in main.npcs_v31:
		if is_instance_valid(n):
			var q: Vector3 = (n as Node3D).global_position
			if q.distance_to(p) < 220.0:
				_npc_pos.append(q)


func night() -> bool:
	var t: Node = main.get("temps_v56")
	return t != null and t.has_method("is_night") and bool(t.is_night())


func _count(kind: String) -> int:
	var n: int = 0
	for b in betes:
		if is_instance_valid(b) and str(b.kind) == kind and b.state != "mort":
			n += 1
	return n


func _maybe_spawn(p: Vector3) -> void:
	var alive: int = 0
	for b in betes:
		if is_instance_valid(b) and b.state != "mort":
			alive += 1
	if alive >= MAX_TOTAL:
		return
	var table: Array = ILES[ile_joueur]["nuit" if night() else "jour"]
	var choix: Array = []
	for e in table:
		var kind: String = e[0]
		if _count(kind) + int(e[3]) <= int(e[1]) and float(_cool.get(kind, 0.0)) <= 0.0:
			choix.append(e)
	if choix.is_empty():
		return
	var e2: Array = choix[_rng.randi() % choix.size()]
	var at: Vector3 = _spot(p, str(e2[2]), str(e2[0]))
	if at == Vector3.INF:
		return
	for i in range(int(e2[3])):
		var off := Vector3(_rng.randf_range(-2.5, 2.5), 0, _rng.randf_range(-2.5, 2.5)) if i > 0 else Vector3.ZERO
		var q: Vector3 = at + off
		if str(e2[2]) != "air":
			q.y = float(main._height_at(q.x, q.z)) + 0.1
		spawn(str(e2[0]), q)


## Une bête de plus (les tests l'appellent aussi directement).
func spawn(kind: String, at: Vector3) -> Node3D:
	var b: CharacterBody3D = Bete.new()
	add_child(b)
	b.setup(self, kind, at)
	b.died.connect(_on_died)
	betes.append(b)
	spawned[kind] = int(spawned.get(kind, 0)) + 1
	if kind == "loup_bois" and _count("loup_bois") == 1:
		main.sfx("loup_hurle", at + Vector3.UP)
	return b


## Un endroit pour naître : sur l'île, dans son milieu (plage, sol, ciel), loin des habitants,
## hors du regard, sans toit ni mur au-dessus.
func _spot(p: Vector3, milieu: String, kind: String) -> Vector3:
	var e: Dictionary = iles[ile_joueur]
	var c: Vector3 = e["c"]
	var peaceful: bool = int(Bete.SPECS132[kind]["degats"]) == 0
	var far_npc: float = 12.0 if peaceful else 32.0
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	for tries in range(14):
		var a: float = _rng.randf() * TAU
		var d: float = _rng.randf_range(16.0, 42.0) if peaceful else _rng.randf_range(28.0, 55.0)
		var q := Vector3(p.x + cos(a) * d, 0, p.z + sin(a) * d)
		if Vector2(q.x - c.x, q.z - c.z).length() > float(e["r"]) * 0.97:
			continue
		var h: float = main._height_at(q.x, q.z)
		match milieu:
			"plage":
				if h < 0.15 or h > 2.2:
					continue
			"sol":
				if h < 1.2:
					continue
				var h2: float = main._height_at(q.x + 1.5, q.z)
				var h3: float = main._height_at(q.x, q.z + 1.5)
				if absf(h2 - h) > 1.1 or absf(h3 - h) > 1.1:
					continue
			"air":
				if h < 0.3:
					continue
		var ok: bool = true
		for np in _npc_pos:
			if Vector2((np as Vector3).x - q.x, (np as Vector3).z - q.z).length() < far_npc:
				ok = false
				break
		if not ok:
			continue
		# hors du regard (sauf si on a beaucoup cherché)
		if cam != null and tries < 9:
			var to: Vector3 = Vector3(q.x, h + 1.0, q.z) - cam.global_position
			if to.normalized().dot(-cam.global_basis.z) > 0.55 and to.length() < 60.0:
				continue
		# pas de toit, de mur, de rocher posé au-dessus
		if is_inside_tree():
			var space := get_world_3d().direct_space_state
			var ray := PhysicsRayQueryParameters3D.create(Vector3(q.x, h + 40.0, q.z), Vector3(q.x, h - 2.0, q.z), 1)
			var hit: Dictionary = space.intersect_ray(ray)
			if not hit.is_empty() and float(hit.position.y) > h + 0.9:
				continue
		q.y = (h + (float(_rng.randf_range(10.0, 16.0)) if kind == "mouette" else 2.8)) if milieu == "air" else h + 0.1
		return q
	return Vector3.INF


## Les bêtes sauvages menaçantes autour du héros (les cœurs en VR, comme dans les donjons).
func hostile_zone(p: Vector3) -> bool:
	for b in betes:
		if is_instance_valid(b) and b.state != "mort" and not bool(b.peaceful) and (b as Node3D).global_position.distance_to(p) < 30.0:
			return true
	return false


# =================================================================== ce que les bêtes demandent

func alert(m: Node3D) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.alert(m)


func hurt_player(amount: int, from_pos: Vector3) -> void:
	var mo: Node = main.get("monstres_v36")
	if mo != null:
		mo.hurt_player(amount, from_pos)


func spawn_extra(kind: String, at: Vector3) -> Node3D:
	return spawn(kind, at) if Bete.SPECS132.has(kind) else null


## Un seul loup (ou une seule chauve-souris) attaque à la fois.
func take_token(b: Node) -> bool:
	if _token == null or not is_instance_valid(_token) or _token == b:
		_token = b
		_token_t = 2.5
		return true
	return false


func release_token(b: Node) -> void:
	if _token == b:
		_token = null


## Le héros est bousculé (charge du sanglier, coup de tête du bouc).
func shove(v: Vector3) -> void:
	var body: CharacterBody3D = null
	if bool(main.get("xr_active")) and main.get("vr_body") != null:
		body = main.vr_body
	elif main.get("pc_body") != null:
		body = main.pc_body
	if body != null and is_instance_valid(body):
		body.move_and_collide(Vector3(v.x, 0.0, v.z) * 0.12)


func _on_died(m: Node3D) -> void:
	betes.erase(m)
	_cool[str(m.kind)] = 25.0
	if main.get("progression_v63") != null and main.progression_v63 != null:
		main.progression_v63.on_kill(str(m.kind), m.global_position + Vector3.UP * 1.0)
	var gains: Array = m.loot(_rng) if m.has_method("loot") else []
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append("+%d %s" % [got, str(main.inventory_v28.ITEMS[str(g[0])]["name"])])
	if not parts.is_empty() and main.combat_v28 != null:
		main.combat_v28.float_text(m.global_position + Vector3.UP * 1.2, "  ".join(parts), Color(1.0, 0.9, 0.5))


# =================================================================== les crachats de braise

func spit(from: Vector3, to: Vector3, dmg: int) -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = from
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.13
	s.height = 0.26
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.55, 0.15)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.1)
	m.emission_energy_multiplier = 4.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s.material = m
	mi.mesh = s
	n.add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.15)
	l.light_energy = 1.2
	l.omni_range = 3.0
	n.add_child(l)
	var fx: Node = main.get("combat_fx_v129")
	if fx != null and fx.has_method("_burst"):
		fx._burst(Vector3.ZERO, {"amount": 16, "life": 0.4, "v0": 0.0, "v1": 0.3, "radius": 0.05, "grav": Vector3(0, 1.0, 0), "size": 0.12,
			"explo": 0.0, "loop": true, "parent": n, "cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(0.6, 0.15, 0.05, 0.0)]})
	var t: float = clampf(from.distance_to(to) / 10.0, 0.5, 1.2)
	var v: Vector3 = (to - from) / t
	v.y += 0.5 * 9.8 * t
	_spits.append({"n": n, "v": v, "life": 2.5, "dmg": dmg, "from": from})
	main.sfx("flamme_lance", from)


func _tick_spits(delta: float) -> void:
	if _spits.is_empty():
		return
	var p: Vector3 = main._player_pos_v27() + Vector3.UP * 1.0
	for s in _spits.duplicate():
		var n: Node3D = s["n"]
		if not is_instance_valid(n):
			_spits.erase(s)
			continue
		s["v"] = (s["v"] as Vector3) + Vector3.DOWN * 9.8 * delta
		n.global_position += (s["v"] as Vector3) * delta
		s["life"] = float(s["life"]) - delta
		var done: bool = false
		if n.global_position.distance_to(p) < 0.8:
			hurt_player(int(s["dmg"]), s["from"])
			done = true
		elif n.global_position.y < float(main._height_at(n.global_position.x, n.global_position.z)) or float(s["life"]) <= 0.0:
			done = true
		if done:
			var fx: Node = main.get("combat_fx_v129")
			if fx != null and fx.has_method("_burst"):
				fx._burst(n.global_position, {"amount": 12, "life": 0.6, "v0": 1.0, "v1": 3.0, "dir": Vector3.UP, "spread": 70.0, "grav": Vector3(0, -6.0, 0),
					"size": 0.1, "mesh": "streak", "cols": [Color(1, 0.9, 0.5), Color(1.0, 0.45, 0.1), Color(1.0, 0.3, 0.05, 0.0)]})
			main.sfx("flamme_impact", n.global_position)
			n.queue_free()
			_spits.erase(s)


# =================================================================== les mouettes chapardeuses

func _gulls(p: Vector3) -> void:
	_swoop_t -= 2.0
	if _swoop_t > 0.0:
		return
	_swoop_t = _rng.randf_range(50.0, 100.0)
	# près du rivage seulement, et pas pendant une conversation
	if float(main._height_at(p.x, p.z)) > 4.0:
		return
	for b in betes:
		if is_instance_valid(b) and str(b.kind) == "mouette" and b.state == "vol" and (b as Node3D).global_position.distance_to(p) < 45.0:
			b.state = "pique"
			b.timer = 4.0
			b._sound("menace")
			return


func _food() -> String:
	var inv: Node = main.inventory_v28
	var opts: Array = []
	for id in inv.ITEMS:
		if str(inv.ITEMS[id].get("kind", "")) == "nourriture" and inv.count(id) > 0:
			opts.append(id)
	return str(opts[_rng.randi() % opts.size()]) if not opts.is_empty() else ""


func _art(id: String) -> String:
	var it: Dictionary = main.inventory_v28.ITEMS.get(id, {})
	return str(it.get("art", it.get("name", id)))


## La mouette passe en rase-mottes : elle chipe à manger (une fois de temps en temps).
func mouette_vole(g: Node3D) -> void:
	var id: String = _food() if _steal_cd <= 0.0 else ""
	main.sfx("mouette_cri", g.global_position)
	if id == "":
		if main.combat_v28 != null:
			main.combat_v28.float_text(g.global_position + Vector3.UP * 0.5, "Kiaaa !", Color(1, 1, 1))
		g.state = "fuite_air"
		g.timer = 2.0
		return
	main.inventory_v28.remove(id, 1)
	g.butin = id
	vols += 1
	_steal_cd = 180.0
	var mdl: Node3D = main.inventory_v28.make_model(id)
	if mdl != null:
		mdl.name = "Butin"
		mdl.scale = Vector3.ONE * 0.35
		var body: Node3D = g._pivots.get("corps")
		if body != null:
			body.add_child(mdl)
			mdl.position = Vector3(0, 0.02, 0.42)
	main._show_message_v28("Une mouette t'a chipé %s ! Frappe-la vite pour qu'elle le lâche." % _art(id))


func _drop_model(g: Node3D) -> void:
	var body: Node3D = g._pivots.get("corps")
	if body != null:
		var m: Node = body.get_node_or_null("Butin")
		if m != null:
			m.queue_free()


func mouette_lache(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id == "":
		return
	main.inventory_v28.add(id, 1)
	rendus += 1
	main._show_message_v28("La mouette lâche %s !" % _art(id))
	main.sfx("ramasse_pieces", g.global_position)


func mouette_garde(g: Node3D) -> void:
	var id: String = str(g.butin)
	g.butin = ""
	_drop_model(g)
	if id != "":
		main._show_message_v28("Trop tard : la mouette s'est envolée avec %s." % _art(id))

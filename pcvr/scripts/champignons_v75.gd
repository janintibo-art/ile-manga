extends Node
## V75 : les champignons féeriques de l'Île du Boucan (des champignons de CONTE : dans la vraie vie,
## on ne mange jamais un champignon qu'on ne connaît pas — Mère Morille le répète à chaque fois).
## On les cueille dans la Cathédrale des Spores (ils repoussent), on les croque depuis le sac :
##  - le Bolet-Ressort (champi_ressort) : on saute trois fois plus haut, et on retombe en douceur ;
##  - la Lunaire (champi_lune) : on voit l'invisible : des cachettes lumineuses apparaissent dans
##    toute l'île (une petite surprise dans chacune, une seule fois) ;
##  - le Babillard (champi_babil) : on comprend les animaux (et Sardine, qui a beaucoup à dire) ;
##  - l'Arc-en-ciel (champi_arcenciel) : le monde ondule de couleurs, on court plus vite, on laisse
##    une traînée arc-en-ciel ;
##  - le Petit-Géant (champi_geant) : on grandit (x1,6) et on frappe plus fort.

const TEXTES := "res://scripts/pnj/boucan_textes_v75.gd"
const KINDS := {"champi_ressort": [45.0, "Bolet-Ressort", Color(1.0, 0.55, 0.15)], "champi_lune": [60.0, "Lunaire", Color(0.85, 0.9, 1.0)],
	"champi_babil": [60.0, "Babillard", Color(0.55, 0.4, 1.0)], "champi_arcenciel": [40.0, "Arc-en-ciel", Color(1.0, 0.3, 0.6)],
	"champi_geant": [30.0, "Petit-Géant", Color(0.3, 0.75, 1.0)]}
## Les coins de cueillette dans la Cathédrale des Spores (repère : le centre du gazomètre).
const PICKS := [[-6.0, 14.0, "champi_ressort"], [9.0, -4.0, "champi_ressort"], [-17.0, -9.0, "champi_lune"], [20.0, 12.0, "champi_babil"],
	[-2.0, -15.0, "champi_arcenciel"], [11.0, 20.0, "champi_geant"], [-21.0, 2.0, "champi_babil"], [3.0, 8.0, "champi_lune"]]
const REGROW: float = 300.0
## Les cachettes que seule la Lunaire montre : [lieu (spot), décalage, récompense, texte].
const SECRETS := [["phare", Vector3(2.4, 0, 1.0), [["piece", 25]], "Au pied du phare, sous une pierre qui luit : une boîte en fer pleine de pièces, et un mot : « Pour le prochain qui verra. — T. »"],
	["plage_cabane", Vector3(-2.0, 0, 2.0), [["limonade_boucan", 2]], "Dans le sable, deux bouteilles de limonade enterrées au frais, avec une étiquette : « À partager. »"],
	["casse_atelier", Vector3(2.5, 0, -2.0), [["piece", 20], ["ressort", 2]], "Sous le capot d'une vieille voiture : des pièces et deux ressorts tout brillants. Ferraille les cachait pour les mauvais jours."],
	["cargo_pont", Vector3(1.5, 0, 2.5), [["patch_rat", 1]], "Derrière un hublot qui brille : un patch des Rats de Cale, tout neuf, oublié par un fan très ancien."],
	["chateau_eau", Vector3(-2.5, 0, -1.5), [["bombe_peinture", 2]], "Une trappe dans le socle du château d'eau : deux bombes de peinture et un dessin d'enfant, très fier, signé « Tornade »."],
	["jardins_serre", Vector3(2.0, 0, 1.0), [["piece", 15], ["sirop_menthe", 1]], "Entre deux pots de tomates : une tirelire en forme de radis. Radis l'avait oubliée. Il dira que c'est pour toi."]]

var main: Node
var bo: Node
var state := {}
var active: Dictionary = {}               # id -> secondes restantes
var _picks: Array = []                    # {node, kind, pos, t}
var _secret_nodes: Array = []             # {node, pos, i}
var _trail: CPUParticles3D
var _clock: float = 0.0
var _env_sat: float = -1.0
var _grown: bool = false
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, manager: Node) -> void:
	main = main_node
	bo = manager
	_rng.randomize()
	state = _fresh()
	_build_picks()
	_build_secrets()


func _fresh() -> Dictionary:
	return {"manges": {}, "secrets": [], "cueillis": 0}


func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	for k in active.keys():
		_end(str(k), true)
	active.clear()
	state = _fresh()
	for k2 in state:
		if d.has(k2):
			state[k2] = d[k2]
	if typeof(state["manges"]) != TYPE_DICTIONARY:
		state["manges"] = {}
	if typeof(state["secrets"]) != TYPE_ARRAY:
		state["secrets"] = []


func trouvailles() -> Dictionary:
	var m: Dictionary = state["manges"]
	return {"boucan_champignon": 1 if not m.is_empty() else 0, "champignons_5": 1 if m.size() >= 5 else 0,
		"secrets_lunaire": (state["secrets"] as Array).size()}


func is_active(id: String) -> bool:
	return active.has(id)


# =================================================================== manger

## Croquer un champignon féerique (depuis le sac : inventory_v28.use_tool). Renvoie true si mangé.
func eat(id: String) -> bool:
	if not KINDS.has(id):
		return false
	var inv: Node = main.get("inventory_v28")
	if inv == null or inv.count(id) <= 0:
		return false
	inv.remove(id, 1)
	if inv.opened:
		inv.close()
	var first: bool = not (state["manges"] as Dictionary).has(id)
	state["manges"][id] = int((state["manges"] as Dictionary).get(id, 0)) + 1
	var was: bool = active.has(id)
	active[id] = float(KINDS[id][0])
	if not was:
		_begin(id)
	bo.sfx("champi_magie", main._player_pos_v27())
	var t: String = _text(id, "manger")
	if t == "":
		t = "Tu croques le %s. Ça pétille sous la langue !" % str(KINDS[id][1])
	if first:
		t += "  (Mère Morille te l'a dit : un champignon de conte, oui ; un champignon inconnu dans la vraie forêt : JAMAIS.)"
	bo.say(t, 8.0)
	return true


func _text(id: String, key: String) -> String:
	if not ResourceLoader.exists(TEXTES):
		return ""
	var c: Dictionary = (load(TEXTES).get_script_constant_map() as Dictionary).get("CHAMPIGNONS", {})
	var e: Variant = (c.get(id, {}) as Dictionary).get(key, "")
	if e is Array and not (e as Array).is_empty():
		return str(e[_rng.randi() % (e as Array).size()])
	return str(e)


func _hero() -> Node:
	return main.get("hero_v28") if main != null else null


func _begin(id: String) -> void:
	var h: Node = _hero()
	match id:
		"champi_ressort":
			if h != null:
				h.jump_mult = 1.75
				h.fall_bonus = 14.0
		"champi_lune":
			_show_secrets(true)
		"champi_babil":
			if bo.faune != null and bo.faune.has_method("set_babil"):
				bo.faune.set_babil(true)
			if bo.chien != null and bo.chien.has_method("set_babil"):
				bo.chien.set_babil(true)
		"champi_arcenciel":
			if h != null:
				h.speed_mult = 1.5
			_make_trail(true)
		"champi_geant":
			if h != null:
				h.temp_force = int(h.temp_force) + 2
				if h.hero != null:
					var tw := create_tween()
					tw.tween_property(h.hero, "scale", Vector3.ONE * 1.6, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				_grown = true


func _end(id: String, silent: bool = false) -> void:
	var h: Node = _hero()
	match id:
		"champi_ressort":
			if h != null:
				h.jump_mult = 1.0
				h.fall_bonus = 0.0
		"champi_lune":
			_show_secrets(false)
		"champi_babil":
			if bo.faune != null and bo.faune.has_method("set_babil"):
				bo.faune.set_babil(false)
			if bo.chien != null and bo.chien.has_method("set_babil"):
				bo.chien.set_babil(false)
		"champi_arcenciel":
			if h != null:
				h.speed_mult = 1.0
			_make_trail(false)
			_restore_env()
		"champi_geant":
			if h != null and _grown:
				h.temp_force = maxi(0, int(h.temp_force) - 2)
				if h.hero != null:
					var tw := create_tween()
					tw.tween_property(h.hero, "scale", Vector3.ONE, 0.6)
				_grown = false
	if not silent:
		bo.sfx("champi_fin", main._player_pos_v27())
		var t: String = _text(id, "fin")
		main._show_message_v28(t if t != "" else "L'effet du %s s'en va doucement." % str(KINDS[id][1]))


## Le joueur s'évanouit, change de partie : tout s'arrête.
func clear_all() -> void:
	for k in active.keys():
		_end(str(k), true)
	active.clear()


func _make_trail(on: bool) -> void:
	var h: Node = _hero()
	if not on:
		if _trail != null:
			_trail.queue_free()
			_trail = null
		return
	if _trail != null or h == null or h.body == null:
		return
	_trail = CPUParticles3D.new()
	_trail.name = "Trainee_arcenciel"
	_trail.amount = 80
	_trail.lifetime = 1.4
	_trail.local_coords = false
	_trail.direction = Vector3.UP
	_trail.spread = 30.0
	_trail.initial_velocity_min = 0.1
	_trail.initial_velocity_max = 0.4
	_trail.gravity = Vector3(0, 0.15, 0)
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_trail.emission_sphere_radius = 0.25
	_trail.scale_amount_min = 0.5
	_trail.scale_amount_max = 1.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 0.2, 0.2, 1), Color(1, 0.6, 0.1, 1), Color(1, 1, 0.2, 1), Color(0.2, 1, 0.3, 0.9), Color(0.2, 0.5, 1, 0.6), Color(0.7, 0.3, 1, 0)])
	_trail.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	q.material = m
	_trail.mesh = q
	(h.body as Node3D).add_child(_trail)
	_trail.position = Vector3(0, 0.6, 0)


func _env() -> Environment:
	var t: Node = main.get("temps_v56")
	return t.env if t != null and t.get("env") != null else null


func _restore_env() -> void:
	var e: Environment = _env()
	if e != null and _env_sat >= 0.0:
		e.adjustment_saturation = _env_sat
	_env_sat = -1.0


# =================================================================== la cueillette

func _cap_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.9
	m.rim_enabled = true
	m.rim = 0.4
	return m


func _build_picks() -> void:
	if bo.dehors == null or bo.ile == null:
		return
	var c: Vector3 = bo.dehors.gazo_center
	var stem := StandardMaterial3D.new()
	stem.albedo_color = Color(0.92, 0.9, 0.84)
	stem.roughness = 0.8
	for e in PICKS:
		var p := Vector3(c.x + float(e[0]), 0.0, c.z + float(e[1]))
		p.y = bo.ile.height(p.x, p.z)
		var n := Node3D.new()
		n.name = "Cueillette_" + str(e[2])
		bo.add_child(n)
		n.global_position = p
		var col: Color = KINDS[str(e[2])][2]
		for k in range(3):
			var a: float = k * 2.1
			var s: float = [1.0, 0.7, 0.55][k]
			var st := MeshInstance3D.new()
			var cy := CylinderMesh.new()
			cy.top_radius = 0.03 * s
			cy.bottom_radius = 0.045 * s
			cy.height = 0.22 * s
			st.mesh = cy
			st.material_override = stem
			n.add_child(st)
			st.position = Vector3(cos(a) * 0.12 * k, 0.11 * s, sin(a) * 0.12 * k)
			var cap := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 0.11 * s
			sp.height = 0.11 * s
			sp.is_hemisphere = true
			cap.mesh = sp
			cap.material_override = _cap_mat(col)
			n.add_child(cap)
			cap.position = st.position + Vector3(0, 0.1 * s, 0)
		_picks.append({"node": n, "kind": str(e[2]), "pos": p, "t": 0.0})


func _pick_near(p: Vector3) -> int:
	for i in range(_picks.size()):
		var e: Dictionary = _picks[i]
		if float(e["t"]) <= 0.0 and p.distance_to(e["pos"]) < 1.6:
			return i
	return -1


func pick_text() -> String:
	var i: int = _pick_near(main._player_pos_v27())
	if i < 0:
		return ""
	return "E : cueillir un " + str(KINDS[str(_picks[i]["kind"])][1])


func pick() -> void:
	var i: int = _pick_near(main._player_pos_v27())
	if i < 0:
		return
	var e: Dictionary = _picks[i]
	var inv: Node = main.get("inventory_v28")
	if inv == null or not inv.ITEMS.has(str(e["kind"])):
		return
	if inv.add(str(e["kind"]), 1) <= 0:
		main._show_message_v28("Ton sac est plein.")
		return
	e["t"] = REGROW
	(e["node"] as Node3D).visible = false
	state["cueillis"] = int(state["cueillis"]) + 1
	bo.sfx("ramasse", e["pos"])
	main._show_message_v28("Tu cueilles un %s. Il luit doucement dans ta main. (À croquer depuis le sac.)" % str(KINDS[str(e["kind"])][1]))


# =================================================================== les cachettes de la Lunaire

func _build_secrets() -> void:
	for i in range(SECRETS.size()):
		var sp: Dictionary = bo.spot(str(SECRETS[i][0]))
		if sp.is_empty():
			continue
		var p: Vector3 = (sp["pos"] as Vector3) + (SECRETS[i][1] as Vector3)
		if bo.ile != null:
			p.y = maxf(p.y, bo.ile.height(p.x, p.z)) if not bo.on_structure(p) else p.y
		var n := Node3D.new()
		n.name = "Cachette_lunaire_%d" % i
		bo.add_child(n)
		n.global_position = p
		n.visible = false
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.45
		tm.outer_radius = 0.55
		ring.mesh = tm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.75, 0.85, 1.0, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = Color(0.7, 0.85, 1.0)
		m.emission_energy_multiplier = 2.0
		ring.material_override = m
		n.add_child(ring)
		ring.position = Vector3(0, 0.05, 0)
		var sparks := CPUParticles3D.new()
		sparks.amount = 16
		sparks.lifetime = 1.6
		sparks.direction = Vector3.UP
		sparks.spread = 20.0
		sparks.initial_velocity_min = 0.3
		sparks.initial_velocity_max = 0.7
		sparks.gravity = Vector3.ZERO
		sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		sparks.emission_sphere_radius = 0.4
		var q := QuadMesh.new()
		q.size = Vector2(0.08, 0.08)
		q.material = m
		sparks.mesh = q
		n.add_child(sparks)
		_secret_nodes.append({"node": n, "pos": p, "i": i})


func _show_secrets(on: bool) -> void:
	for s in _secret_nodes:
		(s["node"] as Node3D).visible = on and not (state["secrets"] as Array).has(int(s["i"]))


func _secret_near(p: Vector3) -> int:
	if not active.has("champi_lune"):
		return -1
	for s in _secret_nodes:
		if not (state["secrets"] as Array).has(int(s["i"])) and p.distance_to(s["pos"]) < 1.8:
			return int(s["i"])
	return -1


func open_secret() -> void:
	var i: int = _secret_near(main._player_pos_v27())
	if i < 0:
		return
	(state["secrets"] as Array).append(i)
	var inv: Node = main.get("inventory_v28")
	for g in SECRETS[i][2]:
		if inv != null and inv.ITEMS.has(str(g[0])):
			inv.add(str(g[0]), int(g[1]))
	_show_secrets(true)
	bo.sfx("ui_quete", main._player_pos_v27())
	bo.say(str(SECRETS[i][3]) + "  (Cachettes de la Lunaire : %d sur %d.)" % [(state["secrets"] as Array).size(), SECRETS.size()], 8.0)


# =================================================================== les invites, le temps

func register_interactions(d: Node) -> void:
	var me = self
	_pick_ia = {"id": "bo_cueillir", "pos": Vector3(0, -9999, 0), "radius": 1.6, "text": "E : cueillir", "vr": "Gâchette : cueillir",
		"call": func(): me.pick(), "when": func(): return me._pick_near(me.main._player_pos_v27()) >= 0}
	bo._ia(d, _pick_ia)
	_secret_ia = {"id": "bo_cachette", "pos": Vector3(0, -9999, 0), "radius": 1.8, "text": "E : fouiller la cachette lumineuse", "vr": "Gâchette : fouiller la cachette",
		"call": func(): me.open_secret(), "when": func(): return me._secret_near(me.main._player_pos_v27()) >= 0}
	bo._ia(d, _secret_ia)


var _pick_ia: Dictionary = {}
var _secret_ia: Dictionary = {}
var _ia_t: float = 0.0


func _process(delta: float) -> void:
	if main == null or bo == null:
		return
	_clock += delta
	for e in _picks:
		if float(e["t"]) > 0.0:
			e["t"] = float(e["t"]) - delta
			if float(e["t"]) <= 0.0:
				(e["node"] as Node3D).visible = true
	for k in active.keys():
		active[k] = float(active[k]) - delta
		if float(active[k]) <= 0.0:
			active.erase(k)
			_end(str(k))
	if active.has("champi_arcenciel"):
		var e2: Environment = _env()
		if e2 != null:
			if _env_sat < 0.0:
				_env_sat = e2.adjustment_saturation
			e2.adjustment_saturation = _env_sat * (1.6 + 0.5 * sin(_clock * 2.4))
	_ia_t -= delta
	if _ia_t <= 0.0:
		_ia_t = 0.3
		var p: Vector3 = main._player_pos_v27()
		if not _pick_ia.is_empty():
			var i: int = _pick_near(p)
			_pick_ia["pos"] = _picks[i]["pos"] if i >= 0 else Vector3(0, -9999, 0)
			_pick_ia["text"] = pick_text() if i >= 0 else "E : cueillir"
		if not _secret_ia.is_empty():
			var j: int = _secret_near(p)
			var sp: Vector3 = Vector3(0, -9999, 0)
			for s in _secret_nodes:
				if int(s["i"]) == j:
					sp = s["pos"]
			_secret_ia["pos"] = sp
		# les cachettes tournent doucement
		if active.has("champi_lune"):
			for s2 in _secret_nodes:
				(s2["node"] as Node3D).rotate_y(0.3 * 0.6)

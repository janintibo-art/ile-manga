extends Node3D
## V67 : Arcanelle, l'île des sorciers — le chef d'orchestre. Il construit l'île
## (ile_arcane_v67), ce qu'on y a bâti (arcanelle_bourg_v67), la végétation (arcane_flore_v67) ;
## il fait vivre les seize habitants de la communauté (pnj_arcanelle_v67) selon l'heure ;
## il anime le Grand Cristal, les braseros de l'Aire des Duels, la cloche de la Tour Penchée,
## les runes de la crypte, le Cristal de Givre de l'îlot, la chouette blessée, les fumées ;
## il propose les services (une chambre au Chaudron Fumant, la voyance d'Agathe) et suit les
## leçons des maîtres (les trouvailles « lecon_… » du carnet) et la cérémonie du diplôme.

const IleScript = preload("res://scripts/ile_arcane_v67.gd")
const BourgScript = preload("res://scripts/arcanelle_bourg_v67.gd")
const FloreScript = preload("res://scripts/arcane_flore_v67.gd")
const Habitants = preload("res://scripts/pnj/arcanelle_habitants_v67.gd")
const PnjArc = preload("res://scripts/pnj/pnj_arcanelle_v67.gd")

const SORTS := ["lumiere", "feu", "gel", "levitation", "telekinesie", "soin"]
const BRASERO_TEMPS: float = 90.0           # un brasero allumé brûle une minute et demie

var main: Node
var ile: Node3D
var bourg: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "nuits": 0, "lecons": {}, "cloche": 0, "braseros": 0, "chouette": false, "ceremonie": false}
var _claims: Dictionary = {}
var _clock: float = 0.0
var _bell_swing: float = 0.0
var _smoke: Array = []
var _fires: Array = []
var _owl_heal: float = -1.0
var _ceremony_t: float = -1.0
var _interactions: Array = []
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 6790


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_arcane_v67"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : ce qu'on a bâti, la végétation, les objets animés.
func build_town() -> void:
	bourg = BourgScript.new()
	bourg.name = "Bourg_arcanelle_v67"
	add_child(bourg)
	bourg.build(main, ile, pc)
	flore = FloreScript.new()
	flore.name = "Flore_arcanelle_v67"
	add_child(flore)
	for a in bourg.flora_avoid:
		flore.avoid.append(a)
	flore.avoid.append([Vector2(bourg.islet_pos.x, bourg.islet_pos.z), 4.0])
	flore.build_arcanelle(ile, bourg.garden_beds, pc, bourg.big_trees)
	for sp in bourg.smoke_spots:
		_smoke.append(_make_smoke(sp))
	for fs in bourg.fire_spots:
		_fires.append(_make_fire(fs[0], float(fs[1]), true))
	for i in range(bourg.braziers.size()):
		var b: Dictionary = bourg.braziers[i]
		var f: Node3D = _make_fire(b["pos"], 0.9, false)
		b["node"] = f
	print("ILE_MANGA_V67: Arcanelle prête")


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À pied : dans l'eau du Lac Miroir, on ne marche pas (sauf sur la glace du sort de gel).
func blocks_walk(p: Vector3) -> bool:
	if ile == null or not ile.in_lake(p.x, p.z):
		return false
	return p.y < IleScript.LAKE_Y + 0.08


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	if bourg != null:
		for it in bourg.interiors:
			var c: Vector3 = it[1]
			var half: Vector2 = it[2]
			if absf(p.x - c.x) < half.x + 0.6 and absf(p.z - c.z) < half.y + 0.6 and p.y > float(it[3]) - 1.0 and p.y < float(it[3]) + 4.0:
				return "arcanelle_" + str(it[0])
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -0.42 and p.y < 2.0:
		return "" if ile.coast_q(l.x, l.y) > 1.15 else "arcanelle_rivage"
	if l.x > 18.0 and l.x < 76.0 and l.y > 20.0 and l.y < 68.0:
		return "arcanelle_bourg"
	if l.y < -70.0:
		return "arcanelle_falaises"
	if Vector2(l.x + 62.0, l.y - 46.0).length() < 28.0:
		return "arcanelle_bois"
	return "arcanelle"


func respawn_point() -> Array:
	var at: Vector3 = IleScript.W(46.0, 50.5, IleScript.town_y(46.0, 50.5) + 0.3)
	return [at, Vector3(0, 0, -1)]


# =================================================================== les habitants

func hour() -> float:
	return float(main.temps_v56.hour) if main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func spot(name: String) -> Dictionary:
	return bourg.spots.get(name, {}) if bourg != null else {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or bourg == null:
		return
	for data in Habitants.all_profiles():
		var start: String = "b_pn"
		var home: String = str(data.get("maison", ""))
		if bourg.points.has(home):
			start = home
		var npc: Node3D = PnjArc.new()
		main.add_child(npc)
		npc.setup(main, data, bourg.points, bourg.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V67: %d habitants à Arcanelle" % habitants.size())


# =================================================================== services

func register_services(journal: Node) -> void:
	journal.add_service("berthe", Callable(self, "_inn_topics"), Callable(self, "_inn_choose"))
	journal.add_service("agathe", Callable(self, "_agathe_topics"), Callable(self, "_agathe_choose"))
	for k in bourg.objets:
		journal.lieux[k] = bourg.objets[k]
	for k2 in ["buche_arc_1", "buche_arc_2", "buche_arc_3", "champi_arc_1", "champi_arc_2", "champi_arc_3"]:
		journal.lieux[k2] = _extra_spot(k2)
	_register_interactions()


func _extra_spot(k: String) -> Vector3:
	var pts := {"buche_arc_1": Vector2(-50.0, 38.0), "buche_arc_2": Vector2(-72.0, 50.0), "buche_arc_3": Vector2(-58.0, 60.0),
		"champi_arc_1": Vector2(-66.0, 36.0), "champi_arc_2": Vector2(-52.0, 58.0), "champi_arc_3": Vector2(-76.0, 44.0)}
	var v: Vector2 = pts[k]
	var w: Vector3 = IleScript.W(v.x, v.y)
	w.y = ile.height(w.x, w.z) + 0.1
	return w


func _inn_topics(_npc: Node) -> Array:
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return [{"id": "q56:service:chaudron", "label": "☾ %s (6 pièces)" % ("Une chambre sous les toits pour la nuit" if night else "Une sieste au coin du feu")}]


func _inn_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 6:
		return {"texte": "Six pièces, mon chou. Même les sorciers paient leur lit. Surtout les sorciers : ils mettent le feu aux draps.", "geste": "parle"}
	var night: bool = hour() >= 18.0 or hour() < 6.0
	return {"texte": ("La chambre du haut, celle avec la lucarne. Si le chaudron chante cette nuit, c'est normal : il rêve." if night else "Installe-toi près du feu. Je te réveille pour le souper."),
		"geste": "salut", "fin": true, "prendre": [["piece", 6]], "_chaudron_lit": 7.0 if night else 18.5}


func _agathe_topics(_npc: Node) -> Array:
	return [{"id": "q56:service:agathe", "label": "✦ Regarder dans la boule de cristal (3 pièces)"}]


func _agathe_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 3:
		return {"texte": "Trois pièces, mon cœur. La brume de la boule ne se lève pas pour rien.", "geste": "parle"}
	var list: Dictionary = main.journal_v56.listing()
	var lines: Array = []
	for e in list["en_cours"]:
		lines.append("Je vois… %s" % str(e["objectif"]))
	for e2 in list["a_faire"]:
		lines.append("Quelqu'un t'attend… %s." % str(e2["qui"]))
	var txt: String
	if lines.is_empty():
		txt = "La brume est calme… Tu as fait tout ce qu'il y avait à faire. Les étoiles te saluent. Moi aussi."
	else:
		txt = "(Agathe se penche sur la boule. La brume tourne, devient bleue, puis violette.) " + str(lines[_rng.randi() % lines.size()]) + "\n\nLa boule ne ment jamais. Elle exagère, parfois."
	return {"texte": txt, "geste": "parle", "prendre": [["piece", 3]]}


## Appelé par main après un échange réussi : la chambre du Chaudron, un sort appris.
func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_chaudron_lit"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_chaudron_lit"]))
	if r.has("_sort67"):
		var so: Node = main.get("sorts_v67")
		if so != null:
			so.learn(str(r["_sort67"]))


# =================================================================== interactions (E, gâchette)

func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var I: Array = d._interactions
	var bi := {"id": "cloche_tour_penchee", "pos": bourg.bell_pos + Vector3.DOWN * 0.8, "radius": 2.6, "text": "E : faire sonner la cloche", "vr": "Gâchette : faire sonner la cloche",
		"call": _ring_bell, "when": func(): return _bell_swing <= 0.2}
	I.append(bi)
	var ci := {"id": "cristal_givre", "pos": bourg.islet_pos + Vector3.UP * 1.0, "radius": 2.4, "text": "E : toucher le Cristal de Givre", "vr": "Gâchette : toucher le Cristal de Givre",
		"call": _touch_frost, "when": func(): return not _lecon("gel")}
	I.append(ci)
	var ce := {"id": "ceremonie_cercle", "pos": bourg.circle_center + Vector3.UP * 0.8, "radius": 3.0, "text": "E : poser la main sur l'autel des Pierres-Lunes", "vr": "Gâchette : poser la main sur l'autel",
		"call": _ceremony, "when": func(): return _ceremony_ready()}
	I.append(ce)
	_interactions = [bi, ci, ce]


func _lecon(id: String) -> bool:
	return bool((state["lecons"] as Dictionary).get(id, false))


func _set_lecon(id: String, msg: String) -> void:
	if _lecon(id):
		return
	(state["lecons"] as Dictionary)[id] = true
	main._show_message_v28(msg)
	if main.has_method("jingle"):
		main.jingle("decouverte")


func _ring_bell() -> void:
	_bell_swing = 3.0
	state["cloche"] = int(state["cloche"]) + 1
	main.sfx("cloche", bourg.bell_pos)
	var so: Node = main.get("sorts_v67")
	if so != null and so.knows("levitation"):
		_set_lecon("levitation", "La cloche de la Tour Penchée sonne sur toute l'île ! Zéphyrine l'a sûrement entendue.")
	else:
		main._show_message_v28("Dong… La vieille cloche sonne sur toute l'île.")


func _touch_frost() -> void:
	main.sfx("sort_gel", bourg.islet_pos)
	var so: Node = main.get("sorts_v67")
	if so != null and so.knows("gel"):
		_set_lecon("gel", "Le Cristal de Givre s'illumine sous ta main : tu as traversé le Lac Miroir. Borée sera fier de toi.")
	else:
		main._show_message_v28("Le cristal est glacé. Il ne se passe rien… pour l'instant.")


func _ceremony_ready() -> bool:
	var j: Node = main.get("journal_v56")
	if j == null or str(j.state("arc_diplome")) != "en_cours":
		return false
	return str(j._step("arc_diplome").get("cle", "")) == "ceremonie" and not bool(state["ceremonie"])


func _ceremony() -> void:
	_ceremony_t = 0.0
	main.sfx("sort_lumiere", bourg.circle_center + Vector3.UP)
	main._show_message_v28("Les runes du Cercle s'allument une à une… Les neuf Pierres-Lunes chantent. Tu es sorcier d'Arcanelle !")


## Les cibles des sorts (sorts_v67.register) et des pouvoirs des sceaux : les braseros et les
## mannequins brûlent sous la Flamme (le sort de feu d'Arcanelle lance cette même Flamme).
func register_targets(so: Node, pw: Node) -> void:
	if pw != null:
		for i in range(bourg.braziers.size()):
			pw.register({"id": "brasero_arc_%d" % i, "power": "flamme", "pos": bourg.braziers[i]["pos"], "radius": 1.6,
				"call": func(): _light_brazier(i), "when": func(): return not bool(bourg.braziers[i]["lit"])})
		for k in range(bourg.dummies.size()):
			pw.register({"id": "mannequin_arc_%d" % k, "power": "flamme", "pos": bourg.dummies[k]["pos"], "radius": 1.3,
				"call": func(): _burn_dummy(k), "when": func(): return float(bourg.dummies[k]["burn"]) <= 0.0})
	if so == null:
		return
	for r in range(bourg.crypt_runes.size()):
		so.register({"id": "rune_crypte_%d" % r, "sort": "lumiere", "pos": bourg.crypt_runes[r]["pos"], "radius": 4.2, "call": func(): _light_rune(r), "when": func(): return not bool(bourg.crypt_runes[r]["lit"])})
	so.register({"id": "chouette_blessee", "sort": "soin", "pos": bourg.owl_pos + Vector3.UP * 0.3, "radius": 3.5, "call": _heal_owl, "when": func(): return not bool(state["chouette"])})
	so.register({"id": "lac_miroir", "sort": "gel", "pos": IleScript.W(IleScript.LAKE.x, IleScript.LAKE.y, IleScript.LAKE_Y), "radius": IleScript.LAKE_R + 14.0,
		"call": func(): pass, "lake": true})


func _light_brazier(i: int) -> void:
	var b: Dictionary = bourg.braziers[i]
	if bool(b["lit"]):
		return
	b["lit"] = true
	b["t"] = BRASERO_TEMPS
	var f: Node3D = b["node"]
	if f != null:
		f.visible = true
	main.sfx("brasero", b["pos"])
	var n: int = 0
	for bb in bourg.braziers:
		if bool(bb["lit"]):
			n += 1
	state["braseros"] = n
	var so: Node = main.get("sorts_v67")
	if n >= bourg.braziers.size() and so != null and so.knows("feu"):
		_set_lecon("feu", "Les cinq braseros de l'Aire des Duels flambent ! Pyra Flammèche applaudit de loin.")
	elif so != null and so.knows("feu") and not _lecon("feu"):
		main._show_message_v28("Brasero allumé : %d / %d (vite, avant qu'ils ne s'éteignent !)" % [n, bourg.braziers.size()])


func _burn_dummy(k: int) -> void:
	var dm: Dictionary = bourg.dummies[k]
	dm["burn"] = 5.0
	var f: Node3D = _make_fire(dm["pos"] + Vector3.DOWN * 0.3, 0.7, true)
	dm["fire"] = f
	main.sfx("brasero", dm["pos"])


func _light_rune(r: int) -> void:
	var cr: Dictionary = bourg.crypt_runes[r]
	if bool(cr["lit"]):
		return
	cr["lit"] = true
	var m: StandardMaterial3D = cr["mat"]
	m.albedo_color = Color(1.0, 0.82, 0.42, 1.0)
	main.sfx("rune_arc", cr["pos"])
	var n: int = 0
	for c in bourg.crypt_runes:
		if bool(c["lit"]):
			n += 1
	if n >= bourg.crypt_runes.size():
		_set_lecon("lumiere", "Les trois runes de la crypte brillent d'or : « Fiat lux ». Aurélien Lumen voudra le savoir.")
	else:
		main._show_message_v28("Une rune s'éveille sous ta lumière… (%d / %d)" % [n, bourg.crypt_runes.size()])


func _heal_owl() -> void:
	if bool(state["chouette"]):
		return
	state["chouette"] = true
	_owl_heal = 0.0
	main.sfx("sort_soin", bourg.owl_pos)
	_set_lecon("soin", "L'aile de la chouette se redresse… Elle hulule, bat des ailes et s'envole vers la lune. Mère Sauge sera contente.")


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null or bourg == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var near: bool = ile.contains(p.x, p.z)
	if near and not bool(state["visite"]) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("Arcanelle — l'île des sorciers")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if not near:
		return
	# le Grand Cristal tourne et respire
	if bourg.big_crystal != null:
		bourg.big_crystal.rotation.y += delta * 0.35
		bourg.big_crystal.position.y = IleScript.PADS["academie"][3] + 3.0 + sin(_clock * 0.8) * 0.25
	if bourg.islet_crystal != null:
		bourg.islet_crystal.rotation.y -= delta * (1.2 if _lecon("gel") else 0.25)
	# la cloche se balance quand on la fait sonner
	if _bell_swing > 0.0 and bourg.bell != null:
		_bell_swing = maxf(_bell_swing - delta, 0.0)
		bourg.bell.rotation.z = sin(_clock * 6.0) * 0.45 * (_bell_swing / 3.0)
	# les braseros s'éteignent au bout d'une minute et demie (il faut les allumer d'affilée)
	for b in bourg.braziers:
		if bool(b["lit"]):
			b["t"] = float(b.get("t", BRASERO_TEMPS)) - delta
			if float(b["t"]) <= 0.0:
				b["lit"] = false
				if b["node"] != null:
					(b["node"] as Node3D).visible = false
	# les mannequins qui brûlent
	for dm in bourg.dummies:
		if float(dm["burn"]) > 0.0:
			dm["burn"] = float(dm["burn"]) - delta
			if float(dm["burn"]) <= 0.0 and dm.has("fire") and is_instance_valid(dm["fire"]):
				(dm["fire"] as Node3D).queue_free()
				dm.erase("fire")
	# la chouette guérie s'envole
	if bourg.owl != null:
		if _owl_heal >= 0.0:
			_owl_heal += delta
			var t: float = _owl_heal
			bourg.owl.position = bourg.owl_pos + Vector3(t * 1.5, t * t * 0.8 + t, t * 0.6)
			var wing: Node3D = bourg.owl.get_node_or_null("Aile")
			if wing != null:
				wing.rotation.z = 1.0 + sin(_clock * 18.0) * 0.8
			if t > 6.0:
				bourg.owl.visible = false
				_owl_heal = -1.0
		elif bool(state["chouette"]):
			bourg.owl.visible = false
		else:
			var wing2: Node3D = bourg.owl.get_node_or_null("Aile")
			if wing2 != null:
				wing2.rotation.z = 1.0 + (sin(_clock * 9.0) * 0.25 if fmod(_clock, 5.0) < 0.6 else 0.0)
	# la cérémonie du diplôme
	if _ceremony_t >= 0.0:
		_ceremony_t += delta
		if _ceremony_t > 4.0:
			_ceremony_t = -1.0
			state["ceremonie"] = true
			if main.has_method("jingle"):
				main.jingle("victoire")


func _make_smoke(at: Vector3) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee_arc"
	s.amount = 18
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.15, 0.12, 0.05)
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.7, 0.75, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	add_child(s)
	s.global_position = at
	return s


## Un feu (flammes en particules et une lumière orangée qui vacille).
func _make_fire(at: Vector3, s: float, on: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu_arc"
	add_child(root)
	root.global_position = at
	var p := CPUParticles3D.new()
	p.amount = int(24 * s) + 8
	p.lifetime = 0.8
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 0.6 * s
	p.initial_velocity_max = 1.4 * s
	p.gravity = Vector3(0, 1.2, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * s
	p.scale_amount_min = 0.5 * s
	p.scale_amount_max = 1.0 * s
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.45)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	p.mesh = qm
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.6 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 50.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	root.visible = on
	return root


# =================================================================== les leçons, pour le carnet

func trouvailles() -> Dictionary:
	var out := {"arcanelle": 1 if bool(state["visite"]) else 0, "ceremonie": 1 if bool(state["ceremonie"]) else 0}
	for k in SORTS:
		out["lecon_" + str(k)] = 1 if _lecon(str(k)) else 0
	var so: Node = main.get("sorts_v67") if main != null else null
	var n: int = 0
	if so != null:
		for k2 in SORTS:
			if so.knows(str(k2)):
				out["sort_" + str(k2)] = 1
				n += 1
	out["six_sorts"] = 1 if n >= SORTS.size() else 0
	out["cloche_tour"] = 1 if int(state["cloche"]) > 0 else 0
	return out


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	var runes: Array = []
	for c in bourg.crypt_runes:
		runes.append(bool(c["lit"]))
	d["runes"] = runes
	return d


func load_data(d: Dictionary) -> void:
	var lec: Variant = d.get("lecons", {})
	state = {"visite": bool(d.get("visite", false)), "nuits": int(d.get("nuits", 0)), "lecons": (lec as Dictionary).duplicate() if lec is Dictionary else {},
		"cloche": int(d.get("cloche", 0)), "braseros": int(d.get("braseros", 0)), "chouette": bool(d.get("chouette", false)), "ceremonie": bool(d.get("ceremonie", false))}
	if bourg != null:
		for i in range(bourg.braziers.size()):
			bourg.braziers[i]["lit"] = false
			if bourg.braziers[i]["node"] != null:
				(bourg.braziers[i]["node"] as Node3D).visible = false
		var runes: Array = d.get("runes", []) if d.get("runes", []) is Array else []
		for r in range(bourg.crypt_runes.size()):
			var on2: bool = r < runes.size() and bool(runes[r])
			bourg.crypt_runes[r]["lit"] = on2
			(bourg.crypt_runes[r]["mat"] as StandardMaterial3D).albedo_color = Color(1.0, 0.82, 0.42, 1.0) if on2 else Color(0.4, 0.42, 0.48, 0.5)
		if bourg.owl != null:
			bourg.owl.visible = not bool(state["chouette"])
			bourg.owl.position = bourg.owl_pos
	_owl_heal = -1.0
	_ceremony_t = -1.0
	_claims.clear()
	for n in habitants:
		n.slot = -2

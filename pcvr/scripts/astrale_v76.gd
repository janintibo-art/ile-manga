extends Node3D
## V76 : Astralys, l'île flottante des Lumens — le chef d'orchestre. Il construit l'île
## (ile_astrale_v76 : le plateau, le dessous, les îlots, les chutes de lumière) et la cité de
## cristal (astrale_ville_v76) ; il pose la Bouée d'accueil sur la mer et le Rayon d'accueil qui
## monte jusqu'au belvédère ; il fait battre le Cœur de la Flèche, tourner les planètes de la
## fontaine, flotter les méduses de ciel de la Serre ; il allume les ponts de lumière quand on
## approche ; il tient la faible gravité du Jardin des Apesanteurs et son parcours d'anneaux, les
## aurores de la nuit (22 h – 2 h), les pluies d'étoiles filantes (des fragments de météorite à
## ramasser) ; il fait vivre les Lumens selon l'heure. Rien d'hostile ici.

const IleScript = preload("res://scripts/ile_astrale_v76.gd")
const CityScript = preload("res://scripts/astrale_ville_v76.gd")
const Mats = preload("res://scripts/astrale_mats_v76.gd")
const HABITANTS := "res://scripts/pnj/astralys_habitants_v76.gd"
const PNJ := "res://scripts/pnj/pnj_lumen_v76.gd"
const TEXTES := "res://scripts/pnj/astralys_textes_v76.gd"
const HOOP_TIME: float = 45.0

var main: Node
var ile: Node3D
var city: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var T                                    # les textes (astralys_textes_v76), s'ils sont là
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _beam: MeshInstance3D
var _auroras: Array = []
var _creatures: Array = []
var _night: bool = false
var _night_t: float = 0.0
var _hoop_i: int = -1
var _hoop_t: float = 0.0
var _gravity_on: bool = false
var _meteor_wait: float = 240.0
var _meteors: Array = []                 # [MeshInstance3D, départ, arrivée, t]
var _fragments: int = 0
var _visited_t: float = 0.0
var _last_safe := Vector3.ZERO
var _interactions: Array = []
var events: Node3D                       # evenements_v76 (les quêtes d'Astralys, les compagnons qui attendent)


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.randomize()
	state = _fresh_state()
	if ResourceLoader.exists(TEXTES):
		T = load(TEXTES)


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "aurores": false, "record": 0.0, "parcours": 0, "fragments": 0, "rayon": 0}


func _line(group: String, key: String = "") -> String:
	if T == null:
		return ""
	var src: Variant = (T.get_script_constant_map() as Dictionary).get(group, null)
	if key != "" and src is Dictionary:
		src = (src as Dictionary).get(key, null)
	if src is Array and not (src as Array).is_empty():
		return str(src[_rng.randi() % (src as Array).size()])
	return ""


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_astrale_v76"
	add_child(ile)
	ile.build(pc)


## La bouée d'accueil (un ponton sur la mer, sous le belvédère), pour la barque.
func dock() -> Array:
	var b: Vector3 = IleScript.buoy_world()
	var dir: Vector3 = (Vector3(IleScript.LANE_END.x, 0, IleScript.LANE_END.y) - b)
	dir.y = 0.0
	dir = dir.normalized()
	return [b - dir * 3.0, b + dir * 9.0]


func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Astralys_v76"
	add_child(city)
	city.build(main, ile, pc)
	_build_beam()
	_build_auroras()
	_build_creatures()
	_glows()
	print("ILE_MANGA_V76: Astralys est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## Le Rayon d'accueil : une colonne de lumière de la bouée au belvédère, et un anneau de cristal
## qui flotte autour de la bouée.
func _build_beam() -> void:
	var b: Vector3 = IleScript.buoy_world()
	var top: Vector3 = city.rayon_top
	var cm := CylinderMesh.new()
	cm.top_radius = 1.8
	cm.bottom_radius = 2.6
	cm.height = top.y - b.y
	cm.radial_segments = 24
	cm.cap_top = false
	cm.cap_bottom = false
	_beam = MeshInstance3D.new()
	_beam.name = "Rayon_d_accueil"
	_beam.mesh = cm
	var sh: String = "res://shaders/chute_lumiere_v76.gdshader"
	if ResourceLoader.exists(sh):
		var m := ShaderMaterial.new()
		m.shader = load(sh)
		m.set_shader_parameter("speed", -0.25)
		_beam.material_override = m
	else:
		_beam.material_override = Mats.make("pont76_or")
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_beam.global_position = Vector3(b.x, (b.y + top.y) * 0.5, b.z)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.6
	tm.outer_radius = 4.0
	tm.rings = 32
	ring.mesh = tm
	ring.material_override = Mats.make("cristal76_or")
	add_child(ring)
	ring.global_position = b + Vector3(0, 2.2, 0)
	ring.name = "Anneau_de_la_bouee"
	ring.set_meta("spin", true)
	_creatures.append(ring)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.86, 0.6)
	l.light_energy = 2.0
	l.omni_range = 18.0
	l.shadow_enabled = false
	add_child(l)
	l.global_position = b + Vector3(0, 4.0, 0)


## Les aurores : de grands rideaux de lumière au-dessus de l'île (la nuit).
func _build_auroras() -> void:
	var sh: String = "res://shaders/chute_lumiere_v76.gdshader"
	for k in range(4):
		var qm := QuadMesh.new()
		qm.size = Vector2(320.0, 90.0)
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		if ResourceLoader.exists(sh):
			var m := ShaderMaterial.new()
			m.shader = load(sh)
			m.set_shader_parameter("speed", 0.05 + 0.03 * k)
			mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var a: float = k * 0.8 - 1.2
		mi.global_transform = Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.25), IleScript.W(sin(a) * 60.0, cos(a) * 60.0 - 40.0, 190.0 + k * 18.0))
		mi.visible = false
		_auroras.append(mi)


## Les méduses de ciel : des cloches lumineuses qui flottent dans la Serre (et quelques-unes
## dehors, au-dessus des jardins).
func _build_creatures() -> void:
	var spots: Array = city.creatures_at.duplicate()
	spots.append([IleScript.W(-92.0, 58.0, 9.0), 14.0])
	for s in spots:
		for k in range(6):
			var root := Node3D.new()
			var bell := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.6
			sm.height = 0.7
			sm.is_hemisphere = true
			bell.mesh = sm
			var col: Color = [Color(0.5, 0.8, 1.0), Color(0.85, 0.55, 1.0), Color(0.5, 1.0, 0.85)][k % 3]
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(col.r, col.g, col.b, 0.55)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = 1.4
			m.rim_enabled = true
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			bell.material_override = m
			root.add_child(bell)
			for t in range(5):
				var q := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.06, 1.2)
				q.mesh = qm
				q.material_override = m
				root.add_child(q)
				var a: float = TAU * t / 5.0
				q.position = Vector3(cos(a) * 0.3, -0.6, sin(a) * 0.3)
			add_child(root)
			var c: Vector3 = s[0]
			var r: float = float(s[1])
			root.global_position = c + Vector3(_rng.randf_range(-r, r) * 0.6, _rng.randf_range(-2.0, 2.0), _rng.randf_range(-r, r) * 0.6)
			root.set_meta("home", root.global_position)
			root.set_meta("ph", _rng.randf() * TAU)
			_creatures.append(root)


func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		return
	for g in Mats.NIGHT_GLOWS:
		var m: Material = Mats.make(str(g[0]))
		if m != null:
			t.register_glow(m, float(g[1]), float(g[2]))
	if ile != null and ile.terrain_mat != null:
		t.register_glow(ile.terrain_mat, 1.0, 0.1)


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var me = self
	var b: Vector3 = IleScript.buoy_world()
	_ia(d, {"id": "as_rayon_monter", "pos": b + Vector3(0, 1.0, 0), "radius": 3.2, "text": "E : entrer dans le Rayon d'accueil (monter à Astralys)",
		"vr": "Gâchette : monter à Astralys", "call": func(): me.ride_beam(true), "when": func(): return true})
	_ia(d, {"id": "as_rayon_descendre", "pos": city.rayon_top + Vector3(0, 0.3, 0), "radius": 3.0, "text": "E : entrer dans le Rayon d'accueil (redescendre à la bouée)",
		"vr": "Gâchette : redescendre à la bouée", "call": func(): me.ride_beam(false), "when": func(): return true})


func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


## Le Rayon : monter de la bouée au belvédère (up), ou redescendre.
func ride_beam(up: bool) -> void:
	var to: Vector3
	var face: Vector3
	if up:
		to = city.rayon_top + Vector3(0, 0.4, 0)
		var d: Vector3 = (city.portail_point - city.rayon_top)
		d.y = 0.0
		face = d.normalized()
	else:
		var dk: Array = dock()
		to = (dk[0] as Vector3) + Vector3(0, 1.4, 0)
		face = ((dk[1] as Vector3) - (dk[0] as Vector3)).normalized()
	sfx("rayon_montee" if up else "rayon_descente", main._player_pos_v27())
	state["rayon"] = int(state["rayon"]) + 1
	var d35: Node = main.get("donjon_v35")
	if d35 != null and d35.has_method("_fade_to"):
		await d35._fade_to(1.0, 0.5)
	main.place_player_v35(to, face)
	var t: String = _line("RAYON", "monte" if up else "descend")
	if t == "":
		t = "Le rayon te soulève, doucement, comme une bulle de savon… 380 mètres plus haut, les Lumens te font coucou." if up else "Le rayon te repose, tout doucement, sur la bouée. Ta barque t'attend, un peu étonnée."
	main._show_message_v28(t)
	if d35 != null and d35.has_method("_fade_to"):
		await d35._fade_to(0.0, 0.8)


# =================================================================== les repères des autres

func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p)


## Pour l'aéronef (V76) : le dessus de l'île, et la roche du dessous (sans collision) :
## [bas de la roche, dessus] au-dessus de (x, z), ou [] hors de l'île et de ses îlots.
func height(x: float, z: float) -> float:
	return ile.height(x, z) if ile != null else -INF


func rock_span(x: float, z: float) -> Array:
	if ile == null:
		return []
	var l: Vector2 = IleScript.L(x, z)
	var r: float = l.length()
	if r < 240.0:
		var rr: float = float(ile.coast_radius(atan2(l.y, l.x))) + 2.0
		if r < rr:
			var t: float = 1.0 - pow(r / rr, 4.0 / 3.0)
			var top: float = ile.height(x, z)
			if top < -1e6:
				top = IleScript.Y0
			return [IleScript.Y0 - 3.2 - (IleScript.DEPTH - 3.2) * pow(t, 1.15) - 2.0, top]
	for it in IleScript.ISLETS:
		var d: float = l.distance_to(it[1])
		var ir: float = float(it[2]) + 1.5
		if d < ir:
			var t2: float = 1.0 - pow(d / ir, 4.0 / 3.0)
			var ty: float = IleScript.Y0 + float(it[3])
			var top2: float = ile.height(x, z)
			if top2 < -1e6:
				top2 = ty
			return [ty - 1.6 - (float(it[4]) - 1.6) * pow(t2, 1.15) - 2.0, top2]
	return []


func solid(p: Vector3) -> bool:
	var sp: Array = rock_span(p.x, p.z)
	return not sp.is_empty() and p.y > float(sp[0]) and p.y < float(sp[1]) - 0.6


func on_structure(p: Vector3) -> bool:
	return city != null and city.on_structure(p)


## À pied, là-haut : sur le plateau, un îlot, un pont, le belvédère (pas dans le vide).
func walkable(p: Vector3) -> bool:
	if on_structure(p):
		return true
	var h: float = ile.height(p.x, p.z)
	return h > -INF and p.y > h - 3.0


func blocks_boat(_p: Vector3) -> bool:
	return false


func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p):
		return ""
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	if ile.height(p.x, p.z) > -INF:
		return "as_bord"
	return "as_ciel"


func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	return "sauvage" if z in ["as_bord", "as_ciel", "as_apesanteur"] else "ville"


func village_point(id: String) -> Array:
	match id:
		"astralys":
			return respawn_point()
		"astralys_bouee":
			var dk: Array = dock()
			return [(dk[0] as Vector3) + Vector3(0, 1.4, 0), ((dk[1] as Vector3) - (dk[0] as Vector3)).normalized()]
	return []


const PLACES := {"as_fleche": "la Flèche de Cristal", "as_agora": "l'Agora des Étoiles", "as_cafe": "le Café Nébuleuse", "as_bazar": "le Bazar galactique",
	"as_musee": "le Musée des Mondes", "as_academie": "l'Académie des Sciences", "as_observatoire": "l'Observatoire", "as_spatioport": "le Spatioport",
	"as_jardins": "les Jardins suspendus", "as_apesanteur": "le Jardin des Apesanteurs", "as_serre": "la Serre des Espèces", "as_portail": "le Portail d'accueil",
	"as_bulles_no": "le quartier des bulles", "as_bulles_ne": "le quartier des bulles", "as_ville": "la cité", "as_pont": "un pont de lumière",
	"as_bord": "les bords de l'île", "as_ciel": "le ciel d'Astralys"}


func place_name(p: Vector3) -> String:
	return "Astralys, " + str(PLACES.get(zone_at(p), "l'île flottante"))


func respawn_point() -> Array:
	# V80 : quelques pas devant l'arche, pour ne plus arriver collé dans le dos de Halo.
	var p: Vector3 = city.portail_arrivee if city != null and city.portail_arrivee != Vector3.ZERO else IleScript.W(120.0, 120.0)
	return [p + Vector3.UP * 0.3, Vector3(-0.7, 0, -0.7)]


func hostile_zone(_p: Vector3) -> bool:
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== les habitants

func spot(name: String) -> Dictionary:
	if city != null and (city.spots as Dictionary).has(name):
		return city.spots[name]
	return {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


## Pour les postures des îles d'avant (concerts de la V75) : jamais ici.
func concert_on() -> bool:
	return false


func spawn_npcs() -> void:
	if not habitants.is_empty() or city == null or not ResourceLoader.exists(HABITANTS) or not ResourceLoader.exists(PNJ):
		return
	var H = load(HABITANTS)
	var P = load(PNJ)
	for data in H.all_profiles():
		var home: String = str(data.get("maison", ""))
		var start: String = home if city.points.has(home) else str(city.points.keys()[0])
		var npc: Node3D = P.new()
		main.add_child(npc)
		npc.setup(main, data, city.points, city.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V76: %d Lumens à Astralys" % habitants.size())
	if events == null:
		events = preload("res://scripts/evenements_v76.gd").new()
		events.setup(main, self)
		add_child(events)
		if _pending_ev is Dictionary:
			events.load_data(_pending_ev)


func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux[str(k)] = city.objets[k]
	journal.lieux["astralys"] = respawn_point()[0]
	journal.lieux["bouee"] = IleScript.buoy_world() + Vector3(0, 1.0, 0)
	_register_interactions()


func after_reply(_r: Dictionary, _npc: Node) -> void:
	pass


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null or city == null:
		return
	_clock += delta
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		var h: float = hour()
		_night = h >= 22.0 or h < 2.0
		for a in _auroras:
			(a as Node3D).visible = _night
	var p: Vector3 = main._player_pos_v27()
	var near: bool = ile.contains(p) or p.distance_to(IleScript.buoy_world()) < 150.0
	# l'anneau de la bouée tourne ; on voit le rayon de partout (il est haut)
	for c in _creatures:
		if not is_instance_valid(c):
			continue
		if (c as Node).has_meta("spin"):
			(c as Node3D).rotate_y(delta * 0.4)
			continue
		if not near:
			continue
		var home: Vector3 = c.get_meta("home")
		var ph: float = float(c.get_meta("ph"))
		(c as Node3D).global_position = home + Vector3(sin(_clock * 0.2 + ph) * 2.0, sin(_clock * 0.7 + ph) * 0.8, cos(_clock * 0.17 + ph) * 2.0)
		(c as Node3D).scale = Vector3(1.0 + 0.08 * sin(_clock * 2.2 + ph), 1.0 - 0.06 * sin(_clock * 2.2 + ph), 1.0 + 0.08 * sin(_clock * 2.2 + ph))
	if not ile.contains(p):
		_set_gravity(false)
		return
	# l'arrivée
	if not bool(state["visite"]) and ile.on_top(p) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("Astralys — l'île flottante des Lumens (ici, même les cailloux brillent)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	_visited_t -= delta
	if _visited_t <= 0.0:
		_visited_t = 1.0
		var z: String = zone_at(p)
		if z.begins_with("as_") and not z in ["as_bord", "as_ciel", "as_pont"] and not bool((state["visites"] as Dictionary).get("ville", false)):
			state["visites"]["ville"] = true
			main._show_message_v28("Astralys, la cité de cristal et de lumière")
		if _night and not bool(state["aurores"]):
			state["aurores"] = true
			var t: String = _line("AURORES", "annonce")
			say(t if t != "" else "Le ciel s'allume : des rideaux de lumière verte, rose et bleue ondulent au-dessus d'Astralys. La Nuit des Aurores commence !", 8.0)
		(state["visites"] as Dictionary)[z] = true
	# le Cœur de la Flèche bat, les planètes tournent, les anneaux aussi
	var beat: float = pow(maxf(sin(_clock * 2.4), 0.0), 6.0)
	if city.heart_light != null:
		city.heart_light.light_energy = (2.4 + 2.0 * beat + (1.5 if _night else 0.0)) * (events.heart_boost() if events != null else 1.0)
	for i in range(city.holo_planets.size()):
		var pl: Node3D = city.holo_planets[i]
		var r: float = 1.6 + i * 0.75
		var a: float = _clock * (0.6 - i * 0.08) + i * 1.3
		pl.global_position = city.fountain_top + Vector3(cos(a) * r, sin(_clock * 0.5 + i) * 0.4 - 1.0 + i * 0.25, sin(a) * r)
	for hp in city.hoops:
		(hp as Node3D).rotate_object_local(Vector3.FORWARD, delta * 0.5)
	# le Jardin des Apesanteurs : la faible gravité, le parcours
	var in_garden: bool = zone_at(p) == "as_apesanteur"
	_set_gravity(in_garden)
	if in_garden:
		_hoops_tick(delta, p)
	# les étoiles filantes
	_meteors_tick(delta, p)
	# on ne tombe pas : si par malheur on passe par-dessus bord, un filet de lumière nous rattrape
	if ile.on_top(p) or on_structure(p):
		_last_safe = p
	elif p.y < IleScript.Y0 - 25.0 and _last_safe != Vector3.ZERO and p.y > IleScript.Y0 - 300.0:
		main.place_player_v35(respawn_point()[0], respawn_point()[1])
		main._show_message_v28("Oups ! Un filet de lumière te rattrape au vol et te repose doucement près du Portail. Halo soupire : « Les Pieds-Lourds… toujours au bord. »")
		_last_safe = Vector3.ZERO


func _set_gravity(on: bool) -> void:
	if on == _gravity_on:
		return
	_gravity_on = on
	var h: Node = main.get("hero_v28")
	if h == null:
		return
	# le Bolet-Ressort (V75) dure peut-être encore : on ne descend jamais sous lui
	h.jump_mult = maxf(float(h.jump_mult), 1.9) if on else (1.75 if _ressort_active() else 1.0)
	h.fall_bonus = maxf(float(h.fall_bonus), 30.0) if on else (14.0 if _ressort_active() else 0.0)
	if on:
		var t: String = _line("APESANTEUR", "entree")
		main._show_message_v28(t if t != "" else "Tes pieds deviennent légers, légers… Ici, la gravité fait la sieste. Saute !")


func _ressort_active() -> bool:
	var bo: Node = main.get("boucan_v75")
	return bo != null and bo.get("champis") != null and bo.champis != null and bo.champis.is_active("champi_ressort")


## Le parcours d'anneaux : on traverse les sept anneaux dans l'ordre, en moins de 45 s.
func _hoops_tick(delta: float, p: Vector3) -> void:
	if city.hoops.is_empty():
		return
	if _hoop_i >= 0:
		_hoop_t += delta
		if _hoop_t > HOOP_TIME:
			main._show_message_v28("Trop tard ! Les anneaux s'éteignent un instant, puis se rallument. On recommence au premier.")
			_hoop_i = -1
			return
	var nxt: int = maxi(_hoop_i + 1, 0)
	if nxt >= city.hoops.size():
		return
	var hp: Node3D = city.hoops[nxt]
	if p.distance_to(hp.global_position) < 1.5 or (p + Vector3(0, 1.0, 0)).distance_to(hp.global_position) < 1.5:
		sfx("anneau_passe", hp.global_position)
		if nxt == 0:
			_hoop_t = 0.0
			main._show_message_v28("Premier anneau ! Le parcours commence : encore six, dans l'ordre, en moins de %d secondes." % int(HOOP_TIME))
		_hoop_i = nxt
		if _hoop_i == city.hoops.size() - 1:
			var rec: float = float(state["record"])
			state["parcours"] = int(state["parcours"]) + 1
			var best: bool = rec <= 0.0 or _hoop_t < rec
			if best:
				state["record"] = _hoop_t
			main._show_message_v28("Les sept anneaux en %.1f s !%s" % [_hoop_t, " Nouveau record d'Astralys !" if best else " (Record : %.1f s.)" % rec])
			if main.has_method("jingle"):
				main.jingle("victoire")
			_hoop_i = -1


## Les étoiles filantes : la nuit, de temps en temps, une traînée dans le ciel et un fragment de
## météorite qui tombe (doucement) quelque part sur l'île.
func _meteors_tick(delta: float, p: Vector3) -> void:
	for mt in _meteors.duplicate():
		var mi: MeshInstance3D = mt[0]
		mt[3] = float(mt[3]) + delta * 0.35
		var t: float = minf(float(mt[3]), 1.0)
		if is_instance_valid(mi):
			mi.global_position = (mt[1] as Vector3).lerp(mt[2], t)
		if t >= 1.0:
			if is_instance_valid(mi):
				mi.queue_free()
			_meteors.erase(mt)
			var inv: Node = main.get("inventory_v28")
			if inv != null and inv.has_method("spawn_pickup") and inv.ITEMS.has("fragment_meteorite"):
				_fragments += 1
				inv.spawn_pickup("as_meteore_%d_%d" % [int(_now()), _fragments], "fragment_meteorite", 1, (mt[2] as Vector3) + Vector3(0, 0.3, 0))
			sfx("meteorite_impact", mt[2])
	if not _night:
		return
	_meteor_wait -= delta
	if _meteor_wait > 0.0:
		return
	_meteor_wait = _rng.randf_range(90.0, 200.0)
	var a: float = _rng.randf() * TAU
	var l := Vector2(cos(a), sin(a)) * _rng.randf_range(30.0, 140.0)
	var land: Vector3 = IleScript.W(l.x, l.y, ile.top_local(l.x, l.y) + 0.1)
	var from: Vector3 = land + Vector3(_rng.randf_range(-160.0, 160.0), 220.0, _rng.randf_range(-160.0, 160.0))
	var mi2 := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	mi2.mesh = sm
	mi2.material_override = Mats.make("lumiere76_ambre")
	add_child(mi2)
	mi2.global_position = from
	_meteors.append([mi2, from, land, 0.0])
	sfx("etoile_filante", p)
	var t2: String = _line("METEORES", "debut")
	main._show_message_v28(t2 if t2 != "" else "Une étoile filante ! Elle file au-dessus de la Flèche… et tombe quelque part sur l'île, en douceur. Un fragment à ramasser !")


# =================================================================== s'évanouir, sauvegarde

func owns_point(p: Vector3) -> bool:
	return contains(p)


func on_faint(_p: Vector3) -> void:
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Aurore, la guérisseuse, pose une main lumineuse sur votre front. « Voilà. Tout est en ordre. Buvez un thé stellaire, Pied-Lourd. »")


func trouvailles() -> Dictionary:
	return {"astralys": 1 if bool(state["visite"]) else 0, "astralys_ville": 1 if bool((state["visites"] as Dictionary).get("ville", false)) else 0,
		"aurores": 1 if bool(state["aurores"]) else 0, "apesanteur_record": 1 if int(state["parcours"]) > 0 else 0,
		"rayon_accueil": 1 if int(state["rayon"]) > 0 else 0}.merged(events.trouvailles() if events != null else {})


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if events != null:
		d["ev"] = events.serialize()
	elif _pending_ev is Dictionary:
		d["ev"] = (_pending_ev as Dictionary).duplicate(true)
	return d


var _pending_ev: Variant = null


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
	_hoop_i = -1
	_pending_ev = (d["ev"] as Dictionary).duplicate(true) if d.get("ev") is Dictionary else {}
	if events != null:
		events.load_data(_pending_ev)


func ensure_dungeon_at(_p: Vector3) -> void:
	pass

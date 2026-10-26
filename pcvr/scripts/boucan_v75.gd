extends Node3D
## V75 : l'Île du Boucan — le chef d'orchestre. Il construit l'île (ile_boucan_v75), Port-Boucan,
## la ville libre des punks dans la friche du vieux port (boucan_ville_v75 et ses grands lieux,
## boucan_lieux_v75 : la Halle Hurlante, la Conserverie, la Filature, le Cargo de Radio Boucan, le
## skatepark, le Mur d'Expression, le château d'eau, les Boîtes, les Jardins Partagés, le bureau de
## vente de Monsieur Lisse), ce qu'il y a dehors (boucan_dehors_v75 : le Gazomètre et sa Cathédrale
## des Spores, le Bois des Spores, l'Usine Grise, la Casse, la Plage aux Galets, le Phare tagué) et
## la végétation de friche (boucan_flore_v75) ; il tient les feux de baril, les néons et les
## fenêtres qui s'allument à la nuit, les champignons qui luisent, le faisceau du phare ; il fait
## vivre les habitants selon l'heure, les animaux de la ville (faune_v75) et Sardine, le chien
## (chien_v75) ; il réveille les robots de Lisse et les champignards quand on s'en approche ; il
## tient les événements (evenements_v75 : les concerts, la Descente des Déménageurs, les
## graffitis, la Gratuiterie, la Cantine, Radio Boucan), les champignons féeriques
## (champignons_v75) et le donjon de l'Usine Grise (usine_grise_v75).

const IleScript = preload("res://scripts/ile_boucan_v75.gd")
const CityScript = preload("res://scripts/boucan_ville_v75.gd")
const DehorsScript = preload("res://scripts/boucan_dehors_v75.gd")
const Mats = preload("res://scripts/boucan_mats_v75.gd")
const FLORE := "res://scripts/boucan_flore_v75.gd"
const HABITANTS := "res://scripts/pnj/boucan_habitants_v75.gd"
const PNJ := "res://scripts/pnj/pnj_boucan_v75.gd"
const DONJON := "res://scripts/usine_grise_v75.gd"
const EVENEMENTS := "res://scripts/evenements_v75.gd"
const CHAMPIGNONS := "res://scripts/champignons_v75.gd"
const FAUNE := "res://scripts/faune_v75.gd"
const CHIEN := "res://scripts/chien_v75.gd"

## Les repaires de l'île : [id, centre local (x, z), rayon d'éveil, quand ("" toujours, "nuit",
## "jour"), réapparition (s), [[sorte, x, z], …]].
const LAIRS := [
	["usine_cour", Vector2(102.0, 82.0), 40.0, "", 420.0, [["robot_demenageur", 96.0, 78.0], ["robot_demenageur", 108.0, 76.0], ["drone_huissier", 102.0, 86.0]]],
	["casse", Vector2(150.0, 32.0), 36.0, "", 420.0, [["robot_demenageur", 146.0, 30.0], ["drone_huissier", 156.0, 36.0]]],
	["bois_spores", Vector2(-8.0, 122.0), 34.0, "jour", 300.0, [["champignard", -12.0, 118.0], ["champignard", -2.0, 126.0], ["champignard", -8.0, 132.0]]],
	["spores_nuit", Vector2(-122.0, 122.0), 38.0, "nuit", 300.0, [["champignard", -118.0, 116.0], ["champignard", -128.0, 128.0], ["champignard", -122.0, 108.0], ["champignard", -112.0, 126.0]]],
	["champignard_roi", Vector2(-150.0, 62.0), 34.0, "", 900.0, [["champignard_roi", -150.0, 62.0], ["champignard", -144.0, 68.0], ["champignard", -156.0, 56.0]]],
	["friche_sud", Vector2(62.0, 168.0), 40.0, "", 420.0, [["drone_huissier", 58.0, 164.0], ["drone_huissier", 68.0, 172.0], ["robot_demenageur", 62.0, 158.0]]],
]

var main: Node
var ile: Node3D
var city: Node3D                         # Port-Boucan (boucan_ville_v75)
var dehors: Node3D
var flore: Node3D
var faune: Node3D                        # les animaux de la ville
var chien: Node3D                        # Sardine, le chien compagnon
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var lairs: Array = []
var dungeon: Node3D                      # l'Usine Grise
var events: Node                         # les concerts, la Descente, les graffitis…
var champis: Node                        # les champignons féeriques
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fires: Array = []
var _smoke: Array = []
var _night: bool = false
var _night_t: float = 0.0
var _lair_t: float = 0.0
var _interactions: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 7590
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "repaires": {}}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_boucan_v75"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : la ville, le dehors, la végétation, les animaux, les feux,
## les fumées, les repaires, le donjon, les événements, les champignons.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Port_Boucan_v75"
	add_child(city)
	city.build(main, ile, pc)
	dehors = DehorsScript.new()
	dehors.name = "Boucan_dehors_v75"
	add_child(dehors)
	dehors.build(self)
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_boucan_v75"
		add_child(flore)
		for a in city.flora_avoid:
			flore.avoid.append(a)
		for a2 in dehors.flora_avoid:
			flore.avoid.append(a2)
		flore.build_boucan(ile, pc, {"arbres": city.tree_spots})
	for f in city.fire_spots:
		_fires.append(_make_fire(f[0], float(f[1])))
	for f2 in dehors.fire_spots:
		_fires.append(_make_fire(f2[0], float(f2[1])))
	var n_smoke: int = 0
	for sp in city.smoke_spots:
		if n_smoke < (36 if pc else 14):
			_smoke.append(_make_smoke(sp, Color(0.5, 0.5, 0.5, 0.2)))
			n_smoke += 1
	_glows()
	_build_lairs()
	if ResourceLoader.exists(FAUNE):
		faune = load(FAUNE).new()
		faune.name = "Faune_boucan_v75"
		add_child(faune)
		faune.setup(main, self)
		var list: Array = []
		for a3 in city.animals:
			list.append(a3)
		for a4 in dehors.animals:
			list.append(a4)
		faune.populate(list)
	if ResourceLoader.exists(CHIEN):
		chien = load(CHIEN).new()
		chien.name = "Sardine_v75"
		main.add_child(chien)
		chien.setup(main)
	if ResourceLoader.exists(DONJON):
		dungeon = load(DONJON).new()
		dungeon.name = "Usine_Grise_v75"
		add_child(dungeon)
		dungeon.setup(main, self)
	if ResourceLoader.exists(EVENEMENTS):
		events = load(EVENEMENTS).new()
		events.name = "Evenements_v75"
		add_child(events)
		events.setup(main, self)
	if ResourceLoader.exists(CHAMPIGNONS):
		champis = load(CHAMPIGNONS).new()
		champis.name = "Champignons_v75"
		add_child(champis)
		champis.setup(main, self)
	print("ILE_MANGA_V75: l'Île du Boucan est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## La nuit : les fenêtres, les néons, les lampes s'allument ; les champignons et la mousse des
## spores luisent plus fort.
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		return
	t.register_glow(Mats.make("vitre75_on"), 2.2, 0.04)
	for c in Mats.LUEURS:
		t.register_glow(Mats.make("chapeau75_" + str(c)), 1.6, 0.25)
		t.register_glow(Mats.make("lamelles75_" + str(c)), 1.2, 0.15)
	for n in Mats.NEONS:
		t.register_glow(Mats.make("neon75_" + str(n)), 3.0, 0.6)
	t.register_glow(Mats.make("lampe75"), 3.0, 0.1)
	t.register_glow(Mats.make("spore75"), 2.0, 0.5)
	if ile != null and ile.get("terrain_mat") != null:
		t.register_glow(ile.terrain_mat, 1.0, 0.15)
	if flore != null and flore.get("glow_mats") != null:
		for g in flore.glow_mats:
			t.register_glow(g[0], float(g[1]), float(g[2]))
	if dehors != null and t.has_method("register_lamp"):
		for l in dehors.spore_lights:
			t.register_lamp(l, float((l as Light3D).light_energy) * 2.2)


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var me = self
	if dungeon != null and dehors != null:
		_ia(d, {"id": "bo_usine_entree", "pos": dehors.dungeon_door, "radius": 2.4, "text": "E : soulever le rideau de fer et entrer dans l'Usine Grise",
			"vr": "Gâchette : entrer dans l'Usine Grise", "call": func(): me._enter_dungeon(), "when": func(): return true})
	if events != null and events.has_method("register_interactions"):
		events.register_interactions(d)
	if champis != null and champis.has_method("register_interactions"):
		champis.register_interactions(d)


func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func _enter_dungeon() -> void:
	if dungeon == null:
		return
	dungeon.enter()


func say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


## Les concerts du soir (pour les musiciens et la foule).
func concert_on() -> bool:
	return events != null and events.concert_on()


## Le champignon féerique (depuis le sac).
func eat_mushroom(id: String) -> bool:
	return champis != null and champis.eat(id)


# =================================================================== les repères des autres

func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func on_structure(p: Vector3) -> bool:
	return city != null and city.on_structure(p)


## À pied : on peut marcher ici (la terre ferme, les quais, le pont du cargo) ? Pas dans le bassin.
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func blocks_boat(_p: Vector3) -> bool:
	return false


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if dungeon != null and dungeon.contains(p):
		return "bo_usine"
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	if events != null:
		var ez: String = events.zone_override(p)
		if ez != "":
			return ez
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if IleScript.coast_q(l.x, l.y) > 1.12 else "bo_rivage"
	if l.distance_to(IleScript.GAZO) < IleScript.GAZO_R + 2.0:
		return "bo_spores"
	if l.distance_to(IleScript.GAZO) < IleScript.SPORES_R:
		return "bo_bois"
	if l.distance_to(IleScript.USINE) < 46.0:
		return "bo_usine_dehors"
	if l.distance_to(IleScript.CASSE) < 40.0:
		return "bo_casse"
	if l.distance_to(IleScript.PHARE) < 26.0:
		return "bo_phare"
	if l.distance_to(IleScript.PLAGE) < 40.0 or IleScript.coast_q(l.x, l.y) > 0.9:
		return "bo_plage" if l.distance_to(IleScript.PLAGE) < 40.0 else "bo_rivage"
	return "bo_friche"


## La région « culturelle » d'un point (pour les ambiances) : la ville, ou la friche.
func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	if z in ["bo_rivage", "bo_spores", "bo_bois", "bo_usine_dehors", "bo_casse", "bo_phare", "bo_plage", "bo_friche", "bo_usine"]:
		return "sauvage"
	return "ville"


## Les points d'arrivée de la téléportation (teleport_v58).
func village_point(id: String) -> Array:
	match id:
		"boucan":
			return respawn_point()
		"boucan_port":
			var q: Dictionary = spot("quai_1")
			var at: Vector3 = q["pos"] if not q.is_empty() else dock()[0]
			return [at + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return []


const PLACES := {"bo_halle": "la Halle Hurlante", "bo_conserverie": "la Conserverie", "bo_toit": "le toit-jardin de la Conserverie",
	"bo_filature": "la Filature", "bo_place": "la Place des Palettes", "bo_port": "le Vieux Bassin", "bo_cargo": "la Baleine Rouillée (Radio Boucan)",
	"bo_skate": "le Bassin à sec", "bo_mur": "le Mur d'Expression", "bo_jardins": "les Jardins Partagés", "bo_boites": "les Boîtes",
	"bo_ville": "Port-Boucan", "bo_spores": "la Cathédrale des Spores", "bo_bois": "le Bois des Spores", "bo_usine_dehors": "l'Usine Grise",
	"bo_usine": "l'Usine Grise (sous terre)", "bo_casse": "la Casse", "bo_phare": "le Phare tagué", "bo_plage": "la Plage aux Galets",
	"bo_rivage": "le rivage", "bo_friche": "la friche", "bo_descente": "Port-Boucan (la Descente des Déménageurs !)",
	"bo_concert_1": "la Halle Hurlante (concert !)", "bo_concert_2": "la Halle Hurlante (concert !)", "bo_concert_3": "la Halle Hurlante (concert !)",
	"bo_concert_gedeon": "la Halle Hurlante (concert !)"}


## Le nom du lieu (pour le carnet, la page des personnages) : « Île du Boucan, … ».
func place_name(p: Vector3) -> String:
	return "Île du Boucan, " + str(PLACES.get(zone_at(p), "l'île"))


func respawn_point() -> Array:
	var sp: Dictionary = spot("place_fontaine")
	if sp.is_empty():
		return [city.points.values()[0] + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	var f: Vector3 = sp["face"]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3, f if f.length() < 1.5 else Vector3(0, 0, 1)]


## Les monstres de l'île sont éveillés (monstres_v36 : « dehors »).
func hostile_zone(p: Vector3) -> bool:
	for L in lairs:
		if not (L["monsters"] as Array).is_empty() and Vector2(p.x - L["c"].x, p.z - L["c"].z).length() < float(L["r"]) + 20.0:
			return true
	if events != null and events.hostile_zone(p):
		return true
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main != null and main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== les habitants (lieux)

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
	print("ILE_MANGA_V75: %d habitants à Port-Boucan" % habitants.size())


## Les services (les comptoirs : objets_v66 ; les quêtes : journal_v56 ; les lieux des quêtes).
func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux[str(k)] = city.objets[k]
	if dehors != null:
		for k2 in dehors.objets:
			journal.lieux[str(k2)] = dehors.objets[k2]
	journal.lieux["boucan"] = respawn_point()[0]
	if dungeon != null and dungeon.has_method("register"):
		dungeon.register(journal)
	if events != null and events.has_method("register_services"):
		events.register_services(journal)
	_register_interactions()


func after_reply(r: Dictionary, npc: Node) -> void:
	if events != null and events.has_method("after_reply"):
		events.after_reply(r, npc)


# =================================================================== les repaires

func _build_lairs() -> void:
	lairs.clear()
	for L in LAIRS:
		var c: Vector3 = IleScript.W((L[1] as Vector2).x, (L[1] as Vector2).y)
		c.y = ile.height(c.x, c.z)
		lairs.append({"id": str(L[0]), "c": c, "r": float(L[2]), "quand": str(L[3]), "respawn": float(L[4]), "list": L[5], "monsters": [], "dead_t": -1e15})


func _lairs_tick() -> void:
	var ms: Node = main.get("monstres_v36")
	if ms == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var night: bool = hour() >= 20.0 or hour() < 5.5
	for L in lairs:
		var d: float = Vector2(p.x - L["c"].x, p.z - L["c"].z).length()
		var mons: Array = L["monsters"]
		var before: int = mons.size()
		mons = mons.filter(func(m): return is_instance_valid(m) and str(m.get("state")) != "mort")
		L["monsters"] = mons
		if before > 0 and mons.is_empty() and d < float(L["r"]) + 60.0:
			state["repaires"][str(L["id"])] = true
		var q: String = str(L["quand"])
		var allowed: bool = q == "" or (q == "nuit" and night) or (q == "jour" and not night)
		if mons.is_empty() and allowed and d < float(L["r"]) and _now() - float(L["dead_t"]) > float(L["respawn"]):
			for e in L["list"]:
				var at: Vector3 = IleScript.W(float(e[1]), float(e[2]))
				at.y = ile.height(at.x, at.z) + 0.2
				var m: Node3D = ms.spawn_extra(str(e[0]), at)
				if m != null:
					m.set("home", at)
					m.set("state", "veille")
					mons.append(m)
			L["monsters"] = mons
			L["dead_t"] = _now()
		elif not mons.is_empty() and (d > float(L["r"]) + 60.0 or not allowed and d > float(L["r"]) + 10.0):
			for m2 in mons:
				if is_instance_valid(m2):
					m2.queue_free()
			L["monsters"] = []
			L["dead_t"] = -1e15


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		var h: float = hour()
		_night = h >= 19.5 or h < 6.0
		if dehors != null and dehors.phare_light != null:
			dehors.phare_light.visible = _night
	# le faisceau du phare tourne (on le voit de loin, depuis la mer)
	if _night and dehors != null and dehors.phare_light != null:
		dehors.phare_light.rotate_y(delta * 0.6)
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île du Boucan — Port-Boucan, la ville libre (ici, tout se partage, même le bruit)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if city == null:
		return
	var pv: String = people_at(p)
	if pv == "ville" and not bool((state["visites"] as Dictionary).get("ville", false)):
		state["visites"]["ville"] = true
		main._show_message_v28("Port-Boucan, la ville libre du vieux port")
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	# les spores tournent lentement dans la Cathédrale
	if dehors != null:
		for i in range(dehors.spore_lights.size()):
			var l: Light3D = dehors.spore_lights[i]
			if is_instance_valid(l):
				l.light_energy = (1.3 if _night else 0.6) * (0.85 + 0.15 * sin(_clock * 0.7 + i * 1.7))


func _make_smoke(at: Vector3, col: Color, scale_k: float = 1.0) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee"
	s.amount = 10
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.25, 0.12, 0.05)
	s.scale_amount_min = 0.6 * scale_k
	s.scale_amount_max = 1.4 * scale_k
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 12, 6))
	s.visibility_range_end = 160.0
	add_child(s)
	s.position = at
	return s


## Un feu de baril (flammes en particules et une lumière orangée).
func _make_fire(at: Vector3, s: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu"
	add_child(root)
	root.position = at
	var p := CPUParticles3D.new()
	p.amount = int(22 * s) + 8
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
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	root.add_child(p)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.25)
	l.light_energy = 1.5 * s
	l.omni_range = 6.0 * s + 2.0
	l.shadow_enabled = false
	l.position = Vector3.UP * 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 60.0
	l.distance_fade_length = 12.0
	root.add_child(l)
	return root


# =================================================================== s'évanouir

func owns_point(p: Vector3) -> bool:
	if contains(p):
		return true
	return dungeon != null and dungeon.contains(p)


func on_faint(p: Vector3) -> void:
	if champis != null:
		champis.clear_all()
	if chien != null and chien.has_method("on_faint"):
		chien.on_faint()
	if dungeon != null and dungeon.contains(p):
		dungeon.respawn()
		return
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	main._show_message_v28("Vous vous êtes évanoui… Vous vous réveillez sur un canapé de la Place des Palettes, sous une couverture à patchs. Lentille vous tend un bol de soupe : « Prix libre. Bois. »")


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	var ds: Dictionary = dungeon.state if dungeon != null else {}
	var rep: Dictionary = state["repaires"]
	var t := {"boucan": 1 if bool(state["visite"]) else 0, "boucan_ville": 1 if bool((state["visites"] as Dictionary).get("ville", false)) else 0,
		"grande_pelleteuse": 1 if bool(ds.get("boss", false)) else 0, "usine_5": 1 if int(ds.get("profond", 0)) >= 5 else 0, "usine_grise": 1 if bool(ds.get("fini", false)) else 0,
		"champignard_roi": 1 if bool(rep.get("champignard_roi", false)) else 0, "robots_usine": 1 if bool(rep.get("usine_cour", false)) else 0}
	if dungeon != null and dungeon.has_method("trouvailles"):
		t.merge(dungeon.trouvailles(), true)
	if events != null:
		t.merge(events.trouvailles(), true)
	if champis != null:
		t.merge(champis.trouvailles(), true)
	return t


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if dungeon != null:
		d["donjon"] = dungeon.serialize()
	if events != null:
		d["evenements"] = events.serialize()
	if champis != null:
		d["champignons"] = champis.serialize()
	if chien != null and chien.has_method("serialize"):
		d["sardine"] = chien.serialize()
	return d


func ensure_dungeon_at(p: Vector3) -> void:
	if dungeon != null and dungeon.near(p):
		dungeon.ensure_built()


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
	for sub in [[dungeon, "donjon"], [events, "evenements"], [champis, "champignons"], [chien, "sardine"]]:
		if sub[0] != null and sub[0].has_method("load_data"):
			var sd: Variant = d.get(str(sub[1]), {})
			sub[0].load_data(sd if sd is Dictionary else {})
	for L in lairs:
		for m in L["monsters"]:
			if is_instance_valid(m):
				m.queue_free()
		L["monsters"] = []
		L["dead_t"] = -1e15

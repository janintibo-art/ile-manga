extends Node3D
## V71 : l'Île de Montjoie — le chef d'orchestre. Il construit l'île (ile_montjoie_v71), la ville
## fortifiée sur la Butte (montjoie_ville_v71 et ses grands lieux, montjoie_lieux_v71), ce qu'il y
## a dehors (montjoie_dehors_v71 : le port, la ferme et ses champs, le moulin, le lac, le camp des
## gobelins, les Crocs, l'entrée du donjon) et la végétation (montjoie_flore_v71) ; il tient les
## feux, les fumées des cheminées, la lueur des fenêtres à la nuit, les ailes des moulins et les
## oriflammes ; il fait vivre les habitants selon l'heure ; il réveille les monstres de l'île
## (slimes des prés, grenouilles géantes du lac, gobelins du Bois des Lutins…) quand on s'en
## approche ; il tient la Guilde des Aventuriers (guilde_v71 : l'inscription, les rangs, le
## tableau des contrats), les compagnons (compagnons_v71), les événements comiques
## (evenements_v71 : l'alerte aux navets, la maison à acheter, le chapeau du Baron) et le Donjon
## des Mille Marches (mille_marches_v71).

const IleScript = preload("res://scripts/ile_montjoie_v71.gd")
const CityScript = preload("res://scripts/montjoie_ville_v71.gd")
const DehorsScript = preload("res://scripts/montjoie_dehors_v71.gd")
const Mats = preload("res://scripts/montjoie_mats_v71.gd")
const FLORE := "res://scripts/montjoie_flore_v71.gd"
const HABITANTS := "res://scripts/pnj/montjoie_habitants_v71.gd"
const PNJ := "res://scripts/pnj/pnj_montjoie_v71.gd"
const DONJON := "res://scripts/mille_marches_v71.gd"
const GUILDE := "res://scripts/guilde_v71.gd"
const EVENEMENTS := "res://scripts/evenements_v71.gd"
const COMPAGNONS := "res://scripts/compagnons_v71.gd"

## Les repaires de l'île : [id, centre local (x, z), rayon d'éveil, quand ("" toujours, "nuit",
## "jour"), réapparition (s), [[sorte, x, z], …]].
const LAIRS := [
	["pres_est", Vector2(126.0, 178.0), 42.0, "", 300.0, [["slime", 118.0, 170.0], ["slime", 134.0, 184.0], ["slime_bleu", 124.0, 192.0], ["slime", 138.0, 166.0]]],
	["pres_ouest", Vector2(-214.0, -44.0), 40.0, "", 300.0, [["slime", -206.0, -50.0], ["slime_rose", -222.0, -36.0], ["slime", -214.0, -60.0]]],
	["lac_sud", Vector2(226.0, 130.0), 40.0, "", 420.0, [["grenouille_geante", 216.0, 128.0], ["grenouille_geante", 238.0, 132.0]]],
	["lac_nord", Vector2(244.0, 26.0), 40.0, "", 600.0, [["grenouille_reine", 244.0, 28.0], ["grenouille_geante", 228.0, 30.0]]],
	["camp", Vector2(206.0, -236.0), 48.0, "", 900.0, [["gobelin_chef", 206.0, -228.0], ["gobelin", 198.0, -240.0], ["gobelin", 214.0, -242.0], ["gobelin", 204.0, -248.0]]],
	["bois", Vector2(160.0, -150.0), 36.0, "jour", 420.0, [["gobelin", 156.0, -146.0], ["gobelin", 166.0, -156.0]]],
	["bois_nuit", Vector2(188.0, -120.0), 38.0, "nuit", 420.0, [["loup", 182.0, -116.0], ["loup", 194.0, -126.0]]],
	["crocs", Vector2(-190.0, 168.0), 30.0, "", 420.0, [["slime_bleu", -186.0, 164.0], ["slime_bleu", -196.0, 174.0]]],
]

var main: Node
var ile: Node3D
var city: Node3D                         # Montjoie (montjoie_ville_v71)
var dehors: Node3D
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var lairs: Array = []
var dungeon: Node3D                      # le Donjon des Mille Marches
var guilde: Node                         # la Guilde des Aventuriers
var events: Node                         # les événements comiques
var compagnons: Node                     # les compagnons recrutés
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fires: Array = []
var _smoke: Array = []
var _sails: Array = []
var _night: bool = false
var _night_t: float = 0.0
var _lair_t: float = 0.0
var _interactions: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 7190
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "repaires": {}, "nuits": 0}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_montjoie_v71"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : la ville, le dehors, la végétation, les feux, les fumées,
## les repaires, la Guilde, les compagnons, les événements, le donjon.
func build_town() -> void:
	var t0: int = Time.get_ticks_msec()
	city = CityScript.new()
	city.name = "Montjoie_v71"
	add_child(city)
	city.build(main, ile, pc)
	dehors = DehorsScript.new()
	dehors.name = "Montjoie_dehors_v71"
	add_child(dehors)
	dehors.build(self)
	if ResourceLoader.exists(FLORE):
		flore = load(FLORE).new()
		flore.name = "Flore_montjoie_v71"
		add_child(flore)
		for a in city.flora_avoid:
			flore.avoid.append(a)
		for a2 in dehors.flora_avoid:
			flore.avoid.append(a2)
		flore.build_montjoie(ile, pc, {"arbres": city.tree_spots})
	# les feux (cheminées des forges, braseros, feu de camp des gobelins), les fumées des cheminées
	for f in city.fire_spots:
		_fires.append(_make_fire(f[0], float(f[1])))
	for f2 in dehors.fire_spots:
		_fires.append(_make_fire(f2[0], float(f2[1])))
	var n_smoke: int = 0
	for sp in city.smoke_spots:
		if n_smoke < (50 if pc else 20):
			_smoke.append(_make_smoke(sp, Color(0.55, 0.54, 0.53, 0.22)))
			n_smoke += 1
	for k in [city.kit, dehors.kit]:
		for s in k.sails:
			_sails.append(s)
	_glows()
	_build_lairs()
	if ResourceLoader.exists(DONJON):
		dungeon = load(DONJON).new()
		dungeon.name = "Mille_Marches_v71"
		add_child(dungeon)
		dungeon.setup(main, self)
	if ResourceLoader.exists(COMPAGNONS):
		compagnons = load(COMPAGNONS).new()
		compagnons.name = "Compagnons_v71"
		add_child(compagnons)
		compagnons.setup(main, self)
	if ResourceLoader.exists(GUILDE):
		guilde = load(GUILDE).new()
		guilde.name = "Guilde_v71"
		add_child(guilde)
		guilde.setup(main, self)
	if ResourceLoader.exists(EVENEMENTS):
		events = load(EVENEMENTS).new()
		events.name = "Evenements_v71"
		add_child(events)
		events.setup(main, self)
	print("ILE_MANGA_V71: l'Île de Montjoie est prête (%d ms)" % (Time.get_ticks_msec() - t0))


## La nuit : les fenêtres, les vitraux, les lanternes s'allument ; les cristaux d'orage luisent.
func _glows() -> void:
	var t: Node = main.get("temps_v56") if main != null else null
	if t == null or not t.has_method("register_glow"):
		Mats.night(0.0)
		return
	t.register_glow(Mats.make("vitre71_on"), 2.4, 0.12)
	t.register_glow(Mats.make("vitrail71"), 1.6, 0.3)
	t.register_glow(Mats.make("verre71"), 3.2, 0.5)
	t.register_glow(Mats.make("orage71"), 2.6, 1.6)
	if flore != null and flore.get("glow_mats") != null:
		for g in flore.glow_mats:
			t.register_glow(g[0], float(g[1]), float(g[2]))


func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var me = self
	if dungeon != null and dehors != null:
		_ia(d, {"id": "mj_donjon_entree", "pos": dehors.dungeon_door, "radius": 2.4, "text": "E : descendre dans le Donjon des Mille Marches",
			"vr": "Gâchette : descendre dans le Donjon des Mille Marches", "call": func(): me._enter_dungeon(), "when": func(): return true})
	if guilde != null and guilde.has_method("register_interactions"):
		guilde.register_interactions(d)
	if events != null and events.has_method("register_interactions"):
		events.register_interactions(d)


func _ia(d: Node, it: Dictionary) -> void:
	d._interactions.append(it)
	_interactions.append(it)


func _enter_dungeon() -> void:
	if dungeon == null:
		return
	if compagnons != null and compagnons.has_method("on_enter_dungeon"):
		compagnons.on_enter_dungeon()
	dungeon.enter()


func say(text: String, seconds: float = 6.0) -> void:
	if main != null and main.get("donjon_v35") != null:
		main.donjon_v35._say(text, seconds)
	elif main != null:
		main._show_message_v28(text)


func sfx(name: String, at: Vector3) -> void:
	if main != null and main.has_method("sfx"):
		main.sfx(name, at)


# =================================================================== les repères des autres

func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func on_structure(p: Vector3) -> bool:
	return city != null and city.on_structure(p)


## À pied : on peut marcher ici (la terre ferme, les pontons, les quais) ? Pas dans le lac.
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	if ile.in_lake_water(p.x, p.z):
		return false
	return ile.height(p.x, p.z) > -0.3 or p.y > 1.0


func blocks_boat(_p: Vector3) -> bool:
	return false


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if dungeon != null and dungeon.contains(p):
		return "mj_donjon"
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	if events != null and events.has_method("zone_override"):
		var ez: String = events.zone_override(p)
		if ez != "":
			return ez
	var cz: String = city.zone_at(p) if city != null else ""
	if cz != "":
		return cz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if l.distance_to(IleScript.HARBOR) < IleScript.HARBOR_R + 40.0:
		return "mj_port"
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		return "" if IleScript.coast_q(l.x, l.y) > 1.12 else "mj_rivage"
	if IleScript.lake_q(l.x, l.y) < 1.5:
		return "mj_lac"
	if l.distance_to(IleScript.FOREST) < IleScript.FOREST_R:
		return "mj_foret"
	if l.distance_to(IleScript.DUNGEON) < 24.0:
		return "mj_ruine"
	for c in IleScript.CROCS:
		if l.distance_to(Vector2(float(c[0]), float(c[1]))) < float(c[2]) + 8.0:
			return "mj_crocs"
	if IleScript.FIELDS.grow(10.0).has_point(l):
		return "mj_champs"
	if IleScript.coast_q(l.x, l.y) > 0.9:
		return "mj_rivage"
	return "mj_campagne"


## La région « culturelle » d'un point (pour les ambiances) : la ville, ou la campagne.
func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z == "":
		return ""
	if z in ["mj_rivage", "mj_campagne", "mj_foret", "mj_ruine", "mj_crocs", "mj_lac", "mj_champs", "mj_donjon"]:
		return "sauvage"
	return "ville"


## Les points d'arrivée de la téléportation (teleport_v58).
func village_point(id: String) -> Array:
	match id:
		"montjoie":
			return respawn_point()
		"montjoie_port":
			var q: Vector3 = city.points.get("port_q1", dock()[0])
			return [q + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return []


const PLACES := {"mj_chateau": "le Château du Baron", "mj_trone": "la salle du trône", "mj_haute": "Montjoie, la Haute-Ville",
	"mj_temple": "le Temple de l'Aube", "mj_chaumiere": "la Chaumière des Glycines", "mj_moyenne": "Montjoie, la Ville-Moyenne",
	"mj_place": "la Grand-Place", "mj_guilde": "la Guilde des Aventuriers", "mj_auberge": "l'auberge « La Grenouille Repue »",
	"mj_basse": "Montjoie, la Basse-Ville", "mj_port": "le Port des Mouettes", "mj_lac": "le Lac des Grenouilles",
	"mj_foret": "le Bois des Lutins", "mj_ruine": "la tour en ruine des Crocs", "mj_crocs": "les Crocs",
	"mj_champs": "les Champs du Sud", "mj_rivage": "le rivage", "mj_campagne": "la campagne", "mj_donjon": "le Donjon des Mille Marches",
	"mj_alerte": "les Champs du Sud (l'alerte aux navets !)"}


## Le nom du lieu (pour le carnet, la page des personnages) : « Île de Montjoie, … ».
func place_name(p: Vector3) -> String:
	return "Île de Montjoie, " + str(PLACES.get(zone_at(p), "l'île"))


func respawn_point() -> Array:
	if events != null and events.has_method("home_point"):
		var hp: Array = events.home_point()
		if not hp.is_empty():
			return hp
	var sp: Dictionary = spot("place_fontaine")
	if sp.is_empty():
		return [city.points.values()[0] + Vector3.UP * 0.3, Vector3(0, 0, 1)]
	return [(sp["pos"] as Vector3) + Vector3.UP * 0.3, sp["face"]]


## Les monstres de l'île sont éveillés (monstres_v36 : « dehors »).
func hostile_zone(p: Vector3) -> bool:
	for L in lairs:
		if not (L["monsters"] as Array).is_empty() and Vector2(p.x - L["c"].x, p.z - L["c"].z).length() < float(L["r"]) + 20.0:
			return true
	if events != null and events.has_method("hostile_zone") and events.hostile_zone(p):
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
	print("ILE_MANGA_V71: %d habitants à Montjoie" % habitants.size())


## Les services (les comptoirs : objets_v66 ; les quêtes : journal_v56 ; les lieux des quêtes).
func register_services(journal: Node) -> void:
	for k in city.objets:
		journal.lieux[str(k)] = city.objets[k]
	if dehors != null:
		for k2 in dehors.objets:
			journal.lieux[str(k2)] = dehors.objets[k2]
	journal.lieux["montjoie"] = respawn_point()[0]
	journal.lieux["guilde"] = city.lieux.guild_counter
	if dungeon != null and dungeon.has_method("register"):
		dungeon.register(journal)
	if guilde != null and guilde.has_method("register_services"):
		guilde.register_services(journal)
	if events != null and events.has_method("register_services"):
		events.register_services(journal)
	_register_interactions()


func after_reply(r: Dictionary, npc: Node) -> void:
	if guilde != null and guilde.has_method("after_reply"):
		guilde.after_reply(r, npc)
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
		# V72 : une quête acceptée après l'apparition du monstre compte quand même (le chapelet)
		for mq in mons:
			_quest_loot(str(mq.get("kind")), mq)
		if before > 0 and mons.is_empty() and d < float(L["r"]) + 60.0:
			state["repaires"][str(L["id"])] = true
			if str(L["id"]) == "camp" and guilde != null and guilde.has_method("on_camp_cleared"):
				guilde.on_camp_cleared()
		var q: String = str(L["quand"])
		var allowed: bool = q == "" or (q == "nuit" and night) or (q == "jour" and not night)
		if mons.is_empty() and allowed and d < float(L["r"]) and _now() - float(L["dead_t"]) > float(L["respawn"]):
			for e in L["list"]:
				var at: Vector3 = IleScript.W(float(e[1]), float(e[2]))
				at.y = ile.height(at.x, at.z) + 0.2
				if ile.in_lake_water(at.x, at.z):
					at.y = maxf(at.y, IleScript.LAKE_Y + 0.1)
				var m: Node3D = ms.spawn_extra(str(e[0]), at)
				if m != null:
					m.set("home", at)
					m.set("state", "veille")
					_quest_loot(str(e[0]), m)
					mons.append(m)
			L["monsters"] = mons
			L["dead_t"] = _now()
		elif not mons.is_empty() and (d > float(L["r"]) + 60.0 or not allowed and d > float(L["r"]) + 10.0):
			for m2 in mons:
				if is_instance_valid(m2):
					m2.queue_free()
			L["monsters"] = []
			L["dead_t"] = -1e15


## Les objets des quêtes, dans le ventre des monstres : le chapelet de Pétronille, avalé par la
## Grenouille Reine (la bannière du chef gobelin, elle, est toujours dans son butin).
func _quest_loot(kind: String, m: Node) -> void:
	var j: Node = main.get("journal_v56")
	var inv: Node = main.get("inventory_v28")
	if j == null or inv == null:
		return
	var extra: Array = []
	if kind == "grenouille_reine" and str(j.state("mj_petronille")) == "en_cours" and inv.count("chapelet_soleil") == 0:
		extra.append(["chapelet_soleil", 1])
	if not extra.is_empty():
		m.set_meta("butin_extra", extra)
	elif m.has_meta("butin_extra"):
		m.remove_meta("butin_extra")


# =================================================================== la vie de l'île

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	# les ailes des moulins tournent (même de loin : on les voit de partout)
	for s in _sails:
		if is_instance_valid(s):
			(s as Node3D).rotate_object_local(Vector3.BACK, delta * 0.55)
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île de Montjoie — la ville des aventuriers (on y recrute ; on y rit beaucoup)")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if city == null:
		return
	var pv: String = people_at(p)
	if pv == "ville" and not bool((state["visites"] as Dictionary).get("ville", false)):
		state["visites"]["ville"] = true
		main._show_message_v28("Montjoie, la ville fortifiée sur la Butte")
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		var h: float = hour()
		_night = h >= 19.0 or h < 6.0
	# les oriflammes
	var flags: Variant = city.kit.get("flags")
	if flags is Array:
		for i in range((flags as Array).size()):
			var fl: MeshInstance3D = flags[i]
			if not is_instance_valid(fl) or not fl.has_meta("base"):
				continue
			var base: Transform3D = fl.get_meta("base")
			fl.transform = base * Transform3D(Basis(Vector3.UP, sin(_clock * 1.7 + i) * 0.2) * Basis(Vector3.RIGHT, sin(_clock * 2.9 + i * 2.0) * 0.05), Vector3.ZERO)


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


## Un feu (flammes en particules et une lumière orangée).
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
	if compagnons != null and compagnons.has_method("on_faint"):
		compagnons.on_faint()
	if dungeon != null and dungeon.contains(p):
		dungeon.respawn()
		return
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	if events != null and events.has_method("home_point") and not events.home_point().is_empty():
		main._show_message_v28("Vous vous êtes évanoui… et vous vous réveillez dans votre lit, à la Chaumière des Glycines. Quelqu'un vous a bordé. Probablement Pétronille. Ou un voisin très gentil.")
	else:
		main._show_message_v28("Vous vous êtes évanoui… Des aventuriers vous ont ramené sur la Grand-Place, et Mamie Rissole vous a fait manger une part de tourte. On se sent tout de suite mieux.")


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	var ds: Dictionary = dungeon.state if dungeon != null else {}
	var rep: Dictionary = state["repaires"]
	var t := {"montjoie": 1 if bool(state["visite"]) else 0, "montjoie_ville": 1 if bool((state["visites"] as Dictionary).get("ville", false)) else 0,
		"roi_gelatineux": 1 if bool(ds.get("boss", false)) else 0, "donjon_5": 1 if int(ds.get("profond", 0)) >= 5 else 0, "mille_marches": 1 if bool(ds.get("fini", false)) else 0,
		"chef_gobelin": 1 if bool(rep.get("camp", false)) else 0,
		"grenouilles_lac": 1 if bool(rep.get("lac_sud", false)) or bool(rep.get("lac_nord", false)) else 0,
		"slimes_pres": 1 if bool(rep.get("pres_est", false)) or bool(rep.get("pres_ouest", false)) else 0}
	if dungeon != null and dungeon.has_method("trouvailles"):
		t.merge(dungeon.trouvailles(), true)
	if guilde != null and guilde.has_method("trouvailles"):
		t.merge(guilde.trouvailles(), true)
	if events != null and events.has_method("trouvailles"):
		t.merge(events.trouvailles(), true)
	return t


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	if dungeon != null:
		d["donjon"] = dungeon.serialize()
	if guilde != null:
		d["guilde"] = guilde.serialize()
	if events != null:
		d["evenements"] = events.serialize()
	if compagnons != null:
		d["compagnons"] = compagnons.serialize()
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
	for sub in [[dungeon, "donjon"], [guilde, "guilde"], [events, "evenements"], [compagnons, "compagnons"]]:
		if sub[0] != null:
			var sd: Variant = d.get(str(sub[1]), {})
			sub[0].load_data(sd if sd is Dictionary else {})
	for L in lairs:
		for m in L["monsters"]:
			if is_instance_valid(m):
				m.queue_free()
		L["monsters"] = []
		L["dead_t"] = -1e15

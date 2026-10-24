extends Node3D
## V69 : l'Île des Trois Soleils — le chef d'orchestre. Il construit l'île (ile_soleils_v69),
## les trois villages (per_hapy_v69 : les Égyptiens ; yaxche_v69 : les Mayas ; aztlan_v69 :
## les Aztèques) et la végétation (soleils_flore_v69) ; il fait vivre les habitants selon
## l'heure ; il tient les trois grands donjons (pyramide_v69, xibalba_v69, cinq_soleils_v69) et
## l'Autel des Trois Soleils ; il réveille les monstres de l'île quand on s'en approche.

const IleScript = preload("res://scripts/ile_soleils_v69.gd")
const EgypteScript = preload("res://scripts/per_hapy_v69.gd")
const MayaScript = preload("res://scripts/yaxche_v69.gd")
const AztequeScript = preload("res://scripts/aztlan_v69.gd")
const FloreScript = preload("res://scripts/soleils_flore_v69.gd")
const Kit = preload("res://scripts/soleils_kit_v69.gd")
const Habitants = preload("res://scripts/pnj/soleils_habitants_v69.gd")
const PnjSol = preload("res://scripts/pnj/pnj_soleils_v69.gd")
const DONJONS := {"egypte": "res://scripts/pyramide_v69.gd", "maya": "res://scripts/xibalba_v69.gd", "azteque": "res://scripts/cinq_soleils_v69.gd"}

## Les repaires de l'île : [id, centre local (x, z), rayon d'éveil, quand ("" toujours, "nuit"),
## réapparition (s), [[sorte, x, z], …]].
const LAIRS := [
	["fleuve", Vector2(250.0, 46.0), 34.0, "", 480.0, [["crocodile", 238.0, 38.0], ["crocodile", 258.0, 40.0], ["crocodile", 268.0, 52.0]]],
	["plateau", Vector2(196.0, 196.0), 40.0, "nuit", 420.0, [["scorpion", 186.0, 190.0], ["scorpion", 206.0, 194.0], ["scorpion", 196.0, 206.0]]],
	["jungle_nord", Vector2(110.0, -170.0), 44.0, "", 480.0, [["vipere", 100.0, -162.0], ["vipere", 118.0, -176.0], ["araignee", 106.0, -182.0]]],
	["jaguars_volcan", Vector2(-190.0, -90.0), 46.0, "", 540.0, [["jaguar", -182.0, -84.0], ["jaguar", -198.0, -96.0]]],
	["cenote_nuit", Vector2(-84.0, -222.0), 30.0, "nuit", 360.0, [["chauve_souris", -80.0, -218.0], ["chauve_souris", -88.0, -226.0], ["chauve_souris", -76.0, -230.0]]],
	["sud", Vector2(60.0, 200.0), 40.0, "", 480.0, [["ronceux", 52.0, 194.0], ["ronceux", 68.0, 204.0], ["plante", 60.0, 210.0]]],
]

var main: Node
var ile: Node3D
var egypte: Node3D
var maya: Node3D
var azteque: Node3D
var villages: Dictionary = {}           # "egypte" | "maya" | "azteque" -> village
var flore: Node3D
var pc: bool = true
var habitants: Array = []
var by_id: Dictionary = {}
var state := {}
var lairs: Array = []                   # {id, c, r, quand, respawn, list, monsters, dead_t}
var dungeons: Dictionary = {}           # "egypte" | "maya" | "azteque" -> le module du donjon
var altar_kit
var altar_slots: Dictionary = {}        # relique -> Vector3 (où elle se pose sur l'autel)
var altar_relics: Dictionary = {}       # relique -> Node3D
var _claims: Dictionary = {}
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _smoke: Array = []
var _fires: Array = []                  # [Node3D, toujours allumé ?]
var _night: bool = false
var _night_t: float = 0.0
var _lair_t: float = 0.0
var _interactions: Array = []
var _shadufs: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	_rng.seed = 6990
	state = _fresh_state()


func _fresh_state() -> Dictionary:
	return {"visite": false, "visites": {}, "sphinx": 0, "chat": false, "reliques": {}, "autel": false, "nuits": 0, "jaguars_volcan": false}


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_soleils_v69"
	add_child(ile)
	ile.build(pc)


## Après le relief et l'heure du jour : les villages, la végétation, les feux, l'autel.
func build_town() -> void:
	egypte = EgypteScript.new()
	egypte.name = "Per_Hapy_v69"
	add_child(egypte)
	egypte.build(main, ile, pc)
	maya = MayaScript.new()
	maya.name = "Yaxche_v69"
	add_child(maya)
	maya.build(main, ile, pc)
	azteque = AztequeScript.new()
	azteque.name = "Aztlan_v69"
	add_child(azteque)
	azteque.build(main, ile, pc)
	villages = {"egypte": egypte, "maya": maya, "azteque": azteque}
	# les trois grands donjons (construits seulement à la première descente)
	for k in DONJONS:
		if not ResourceLoader.exists(str(DONJONS[k])):
			continue
		var dn: Node3D = load(str(DONJONS[k])).new()
		dn.name = "Donjon_%s_v69" % k
		add_child(dn)
		dn.setup(main, self)
		dungeons[k] = dn
	_build_altar()
	flore = FloreScript.new()
	flore.name = "Flore_soleils_v69"
	add_child(flore)
	for v in villages.values():
		for a in v.flora_avoid:
			flore.avoid.append(a)
	var sycs: Array = []
	for sp in [Vector2(186.0, -6.0), Vector2(240.0, -4.0), Vector2(150.0, -30.0)]:
		sycs.append(IleScript.W(sp.x, sp.y, IleScript.TOWN_E_Y))
	flore.build_soleils(ile, pc, {"palmiers": egypte.palms, "sycomores": sycs, "saules": azteque.willows})
	for v2 in villages.values():
		for sp2 in v2.smoke_spots:
			_smoke.append(_make_smoke(sp2))
		for fs in v2.fire_spots:
			_fires.append([_make_fire(fs[0], float(fs[1]), false), false])
	_make_plume()
	for arm in egypte.kit.animated69:
		_shadufs.append(arm)
	_build_lairs()
	print("ILE_MANGA_V69: l'Île des Trois Soleils est prête")


## L'Autel des Trois Soleils, sur les hautes terres : un cercle de pierre, trois piliers (un
## obélisque, une stèle maya, une pierre du soleil aztèque) ; chacun attend sa relique.
func _build_altar() -> void:
	var holder := Node3D.new()
	holder.name = "Autel_des_Trois_Soleils"
	add_child(holder)
	altar_kit = Kit.new()
	altar_kit.setup(holder, null)
	var c: Vector3 = ile.pads_world["autel"]
	var xf := Transform3D(Basis(), c)
	altar_kit.cyl(xf, 8.0, 8.0, 0.4, "dalles69", 40)
	altar_kit.ring(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), 7.4, 8.2, 0.3, "calc69", 40)
	altar_kit.col_cyl(c, 8.0, 0.4)
	altar_kit.cyl(xf * Transform3D(Basis(), Vector3(0, 0.4, 0)), 1.6, 1.4, 1.0, "calc69", 20)
	altar_kit.disc(xf * Transform3D(Basis(), Vector3(0, 1.41, 0)), 1.35, "psoleil69", 24, 2.7)
	altar_kit.col_cyl(c, 1.6, 1.4)
	var kinds := [["oeil_horus", 90.0], ["masque_jade", 210.0], ["plume_quetzal", 330.0]]
	for k in kinds:
		var a: float = deg_to_rad(float(k[1]))
		var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * 5.2 + Vector3.UP * 0.4
		var face: Vector3 = (c - p) * Vector3(1, 0, 1)
		var pxf := Transform3D(Basis.looking_at(-face.normalized(), Vector3.UP), p)
		match str(k[0]):
			"oeil_horus":
				altar_kit.obelisk(p, 6.0, "calc69")
			"masque_jade":
				altar_kit.stela(pxf, 1.6, 3.4, "glyphm69", false)
			"plume_quetzal":
				altar_kit.cyl(pxf, 0.9, 0.8, 3.0, "tezo69", 16)
				altar_kit.quadz(pxf * Transform3D(Basis(), Vector3(0, 2.0, 0.86)), 1.4, 1.4, "psoleil69")
		# la niche de la relique : un petit socle devant le pilier, dans la pierre de son peuple,
		# le signe de la relique gravé sur sa face
		var slot: Vector3 = p + face.normalized() * 1.6
		var sxf := Transform3D(pxf.basis, slot)
		var mk: String = {"oeil_horus": "gres69_rose", "masque_jade": "pmaya69", "plume_quetzal": "tezo69"}[str(k[0])]
		altar_kit.box(sxf * Transform3D(Basis(), Vector3(0, 0.08, 0)), Vector3(0.9, 0.16, 0.9), mk, 1.0)
		altar_kit.box(sxf * Transform3D(Basis(), Vector3(0, 0.47, 0)), Vector3(0.52, 0.62, 0.52), mk, 1.0)
		altar_kit.box(sxf * Transform3D(Basis(), Vector3(0, 0.85, 0)), Vector3(0.76, 0.14, 0.76), mk, 1.0)
		altar_kit.quadz(sxf * Transform3D(Basis(), Vector3(0, 0.48, 0.265)), 0.42, 0.42, {"oeil_horus": "sym69_oeil", "masque_jade": "sym69_jour_ahau", "plume_quetzal": "sym69_plume"}[str(k[0])])
		altar_kit.col_box(Transform3D(Basis(), slot + Vector3(0, 0.45, 0)), Vector3(0.7, 0.9, 0.7))
		altar_slots[str(k[0])] = slot + Vector3(0, 0.95, 0)
	altar_kit.commit()


func dock() -> Array:
	return [IleScript.W(IleScript.DOCK_A.x, IleScript.DOCK_A.y), IleScript.W(IleScript.DOCK_B.x, IleScript.DOCK_B.y)]


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


func on_structure(p: Vector3) -> bool:
	for v in villages.values():
		if v.on_structure(p):
			return true
	return false


## À pied : on peut marcher ici (la terre ferme, les pontons, les ponts) ? Pas dans l'eau du lac
## ni dans celle du Cénote.
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	if ile.in_lake_water(p.x, p.z) and p.y < IleScript.LAKE_Y + 0.2:
		return false
	if ile.in_cenote(p.x, p.z) and p.y < IleScript.CENOTE_Y + 0.4:
		return false
	return ile.height(p.x, p.z) > -0.3


func blocks_boat(p: Vector3) -> bool:
	return egypte != null and egypte.blocks_boat(p)


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	for k in dungeons:
		if dungeons[k].contains(p):
			return "soleils_d_" + str(k)
	if ile == null or not ile.contains(p.x, p.z) or p.y < -20.0:
		return ""
	for v in villages.values():
		var vz: String = v.zone_at(p)
		if vz != "":
			return vz
	var l: Vector2 = IleScript.L(p.x, p.z)
	var h: float = ile.height(p.x, p.z)
	if h < -0.42 and p.y < 2.0 and not on_structure(p):
		var rv: Vector2 = IleScript.river(l.x, l.y)
		if rv.x < rv.y + 4.0:
			return "soleils_fleuve"
		return "" if ile.coast_q(l.x, l.y) > 1.12 else "soleils_rivage"
	if IleScript._rect_dist(l.x, l.y, IleScript.TOWN_E) < 8.0:
		return "soleils_egypte"
	if l.distance_to(IleScript.PLATEAU) < IleScript.PLATEAU_R + 14.0:
		return "soleils_pyramide"
	if IleScript.river(l.x, l.y).x < 40.0 or IleScript._rect_dist(l.x, l.y, IleScript.FIELDS) < 6.0:
		return "soleils_fleuve"
	if IleScript._rect_dist(l.x, l.y, IleScript.PLAZA_M) < 10.0:
		return "soleils_maya"
	if IleScript.lake_q(l.x, l.y) < 1.15:
		return "soleils_lac"
	if l.distance_to(IleScript.VOLCANO) < 120.0:
		return "soleils_volcan"
	if l.distance_to(IleScript.ALTAR) < 20.0:
		return "soleils_autel"
	if ile.biome_at(p.x, p.z).g > 0.4:
		return "soleils_jungle"
	return "soleils_prairie"


## La région « culturelle » d'un point (pour les ambiances, la musique) : egypte, maya, azteque.
func people_at(p: Vector3) -> String:
	var z: String = zone_at(p)
	if z in ["soleils_egypte", "soleils_pyramide", "soleils_fleuve", "soleils_temple_re"]:
		return "egypte"
	if z in ["soleils_maya", "soleils_cenote", "soleils_jungle"]:
		return "maya"
	if z in ["soleils_azteque", "soleils_lac", "soleils_chinampas", "soleils_volcan"]:
		return "azteque"
	return ""


## Les points d'arrivée de la téléportation (teleport_v58) : la place de chaque village.
func village_point(id: String) -> Array:
	match id:
		"per_hapy":
			return respawn_point()
		"yaxche":
			return [maya.points["m_m"] + Vector3.UP * 0.3, Vector3(0, 0, -1)]
		"aztlan":
			return [azteque.points["pl_c"] + Vector3.UP * 0.3, Vector3(1, 0, 0)]
	return []


## Le nom du lieu (pour le carnet, la page des personnages) : « Trois Soleils, … ».
func place_name(p: Vector3) -> String:
	var z: String = zone_at(p)
	return "Trois Soleils, " + str({"soleils_egypte": "Per-Hâpy", "soleils_temple_re": "Per-Hâpy, le temple de Rê", "soleils_fleuve": "le fleuve Iterou",
		"soleils_pyramide": "le plateau de Rê", "soleils_maya": "Yaxché", "soleils_cenote": "Yaxché, le Cénote sacré", "soleils_jungle": "la jungle",
		"soleils_azteque": "Aztlán", "soleils_chinampas": "les chinampas", "soleils_lac": "le Lac de la Lune", "soleils_volcan": "le Mont Fumant",
		"soleils_autel": "l'Autel des Trois Soleils", "soleils_rivage": "le rivage", "soleils_prairie": "les hautes terres",
		"soleils_d_egypte": "la Pyramide de Rê", "soleils_d_maya": "Xibalba", "soleils_d_azteque": "les Cinq Soleils"}.get(z, "l'île"))


func respawn_point() -> Array:
	var at: Vector3 = IleScript.W(196.0, 4.0, IleScript.TOWN_E_Y + 0.3)
	return [at, Vector3(0, 0, 1)]


## Les monstres de l'île sont éveillés (monstres_v36 : « dehors »).
func hostile_zone(p: Vector3) -> bool:
	for L in lairs:
		if not (L["monsters"] as Array).is_empty() and Vector2(p.x - L["c"].x, p.z - L["c"].z).length() < float(L["r"]) + 20.0:
			return true
	return false


func hour() -> float:
	return float(main.temps_v56.hour) if main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func _now() -> float:
	return float(main.game_menu.seconds) if main != null and main.game_menu != null else 0.0


# =================================================================== les habitants (lieux)

func spot(name: String) -> Dictionary:
	for v in villages.values():
		if (v.spots as Dictionary).has(name):
			return v.spots[name]
	return {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


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
		# les jaguars du Mont Fumant vaincus (la quête de Mixtli)
		if before > 0 and mons.is_empty() and str(L["id"]) == "jaguars_volcan" and d < float(L["r"]) + 60.0:
			state["jaguars_volcan"] = true
		var allowed: bool = str(L["quand"]) == "" or (str(L["quand"]) == "nuit" and night)
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
	var p: Vector3 = main._player_pos_v27()
	if not ile.contains(p.x, p.z):
		return
	if not bool(state["visite"]) and (ile.height(p.x, p.z) > -0.2 or on_structure(p)) and bool(main.get("game_started")):
		state["visite"] = true
		main._show_message_v28("L'Île des Trois Soleils — Per-Hâpy, Yaxché et Aztlán")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	if egypte == null:
		return
	# chaque village découvert (pour le carnet et la téléportation)
	var pv: String = people_at(p)
	if pv != "" and not bool((state["visites"] as Dictionary).get(pv, false)) and ile.height(p.x, p.z) > 0.0:
		state["visites"][pv] = true
		var names := {"egypte": "Per-Hâpy, le village du fleuve (les Égyptiens)", "maya": "Yaxché, la cité de la jungle (les Mayas)", "azteque": "Aztlán, la cité du lac (les Aztèques)"}
		main._show_message_v28(str(names[pv]))
	# le Cénote sacré : on ne nage pas dans l'eau des dieux ; qui y tombe remonte par les marches
	if ile.in_cenote(p.x, p.z) and p.y < IleScript.CENOTE_Y + 0.9 and p.y > IleScript.CENOTE_Y - 6.0:
		var sb: Array = ile.paths_world.get("cenote", [])
		if sb.size() >= 3:
			var top: Vector3 = sb[-3]
			main.place_player_v35(top + Vector3(0, 0.3, 0), (sb[-1] as Vector3) - top)
			main._show_message_v28("L'eau verte du Cénote est aux dieux : on remonte par les marches.")
	# la surface vue d'en dessous suit le plongeur (la mer de l'île est loin du centre du monde)
	var mer: Node = main.get("mer_v55")
	if mer != null and mer.get("_underside") != null:
		(mer._underside as Node3D).global_position = Vector3(snappedf(p.x, 40.0), (mer._underside as Node3D).global_position.y, snappedf(p.z, 40.0))
	_clock += delta
	_lair_t -= delta
	if _lair_t <= 0.0:
		_lair_t = 0.5
		_lairs_tick()
	# la nuit : les torches, les braseros
	_night_t -= delta
	if _night_t <= 0.0:
		_night_t = 2.0
		# Miou ne dort sous le mastaba que tant que Nebet le cherche
		if _cat != null:
			_cat.visible = _cat_visible()
		var h: float = hour()
		var night: bool = h >= 19.0 or h < 6.0
		if night != _night or _clock < 3.0:
			_night = night
			for f in _fires:
				(f[0] as Node3D).visible = night or bool(f[1])
			if not night:
				state["nuits"] = int(state["nuits"]) + 0
	# les oriflammes, les chadoufs
	for v in villages.values():
		for i in range(v.kit.flags.size()):
			var fl: MeshInstance3D = v.kit.flags[i]
			var base: Transform3D = fl.get_meta("base")
			fl.transform = base * Transform3D(Basis(Vector3.UP, sin(_clock * 1.7 + i) * 0.2) * Basis(Vector3.RIGHT, sin(_clock * 2.9 + i * 2.0) * 0.05), Vector3.ZERO)
	for k in range(_shadufs.size()):
		var arm: Node3D = _shadufs[k]
		arm.rotation.x = sin(_clock * 0.55 + k * 2.1) * 0.32


func _make_smoke(at: Vector3) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.name = "Fumee_sol"
	s.amount = 14
	s.lifetime = 5.0
	s.emitting = true
	s.direction = Vector3(0.2, 1, 0.1)
	s.spread = 12.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.2, 0.12, 0.05)
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.6))
	s.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.66, 0.64, 0.6, 0.22)
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


## Le panache du Mont Fumant : une fumée grise et lente qui monte du cratère et part avec le vent.
func _make_plume() -> void:
	var c: Vector3 = IleScript.W(IleScript.VOLCANO.x, IleScript.VOLCANO.y)
	c.y = ile.height(c.x, c.z) + 2.0
	var s := CPUParticles3D.new()
	s.name = "Panache_Mont_Fumant"
	s.amount = 36 if pc else 16
	s.lifetime = 16.0
	s.preprocess = 16.0
	s.emitting = true
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	s.emission_sphere_radius = 5.0
	s.direction = Vector3(0, 1, 0)
	s.spread = 10.0
	s.initial_velocity_min = 2.2
	s.initial_velocity_max = 3.2
	s.gravity = Vector3(0.55, 0.05, 0.25)
	s.angular_velocity_min = -6.0
	s.angular_velocity_max = 6.0
	s.scale_amount_min = 0.8
	s.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35))
	curve.add_point(Vector2(0.4, 1.4))
	curve.add_point(Vector2(1.0, 2.6))
	s.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.5, 0.48, 0.46, 0.0))
	grad.set_color(1, Color(0.82, 0.8, 0.78, 0.0))
	grad.add_point(0.12, Color(0.55, 0.53, 0.5, 0.42))
	grad.add_point(0.6, Color(0.75, 0.73, 0.7, 0.26))
	s.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(10.0, 10.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 1)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if main != null and main.has_method("_soft_dot_v24"):
		m.albedo_texture = main._soft_dot_v24()
	qm.material = m
	s.mesh = qm
	s.visibility_aabb = AABB(Vector3(-60, -10, -60), Vector3(160, 120, 120))
	add_child(s)
	s.global_position = c


## Un feu (flammes en particules et une lumière orangée qui vacille).
func _make_fire(at: Vector3, s: float, on: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "Feu_sol"
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


# =================================================================== les habitants

func spawn_npcs() -> void:
	if not habitants.is_empty() or egypte == null:
		return
	for data in Habitants.all_profiles():
		var v: Node3D = villages.get(str(data.get("village", "egypte")), egypte)
		var home: String = str(data.get("maison", ""))
		var start: String = home if v.points.has(home) else str(v.points.keys()[0])
		var npc: Node3D = PnjSol.new()
		main.add_child(npc)
		npc.setup(main, data, v.points, v.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	print("ILE_MANGA_V69: %d habitants sur l'Île des Trois Soleils" % habitants.size())


## Les services : la bénédiction de Rê (Néferet soigne), le cacao d'Ix Chab, la galette de Mérit
## sont au comptoir (objets_v66) ; les quêtes au carnet (journal_v56).
func register_services(journal: Node) -> void:
	journal.add_service("neferet", Callable(self, "_neferet_topics"), Callable(self, "_neferet_choose"))
	for v in villages.values():
		for k in v.objets:
			journal.lieux[str(k)] = v.objets[k]
	journal.lieux["sphinx"] = egypte.sphinx_talk
	journal.lieux["pyramide"] = egypte.pyramid_door
	journal.lieux["kukulkan"] = maya.temple_door
	journal.lieux["grand_temple"] = azteque.temple_gate
	journal.lieux["autel_soleils"] = ile.pads_world["autel"]
	for i in range(5):
		journal.lieux["cempasuchil_%d" % i] = _flower_spot(i)
	for d in dungeons.values():
		if d != null and d.has_method("register"):
			d.register(journal)
	_register_interactions()


func _neferet_topics(_npc: Node) -> Array:
	return [{"id": "q56:service:benediction", "label": "☀ La bénédiction de Rê (une offrande de 3 pièces)"}]


func _neferet_choose(_npc: Node, _choice: String) -> Dictionary:
	var hero: Node = main.get("hero_v28")
	if hero != null and int(hero.hp) >= int(hero.HP_MAX) and not main.xr_active:
		return {"texte": "Ton cœur bat fort et ton souffle est plein. Rê n'a rien à te donner aujourd'hui… sinon sa lumière, et celle-là est gratuite.", "geste": "rire"}
	if main.inventory_v28.count("piece") < 3:
		return {"texte": "Trois pièces pour l'offrande du temple. Les dieux ne sont pas avares, mais le temple a des lampes à remplir.", "geste": "parle"}
	return {"texte": "Agenouille-toi. … « Rê qui renais chaque matin, rends à celui-ci la force de sa journée. » Voilà. Tu es neuf, comme le soleil à l'aube.",
		"geste": "salut", "prendre": [["piece", 3]], "_soins69": true}


func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_soins69"):
		var hero: Node = main.get("hero_v28")
		if hero != null:
			hero.hp = hero.HP_MAX
			hero.health_changed.emit(hero.hp, hero.HP_MAX)
		if main.has_method("sfx"):
			main.sfx("sort_soin", main._player_pos_v27() + Vector3.UP)


## Les bouquets de cempasúchil (la quête de Xóchitl) : sur les chinampas du sud.
func _flower_spot(i: int) -> Vector3:
	var pts := [Vector2(-104.0, 174.0), Vector2(-140.0, 166.0), Vector2(-168.0, 150.0), Vector2(-186.0, 128.0), Vector2(-86.0, 182.0)]
	var p: Vector2 = pts[i]
	var c: Vector2 = Vector2(p.x - fposmod(p.x + 300.0, 7.2) + 2.5, p.y - fposmod(p.y + 300.0, 26.0) + 12.2)
	return IleScript.W(c.x, c.y, IleScript.LAKE_Y + 0.5)


# =================================================================== le chat de Nebet, l'autel

func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	# Miou, le chat de Nebet, qui dort à l'ombre d'un mastaba
	_cat = _make_cat()
	var cp: Vector3 = egypte.objets["mastaba_chat"]
	_cat.global_position = cp
	var it := {"id": "chat_nebet", "pos": cp, "radius": 1.8, "text": "E : prendre Miou dans tes bras", "vr": "Gâchette : prendre Miou",
		"call": func(): _take_cat(), "when": func(): return _cat_visible()}
	d._interactions.append(it)
	_interactions.append(it)
	# l'Autel des Trois Soleils
	for k in altar_slots:
		var key: String = str(k)
		var ia := {"id": "autel_" + key, "pos": altar_slots[key], "radius": 1.6, "text": "", "vr": "",
			"call": func(): _altar_place(key), "when": func(): return not bool((state["reliques"] as Dictionary).get(key, false))}
		ia["text"] = "E : poser %s sur l'autel" % _relic_name(key)
		ia["vr"] = "Gâchette : poser la relique"
		d._interactions.append(ia)
		_interactions.append(ia)
	_apply_altar()


var _cat: Node3D


func _make_cat() -> Node3D:
	var root := Node3D.new()
	root.name = "Miou"
	add_child(root)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.82, 0.48, 0.22)
	fur.roughness = 0.95
	var parts := [[Vector3(0, 0.16, 0), Vector3(0.16, 0.13, 0.3)], [Vector3(0, 0.27, 0.15), Vector3(0.11, 0.1, 0.1)], [Vector3(0, 0.09, -0.2), Vector3(0.04, 0.04, 0.2)]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		mi.mesh = sm
		mi.scale = p[1] * 2.0
		mi.position = p[0]
		mi.material_override = fur
		root.add_child(mi)
	for s in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.03
		cm.height = 0.06
		ear.mesh = cm
		ear.position = Vector3(s * 0.05, 0.36, 0.15)
		ear.rotation_degrees = Vector3(0, 0, s * (-25.0 if s > 0 else 10.0))
		ear.material_override = fur
		root.add_child(ear)
	return root


func _cat_visible() -> bool:
	var j: Node = main.get("journal_v56")
	return j != null and str(j.state("eg_chat")) == "en_cours" and not bool(state["chat"])


func _take_cat() -> void:
	state["chat"] = true
	_cat.visible = false
	main._show_message_v28("Miou ronronne dans tes bras. Ramène-le à Nebet, à Per-Hâpy !")
	if main.has_method("sfx"):
		main.sfx("chat", _cat.global_position)


const RELIQUES := {"oeil_horus": "l'Œil d'Horus", "masque_jade": "le Masque de Jade", "plume_quetzal": "la Plume de Quetzalcóatl"}


func _relic_name(k: String) -> String:
	return str(RELIQUES.get(k, k))


func _altar_place(key: String) -> void:
	var inv: Node = main.inventory_v28
	if inv.count(key) <= 0:
		main._show_message_v28("Cette niche attend %s. Elle est cachée au fond d'un des trois grands temples de l'île." % _relic_name(key))
		return
	inv.remove(key, 1)
	state["reliques"][key] = true
	_apply_altar()
	if main.has_method("sfx"):
		main.sfx("mecanisme", altar_slots[key])
	var n: int = 0
	for k in RELIQUES:
		if bool((state["reliques"] as Dictionary).get(k, false)):
			n += 1
	if n < 3:
		main._show_message_v28("%s brille sur l'autel. (%d relique%s sur 3)" % [_relic_name(key).capitalize(), n, "" if n == 1 else "s"])
		return
	state["autel"] = true
	main._show_message_v28("Les trois soleils se lèvent ensemble ! Rê, Kinich Ahau et Tonatiuh te saluent : tu es l'Enfant des Trois Soleils.")
	if main.has_method("jingle"):
		main.jingle("victoire")
	var j: Node = main.get("journal_v56")
	if j != null:
		if not (j.titres as Array).has("Enfant des Trois Soleils"):
			j.titres.append("Enfant des Trois Soleils")
		j.bonus["coeur"] = int(j.bonus.get("coeur", 0)) + 1
		j.apply_bonuses()


## Les reliques posées brillent sur leurs socles ; quand les trois y sont, un rayon d'or monte.
func _apply_altar() -> void:
	for k in RELIQUES:
		var on: bool = bool((state["reliques"] as Dictionary).get(k, false))
		if on and not altar_relics.has(k):
			var n := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.18
			sm.height = 0.36
			n.mesh = sm
			n.material_override = Kit.Mats69.make({"oeil_horus": "or69", "masque_jade": "jade69", "plume_quetzal": "plume69"}[k])
			add_child(n)
			n.global_position = altar_slots[k] + Vector3.UP * 0.2
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.85, 0.5)
			l.light_energy = 1.4
			l.omni_range = 5.0
			n.add_child(l)
			altar_relics[k] = n
		elif not on and altar_relics.has(k):
			(altar_relics[k] as Node3D).queue_free()
			altar_relics.erase(k)


# =================================================================== s'évanouir

## Ce point est-il à cette île (dehors, ou dans un de ses donjons) ?
func owns_point(p: Vector3) -> bool:
	if contains(p):
		return true
	for d in dungeons.values():
		if d != null and d.contains(p):
			return true
	return false


func on_faint(p: Vector3) -> void:
	for d in dungeons.values():
		if d != null and d.contains(p):
			d.respawn()
			return
	# dehors : on se réveille au village le plus proche
	var l: Vector2 = IleScript.L(p.x, p.z)
	var at: Vector3
	var msg: String
	if l.distance_to(IleScript.AZTLAN) < l.distance_to(Vector2(196.0, 0.0)) and l.distance_to(IleScript.AZTLAN) < l.distance_to(IleScript.PLAZA_M.get_center()):
		at = azteque.points["pl_c"] + Vector3.UP * 0.3
		msg = "Vous vous êtes évanoui… Des pêcheurs vous ont ramené en pirogue jusqu'à Aztlán."
	elif l.distance_to(IleScript.PLAZA_M.get_center()) < l.distance_to(Vector2(196.0, 0.0)):
		at = maya.points["m_m"] + Vector3.UP * 0.3
		msg = "Vous vous êtes évanoui… Des chasseurs mayas vous ont porté jusqu'à Yaxché."
	else:
		at = respawn_point()[0]
		msg = "Vous vous êtes évanoui… Néferet vous a soigné au temple de Per-Hâpy."
	main.place_player_v35(at, Vector3(0, 0, 1))
	main._show_message_v28(msg)


# =================================================================== carnet, sauvegarde

func trouvailles() -> Dictionary:
	var v: Dictionary = state.get("visites", {})
	var de: Dictionary = dungeons["egypte"].state if dungeons.has("egypte") else {}
	var dm: Dictionary = dungeons["maya"].state if dungeons.has("maya") else {}
	var da: Dictionary = dungeons["azteque"].state if dungeons.has("azteque") else {}
	return {"soleils": 1 if bool(state["visite"]) else 0, "soleils_egypte": 1 if bool(v.get("egypte", false)) else 0,
		"soleils_maya": 1 if bool(v.get("maya", false)) else 0, "soleils_azteque": 1 if bool(v.get("azteque", false)) else 0,
		"sphinx": 1 if int(state["sphinx"]) >= 3 else 0, "chat_trouve": 1 if bool(state["chat"]) else 0,
		"trois_soleils": 1 if bool(state["autel"]) else 0, "jaguars_volcan": 1 if bool(state["jaguars_volcan"]) else 0,
		"pyramide": 1 if bool(de.get("fini", false)) else 0, "apophis": 1 if bool(de.get("boss", false)) else 0,
		"calendrier": 1 if bool(dm.get("calendrier", false)) else 0, "xibalba": 1 if bool(dm.get("fini", false)) else 0,
		"camazotz": 1 if bool(dm.get("boss", false)) else 0, "offrandes": 1 if bool(da.get("ouvert", false)) else 0,
		"cinq_soleils": 1 if bool(da.get("fini", false)) else 0, "cipactli": 1 if bool(da.get("boss", false)) else 0}


func serialize() -> Dictionary:
	var d: Dictionary = state.duplicate(true)
	var dd: Dictionary = {}
	for k in dungeons:
		dd[k] = dungeons[k].serialize()
	d["donjons"] = dd
	return d


## Une partie sauvée dans un donjon : il doit être construit avant qu'on y pose le pied.
func ensure_dungeon_at(p: Vector3) -> void:
	for k in dungeons:
		if dungeons[k].near(p):
			dungeons[k].ensure_built()


func load_data(d: Dictionary) -> void:
	state = _fresh_state()
	for k in state:
		if d.has(k):
			state[k] = d[k] if not (d[k] is Dictionary) else (d[k] as Dictionary).duplicate(true)
	_claims.clear()
	var dd: Variant = d.get("donjons", {})
	for k in dungeons:
		var one: Variant = (dd as Dictionary).get(k, {}) if dd is Dictionary else {}
		dungeons[k].load_data(one if one is Dictionary else {})
	for L in lairs:
		for m in L["monsters"]:
			if is_instance_valid(m):
				m.queue_free()
		L["monsters"] = []
		L["dead_t"] = -1e15

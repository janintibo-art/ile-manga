extends Node3D
## V49 : les ambiances sonores.
##  - Des « nappes » (sons d'ambiance en boucle, non localisés) qui se fondent l'une dans
##    l'autre selon l'endroit : village, jungle, île des elfes, île des nains, grand large,
##    souterrains, Royaume des Racines, cité de Forgefer. Le ressac grossit près du rivage,
##    le vent du volcan avec l'altitude.
##  - Des « émetteurs » placés dans le monde (sons 3D) : cascades, feu de camp, fontaine de
##    lune, cascade de lumière des fées, forges et enclumes des nains, lac de lave, fumerolles,
##    rigoles de lave et Forge Royale.
##  - Des sons « ponctuels » joués au hasard autour du joueur : oiseaux exotiques, mouettes,
##    gouttes qui tombent dans les grottes, carillons féeriques.
## Tout passe par le bus « Ambiance » (réverbération sur le bus « Ambiance_grotte » sous terre).
## Sons : enregistrements CC0 et sons synthétisés (pcvr/tools/generate_sons_v49.py).

const DIR := "res://assets/sons/"
const BEDS := {
	"ressac": "ambiance/ressac", "large": "ambiance/large", "brise": "ambiance/brise",
	"oiseaux": "ambiance/oiseaux_foret", "jungle": "ambiance/jungle_insectes",
	"volcan": "ambiance/vent_volcan", "grotte": "ambiance/grotte", "feerique": "ambiance/feerique",
	"halle": "ambiance/halle_forge", "vent_vol": "ambiance/vent_altitude",
	"sous_marin": "ambiance/sous_marin", "atlantide": "ambiance/atlantide",
	"ville_azur": "ambiance/ville_azur", "port_azur": "ambiance/port_azur", "taverne": "ambiance/taverne",
	"plage": "ambiance/plage", "cigales": "ambiance/cigales", "grillons": "ambiance/grillons",
	"epave": "ambiance/epave", "lande": "ambiance/lande", "brumes": "ambiance/brumes", "desert": "ambiance/desert",
	"souk": "ambiance/souk", "criee": "ambiance/criee", "atelier": "ambiance/atelier",
	"ramure": "ambiance/ramure",
	"port_pirate": "ambiance/port_pirate", "taverne_pirate": "ambiance/taverne_pirate", "marais": "ambiance/marais",
	"nil": "ambiance/nil", "jungle_maya": "ambiance/jungle_maya", "lac_aztlan": "ambiance/lac_aztlan",
	"donjon_pyramide": "ambiance/donjon_pyramide", "donjon_xibalba": "ambiance/donjon_xibalba", "donjon_soleils": "ambiance/donjon_soleils",
	"pandemonia_jour": "ambiance/pandemonia_jour", "pandemonia_nuit": "ambiance/pandemonia_nuit", "champ_lave": "ambiance/champ_lave",
	"port_braise": "ambiance/port_braise", "neuf_cercles": "ambiance/neuf_cercles", "cocyte": "ambiance/cocyte", "arene": "ambiance/arene",
	"thermes_soufre": "ambiance/thermes_soufre",
	"montjoie_jour": "ambiance/montjoie_jour", "montjoie_nuit": "ambiance/montjoie_nuit", "guilde": "ambiance/guilde",
	"campagne": "ambiance/campagne", "lac_grenouilles": "ambiance/lac_grenouilles", "foret_lutins": "ambiance/foret_lutins",
	"donjon_caves": "ambiance/donjon_caves", "donjon_lac": "ambiance/donjon_lac",
	"boucan_jour": "ambiance/boucan_jour", "boucan_nuit": "ambiance/boucan_nuit", "halle_hurlante": "ambiance/halle",
	"spores": "ambiance/spores", "casse": "ambiance/casse", "usine": "ambiance/usine", "port_boucan": "ambiance/port_boucan",
}
## Volume de référence de chaque nappe (dB) quand elle est à fond.
const BED_DB := {
	"ressac": -9.0, "large": -10.0, "brise": -15.0, "oiseaux": -13.0, "jungle": -15.0,
	"volcan": -12.0, "grotte": -12.0, "feerique": -16.0, "halle": -14.0, "vent_vol": -11.0, "sous_marin": -6.0, "atlantide": -10.0,
	"ville_azur": -12.0, "port_azur": -11.0, "taverne": -9.0, "plage": -13.0, "cigales": -17.0, "grillons": -16.0,
	"epave": -9.0, "lande": -14.0, "brumes": -13.0, "desert": -14.0,
	"souk": -11.0, "criee": -10.0, "atelier": -11.0,
	"ramure": -12.0,
	"port_pirate": -13.0, "taverne_pirate": -11.0, "marais": -12.0,
	"nil": -12.0, "jungle_maya": -13.0, "lac_aztlan": -12.0, "donjon_pyramide": -12.0, "donjon_xibalba": -12.0, "donjon_soleils": -12.0,
	"pandemonia_jour": -12.0, "pandemonia_nuit": -12.0, "champ_lave": -11.0, "port_braise": -11.0, "neuf_cercles": -11.0, "cocyte": -10.0,
	"arene": -11.0, "thermes_soufre": -12.0,
	"montjoie_jour": -12.0, "montjoie_nuit": -12.0, "guilde": -10.0, "campagne": -12.0, "lac_grenouilles": -12.0, "foret_lutins": -12.0,
	"donjon_caves": -11.0, "donjon_lac": -11.0,
	"boucan_jour": -13.0, "boucan_nuit": -13.0, "halle_hurlante": -12.0, "spores": -12.0, "casse": -13.0, "usine": -11.0, "port_boucan": -12.0,
}

var main: Node
var beds: Dictionary = {}           # nom -> {player, cur, target}
var emitters: Array = []            # {player, pos, reach}
var targets: Dictionary = {}
var zone: String = ""
var sea: float = 0.0                # 0 : loin de la mer, 1 : au bord de l'eau
var _tick: float = 0.0
var _event_clock: float = 3.0
var _last_zone_v67: String = ""
var _shots: Array = []              # lecteurs 3D pour les sons ponctuels
var _shot_i: int = 0
var _anvils: Array = []             # {player, clock}
var _rng := RandomNumberGenerator.new()
var _streams: Dictionary = {}
var bus_main: int = -1
var bus_cave: int = -1
var built: bool = false
var anvil_hits: int = 0             # nombre de coups d'enclume joués (pour les tests)


func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	_make_buses()
	for k in BEDS:
		var p := AudioStreamPlayer.new()
		p.name = "Nappe_" + str(k)
		p.stream = _loop(str(BEDS[k]))
		p.bus = "Ambiance"
		p.volume_db = -80.0
		add_child(p)
		beds[k] = {"player": p, "cur": 0.0}
		targets[k] = 0.0
	for i in range(4):
		var sp := AudioStreamPlayer3D.new()
		sp.name = "Ponctuel_%d" % i
		sp.bus = "Ambiance"
		sp.unit_size = 12.0
		sp.max_distance = 70.0
		sp.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(sp)
		_shots.append(sp)


func _make_buses() -> void:
	bus_main = AudioServer.get_bus_index("Ambiance")
	if bus_main < 0:
		AudioServer.add_bus()
		bus_main = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_main, "Ambiance")
		AudioServer.set_bus_send(bus_main, "Master")
		AudioServer.set_bus_volume_db(bus_main, -2.0)
	bus_cave = AudioServer.get_bus_index("Ambiance_grotte")
	if bus_cave < 0:
		AudioServer.add_bus()
		bus_cave = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_cave, "Ambiance_grotte")
		AudioServer.set_bus_send(bus_cave, "Ambiance")
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.85
		rv.damping = 0.4
		rv.wet = 0.35
		rv.dry = 0.85
		AudioServer.add_bus_effect(bus_cave, rv)


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var full: String = DIR + path + ".ogg"
	var s: AudioStream = load(full) if ResourceLoader.exists(full) else null
	_streams[path] = s
	return s


func _loop(path: String) -> AudioStream:
	var s: AudioStream = _stream(path)
	if s is AudioStreamOggVorbis:
		s = (s as AudioStreamOggVorbis).duplicate()
		(s as AudioStreamOggVorbis).loop = true
	return s


# =================================================================== émetteurs

## Une source sonore fixe dans le monde (boucle), audible jusqu'à « reach » mètres.
func add_emitter(parent: Node3D, pos: Vector3, path: String, db: float, unit: float, reach: float, cave: bool = false) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = "Son_" + path.get_file()
	p.stream = _loop(path)
	p.volume_db = db
	p.unit_size = unit
	p.max_distance = reach
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p.bus = "Ambiance_grotte" if cave else "Ambiance"
	parent.add_child(p)
	p.global_position = pos
	emitters.append({"player": p, "reach": reach})
	return p


## Une enclume : des coups de marteau en rythme, avec des pauses (le forgeron souffle).
func add_anvil(parent: Node3D, pos: Vector3, cave: bool = false) -> void:
	var p := AudioStreamPlayer3D.new()
	p.name = "Enclume"
	p.volume_db = -4.0
	p.unit_size = 6.0
	p.max_distance = 45.0
	p.bus = "Ambiance_grotte" if cave else "Ambiance"
	parent.add_child(p)
	p.global_position = pos
	_anvils.append({"player": p, "clock": _rng.randf_range(0.5, 3.0), "serie": 0})


## Les émetteurs connus du monde. Appelé une fois que toutes les îles sont construites.
func build_world() -> void:
	built = true
	# Les cascades de l'île du village (V13/V26)
	for b in main.find_children("Brume_cascade_v26", "", true, false):
		var at: Vector3 = (b as Node3D).global_position
		add_emitter(self, at + Vector3.UP * 2.0, "emetteurs/cascade", -2.0, 9.0, 70.0)
		add_emitter(self, at + Vector3.UP * 0.5, "emetteurs/riviere", -6.0, 5.0, 35.0)
	# Le feu de camp du village
	var camp: Node = main.find_child("Feu_camp_original", true, false)
	if camp is Node3D:
		add_emitter(self, (camp as Node3D).global_position + Vector3.UP * 0.4, "emetteurs/feu", -6.0, 3.0, 22.0)
	# Île des elfes : la Fontaine de lune
	var el: Node = main.get("elfes_v41")
	if el != null and el.village != null:
		var g: Vector3 = el.village.G
		add_emitter(self, Vector3(g.x, g.y + 0.8, g.z + 13.5), "emetteurs/ruisseau", -8.0, 4.0, 28.0)
	# Royaume des Racines : la cascade de lumière du Village des Fées
	if el != null and el.feerique != null and el.feerique.s != null:
		var fs: Node3D = el.feerique.s
		add_emitter(self, fs.to_global(Vector3(31.0, 2.0, -99.0)), "emetteurs/ruisseau", -4.0, 6.0, 40.0, true)
	# Île des nains
	var n: Node = main.get("nains_v46")
	if n != null and n.ile != null:
		var pk: Vector3 = n.ile.peak_world()
		add_emitter(self, pk + Vector3.UP * 1.0, "emetteurs/lave", 2.0, 14.0, 110.0)
		add_emitter(self, pk + Vector3.UP * 1.0, "emetteurs/lave_bulles", -2.0, 8.0, 50.0)
		for fp in n.fumaroles:
			add_emitter(self, (fp as Vector3) + Vector3.UP * 0.4, "emetteurs/fumerolle", -8.0, 2.5, 18.0)
		for f in n.forges:
			var fn: Node3D = f
			add_emitter(self, fn.to_global(Vector3(0, 1.2, -1.2)), "emetteurs/feu", -6.0, 3.0, 20.0)
			add_anvil(self, fn.to_global(Vector3(0, 0.9, 0.8)))
		if n.forge_root != null:
			add_emitter(self, n.forge_root.to_global(Vector3(7.0, 0.5, 9.5)), "emetteurs/feu", -9.0, 2.5, 14.0)
		if n.forgefer != null and n.forgefer.s != null:
			var hs: Node3D = n.forgefer.s
			for cx in [-15.0, 15.0]:
				add_emitter(self, hs.to_global(Vector3(cx, 0.5, 0.0)), "emetteurs/lave_bulles", -10.0, 5.0, 26.0, true)
			add_emitter(self, hs.to_global(Vector3(24.0, 3.0, -6.0)), "emetteurs/feu", -4.0, 4.0, 30.0, true)
			add_emitter(self, hs.to_global(Vector3(24.0, 3.0, -6.0)), "emetteurs/lave", -8.0, 5.0, 30.0, true)
			add_anvil(self, hs.to_global(Vector3(19.0, 1.3, -6.0)), true)
	print("ILE_MANGA_V49: ambiances, ", emitters.size(), " émetteurs, ", _anvils.size(), " enclumes")


# =================================================================== chaque image

func _process(delta: float) -> void:
	if main == null:
		return
	var running: bool = bool(main.game_started)
	# Le monde est complet (cité des nains comprise) quand la partie commence.
	if running and not built:
		build_world()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		_choose_zone(running)
		_cull_emitters()
		# V67 : en changeant de lieu (une grotte, une île), ses bruits viennent sans attendre
		if zone != _last_zone_v67:
			_last_zone_v67 = zone
			_event_clock = minf(_event_clock, 1.5)
	# Fondu des nappes vers leur volume cible
	for k in beds:
		var b: Dictionary = beds[k]
		var t: float = float(targets.get(k, 0.0))
		var cur: float = move_toward(float(b["cur"]), t, delta * 0.5)
		b["cur"] = cur
		var p: AudioStreamPlayer = b["player"]
		if cur > 0.001:
			p.volume_db = float(BED_DB[k]) + linear_to_db(cur)
			if not p.playing and p.stream != null:
				p.play(_rng.randf() * maxf(p.stream.get_length() - 1.0, 0.0))
		elif p.playing:
			p.stop()
	if not running:
		return
	_tick_anvils(delta)
	_event_clock -= delta
	if _event_clock <= 0.0:
		_event()


## Où est le joueur ? On en déduit le volume de chaque nappe.
func _choose_zone(running: bool) -> void:
	for k in targets:
		targets[k] = 0.0
	if not running:
		zone = "menu"
		targets["ressac"] = 0.6
		targets["brise"] = 0.5
		return
	var p: Vector3 = main._player_pos_v27()
	var d: Node = main.get("donjon_v35")
	var under: bool = d != null and d.is_inside(p)
	if under:
		var el: Node = main.get("elfes_v41")
		var n: Node = main.get("nains_v46")
		var co: Node = main.get("coeur_v63")
		var so: Node = main.get("soleils_v69")
		var sz: String = so.zone_at(p) if so != null and so.get("ile") != null and so.ile != null else ""
		var br: Node = main.get("braise_v70")
		var bd: Node = br.dungeon if br != null and br.get("dungeon") != null else null
		var mjn: Node = main.get("montjoie_v71")
		var md: Node = mjn.dungeon if mjn != null and mjn.get("dungeon") != null else null
		var bon: Node = main.get("boucan_v75")
		var bud: Node = bon.dungeon if bon != null and bon.get("dungeon") != null else null
		# V75 : dans l'Usine Grise (les machines, partout)
		if bud != null and bud.contains(p):
			zone = "bo_usine"
			targets["usine"] = 1.0
		# V71 : dans le Donjon des Mille Marches (le Lac Souterrain : l'eau qui goutte)
		elif md != null and md.contains(p):
			zone = "mj_donjon"
			targets[str(md.ambience()) if md.has_method("ambience") else "donjon_caves"] = 1.0
			targets["grotte"] = 0.2
		# V70 : dans les Neuf Cercles (le Cocyte : le vent glacé)
		elif bd != null and bd.contains(p):
			zone = "braise_cercles"
			if str(bd.room) == "cocyte":
				targets["cocyte"] = 1.0
			else:
				targets["neuf_cercles"] = 1.0
				targets["volcan"] = 0.3 if str(bd.room) in ["phlegethon", "malebolge", "tourmente"] else 0.0
			targets["grotte"] = 0.2
		# V69 : dans un des trois grands donjons de l'Île des Trois Soleils
		elif sz.begins_with("soleils_d_"):
			zone = sz
			targets[{"soleils_d_egypte": "donjon_pyramide", "soleils_d_maya": "donjon_xibalba", "soleils_d_azteque": "donjon_soleils"}.get(sz, "grotte")] = 1.0
			targets["grotte"] = 0.25
		# V63 : sous le Cœur-de-Pierre, la grotte et le grondement du feu
		elif co != null and co.region_contains(p):
			zone = "coeur"
			targets["grotte"] = 1.0
			targets["halle"] = 0.15
		elif el != null and el.feerique != null and bool(el.feerique.in_zone):
			zone = "racines"
			targets["feerique"] = 1.0
			targets["grotte"] = 0.35
		elif n != null and n.forgefer != null and n.forgefer.s != null and p.distance_to(n.forgefer.s.global_position) < 60.0:
			zone = "forgefer"
			targets["halle"] = 1.0
			targets["grotte"] = 0.25
		else:
			zone = "souterrain"
			targets["grotte"] = 1.0
		sea = 0.0
		return
	# V55 : sous l'eau (le large étouffé), ou sous le dôme de l'Atlantide
	var ocean: Node = main.get("mer_v55")
	if ocean != null and str(ocean.zone) != "":
		zone = str(ocean.zone)
		if zone == "sous_marin":
			targets["sous_marin"] = 1.0
			targets["large"] = 0.15
		else:
			targets["atlantide"] = 1.0
			targets["sous_marin"] = 0.3
		sea = 0.0
		return
	# V58 : au royaume des fées (la prairie, ou le bois creux d'Yggdrasil)
	var fe: Node = main.get("feerie_v58")
	if fe != null and fe.contains(p):
		sea = 0.0
		var frm: String = fe.room(p)
		if frm != "" and frm != "couronne":
			zone = "yggdrasil"
			targets["feerique"] = 1.0
			targets["grotte"] = 0.3
		else:
			zone = "fees"
			targets["feerique"] = 0.75
			targets["oiseaux"] = 0.55
			targets["brise"] = 0.6 if frm == "" else 0.9
		return
	# V54 : en vol sur Ventaile, ou là-haut sur l'île flottante
	var sky: Node = main.get("ciel_v54")
	if sky != null and bool(sky.riding):
		zone = "vol"
		sea = 0.0
		var spd: float = clampf(float(sky.aigle.speed) / 30.0, 0.0, 1.0)
		targets["vent_vol"] = 0.45 + 0.55 * spd
		targets["large"] = 0.25
		return
	if sky != null and sky.on_sky(p):
		var room: String = sky._room(p)
		sea = 0.0
		if room in ["salle", "bibliotheque", "armurerie"]:
			zone = "chateau"
			targets["grotte"] = 0.3
			targets["brise"] = 0.25
		else:
			zone = "ciel"
			targets["vent_vol"] = 0.3
			targets["brise"] = 0.9
			targets["oiseaux"] = 0.25
		return
	sea = _sea_closeness(p)
	var boat: Node = main.get("boat_v29")
	var on_boat: bool = boat != null and bool(boat.driving)
	# V56 : Port-Azur (ville, port, taverne, plage, collines), à bord de L'Hirondelle : le large
	var az: Node = main.get("azur_v56")
	var on_ferry: bool = az != null and az.ferry != null and bool(az.ferry.riding)
	var az_zone: String = az.zone_at(p) if az != null and az.get("ile") != null and az.ile != null and not on_ferry else ""
	if az_zone != "" and not on_boat:
		zone = az_zone
		_azur_beds(az_zone, p)
		_night_beds()
		return
	# V75 : l'Île du Boucan (Port-Boucan, la Halle Hurlante, la Cathédrale des Spores, la Casse, l'usine)
	var bos: Node = main.get("boucan_v75")
	var bo_zone: String = bos.zone_at(p) if bos != null and bos.get("city") != null and bos.city != null and not on_ferry else ""
	if bo_zone != "" and not on_boat:
		zone = bo_zone
		_boucan_beds(bo_zone, p)
		_night_beds()
		return
	# V71 : l'Île de Montjoie (la ville sur la Butte, la Guilde, la campagne, le lac, le bois)
	var mjs: Node = main.get("montjoie_v71")
	var mj_zone: String = mjs.zone_at(p) if mjs != null and mjs.get("city") != null and mjs.city != null and not on_ferry else ""
	if mj_zone != "" and not on_boat:
		zone = mj_zone
		_montjoie_beds(mj_zone, p)
		_night_beds()
		return
	# V70 : l'Île de Braise (Pandémonia, son port, l'arène, les thermes ; le volcan, la lave)
	var brs: Node = main.get("braise_v70")
	var br_zone: String = brs.zone_at(p) if brs != null and brs.get("city") != null and brs.city != null and not on_ferry else ""
	if br_zone != "" and not on_boat:
		zone = br_zone
		_braise_beds(br_zone, p)
		_night_beds()
		return
	# V69 : l'Île des Trois Soleils (le fleuve des Égyptiens, la jungle des Mayas, le lac des Aztèques)
	var sol: Node = main.get("soleils_v69")
	var sol_zone: String = sol.zone_at(p) if sol != null and sol.get("ile") != null and sol.ile != null and not on_ferry else ""
	if sol_zone != "" and not on_boat:
		zone = sol_zone
		_soleils_beds(sol_zone, p)
		_night_beds()
		return
	# V68 : l'Île de la Balafre (Port-Coutelas, ses tavernes, le marais, le ravin, le fort)
	var pir: Node = main.get("pirates_v68")
	var pir_zone: String = pir.zone_at(p) if pir != null and pir.get("ile") != null and pir.ile != null and not on_ferry else ""
	if pir_zone != "" and not on_boat:
		zone = pir_zone
		_balafre_beds(pir_zone, p)
		_night_beds()
		return
	# V67 : Arcanelle, l'île des sorciers
	var arc: Node = main.get("arcanelle_v67")
	var arc_zone: String = arc.zone_at(p) if arc != null and arc.get("ile") != null and arc.ile != null and not on_ferry else ""
	if arc_zone != "" and not on_boat:
		zone = arc_zone
		_arcanelle_beds(arc_zone, p)
		_night_beds()
		return
	# V59 : la grande île de l'est : Carène (dans l'épave), les quatre régions, le massif
	var gr: Node = main.get("grande_v59")
	var gr_zone: String = gr.zone_at(p) if gr != null and gr.get("ile") != null and gr.ile != null and not on_ferry else ""
	if gr_zone != "" and not on_boat:
		zone = gr_zone
		_grande_beds(gr_zone, p)
		_night_beds()
		return
	var island: String = "" if on_ferry else _island_at(p)
	if on_boat or island == "":
		zone = "large"
		targets["large"] = 1.0
		targets["ressac"] = 0.35 * sea
		return
	zone = island
	targets["ressac"] = 0.25 + 0.75 * sea
	match island:
		"village":
			targets["oiseaux"] = 0.8 * (1.0 - 0.5 * sea)
			targets["brise"] = 0.6
		"jungle":
			targets["jungle"] = 1.0 - 0.4 * sea
			targets["oiseaux"] = 0.5
			targets["brise"] = 0.25
		"elfes":
			targets["oiseaux"] = 0.9 * (1.0 - 0.4 * sea)
			targets["brise"] = 0.45
			targets["feerique"] = 0.18
		"nains":
			var alt: float = clampf(p.y / 60.0, 0.0, 1.0)
			targets["volcan"] = 0.55 + 0.45 * alt
			targets["ressac"] = (0.2 + 0.6 * sea) * (1.0 - 0.6 * alt)
	_night_beds()


## V67 : les nappes d'Arcanelle : la lande et le vent, un peu de féerie, la taverne, la crypte.
func _arcanelle_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"arcanelle_chaudron":
			sea = 0.0
			targets["taverne"] = 1.0 if not day or _evening() else 0.6
		"arcanelle_bibliotheque", "arcanelle_salle":
			sea = 0.0
			targets["grotte"] = 0.15
			targets["brise"] = 0.1
		"arcanelle_crypte":
			sea = 0.0
			targets["grotte"] = 0.85
			targets["feerique"] = 0.12
		"arcanelle_bourg":
			targets["ville_azur"] = 0.3 if day else 0.1
			targets["feerique"] = 0.15
			targets["brise"] = 0.4
			targets["ressac"] = 0.25 * sea + 0.05
		"arcanelle_bois":
			targets["feerique"] = 0.45
			targets["oiseaux"] = 0.3 if day else 0.0
			targets["brise"] = 0.2
		"arcanelle_falaises":
			targets["vent_vol"] = 0.55
			targets["brise"] = 0.8
			targets["ressac"] = 0.2 + 0.6 * sea
		"arcanelle_rivage":
			targets["ressac"] = 0.4 + 0.6 * sea
			targets["brise"] = 0.6
		_:
			targets["lande"] = 0.8
			targets["feerique"] = 0.2
			targets["brise"] = 0.5
			targets["ressac"] = 0.3 * sea
			targets["vent_vol"] = clampf((p.y - 14.0) / 20.0, 0.0, 0.35)


## V71 : les nappes de l'Île de Montjoie.
func _montjoie_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	var ville: String = "montjoie_jour" if day else "montjoie_nuit"
	match z:
		"mj_guilde":
			targets["guilde"] = 1.0
		"mj_auberge":
			targets["taverne"] = 1.0
		"mj_trone", "mj_temple", "mj_chaumiere":
			targets["halle"] = 0.5
			targets[ville] = 0.3
		"mj_chateau", "mj_haute", "mj_moyenne", "mj_basse", "mj_place":
			targets[ville] = 1.0
			targets["brise"] = clampf((p.y - 20.0) / 30.0, 0.0, 0.4)
		"mj_alerte":
			targets["campagne"] = 1.0
			targets[ville] = 0.4
		"mj_port":
			targets["port_azur"] = 0.6
			targets["ressac"] = 0.4 + 0.4 * sea
		"mj_lac":
			targets["lac_grenouilles"] = 1.0
			targets["campagne"] = 0.3
		"mj_foret":
			targets["foret_lutins"] = 1.0
			targets["grillons"] = 0.0 if day else 0.5
		"mj_crocs", "mj_ruine":
			targets["brise"] = 0.8
			targets["vent_vol"] = clampf((p.y - 15.0) / 40.0, 0.0, 0.5)
			targets["campagne"] = 0.3
		"mj_rivage":
			targets["ressac"] = 0.5 + 0.5 * sea
			targets["brise"] = 0.4
		_:
			targets["campagne"] = 1.0 if day else 0.3
			targets["grillons"] = 0.0 if day else 0.7
			targets["ressac"] = 0.25 * sea


## V75 : les nappes de l'Île du Boucan.
func _boucan_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	var ville: String = "boucan_jour" if day else "boucan_nuit"
	if z.begins_with("bo_concert"):
		targets["halle_hurlante"] = 0.6
		return
	match z:
		"bo_halle":
			targets["halle_hurlante"] = 0.5
			targets[ville] = 0.3
		"bo_port", "bo_cargo":
			targets["port_boucan"] = 1.0
			targets["ressac"] = 0.3 + 0.4 * sea
		"bo_spores", "bo_bois":
			targets["spores"] = 1.0 if z == "bo_spores" else 0.6
			targets["oiseaux"] = 0.0 if not day or z == "bo_spores" else 0.4
		"bo_casse":
			targets["casse"] = 1.0
		"bo_usine":
			targets["usine"] = 1.0
		"bo_usine_dehors":
			targets["usine"] = 0.6
			targets["brise"] = 0.3
		"bo_phare", "bo_plage", "bo_rivage":
			targets["ressac"] = 0.6 + 0.4 * sea
			targets["brise"] = 0.5
		"bo_friche":
			targets["brise"] = 0.5
			targets["grillons"] = 0.0 if day else 0.6
			targets["cigales"] = 0.3 if day else 0.0
		_:
			targets[ville] = 1.0
			targets["ressac"] = 0.15 * sea


## V70 : les nappes de l'Île de Braise.
func _braise_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"braise_taverne":
			targets["taverne"] = 1.0
		"braise_arene":
			targets["arene"] = 1.0
		"braise_thermes":
			targets["thermes_soufre"] = 1.0
			targets["pandemonia_jour" if day else "pandemonia_nuit"] = 0.25
		"braise_port":
			targets["port_braise"] = 1.0
			targets["ressac"] = 0.3 + 0.4 * sea
		"braise_fete":
			targets["pandemonia_nuit"] = 1.0
			targets["arene"] = 0.35
		"braise_trone", "braise_cathedrale", "braise_bibliotheque", "braise_academie":
			targets["grotte"] = 0.35
			targets["pandemonia_jour" if day else "pandemonia_nuit"] = 0.35
		"braise_palais", "braise_haute", "braise_basse", "braise_place", "braise_cercle":
			targets["pandemonia_jour" if day else "pandemonia_nuit"] = 1.0
			targets["champ_lave"] = 0.25 if z == "braise_cercle" else 0.0
		"braise_champ", "braise_cratere":
			targets["champ_lave"] = 1.0
			targets["vent_vol"] = clampf((p.y - 40.0) / 80.0, 0.0, 0.4)
		"braise_volcan":
			targets["volcan"] = 0.8
			targets["champ_lave"] = 0.3
			targets["vent_vol"] = clampf((p.y - 30.0) / 60.0, 0.0, 0.4)
		"braise_sources":
			targets["thermes_soufre"] = 0.7
			targets["volcan"] = 0.3
		"braise_bois":
			targets["grillons"] = 0.2 if day else 0.6
			targets["volcan"] = 0.25
			targets["brise"] = 0.3
		"braise_ruines":
			targets["brise"] = 0.8
			targets["vent_vol"] = 0.2
			targets["ressac"] = 0.3 * sea
		"braise_rivage":
			targets["ressac"] = 0.5 + 0.5 * sea
			targets["brise"] = 0.4
		_:
			targets["lande"] = 0.6
			targets["volcan"] = 0.3
			targets["ressac"] = 0.3 * sea


## V69 : les nappes de l'Île des Trois Soleils.
func _soleils_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"soleils_egypte", "soleils_temple_re":
			targets["nil"] = 0.7
			targets["brise"] = 0.3
			targets["grillons"] = 0.0 if day else 0.4
		"soleils_fleuve":
			targets["nil"] = 1.0
			targets["brise"] = 0.3
			targets["grillons"] = 0.0 if day else 0.35
		"soleils_pyramide":
			targets["desert"] = 0.8
			targets["brise"] = 0.5
			targets["nil"] = 0.15
		"soleils_maya", "soleils_cenote", "soleils_jungle":
			targets["jungle_maya"] = 1.0 if day else 0.6
			targets["grillons"] = 0.0 if day else 0.4
		"soleils_azteque", "soleils_chinampas", "soleils_lac":
			targets["lac_aztlan"] = 1.0
			targets["oiseaux"] = 0.3 if day else 0.0
			targets["grillons"] = 0.0 if day else 0.3
		"soleils_volcan":
			targets["volcan"] = 0.6
			targets["oiseaux"] = 0.35 if day else 0.0
			targets["vent_vol"] = clampf((p.y - 30.0) / 60.0, 0.0, 0.4)
		"soleils_rivage":
			targets["ressac"] = 0.5 + 0.5 * sea
			targets["brise"] = 0.5
		_:
			targets["oiseaux"] = 0.5 if day else 0.0
			targets["brise"] = 0.5
			targets["grillons"] = 0.0 if day else 0.4
			targets["ressac"] = 0.3 * sea


## V68 : les nappes de la Balafre : le port des pirates, les tavernes, le marais, la jungle.
func _balafre_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"balafre_crane_fendu":
			sea = 0.0
			targets["taverne_pirate"] = 1.0 if not day or _evening() else 0.55
		"balafre_dent_requin":
			sea = 0.0
			targets["taverne_pirate"] = 0.7 if not day or _evening() else 0.35
			targets["taverne"] = 0.15
		"balafre_navire":
			targets["epave"] = 0.35
			targets["port_pirate"] = 0.5 if day else 0.25
			targets["ressac"] = 0.3 + 0.3 * sea
			targets["brise"] = 0.5
		"balafre_port":
			targets["port_pirate"] = 0.9 if day else 0.4
			targets["ressac"] = 0.25 + 0.5 * sea
			targets["brise"] = 0.35
			targets["grillons"] = 0.0 if day else 0.3
		"balafre_marais":
			targets["marais"] = 1.0
			targets["jungle"] = 0.3 if day else 0.15
			targets["grillons"] = 0.0 if day else 0.35
		"balafre_ravin":
			targets["brise"] = 0.5
			targets["vent_vol"] = clampf((p.y - 8.0) / 30.0, 0.05, 0.35)
			targets["grotte"] = 0.12
		"balafre_fort":
			targets["brise"] = 0.7
			targets["vent_vol"] = 0.2
			targets["ressac"] = 0.2 + 0.4 * sea
			targets["grotte"] = 0.0 if day else 0.12
		"balafre_cimetiere":
			targets["brise"] = 0.4
			targets["grillons"] = 0.0 if day else 0.5
			targets["grotte"] = 0.0 if day else 0.15
		"balafre_plage":
			targets["plage"] = 0.7
			targets["ressac"] = 0.5 + 0.5 * sea
			targets["brise"] = 0.5
		"balafre_rivage":
			targets["ressac"] = 0.4 + 0.6 * sea
			targets["brise"] = 0.6
		_:
			targets["jungle"] = 1.0 - 0.4 * sea
			targets["oiseaux"] = 0.45 if day else 0.0
			targets["grillons"] = 0.0 if day else 0.4
			targets["brise"] = 0.25
			targets["ressac"] = 0.3 * sea


## V56 : les nappes de Port-Azur.
func _azur_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"azur_taverne":
			sea = 0.0
			targets["taverne"] = 1.0 if not day or _evening() else 0.55
			targets["ressac"] = 0.08
		"azur_hotel":
			sea = 0.0
			targets["ville_azur"] = 0.25
			targets["ressac"] = 0.08
		"azur_port":
			targets["port_azur"] = 1.0
			targets["ville_azur"] = 0.35 if day else 0.15
			targets["ressac"] = 0.2 + 0.3 * sea
		"azur_ville":
			targets["ville_azur"] = 1.0 if day else 0.35
			targets["port_azur"] = 0.2 * sea
			targets["cigales"] = 0.3
			targets["ressac"] = 0.1 + 0.3 * sea
		"azur_plage":
			targets["plage"] = 1.0 if day else 0.0
			targets["ressac"] = 0.5 + 0.5 * sea
			targets["brise"] = 0.45
			targets["cigales"] = 0.25
		_:
			targets["cigales"] = 1.0
			targets["brise"] = 0.6
			targets["oiseaux"] = 0.3
			targets["ressac"] = 0.15 + 0.6 * sea
	if p.y > 30.0:
		targets["brise"] = 0.9


## V59 : les nappes de la grande île.
func _grande_beds(z: String, p: Vector3) -> void:
	var day: bool = not _is_night()
	match z:
		"carene_taverne":
			sea = 0.0
			targets["taverne"] = 1.0 if not day or _evening() else 0.6
			targets["epave"] = 0.3
		"carene_cale":
			sea = 0.2
			targets["epave"] = 0.9
			targets["taverne"] = 0.3 if day else 0.0
		"carene_entrepont":
			sea = 0.0
			targets["epave"] = 1.0
			targets["ressac"] = 0.1
		"carene":
			targets["port_azur"] = 0.7
			targets["epave"] = 0.25
			targets["ressac"] = 0.3 + 0.5 * sea
			targets["brise"] = 0.5
		"grande_nord":
			targets["lande"] = 1.0
			targets["vent_vol"] = clampf((p.y - 25.0) / 40.0, 0.0, 0.5)
			targets["ressac"] = 0.4 * sea
		"grande_est":
			targets["brumes"] = 1.0
			targets["oiseaux"] = 0.25
			targets["ressac"] = 0.3 * sea
		"grande_sud":
			targets["desert"] = 1.0
			targets["cigales"] = 0.35
			targets["ressac"] = 0.4 * sea
		"tazira_port":
			var h: float = _hour()
			var auction: float = 1.0 if h >= 10.3 and h < 14.0 else 0.0
			targets["criee"] = auction
			targets["port_azur"] = 0.6 * (1.0 - auction) + 0.15
			targets["ressac"] = 0.3 + 0.5 * sea
			targets["souk"] = 0.15 if day else 0.0
		"tazira_souk":
			sea = 0.0
			targets["souk"] = 1.0 if day else 0.25
			targets["grillons"] = 0.0 if day else 0.4
		"tazira_place":
			targets["souk"] = 0.45 if day else 0.2
			targets["ressac"] = 0.12
			targets["brise"] = 0.3
		"tazira_ville":
			targets["souk"] = 0.25 if day else 0.05
			targets["desert"] = 0.25
			targets["cigales"] = 0.35 if day else 0.0
			targets["ressac"] = 0.1 + 0.3 * sea
		"tazira_murene":
			sea = 0.0
			targets["taverne"] = 1.0 if not day or _evening() else 0.55
			targets["ressac"] = 0.08
		"tazira_navire":
			targets["epave"] = 0.35
			targets["ressac"] = 0.5
			targets["port_azur"] = 0.4
			targets["brise"] = 0.5
		"cliquetis", "cliquetis_foire":
			targets["atelier"] = (1.0 if z == "cliquetis_foire" else 0.75) if day else 0.3
			targets["lande"] = 0.3
			targets["ville_azur"] = (0.4 if z == "cliquetis_foire" else 0.15) if day else 0.0
		"ramure", "ramure_cercle", "ramure_arbres":
			targets["ramure"] = 1.0 if day else 0.55
			targets["brumes"] = 0.35 if z != "ramure_arbres" else 0.2
			targets["grillons"] = 0.0 if day else 0.45
			targets["brise"] = 0.45 if z == "ramure_arbres" else 0.1
		"ramure_ponton":
			targets["ramure"] = 0.3
			targets["ressac"] = 0.5 + 0.4 * sea
			targets["brise"] = 0.5
		"cliquetis_port":
			targets["port_azur"] = 0.8
			targets["ressac"] = 0.35 + 0.5 * sea
			targets["atelier"] = 0.2
		"grande_massif":
			targets["vent_vol"] = 0.45 + clampf((p.y - 40.0) / 60.0, 0.0, 0.4)
			targets["brise"] = 0.5
		_:
			targets["brise"] = 0.8
			targets["oiseaux"] = 0.45
			targets["ressac"] = 0.2 + 0.7 * sea


func _is_night() -> bool:
	var t: Node = main.get("temps_v56")
	return t != null and bool(t.is_night())


func _hour() -> float:
	var t: Node = main.get("temps_v56")
	return float(t.hour) if t != null else 12.0


func _evening() -> bool:
	var t: Node = main.get("temps_v56")
	return t != null and float(t.hour) >= 18.0


## V56 : la nuit, les cigales se taisent, les oiseaux se calment, les grillons chantent.
func _night_beds() -> void:
	if not _is_night():
		return
	if float(targets.get("cigales", 0.0)) > 0.0 or zone in ["village", "jungle", "elfes", "nains", "azur_ville", "azur_collines", "azur_plage", "azur_port"]:
		targets["grillons"] = maxf(float(targets.get("cigales", 0.0)), 0.7)
	targets["cigales"] = 0.0
	targets["oiseaux"] = float(targets.get("oiseaux", 0.0)) * 0.5


func _island_at(p: Vector3) -> String:
	var j: Node = main.get("jungle_v29")
	if j != null and j.contains(p.x, p.z) and main._height_at(p.x, p.z) > -2.0:
		return "jungle"
	var el: Node = main.get("elfes_v41")
	if el != null and el.ile != null and el.ile.contains(p.x, p.z) and el.ile.height(p.x, p.z) > -2.0:
		return "elfes"
	var n: Node = main.get("nains_v46")
	if n != null and n.ile != null and n.ile.contains(p.x, p.z) and n.ile.height(p.x, p.z) > -2.0:
		return "nains"
	if Vector2(p.x, p.z).length() < 110.0 and main._height_at(p.x, p.z) > -2.0:
		return "village"
	return ""


## Proximité de la mer : on sonde le relief autour du joueur (8 directions, 3 distances).
func _sea_closeness(p: Vector3) -> float:
	if main._height_at(p.x, p.z) < -0.2:
		return 1.0
	var best: float = 0.0
	for r in [8.0, 20.0, 40.0]:
		for k in range(8):
			var a: float = TAU * k / 8.0
			if main._height_at(p.x + cos(a) * r, p.z + sin(a) * r) < -0.4:
				best = maxf(best, 1.0 - (r - 8.0) / 40.0)
		if best > 0.0:
			break
	return clampf(best, 0.0, 1.0)


## On ne fait tourner que les émetteurs à portée d'oreille.
func _cull_emitters() -> void:
	var lp: Vector3 = main._player_pos_v27()
	for e in emitters:
		var pl: AudioStreamPlayer3D = e["player"]
		var near: bool = pl.global_position.distance_to(lp) < float(e["reach"]) + 8.0
		if near and not pl.playing and pl.stream != null:
			pl.play(_rng.randf() * maxf(pl.stream.get_length() - 1.0, 0.0))
		elif not near and pl.playing:
			pl.stop()


func _tick_anvils(delta: float) -> void:
	var lp: Vector3 = main._player_pos_v27()
	for a in _anvils:
		var pl: AudioStreamPlayer3D = a["player"]
		if pl.global_position.distance_to(lp) > pl.max_distance:
			continue
		a["clock"] = float(a["clock"]) - delta
		if float(a["clock"]) > 0.0:
			continue
		pl.stream = _stream("ponctuels/enclume_%d" % _rng.randi_range(1, 4))
		pl.pitch_scale = _rng.randf_range(0.92, 1.08)
		pl.play()
		anvil_hits += 1
		a["serie"] = int(a["serie"]) + 1
		if int(a["serie"]) >= _rng.randi_range(4, 9):
			a["serie"] = 0
			a["clock"] = _rng.randf_range(2.5, 6.0)
		else:
			a["clock"] = _rng.randf_range(0.55, 0.7)


## Un son ponctuel au hasard, quelque part autour du joueur.
func _event() -> void:
	var list: Array = []
	var gap: Vector2 = Vector2(4.0, 9.0)
	var high: float = 4.0
	match zone:
		"jungle":
			list = ["ponctuels/oiseau_jungle_1", "ponctuels/oiseau_jungle_2", "ponctuels/oiseau_jungle_3", "ponctuels/oiseau_jungle_4"]
			gap = Vector2(2.5, 7.0)
			high = 9.0
		"large":
			list = ["ponctuels/mouette_1", "ponctuels/mouette_2", "ponctuels/mouette_3"]
			gap = Vector2(6.0, 14.0)
			high = 12.0
		"azur_port", "azur_plage", "carene", "tazira_port", "tazira_navire", "cliquetis_port":
			list = ["ponctuels/mouette_1", "ponctuels/mouette_2", "ponctuels/mouette_3"]
			gap = Vector2(7.0, 16.0)
			high = 14.0
		"village", "elfes", "nains":
			if sea > 0.4:
				list = ["ponctuels/mouette_1", "ponctuels/mouette_2", "ponctuels/mouette_3"]
				gap = Vector2(9.0, 20.0)
				high = 14.0
			elif zone == "elfes":
				list = ["ponctuels/carillon_1", "ponctuels/carillon_2", "ponctuels/carillon_3"]
				gap = Vector2(8.0, 18.0)
		"fees", "yggdrasil":
			list = ["ponctuels/carillon_1", "ponctuels/carillon_2", "ponctuels/carillon_3"]
			gap = Vector2(5.0, 12.0)
			high = 5.0
		"souterrain", "racines", "coeur":
			list = ["ponctuels/goutte_1", "ponctuels/goutte_2", "ponctuels/goutte_3", "ponctuels/goutte_4"]
			gap = Vector2(1.5, 5.0)
			high = 3.0
			if zone == "racines" and _rng.randf() < 0.35:
				list = ["ponctuels/carillon_1", "ponctuels/carillon_2", "ponctuels/carillon_3"]
	_event_clock = _rng.randf_range(gap.x, gap.y)
	if list.is_empty():
		return
	var sp: AudioStreamPlayer3D = _shots[_shot_i]
	_shot_i = (_shot_i + 1) % _shots.size()
	var lp: Vector3 = main._player_pos_v27()
	var a: float = _rng.randf() * TAU
	var r: float = _rng.randf_range(6.0, 22.0)
	sp.global_position = lp + Vector3(cos(a) * r, _rng.randf_range(1.0, high), sin(a) * r)
	sp.stream = _stream(str(list[_rng.randi() % list.size()]))
	sp.bus = "Ambiance_grotte" if zone in ["souterrain", "racines", "coeur"] else "Ambiance"
	sp.pitch_scale = _rng.randf_range(0.9, 1.1)
	sp.volume_db = -6.0 if zone in ["souterrain", "racines", "coeur"] else -3.0
	sp.play()

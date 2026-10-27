extends Node3D
## V58 : le royaume des fées et la quête de la graine d'Yggdrasil.
##
##  1. À la teuf de la plage, Lulu offre un champignon qui brille (journal : service « lulu »).
##     On le mange (inventaire, « Utiliser ») : le monde tourne… et l'on se retrouve dans le
##     cercle de champignons du royaume des fées, au-dessus d'une mer de nuages.
##  2. La reine Oriane confie la quête (journal_v56 : « graine_yggdrasil ») : rapporter la graine
##     qui dort dans Yggdrasil, l'Arbre-Monde. Une porte aux runes apparaît dans le tronc.
##  3. Dans le tronc creux : la Salle des Lucioles (rejouer l'air de lumière sur les pierres-
##     runes), la Salle de la Sève (tourner trois fleurs-miroirs pour mener la lumière au cœur
##     de bois), la Salle des Saisons (des plantes carnivores ; faire fleurir les quatre fleurs
##     selon la stèle), puis la Couronne : des ronceux, et la Mère-Ronce.
##  4. L'esprit de l'arbre remet la graine ; un cercle de lumière ramène auprès des fées.
##  5. La reine reçoit la graine et offre la magie de téléportation (teleport_v58.gd).
##  Le cercle de champignons ramène sur la plage de la teuf.

const IleScript = preload("res://scripts/ile_fees_v58.gd")
const YggScript = preload("res://scripts/yggdrasil_v58.gd")
const FeeScript = preload("res://scripts/pnj/fee_v44.gd")
const Fees = preload("res://scripts/pnj/fees_yggdrasil_v58.gd")
const QUEST := "graine_yggdrasil"
const SEQ := [3, 0, 4, 1, 2]
## Pour chaque fleur-miroir, les directions possibles du rayon (on tourne la fleur pour changer)
const MIRROR_OPTIONS := [["mur_n", "M1", "mur_s", "M2"], ["mur_e", "M0", "mur_ne", "M2"], ["mur_se", "M1", "H", "mur_o"]]
const MIRROR_START := [0, 2, 3]
## Les fleurs des saisons : nord, est, sud, ouest ; 0 printemps, 1 été, 2 automne, 3 hiver
const SEASON_GOAL := [3, 0, 1, 2]
const SEASON_START := [0, 2, 3, 1]
const SEASON_NAMES := ["printemps", "été", "automne", "hiver"]
const DIR_NAMES := ["du nord", "de l'est", "du sud", "de l'ouest"]

var main: Node
var pc: bool = true
var ile: Node3D
var ygg: Node3D
var fairies: Array = []
var state: Dictionary = {}
var fight: bool = false
var boss: Node3D
var _mirror: Array = MIRROR_START.duplicate()
var _season: Array = SEASON_START.duplicate()
var _seq_in: Array = []
var _showing: bool = false
var _wave: Dictionary = {}
var _was_in: bool = false
var _clock: float = 0.0
var _bar_vr: Label3D
var _busy: bool = false
var _tp_announced: bool = false


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")
	state = _defaults()


func _defaults() -> Dictionary:
	return {"visite": false, "champignon": false, "porte": false, "entree": false, "lucioles": false, "seve": false,
		"vague_saisons": false, "saisons": false, "vague_couronne": false, "boss": false, "graine": false, "teleport_dit": false}


# =================================================================== construction

func build() -> void:
	ile = IleScript.new()
	ile.name = "Ile_des_fees_v58"
	add_child(ile)
	ile.build(pc)
	ygg = YggScript.new()
	ygg.name = "Yggdrasil_v58"
	add_child(ygg)
	ygg.position = ile.world(ile.TREE, 0.0)
	ygg.build(pc)
	apply_state()
	print("ILE_MANGA_V58: royaume des fées (", ile.CENTER, ", ", ile.Y0, " m), Yggdrasil à ", ygg.global_position)


func spawn_fairies() -> void:
	if not fairies.is_empty():
		return
	for e in Fees.all_profiles():
		var data: Dictionary = e[0]
		var l: Vector2 = e[1]
		var at: Vector3 = ile.world(l, 0.0)
		var fee: Node3D = FeeScript.new()
		main.add_child(fee)
		fee.setup(main, data, at)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			fee.load_data(saved)
		main.npcs_v31.append(fee)
		fairies.append(fee)
		if str(data["id"]) == "oriane":
			_crown(fee)


## Une petite couronne d'or et de perles de rosée pour la reine.
func _crown(fee: Node3D) -> void:
	var head: Node3D = null
	var body: Node = fee.get_node_or_null("Corps")
	if body == null or body.get_child_count() == 0:
		return
	for c in body.get_child(0).get_children():
		if c is Node3D and not (c is MeshInstance3D) and (c as Node3D).position.is_equal_approx(Vector3(0, 0.15, 0)):
			head = c
	if head == null:
		return
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.38)
	gold.metallic = 0.95
	gold.roughness = 0.25
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.75, 0.3)
	gold.emission_energy_multiplier = 0.4
	var pearl := StandardMaterial3D.new()
	pearl.albedo_color = Color(0.85, 0.95, 1.0)
	pearl.emission_enabled = true
	pearl.emission = Color(0.6, 0.85, 1.0)
	pearl.emission_energy_multiplier = 1.5
	var crown := Node3D.new()
	crown.name = "Couronne_reine"
	crown.position = Vector3(0, 0.085, -0.005)
	crown.rotation.x = -0.15
	head.add_child(crown)
	var band := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.052
	tm.outer_radius = 0.062
	tm.rings = 24
	tm.ring_segments = 6
	band.mesh = tm
	band.material_override = gold
	crown.add_child(band)
	for k in range(7):
		var a: float = TAU * k / 7.0
		var spike := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.009
		cm.height = 0.04 if k % 2 == 0 else 0.028
		cm.radial_segments = 6
		spike.mesh = cm
		spike.material_override = gold
		spike.position = Vector3(cos(a) * 0.057, cm.height * 0.5, sin(a) * 0.057)
		crown.add_child(spike)
		var p := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.006
		sm.height = 0.012
		p.mesh = sm
		p.material_override = pearl
		p.position = Vector3(cos(a) * 0.057, cm.height + 0.004, sin(a) * 0.057)
		crown.add_child(p)


## Les invites « E » (et gâchette en VR) : on les confie au Temple (donjon_v35._interactions).
func build_quest() -> void:
	var d: Node = main.donjon_v35
	var I: Array = d._interactions
	I.append({"id": "fees_cercle", "pos": ile.world(ile.RING, 0.0), "radius": ile.RING_R, "text": "E : entrer dans le cercle de champignons (retour sur la plage)",
		"vr": "Gâchette : rentrer sur la plage", "call": _ring_home})
	I.append({"id": "ygg_entrer", "pos": ygg.at("porte_dehors"), "radius": 3.6, "text": "E : entrer dans Yggdrasil", "vr": "Gâchette : entrer dans Yggdrasil",
		"call": _go_into_tree, "when": func(): return bool(state["porte"])})
	I.append({"id": "ygg_porte_fermee", "pos": ygg.at("porte_dehors"), "radius": 3.6, "text": "E : toucher l'écorce d'Yggdrasil", "vr": "Gâchette : toucher l'écorce",
		"call": func(): _say("L'écorce est tiède, et vibre doucement, comme un cœur qui bat très lentement. Pas de porte… pour l'instant. La reine des fées en sait sûrement plus.", 6.0),
		"when": func(): return not bool(state["porte"])})
	I.append({"id": "ygg_sortir", "pos": ygg.at("sortie"), "radius": 2.0, "text": "E : sortir d'Yggdrasil", "vr": "Gâchette : sortir", "call": _go_out_of_tree})
	I.append({"id": "ygg_bassin", "pos": ygg.at("bassin"), "radius": 2.4, "text": "E : regarder les lucioles du bassin", "vr": "Gâchette : les lucioles du bassin",
		"call": _show_sequence, "when": func(): return not bool(state["lucioles"]) and not _showing})
	for k in range(5):
		var kk: int = k
		I.append({"id": "ygg_pierre_%d" % k, "pos": ygg.to_global(ygg.stones[k]["pos"]), "radius": 1.3, "text": "E : toucher la pierre-rune %s" % ygg.STONE_NAMES[k],
			"vr": "Gâchette : toucher la pierre", "call": func(): _touch_stone(kk), "when": func(): return not bool(state["lucioles"]) and not _showing})
	for i in range(3):
		var ii: int = i
		I.append({"id": "ygg_monter_%d" % i, "pos": ygg.at("escalier_%d" % i), "radius": 2.0, "text": "E : monter l'escalier de racines", "vr": "Gâchette : monter",
			"call": func(): _climb_up(ii)})
		I.append({"id": "ygg_descendre_%d" % i, "pos": ygg.at("trou_%d" % (i + 1)), "radius": 1.9, "text": "E : redescendre", "vr": "Gâchette : redescendre",
			"call": func(): _climb_down(ii), "when": func(): return not fight})
	for m in range(3):
		var mm: int = m
		I.append({"id": "ygg_miroir_%d" % m, "pos": ygg.to_global(ygg.mirrors[m]["pos"]) + Vector3.DOWN * 1.5, "radius": 1.4, "text": "E : tourner la fleur-miroir",
			"vr": "Gâchette : tourner la fleur", "call": func(): _turn_mirror(mm), "when": func(): return not bool(state["seve"])})
	I.append({"id": "ygg_coeur", "pos": ygg.to_global(ygg.heart_pos) + Vector3.DOWN * 1.5, "radius": 2.0, "text": "E : toucher le cœur de bois", "vr": "Gâchette : le cœur de bois",
		"call": _touch_heart, "when": func(): return not bool(state["seve"])})
	for s in range(4):
		var ss: int = s
		I.append({"id": "ygg_saison_%d" % s, "pos": ygg.to_global(ygg.pedestals[s]["pos"]), "radius": 1.5, "text": "E : effleurer la fleur %s" % DIR_NAMES[s],
			"vr": "Gâchette : effleurer la fleur", "call": func(): _turn_season(ss), "when": func(): return not bool(state["saisons"])})
	I.append({"id": "ygg_stele", "pos": ygg.at("stele"), "radius": 1.8, "text": "E : lire la stèle", "vr": "Gâchette : lire la stèle", "call": _read_stele})
	I.append({"id": "ygg_esprit", "pos": ygg.to_global(Vector3(0, ygg.CROWN, 0)), "radius": 3.0, "text": "E : parler à l'esprit de l'arbre", "vr": "Gâchette : parler à l'esprit",
		"call": _talk_spirit, "when": func(): return bool(state["boss"]) and not fight})
	I.append({"id": "ygg_cercle", "pos": ygg.at("cercle"), "radius": 2.0, "text": "E : entrer dans le cercle de lumière (vers la clairière des fées)", "vr": "Gâchette : le cercle de lumière",
		"call": _circle_to_glade, "when": func(): return bool(state["graine"])})
	# Les sons : l'étang, les chutes, la brise féerique
	var amb: Node = main.get("ambiance_v49")
	if amb != null:
		for f in ile.falls:
			amb.add_emitter(self, (f as Vector3) + Vector3.UP * 10.0, "emetteurs/cascade", 2.0, 30.0, 300.0)
		for s2 in ile.streams:
			var rim: Vector2 = s2["rim"]
			amb.add_emitter(self, ile.world(rim * 0.95, 0.5), "emetteurs/cascade", -3.0, 8.0, 60.0)
			amb.add_emitter(self, ile.world(s2["spring"], 0.4), "emetteurs/ruisseau", -8.0, 4.0, 26.0)


# =================================================================== état

func serialize() -> Dictionary:
	return state.duplicate(true)


func load_data(d: Dictionary) -> void:
	_reset_fight()
	_despawn_wave()
	state = _defaults()
	for k in state:
		if d.has(k):
			state[k] = bool(d[k])
	_seq_in.clear()
	_showing = false
	_mirror = MIRROR_START.duplicate()
	_season = SEASON_START.duplicate()
	_tp_announced = bool(state["teleport_dit"])
	apply_state()


func apply_state() -> void:
	if ygg == null:
		return
	ygg.show_door(bool(state["porte"]), false)
	ygg.open_door(bool(state["porte"]), false)
	for i in range(3):
		var solved: bool = [bool(state["lucioles"]), bool(state["seve"]), bool(state["saisons"])][i]
		if solved:
			ygg.open_gate(i, true)
		else:
			ygg.close_gate(i)
	for k in range(5):
		ygg.stone_glow(k, 0.6 if bool(state["lucioles"]) else 0.0)
	if bool(state["seve"]):
		_mirror = [1, 3, 2]
	_trace_beam()
	if bool(state["saisons"]):
		_season = SEASON_GOAL.duplicate()
	for s in range(4):
		ygg.set_season(s, _season[s], false)
	ygg.seasons_glow(bool(state["saisons"]))
	ygg.show_spirit(bool(state["boss"]), false)
	ygg.circle.visible = bool(state["graine"])


func quest_state() -> String:
	var j: Node = main.get("journal_v56")
	return str(j.state(QUEST)) if j != null else ""


## Trouvailles (main._npc_ctx_v31), pour le carnet et les dialogues.
func trouvailles() -> Dictionary:
	var j: Node = main.get("journal_v56")
	return {"champignon": 1 if bool(state["champignon"]) else 0, "royaume_fees": 1 if bool(state["visite"]) else 0,
		"porte_ygg": 1 if bool(state["entree"]) else 0, "lucioles": 1 if bool(state["lucioles"]) else 0, "seve": 1 if bool(state["seve"]) else 0,
		"saisons": 1 if bool(state["saisons"]) else 0, "mere_ronce": 1 if bool(state["boss"]) else 0, "graine_ygg": 1 if bool(state["graine"]) else 0,
		"teleportation": 1 if j != null and bool(j.flags.get("teleportation", false)) else 0}


# =================================================================== lieux

func contains(p: Vector3) -> bool:
	return ile != null and ile.near(p, 30.0)


func _local(p: Vector3) -> Vector3:
	return ygg.to_local(p)


## Où est le joueur ? "" (dehors), "salle_0", "salle_1", "salle_2", "couronne".
func room(p: Vector3) -> String:
	if ygg == null or not contains(p):
		return ""
	var l: Vector3 = _local(p)
	var r: float = Vector2(l.x, l.z).length()
	if l.y > ygg.CROWN - 1.0 and l.y < ygg.CROWN + 12.0 and r < float(ygg.points["crown_r"]) + 1.0:
		return "couronne"
	if r > ygg.RI + 0.5 or l.y < -1.0 or l.y > ygg.CROWN - 0.5:
		return ""
	if l.y < ygg.FLOORS[1] - 0.8:
		return "salle_0"
	if l.y < ygg.FLOORS[2] - 0.8:
		return "salle_1"
	return "salle_2"


func hostile_zone(p: Vector3) -> bool:
	return room(p) != ""


func walkable_at(p: Vector3) -> bool:
	var rm: String = room(p)
	if rm == "couronne":
		var l: Vector3 = _local(p)
		return Vector2(l.x, l.z).length() < float(ygg.points["crown_r"]) - 0.7
	if rm != "":
		return true
	return ile.walkable(p.x, p.z)


func respawn_point(p: Vector3) -> Array:
	if room(p) != "":
		_reset_fight()
		_despawn_wave()
		return [ygg.at("entree") + Vector3.UP * 0.1, Vector3(0, 0, -1)]
	return [glade_spot(), Vector3(0, 0, -1)]


func glade_spot() -> Vector3:
	return ile.world(ile.GLADE + Vector2(0.0, 6.0), 0.1)


func ring_spot() -> Vector3:
	return ile.world(ile.RING, 0.1)


## Sur la plage de la teuf, à quelques pas de Lulu.
func beach_spot() -> Array:
	# V80 : au bord de la piste, sur le sable (avant : 9 m en retrait, dans l'herbe du village).
	var tf: Node = main.get("teuf_v57")
	var px: float = 2.0
	var pz: float = 51.5
	if tf != null:
		px = tf.PISTE.x
		pz = tf.PISTE.y
	var x: float = px - 10.0
	var z: float = pz - 3.5
	var at := Vector3(x, main._height_at(x, z) + 0.1, z)
	return [at, (Vector3(px, at.y, pz) - at).normalized()]


# =================================================================== entrer et sortir du royaume

## On croque le champignon de Lulu (inventaire, « Utiliser »).
func eat_mushroom() -> bool:
	if contains(main._player_pos_v27()):
		main._show_message_v28("Tu es déjà au royaume des fées. Garde ce champignon pour une autre fois.")
		return true
	if not _can_travel():
		return true
	main.inventory_v28.remove("champignon_magique", 1)
	main.inventory_v28.close()
	state["champignon"] = true
	main.sfx("manger")
	enter("Tu croques le champignon de Lulu… Il a un goût de miel et de pluie. Tout se met à tourner doucement, les couleurs se mettent à chanter, et le monde se dissout dans une lumière dorée…")
	return true


func _can_travel() -> bool:
	if main.get("ciel_v54") != null and main.ciel_v54 != null and bool(main.ciel_v54.riding):
		main._show_message_v28("Pas en plein vol ! Pose-toi d'abord.")
		return false
	# V76 : ni à bord de l'aéronef
	if main.get("aeronef_v76") != null and main.aeronef_v76 != null and bool(main.aeronef_v76.riding):
		main._show_message_v28("Pas en plein vol ! Pose-toi d'abord.")
		return false
	if main.get("boat_v29") != null and main.boat_v29 != null and bool(main.boat_v29.driving):
		main._show_message_v28("Pas en pleine mer ! Accoste d'abord.")
		return false
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ferry") != null and az.ferry != null and bool(az.ferry.riding):
		main._show_message_v28("Pas à bord de L'Hirondelle ! Attends d'être à quai.")
		return false
	# V72 : ni en dirigeable, ni en télécabine, ni en tyrolienne (on était remis à sa place aussitôt)
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.has_method("riding") and bool(gr.riding()):
		main._show_message_v28("Pas pendant le trajet ! Attends d'être arrivé.")
		return false
	return true


func enter(text: String = "") -> void:
	if _busy:
		return
	_busy = true
	var d: Node = main.donjon_v35
	main.sfx("teleport")
	if text != "":
		_say(text, 6.0)
	await d._fade_to(1.0, 1.4)
	main.place_player_v35(ring_spot(), (glade_spot() - ring_spot()).normalized())
	d.update_inside(true)
	await get_tree().create_timer(0.6).timeout
	await d._fade_to(0.0, 1.6)
	_busy = false
	if not bool(state["visite"]):
		state["visite"] = true
		main.jingle("decouverte")
		_say("Le royaume des fées ! Une prairie en fleurs flotte au-dessus d'une mer de nuages dorés. Des lucioles dansent en plein jour… et au nord se dresse un arbre immense, si grand que sa couronne touche le ciel : Yggdrasil, l'Arbre-Monde. Des fées t'attendent dans la clairière, au sud.", 11.0)
	else:
		_say("Te revoilà au royaume des fées.", 3.5)


func _ring_home() -> void:
	if _busy:
		return
	_busy = true
	var d: Node = main.donjon_v35
	main.sfx("teleport")
	_say("Tu entres dans le cercle de champignons. Les lueurs montent en spirale autour de toi…", 4.0)
	await d._fade_to(1.0, 1.2)
	var b: Array = beach_spot()
	main.place_player_v35(b[0], b[1])
	d.update_inside(true)
	await get_tree().create_timer(0.5).timeout
	await d._fade_to(0.0, 1.4)
	_busy = false
	_say("… et te voilà sur la plage, la musique de la teuf dans les oreilles. Lulu te fait un clin d'œil.", 5.0)


func _circle_to_glade() -> void:
	if _busy:
		return
	_busy = true
	var d: Node = main.donjon_v35
	main.sfx("teleport")
	await d._fade_to(1.0, 0.9)
	main.place_player_v35(glade_spot(), Vector3(0, 0, -1))
	d.update_inside(true)
	await get_tree().create_timer(0.4).timeout
	await d._fade_to(0.0, 1.2)
	_busy = false
	if bool(state["graine"]) and quest_state() == "en_cours":
		_say("Le cercle de lumière te dépose dans la clairière des fées. La reine Oriane t'attend : la graine d'Yggdrasil brille au fond de ton sac.", 6.0)


func _go_into_tree() -> void:
	var first: bool = not bool(state["entree"])
	state["entree"] = true
	main.sfx("porte_ouvre", ygg.at("porte"))
	await main.donjon_v35._travel(ygg.at("entree") + Vector3.UP * 0.1, Vector3(0, 0, -1))
	if first:
		main.jingle("decouverte")
		_say("L'intérieur d'Yggdrasil ! Le tronc est creux comme une tour. Les parois luisent de champignons et de mousse, des racines pendent du plafond. Au centre, un bassin où dansent des lucioles ; autour, cinq pierres gravées de runes. Au fond, un escalier de racines… fermé par un enchevêtrement de racines.", 11.0)


func _go_out_of_tree() -> void:
	await main.donjon_v35._travel(ygg.at("porte_dehors") + Vector3.UP * 0.1, Vector3(0, 0, 1))


func _climb_up(i: int) -> void:
	var solved: bool = [bool(state["lucioles"]), bool(state["seve"]), bool(state["saisons"])][i]
	if not solved:
		var why: String = ["Des racines épaisses ferment l'escalier. Peut-être s'ouvriront-elles si l'on rejoue l'air des lucioles…",
			"Des racines ferment l'escalier. La salle attend quelque chose : la lumière de la sève, peut-être, sur ce gros nœud de bois…",
			"Les racines ne bougent pas. Les quatre fleurs de pierre ne sont pas encore dans l'ordre que demande la stèle."][i]
		_say(why, 6.0)
		return
	var to: Vector3 = ygg.at("arrivee_%d" % (i + 1)) + Vector3.UP * 0.1
	var face: Vector3 = (ygg.global_position - to) * Vector3(1, 0, 1)
	_say(["Tu gravis l'escalier de racines…", "Tu montes, marche après marche, dans le cœur de l'arbre…", "Tu montes vers la lumière… le vent souffle là-haut."][i], 2.5)
	await main.donjon_v35._travel(to, face)
	match i:
		0:
			if not bool(state["seve"]):
				_say("La Salle de la Sève. À l'ouest, une source d'ambre d'où coule une lumière dorée. Trois fleurs aux cœurs d'argent poli, comme des miroirs. À l'est, un gros nœud de bois sombre : le cœur de l'arbre ?", 9.0)
		1:
			if not bool(state["saisons"]):
				_say("La Salle des Saisons. Quatre fleurs de pierre, une à chaque point cardinal, et une stèle gravée près de toi… Et des feuilles qui bougent toutes seules !", 8.0)
		2:
			if not bool(state["boss"]):
				_say("La Couronne d'Yggdrasil ! À ciel ouvert, au milieu des branches immenses, le sommet du tronc fait une grande place de bois vivant. Mais quelque chose rampe entre les branches…", 8.0)


func _climb_down(i: int) -> void:
	var to: Vector3 = ygg.at("escalier_%d" % i) + Vector3.UP * 0.1
	var face: Vector3 = (ygg.global_position - to) * Vector3(1, 0, 1)
	await main.donjon_v35._travel(to, face)


# =================================================================== salle 0 : les lucioles

func _show_sequence() -> void:
	if _showing:
		return
	_showing = true
	_seq_in.clear()
	var f: Node3D = ygg.firefly
	var base: Vector3 = ygg.points["bassin"] + Vector3.UP * 1.6
	f.position = base
	f.visible = true
	_say("Une luciole plus grosse que les autres sort du bassin… Regarde bien où elle se pose.", 4.0)
	await get_tree().create_timer(1.2).timeout
	for k in SEQ:
		var to: Vector3 = (ygg.stones[k]["pos"] as Vector3) + Vector3.UP * 0.7
		var tw := create_tween()
		tw.tween_property(f, "position", to, 0.75).set_trans(Tween.TRANS_SINE)
		await tw.finished
		ygg.stone_glow(k, 1.0)
		main.sfx("rune_%d" % k, ygg.to_global(to))
		await get_tree().create_timer(0.7).timeout
		ygg.stone_glow(k, 0.0)
	var back := create_tween()
	back.tween_property(f, "position", base, 0.8).set_trans(Tween.TRANS_SINE)
	await back.finished
	f.visible = false
	_showing = false
	_say("La luciole replonge dans le bassin. À toi : touche les pierres dans le même ordre (E sur chaque pierre).", 5.0)


func _touch_stone(k: int) -> void:
	if bool(state["lucioles"]) or _showing:
		return
	var at: Vector3 = ygg.to_global(ygg.stones[k]["pos"])
	main.sfx("rune_%d" % k, at)
	ygg.stone_glow(k, 1.0)
	_seq_in.append(k)
	var i: int = _seq_in.size() - 1
	if SEQ[i] != k:
		_seq_in.clear()
		await get_tree().create_timer(0.35).timeout
		ygg.stones_flash(Color(1.0, 0.3, 0.25))
		main.sfx("ui_erreur")
		_say("Les pierres s'éteignent toutes d'un coup… Ce n'était pas le bon ordre. (Le bassin des lucioles peut te remontrer l'air.)", 5.0)
		for s in range(5):
			ygg.stone_glow(s, 0.0)
		return
	if _seq_in.size() < SEQ.size():
		return
	state["lucioles"] = true
	_seq_in.clear()
	await get_tree().create_timer(0.6).timeout
	for s in range(5):
		ygg.stone_glow(s, 1.0)
		main.sfx("rune_%d" % s, ygg.to_global(ygg.stones[s]["pos"]))
		await get_tree().create_timer(0.18).timeout
	main.jingle("decouverte")
	main.sfx("racines", ygg.at("escalier_0"))
	ygg.open_gate(0, false)
	_say("Les cinq pierres chantent ensemble ! Des milliers de lucioles jaillissent du bassin et tourbillonnent jusqu'au plafond… Dans un long craquement, les racines qui fermaient l'escalier se retirent.", 8.0)
	await get_tree().create_timer(2.5).timeout
	for s2 in range(5):
		ygg.stone_glow(s2, 0.6)


# =================================================================== salle 1 : la sève

func _trace_beam() -> void:
	if ygg == null:
		return
	var T: Dictionary = ygg.mirror_targets
	var path: Array = [ygg.source_pos]
	var cur: String = "M0"
	var prev: Vector3 = ygg.source_pos
	var through: int = 0
	var reached: bool = false
	var seen := {}
	var aimed := {}
	while true:
		var p: Vector3 = T[cur]
		path.append(p)
		if cur == "H":
			reached = true
			break
		if not cur.begins_with("M") or seen.has(cur):
			break
		seen[cur] = true
		through += 1
		var i: int = int(cur.substr(1))
		var nxt: String = MIRROR_OPTIONS[i][_mirror[i]]
		ygg.aim_mirror(i, prev, T[nxt])
		aimed[i] = true
		prev = p
		cur = nxt
	# les fleurs que le rayon ne touche pas regardent quand même vers leur cible
	for m in range(3):
		if not aimed.has(m):
			ygg.aim_mirror(m, Vector3(0, (T["M0"] as Vector3).y, 0), T[MIRROR_OPTIONS[m][_mirror[m]]])
	ygg.set_beam(path, (through + 1) if reached else 0)
	set_meta("beam", [through, reached])


func _turn_mirror(m: int) -> void:
	if bool(state["seve"]):
		return
	_mirror[m] = (_mirror[m] + 1) % 4
	main.sfx("fleur_tourne", ygg.to_global(ygg.mirrors[m]["pos"]))
	_trace_beam()
	var r: Array = get_meta("beam")
	if bool(r[1]) and int(r[0]) >= 3:
		state["seve"] = true
		await get_tree().create_timer(0.8).timeout
		main.jingle("decouverte")
		main.sfx("racines", ygg.at("escalier_1"))
		ygg.open_gate(1, false)
		_say("La lumière de la sève passe par les trois fleurs-miroirs, de plus en plus vive… et frappe le cœur de bois ! Il s'allume comme une braise d'or, la salle entière se met à battre doucement. Les racines de l'escalier se retirent.", 9.0)
	elif bool(r[1]):
		_say("La lumière touche le cœur de bois… mais il reste presque éteint. Elle est trop faible : il faudrait qu'elle passe par les trois fleurs.", 6.0)


func _touch_heart() -> void:
	var r: Array = get_meta("beam", [0, false])
	if bool(r[1]):
		_say("Le cœur de bois est tiède. La lumière l'atteint, mais trop faible : elle doit d'abord passer par les trois fleurs-miroirs.", 6.0)
	else:
		_say("Un gros nœud de bois sombre, lisse comme une pierre de rivière, et froid. On dirait qu'il attend la lumière. Les fleurs-miroirs, en tournant, renvoient celle de la source…", 7.0)


# =================================================================== salle 2 : les saisons

func _read_stele() -> void:
	_say("« Les quatre fleurs fleuriront quand chacune vivra sa saison. Là où le soleil naît, tout s'éveille. Là où il règne à midi, tout flamboie. Là où il meurt, tout s'effeuille. Là où il ne va jamais, tout dort sous la neige. » En dessous : printemps, été, automne, hiver.", 12.0)


func _turn_season(s: int) -> void:
	if bool(state["saisons"]):
		return
	_season[s] = (_season[s] + 1) % 4
	ygg.set_season(s, _season[s], true)
	main.sfx("fleur_tourne", ygg.to_global(ygg.pedestals[s]["pos"]))
	main._show_message_v28("La fleur %s : %s." % [DIR_NAMES[s], SEASON_NAMES[_season[s]]])
	for k in range(4):
		if _season[k] != SEASON_GOAL[k]:
			return
	state["saisons"] = true
	await get_tree().create_timer(0.7).timeout
	ygg.seasons_glow(true)
	main.jingle("decouverte")
	main.sfx("racines", ygg.at("escalier_2"))
	ygg.open_gate(2, false)
	_say("Les quatre fleurs s'ouvrent ensemble : le printemps à l'est, l'été au sud, l'automne à l'ouest, l'hiver au nord. Un parfum de toutes les saisons à la fois emplit la salle… Les racines du dernier escalier se retirent. Tout en haut, la Couronne.", 9.0)


# =================================================================== combats

func _process(delta: float) -> void:
	if main == null or not main.game_started or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	# La porte apparaît quand la reine a confié sa quête
	var qs: String = quest_state()
	if not bool(state["porte"]) and qs in ["en_cours", "finie"]:
		state["porte"] = true
		var near: bool = contains(p)
		ygg.show_door(true, near)
		ygg.open_door(true, near)
		if near:
			main.sfx("porte_ygg", ygg.at("porte"))
			_say("Un grondement profond monte de la terre… Au pied d'Yggdrasil, des runes s'allument dans l'écorce, dessinent une grande porte… qui s'ouvre lentement !", 7.0)
	# La reine a offert la magie de téléportation
	var j: Node = main.get("journal_v56")
	if not _tp_announced and j != null and bool(j.flags.get("teleportation", false)):
		_tp_announced = true
		state["teleport_dit"] = true
		main.jingle("decouverte")
		main.sfx("teleport")
		_say("La reine Oriane pose deux doigts sur ton front… Une chaleur, un éclat d'or, des ailes de lumière autour de toi : tu connais la magie de téléportation ! Tu peux retourner en un instant dans un lieu déjà visité : touche T au PC, ou ouvre le carnet, onglet Carte, « Se téléporter ».", 12.0)
	# Tombé de l'île : les fées te rattrapent
	if _was_in and p.y < ile.Y0 - 30.0 and Vector2(p.x - ile.CENTER.x, p.z - ile.CENTER.z).length() < 170.0:
		_was_in = false
		main.place_player_v35(glade_spot(), Vector3(0, 0, -1))
		_say("Une nuée de fées te rattrape au vol, en riant, et te repose dans la clairière. « Attention au bord ! »", 5.0)
		return
	if not contains(p):
		_was_in = false
		if fight or not _wave.is_empty():
			_reset_fight()
			_despawn_wave()
		return
	if p.y > ile.Y0 - 6.0:
		_was_in = true
	# Les lumières des champignons : allumées seulement à proximité
	if int(_clock * 2.0) % 2 == 0:
		for l in ile.lights:
			(l as OmniLight3D).visible = (l as OmniLight3D).global_position.distance_to(p) < 60.0
	_tick_rooms(p)


func _tick_rooms(p: Vector3) -> void:
	var rm: String = room(p)
	if _wave.is_empty():
		if rm == "salle_2" and not bool(state["vague_saisons"]):
			_spawn_wave("salle_2")
		elif rm == "couronne" and not bool(state["vague_couronne"]) and not bool(state["boss"]):
			_spawn_wave("couronne")
	else:
		var alive: int = 0
		for m in _wave["monsters"]:
			if is_instance_valid(m) and m.state != "mort":
				alive += 1
		if alive == 0:
			_wave_done(str(_wave["room"]))
		elif rm != str(_wave["room"]):
			_despawn_wave()
	if rm == "couronne" and bool(state["vague_couronne"]) and not bool(state["boss"]) and not fight and _wave.is_empty():
		_start_fight()
	elif fight and rm != "couronne":
		_reset_fight()
	if fight and boss != null and is_instance_valid(boss):
		var d: Node = main.donjon_v35
		d._update_bar(maxi(int(boss.hp), 0), 80)
		if boss.state == "mort":
			_on_boss_dead()


func _spawn_wave(rm: String) -> void:
	var mo: Node = main.monstres_v36
	if mo == null:
		return
	var list: Array = []
	if rm == "salle_2":
		var y: float = ygg.FLOORS[2]
		list = [["plante", Vector3(3.6, y, -3.4)], ["plante", Vector3(-3.8, y, -3.2)], ["plante", Vector3(3.4, y, 3.8)], ["ronceux", Vector3(-2.0, y, 1.0)]]
		_say("Les feuilles qui bougeaient se redressent : des plantes carnivores ! Et un paquet de ronces qui marche…", 5.0)
	else:
		var c: float = ygg.CROWN
		for k in range(5):
			var a: float = TAU * k / 5.0 + 0.4
			list.append(["ronceux" if k % 2 == 0 else "plante", Vector3(cos(a) * 6.5, c, sin(a) * 6.5)])
		_say("Des ronces surgissent d'entre les branches et marchent vers toi ! Des plantes carnivores ouvrent leurs mâchoires…", 5.0)
	var monsters: Array = []
	for e in list:
		var at: Vector3 = ygg.to_global(e[1]) + Vector3.UP * 0.15
		var m: Node3D = mo.spawn_extra(str(e[0]), at)
		m.state = "veille"
		m.home = at
		monsters.append(m)
	_wave = {"room": rm, "monsters": monsters}


func _despawn_wave() -> void:
	if _wave.is_empty():
		return
	var mo: Node = main.monstres_v36 if main != null else null
	for m in _wave["monsters"]:
		if is_instance_valid(m):
			if mo != null:
				mo.monsters.erase(m)
			m.queue_free()
	_wave = {}


func _wave_done(rm: String) -> void:
	_wave = {}
	main.jingle("victoire")
	if rm == "salle_2":
		state["vague_saisons"] = true
		_say("Les plantes retombent, fanées. La Salle des Saisons retrouve son calme… La stèle, près de l'escalier, attend d'être lue.", 6.0)
	else:
		state["vague_couronne"] = true
		_say("Les ronces s'effondrent… Le bois de la Couronne tremble. Au centre, quelque chose d'énorme pousse à travers l'écorce !", 5.0)


func _start_fight() -> void:
	fight = true
	var d: Node = main.donjon_v35
	var c: Vector3 = ygg.to_global(Vector3(0, ygg.CROWN + 0.15, 0))
	boss = main.monstres_v36.spawn_extra("plante_mere", c)
	boss.home = c
	boss.state = "chasse"
	main.sfx("plante_menace", c + Vector3.UP * 3.0)
	d._bar_name = "La Mère-Ronce, reine des plantes d'Yggdrasil"
	d._bar_label.text = d._bar_name
	d._bar_layer.visible = not main.xr_active
	if main.xr_active:
		_bar_vr = Label3D.new()
		_bar_vr.font_size = 48
		_bar_vr.pixel_size = 0.004
		_bar_vr.outline_size = 10
		_bar_vr.modulate = Color(1.0, 0.6, 0.9)
		_bar_vr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_vr.no_depth_test = true
		_bar_vr.position = Vector3(0, 7.0, 0)
		boss.add_child(_bar_vr)
		d._bar_vr = _bar_vr
	d._update_bar(80, 80)
	boss.scale = Vector3(0.1, 0.1, 0.1)
	create_tween().tween_property(boss, "scale", Vector3.ONE, 1.6).set_trans(Tween.TRANS_BACK)
	_say("Une fleur géante jaillit du bois, tentacules de ronces et mâchoires grandes comme une porte : LA MÈRE-RONCE ! C'est elle qui a rendu les plantes d'Yggdrasil méchantes.", 7.0)


func _reset_fight() -> void:
	if not fight:
		return
	fight = false
	if boss != null and is_instance_valid(boss):
		var mo: Node = main.monstres_v36
		if mo != null:
			mo.monsters.erase(boss)
		boss.queue_free()
	boss = null
	var d: Node = main.donjon_v35
	if d != null:
		d._bar_layer.visible = false
		d._bar_vr = null
	_bar_vr = null


func _on_boss_dead() -> void:
	fight = false
	state["boss"] = true
	boss = null
	var d: Node = main.donjon_v35
	d._bar_layer.visible = false
	d._bar_vr = null
	main.jingle("victoire")
	_say("La Mère-Ronce se fane, se recroqueville… et retombe en poussière d'or. Les branches d'Yggdrasil frémissent de soulagement.", 6.0)
	await get_tree().create_timer(4.0).timeout
	main.sfx("esprit", ygg.to_global(Vector3(0, ygg.CROWN + 2.0, 0)))
	ygg.show_spirit(true, true)
	_say("Une lumière verte monte du cœur du bois et prend forme : grand, souple comme une branche, une couronne de bois de cerf sur la tête… l'esprit de l'arbre. Il te regarde. (E : lui parler)", 8.0)


func _talk_spirit() -> void:
	if not bool(state["graine"]):
		if not main.inventory_v28.can_accept([["graine_yggdrasil", 1]]):
			_say("« Ton sac est trop plein pour ce que j'ai à te confier, petit voyageur. Fais-y de la place. »", 5.0)
			return
		state["graine"] = true
		main.inventory_v28.add("graine_yggdrasil", 1)
		main.sfx("esprit", ygg.to_global(Vector3(0, ygg.CROWN + 2.0, 0)))
		main.jingle("decouverte")
		ygg.circle.visible = true
		ygg.circle.scale = Vector3(0.05, 1.0, 0.05)
		create_tween().tween_property(ygg.circle, "scale", Vector3.ONE, 1.5)
		var words := "« Cent ans que la ronce m'étouffait. Cent ans sans graine. Tu m'as rendu mon souffle, petit voyageur. » L'esprit ouvre ses mains de lumière : une graine dorée, veinée de feu, y repose. « Porte-la aux fées. Dans mille ans, elle sera un monde. » Un cercle de lumière s'allume sur la Couronne : il te ramènera à la clairière."
		_say(words, 14.0)
		# le carnet note l'étape (« rapporter la graine ») : on laisse la parole à l'esprit
		await get_tree().create_timer(0.7).timeout
		_say(words, 14.0)
		return
	var lines: Array = ["« Les racines se souviennent de toi. »", "« Chaque île boit à mes racines. Prends soin d'elles, et elles prendront soin de toi. »",
		"« Le vent t'a vu passer, ici, là-bas, partout. Les fées sauront t'apprendre à faire de même. »"]
	_say(str(lines[int(_clock) % lines.size()]), 5.0)


func _say(text: String, seconds: float = 4.0) -> void:
	main.donjon_v35._say(text, seconds)

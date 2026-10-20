extends Node3D
## V56 : Port-Azur, la grande île touristique — le chef d'orchestre. Il construit l'île
## (ile_azur_v56), la ville (port_azur_v56), la végétation (azur_flore_v56), le bateau de
## ligne (ferry_v56) ; il fait vivre les quarante-deux habitants (pnj_azur_v56) selon
## l'heure du jeu ; il anime l'horloge, la cloche, le phare, les mouettes, le chien
## voleur de croissants ; il propose les services (traversée, chambre d'hôtel, voyance).

const IleScript = preload("res://scripts/ile_azur_v56.gd")
const PortScript = preload("res://scripts/port_azur_v56.gd")
const FloreScript = preload("res://scripts/azur_flore_v56.gd")
const FerryScript = preload("res://scripts/ferry_v56.gd")
const Habitants = preload("res://scripts/pnj/azur_habitants_v56.gd")
const PnjAzur = preload("res://scripts/pnj/pnj_azur_v56.gd")

var main: Node
var ile: Node3D
var port: Node3D
var flore: Node3D
var ferry: Node3D
var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "nuits": 0}
var _claims: Dictionary = {}           # lieu -> pnj
var _gulls: Array = []
var _dog: Node3D
var _dog_t: float = 0.0
var _sparkles: Dictionary = {}         # lieu à creuser -> Node3D
var _last_bell_hour: int = -1
var _clock: float = 0.0
var pc: bool = true
var django_heard: bool = false        # la guitare de Django s'entend (la musique du lieu se tait)
var _django_player: AudioStreamPlayer3D
var _django_song: String = ""


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")


# =================================================================== construction

func build_island() -> void:
	ile = IleScript.new()
	ile.name = "Ile_azur_v56"
	add_child(ile)
	ile.build(pc)


## Après le relief : la ville, la végétation, le bateau de ligne (main a créé le temps).
func build_town() -> void:
	port = PortScript.new()
	port.name = "Port_azur_v56"
	add_child(port)
	port.build(main, ile, pc)
	flore = FloreScript.new()
	flore.name = "Flore_azur_v56"
	add_child(flore)
	for pw in ile.pads_world:
		flore.avoid.append([Vector2(pw.x, pw.z), 9.5])
	for lp in ile.lane_world:
		flore.avoid.append([Vector2(lp.x, lp.z), 3.4])
	flore.avoid.append([Vector2(ile.summit_world.x, ile.summit_world.z), 9.0])
	var lh: Vector3 = ile.to_world(ile.LIGHTHOUSE.x, ile.LIGHTHOUSE.y)
	flore.avoid.append([Vector2(lh.x, lh.z), 8.0])
	var kite: Vector3 = port.objets.get("cerf_volant", Vector3.INF)
	flore.build(ile, port.flora_spots, pc)
	if kite != Vector3.INF:
		# le cerf-volant est resté accroché dans un olivier
		_tree_for_kite(kite)
	_make_gulls()
	_make_dog()
	print("ILE_MANGA_V56: Port-Azur prêt, ", habitants.size(), " habitants")


func dock() -> Array:
	return port.boat_dock


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## Le joueur est-il dans la ville (pour la musique et les ambiances) ?
func zone_at(p: Vector3) -> String:
	if ile == null or not ile.contains(p.x, p.z):
		return ""
	for it in port.interiors:
		var c: Vector3 = it[1]
		var half: Vector2 = it[2]
		var l: Vector2 = ile.to_town(p.x, p.z) - ile.to_town(c.x, c.z)
		if absf(l.x) < half.x and absf(l.y) < half.y and p.y < c.y + 4.0:
			return "azur_" + str(it[0])
	var t: Vector2 = ile.to_town(p.x, p.z)
	if t.x < -80.0 and t.y < 30.0:
		return "azur_plage"
	if t.x > -82.0 and t.x < 68.0 and t.y > -2.0 and t.y < 90.0:
		return "azur_ville"
	if t.y < 0.0:
		return "azur_port"
	return "azur_collines"


func respawn_point() -> Array:
	return [port.T(0.0, 40.0, 0.3), (port.T(0.0, 30.0) - port.T(0.0, 40.0)).normalized()]


# =================================================================== les habitants

func hour() -> float:
	return float(main.temps_v56.hour) if main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func spot(name: String) -> Dictionary:
	return port.spots.get(name, {})


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty():
		return
	for data in Habitants.all_profiles():
		var start: String = "q7"
		var home: String = str(data.get("maison", ""))
		if port.points.has(home):
			start = home
		var npc: Node3D = PnjAzur.new()
		main.add_child(npc)
		npc.setup(main, data, port.points, port.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc
	if ferry != null:
		ferry.captain = by_id.get("leon", null)
		ferry.place_captain()


# =================================================================== le bateau de ligne

func build_ferry(village_pier: Array) -> void:
	ferry = FerryScript.new()
	ferry.name = "Ferry_v56"
	add_child(ferry)
	ferry.setup(main, self, village_pier, port.ferry_berth, port.ferry_gangway)


## Services proposés dans les dialogues (le capitaine, le réceptionniste, la voyante).
func register_services(journal: Node) -> void:
	journal.add_service("leon", Callable(self, "_leon_topics"), Callable(self, "_leon_choose"))
	journal.add_service("edmond", Callable(self, "_hotel_topics"), Callable(self, "_hotel_choose"))
	journal.add_service("rita", Callable(self, "_rita_topics"), Callable(self, "_rita_choose"))


func _leon_topics(_npc: Node) -> Array:
	if ferry == null or ferry.sailing():
		return []
	var dest: String = "Port-Azur" if ferry.at == "village" else "l'île du village"
	var price: int = ferry.price()
	return [{"id": "q56:service:ferry", "label": "⚓ Embarquer pour %s (%s)" % [dest, ("gratuit" if price == 0 else "%d pièces" % price)]}]


func _leon_choose(_npc: Node, _choice: String) -> Dictionary:
	var price: int = ferry.price()
	if main.inventory_v28.count("piece") < price:
		return {"texte": "C'est %d pièces la traversée, et ta bourse sonne creux. Reviens quand tu pourras payer, matelot." % price, "geste": "parle"}
	var r := {"texte": "Bienvenue à bord ! Installe-toi sur le pont, on largue les amarres. Cap sur %s !" % ("Port-Azur" if ferry.at == "village" else "l'île du village"), "geste": "salut", "fin": true, "_ferry": true}
	if price > 0:
		r["prendre"] = [["piece", price]]
	return r


func _hotel_topics(_npc: Node) -> Array:
	var h: float = hour()
	var night: bool = h >= 18.0 or h < 6.0
	return [{"id": "q56:service:hotel", "label": "☾ %s (10 pièces)" % ("Prendre une chambre pour la nuit" if night else "Faire une sieste jusqu'au soir")}]


func _hotel_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 10:
		return {"texte": "Je suis désolé, une chambre coûte dix pièces. L'hôtel n'est pas une œuvre de charité. Hélas.", "geste": "parle"}
	var h: float = hour()
	var night: bool = h >= 18.0 or h < 6.0
	return {"texte": ("Chambre sept… non, elle est prise. Chambre neuf, vue sur la mer. Bonne nuit." if night else "Une sieste ? Excellente idée. Je vous réveille à sept heures du soir."), "geste": "salut", "fin": true, "prendre": [["piece", 10]], "_dormir": 8.0 if night else 19.0}


func _rita_topics(_npc: Node) -> Array:
	return [{"id": "q56:service:rita", "label": "✦ Lire mon avenir (2 pièces)"}]


func _rita_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 2:
		return {"texte": "Deux petites pièces, voyageur. Le destin ne se lit pas gratuitement.", "geste": "parle"}
	var list: Dictionary = main.journal_v56.listing()
	var lines: Array = []
	for e in list["a_faire"]:
		lines.append("%s… %s" % [str(e["qui"]), str(e["texte"])])
	for e2 in list["en_cours"]:
		lines.append("Ton chemin passe par ceci : %s" % str(e2["objectif"]))
	var txt: String
	if lines.is_empty():
		txt = "Les cartes sont blanches… Tu as aidé tout le monde. Il ne te reste qu'à vivre heureux. C'est le plus difficile."
	else:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		txt = "Je vois… je vois… " + str(lines[rng.randi() % lines.size()]) + "\n\nLes cartes ne mentent jamais. Moi, parfois."
	return {"texte": txt, "geste": "parle", "prendre": [["piece", 2]]}


## Appelé par main après un échange réussi : départ du bateau, nuit à l'hôtel.
func after_reply(r: Dictionary, npc: Node) -> void:
	if bool(r.get("_ferry", false)) and ferry != null:
		main._close_dialogue_v31()
		ferry.depart(true)
	if r.has("_dormir"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_dormir"]))


# =================================================================== vie de la ville

func _process(delta: float) -> void:
	if main == null or port == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	var near: bool = ile.contains(p.x, p.z)
	if near and not bool(state["visite"]):
		state["visite"] = true
		main._show_message_v28("Port-Azur — la perle de l'archipel")
		if main.has_method("jingle"):
			main.jingle("decouverte")
	# la cloche sonne les heures (si l'horloge est réparée)
	var j: Node = main.get("journal_v56")
	var clock_ok: bool = j != null and bool(j.flags.get("horloge", false))
	var h: int = int(hour())
	if clock_ok and h != _last_bell_hour:
		if _last_bell_hour >= 0 and near:
			main.sfx("cloche", port.bell_pos)
		_last_bell_hour = h
	# le phare ne tourne que si sa lentille est réparée
	if port.lighthouse_head != null:
		port.lighthouse_head.visible = j == null or bool(j.flags.get("phare", false))
	_tick_gulls(delta, near)
	_tick_dog(delta)
	_tick_sparkles()
	_tick_django(p)


## Django joue sur la scène du Perroquet Bleu, le soir : un air triste tant que sa partition
## est perdue, « La Valse d'Azur » quand on la lui a rendue.
func _tick_django(p: Vector3) -> void:
	django_heard = false
	var dj: Node3D = by_id.get("django", null)
	if dj == null or not is_instance_valid(dj):
		return
	if _django_player == null:
		_django_player = AudioStreamPlayer3D.new()
		_django_player.name = "Guitare_Django"
		_django_player.bus = "Musique" if AudioServer.get_bus_index("Musique") >= 0 else "Master"
		_django_player.unit_size = 5.0
		_django_player.max_distance = 40.0
		_django_player.volume_db = -4.0
		_django_player.position = Vector3(0.3, 1.0, -0.3)
		dj.add_child(_django_player)
	var on_stage: bool = dj.visible and str(dj.pose) == "guitare"
	var d: float = p.distance_to(dj.global_position)
	if not on_stage or d > 38.0:
		if _django_player.playing:
			_django_player.stop()
		return
	var j: Node = main.get("journal_v56")
	var song: String = "valse_azur" if j != null and bool(j.flags.get("valse", false)) else "guitare_triste"
	if song != _django_song or _django_player.stream == null:
		_django_song = song
		var path: String = "res://assets/sons/musique/%s.ogg" % song
		var st: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if st is AudioStreamOggVorbis:
			st = (st as AudioStreamOggVorbis).duplicate()
			(st as AudioStreamOggVorbis).loop = true
		_django_player.stream = st
		_django_player.stop()
	if _django_player.stream != null and not _django_player.playing:
		_django_player.play()
	django_heard = _django_player.playing and d < 28.0


func _tree_for_kite(_p: Vector3) -> void:
	pass


# --- mouettes : des oiseaux blancs qui tournent au-dessus du port
func _make_gulls() -> void:
	var body_m := StandardMaterial3D.new()
	body_m.albedo_color = Color(0.96, 0.96, 0.95)
	body_m.roughness = 0.8
	var wing_m := StandardMaterial3D.new()
	wing_m.albedo_color = Color(0.82, 0.84, 0.86)
	wing_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tip_m := StandardMaterial3D.new()
	tip_m.albedo_color = Color(0.12, 0.12, 0.13)
	tip_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 5690
	for i in range(14):
		var g := Node3D.new()
		g.name = "Mouette_%d" % i
		var b := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		b.mesh = sm
		b.scale = Vector3(0.8, 0.8, 2.2)
		b.material_override = body_m
		g.add_child(b)
		var head := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.08
		hs.height = 0.16
		head.mesh = hs
		head.material_override = body_m
		head.position = Vector3(0, 0.05, -0.27)
		g.add_child(head)
		var beak := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.0
		bm.bottom_radius = 0.025
		bm.height = 0.1
		beak.mesh = bm
		var beak_m := StandardMaterial3D.new()
		beak_m.albedo_color = Color(0.95, 0.75, 0.2)
		beak.material_override = beak_m
		beak.rotation = Vector3(-PI / 2.0, 0, 0)
		beak.position = Vector3(0, 0.04, -0.37)
		g.add_child(beak)
		var wings: Array = []
		for s in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.position = Vector3(s * 0.08, 0.04, -0.04)
			g.add_child(pivot)
			var w := MeshInstance3D.new()
			var bx := BoxMesh.new()
			bx.size = Vector3(0.62, 0.015, 0.2)
			w.mesh = bx
			w.material_override = wing_m
			w.position = Vector3(s * 0.31, 0, 0)
			pivot.add_child(w)
			var tip := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(0.16, 0.016, 0.16)
			tip.mesh = tb
			tip.material_override = tip_m
			tip.position = Vector3(s * 0.66, 0, 0.02)
			pivot.add_child(tip)
			wings.append(pivot)
		add_child(g)
		var center: Vector3 = port.T(rng.randf_range(-70.0, 60.0), rng.randf_range(-50.0, 30.0), 0.0)
		_gulls.append({"node": g, "wings": wings, "c": center, "r": rng.randf_range(10.0, 30.0), "h": rng.randf_range(8.0, 22.0), "a": rng.randf() * TAU, "w": rng.randf_range(0.15, 0.35) * (1.0 if i % 2 == 0 else -1.0), "ph": rng.randf() * TAU})


func _tick_gulls(delta: float, near: bool) -> void:
	for g in _gulls:
		var n: Node3D = g["node"]
		n.visible = near
		if not near:
			continue
		g["a"] = float(g["a"]) + delta * float(g["w"])
		var a: float = float(g["a"])
		var c: Vector3 = g["c"]
		var pos := Vector3(c.x + cos(a) * float(g["r"]), c.y + float(g["h"]) + sin(a * 2.3 + float(g["ph"])) * 1.5, c.z + sin(a) * float(g["r"]))
		var nxt := Vector3(c.x + cos(a + 0.05 * signf(float(g["w"]))) * float(g["r"]), pos.y, c.z + sin(a + 0.05 * signf(float(g["w"]))) * float(g["r"]))
		n.global_position = pos
		n.look_at(nxt, Vector3.UP)
		n.rotate_object_local(Vector3.FORWARD, -signf(float(g["w"])) * 0.35)
		var flap: float = sin(_clock * 6.0 + float(g["ph"])) * 0.5 if fmod(_clock + float(g["ph"]), 6.0) < 2.0 else 0.08
		(g["wings"][0] as Node3D).rotation.z = flap
		(g["wings"][1] as Node3D).rotation.z = -flap


# --- le petit chien blanc, voleur de croissants : il trotte entre la boulangerie et le quai
func _make_dog() -> void:
	_dog = Node3D.new()
	_dog.name = "Chien_blanc"
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.95, 0.94, 0.9)
	fur.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.08, 0.08)
	var parts := [[Vector3(0, 0.3, 0), Vector3(0.22, 0.2, 0.42), fur], [Vector3(0, 0.42, -0.26), Vector3(0.18, 0.17, 0.2), fur], [Vector3(0, 0.38, -0.38), Vector3(0.09, 0.08, 0.1), fur],
		[Vector3(0, 0.39, -0.44), Vector3(0.04, 0.035, 0.03), dark], [Vector3(0.07, 0.52, -0.24), Vector3(0.05, 0.08, 0.04), fur], [Vector3(-0.07, 0.52, -0.24), Vector3(0.05, 0.08, 0.04), fur],
		[Vector3(0, 0.42, 0.24), Vector3(0.04, 0.04, 0.16), fur]]
	for pr in parts:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		mi.mesh = sm
		mi.scale = pr[1]
		mi.position = pr[0]
		mi.material_override = pr[2]
		_dog.add_child(mi)
	for lx in [-0.08, 0.08]:
		for lz in [-0.14, 0.14]:
			var leg := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.03
			cm.height = 0.22
			leg.mesh = cm
			leg.material_override = fur
			leg.position = Vector3(lx, 0.11, lz)
			leg.name = "Patte"
			_dog.add_child(leg)
	for e in [-0.045, 0.045]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.018
		es.height = 0.036
		eye.mesh = es
		eye.material_override = dark
		eye.position = Vector3(e, 0.46, -0.36)
		_dog.add_child(eye)
	add_child(_dog)
	_dog.set_meta("route", ["s3", "s9", "s1", "h1", "g2", "g1", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11", "q12", "q13"])
	_dog.set_meta("i", 0)
	_dog.set_meta("dir", 1)
	_dog.global_position = port.points["s3"]


func _tick_dog(delta: float) -> void:
	if _dog == null:
		return
	var p: Vector3 = main._player_pos_v27()
	var near: bool = _dog.global_position.distance_to(p) < 80.0
	_dog.visible = near
	if not near:
		return
	_dog_t += delta
	var route: Array = _dog.get_meta("route")
	var i: int = int(_dog.get_meta("i"))
	var goal: Vector3 = port.points[route[i]]
	var to: Vector3 = goal - _dog.global_position
	to.y = 0.0
	if to.length() < 0.3:
		var d: int = int(_dog.get_meta("dir"))
		i += d
		if i >= route.size() or i < 0:
			d = -d
			i = clampi(i + 2 * d, 0, route.size() - 1)
			_dog.set_meta("dir", d)
		_dog.set_meta("i", i)
		return
	var speed: float = 1.6 if p.distance_to(_dog.global_position) > 4.0 else 2.6
	_dog.global_position += to.normalized() * minf(speed * delta, to.length())
	_dog.global_position.y = maxf(main._height_at(_dog.global_position.x, _dog.global_position.z), ile.TOWN_Y) + 0.02
	_dog.rotation.y = atan2(-to.x, -to.z)
	var k: int = 0
	for c in _dog.get_children():
		if c.name.begins_with("Patte"):
			(c as Node3D).rotation.x = sin(_dog_t * 14.0 + k * PI) * 0.5
			k += 1


# --- les endroits à creuser brillent
func _tick_sparkles() -> void:
	var j: Node = main.get("journal_v56")
	if j == null:
		return
	var want: Array = j.dig_spots()
	for w in want:
		var key: String = str(Vector3i(w))
		if not _sparkles.has(key):
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			s.mesh = sm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.95, 0.6, 0.8)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.9, 0.5)
			m.emission_energy_multiplier = 3.0
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			s.material_override = m
			add_child(s)
			s.global_position = w + Vector3.UP * 0.1
			_sparkles[key] = s
	for key2 in _sparkles.keys():
		var found: bool = false
		for w2 in want:
			if str(Vector3i(w2)) == key2:
				found = true
		var sp: MeshInstance3D = _sparkles[key2]
		if not found:
			sp.queue_free()
			_sparkles.erase(key2)
		else:
			sp.scale = Vector3.ONE * (0.6 + 0.4 * absf(sin(_clock * 3.0)))


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var d := state.duplicate()
	if ferry != null:
		d["ferry"] = ferry.serialize()
	return d


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "nuits": int(d.get("nuits", 0))}
	if ferry != null:
		var f: Variant = d.get("ferry", {})
		ferry.load_data(f if f is Dictionary else {})
	_claims.clear()
	for n in habitants:
		n.slot = -2

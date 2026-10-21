extends Node3D
## V59 : la grande île de l'est (grande_ile_v59.gd), le Léviathan (epave_v59.gd), Carène
## (carene_v59.gd), la végétation (grande_flore_v59.gd), les gens de Carène
## (pnj/carene_habitants_v59.gd) et ce qui les relie au reste du jeu : les lieux et l'heure
## pour les habitants, les zones (musique, ambiances), le retour après une chute, la porte
## aux Quatre Sceaux (examinée pour la quête de Matthias), la sauvegarde.
## L'île est à l'est de l'archipel : la barque y va en longeant l'île des elfes.

const IleScript = preload("res://scripts/grande_ile_v59.gd")
const EpaveScript = preload("res://scripts/epave_v59.gd")
const CareneScript = preload("res://scripts/carene_v59.gd")
const FloreScript = preload("res://scripts/grande_flore_v59.gd")
const Habitants = preload("res://scripts/pnj/carene_habitants_v59.gd")
const PnjAzur = preload("res://scripts/pnj/pnj_azur_v56.gd")
const WRECK_AT := Vector3(665.0, -4.8, -150.0)

var main: Node
var ile: Node3D
var epave: Node3D
var carene: Node3D
var flore: Node3D
var habitants: Array = []
var by_id: Dictionary = {}
var state := {"visite": false, "porte": false, "nuits": 0}
var pc: bool = true
var _claims: Dictionary = {}
var _clock: float = 0.0
var _gulls: Array = []


func setup(main_node: Node) -> void:
	main = main_node
	pc = OS.has_feature("ile_manga_pc")


# =================================================================== construction

## Le relief et l'épave (avant l'heure du jour : main a besoin du relief tout de suite).
func build_island() -> void:
	epave = EpaveScript.new()
	epave.name = "Leviathan_v59"
	epave.place(WRECK_AT)
	ile = IleScript.new()
	ile.name = "Grande_ile_v59"
	add_child(ile)
	ile.build(pc, epave)
	add_child(epave)
	epave.place(WRECK_AT)
	epave.build(pc)


## Après l'heure du jour : Carène, la végétation, les oiseaux, les invites « E ».
func build_town() -> void:
	carene = CareneScript.new()
	carene.name = "Carene_v59"
	add_child(carene)
	carene.build(main, epave, ile, pc)
	flore = FloreScript.new()
	flore.name = "Flore_grande_ile_v59"
	add_child(flore)
	flore.build_island(ile, epave, pc)
	_make_gulls()
	_register_interactions()
	print("ILE_MANGA_V59: la grande île est prête")


func dock() -> Array:
	return carene.boat_dock if carene != null else []


func contains(p: Vector3) -> bool:
	return ile != null and ile.contains(p.x, p.z) and p.y > -45.0


## À bord du Léviathan, sur un ponton de Carène ?
func on_structure(p: Vector3) -> bool:
	if epave != null and epave.aboard(p):
		return true
	return carene != null and carene.on_walkway(p)


## À pied : on peut marcher ici (la terre ferme de l'île, l'épave, les pontons) ?
func walkable(p: Vector3) -> bool:
	if not contains(p):
		return false
	if on_structure(p):
		return true
	return ile.height(p.x, p.z) > -0.3


## La barque ne passe pas à travers la coque.
func blocks_boat(p: Vector3) -> bool:
	return epave != null and epave.blocks_boat(p)


## La zone du joueur (pour la musique et les ambiances).
func zone_at(p: Vector3) -> String:
	if not contains(p):
		return ""
	if epave != null:
		var l: Vector3 = epave.Lc(p)
		if absf(l.x) < epave.HL + 2.0 and absf(l.z) < epave.HB + 1.0 and l.y > -2.0 and l.y < epave.D + 50.0:
			if l.x < epave.CASTLE_X and l.y > epave.D - 0.5 and l.y < epave.QD_Y - 0.5:
				return "carene_taverne"
			if l.y < epave.GUN_Y - 0.5:
				return "carene_cale"
			if l.y < epave.D - 0.5:
				return "carene_entrepont"
			return "carene"
		if l.x > -80.0 and l.x < 90.0 and l.z > -70.0 and l.z < 30.0:
			return "carene"
	var c: Vector3 = ile.CENTER
	if Vector2(p.x - c.x, p.z - c.z).length() < 90.0:
		return "grande_massif"
	if ile.height(p.x, p.z) < -0.42 and not on_structure(p):
		return ""
	return "grande_" + ile.region_name(p.x, p.z)


func respawn_point() -> Array:
	var at: Vector3 = carene.points.get("e1", ile.door_front()) if carene != null else ile.door_front()
	var to: Vector3 = carene.points.get("e_gang", at + Vector3.FORWARD) if carene != null else at + Vector3.FORWARD
	return [at + Vector3.UP * 0.3, (to - at).normalized()]


# =================================================================== les habitants

func hour() -> float:
	return float(main.temps_v56.hour) if main.get("temps_v56") != null and main.temps_v56 != null else 12.0


func spot(name: String) -> Dictionary:
	return carene.spots.get(name, {}) if carene != null else {}


func spot_free(name: String, who: Node) -> bool:
	var c: Variant = _claims.get(name, null)
	return c == null or c == who or not is_instance_valid(c)


func claim_spot(name: String, who: Node) -> void:
	_claims[name] = who


func release_spot(name: String, who: Node) -> void:
	if _claims.get(name, null) == who:
		_claims.erase(name)


func spawn_npcs() -> void:
	if not habitants.is_empty() or carene == null:
		return
	for data in Habitants.all_profiles():
		var start: String = "d_place"
		var home: String = str(data.get("maison", ""))
		if carene.points.has(home):
			start = home
		var npc: Node3D = PnjAzur.new()
		main.add_child(npc)
		npc.setup(main, data, carene.points, carene.graph, start)
		npc.setup_azur(self, data)
		var saved: Variant = main.pending_pnj_v31.get(str(data["id"]), {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			npc.load_data(saved)
		main.npcs_v31.append(npc)
		habitants.append(npc)
		by_id[str(data["id"])] = npc


## Services : l'auberge de Pierrick (une nuit dans un hamac).
func register_services(journal: Node) -> void:
	journal.add_service("pierrick", Callable(self, "_inn_topics"), Callable(self, "_inn_choose"))


func _inn_topics(_npc: Node) -> Array:
	var h: float = hour()
	var night: bool = h >= 18.0 or h < 6.0
	return [{"id": "q56:service:hamac", "label": "☾ %s (6 pièces)" % ("Un hamac pour la nuit" if night else "Une sieste dans un hamac jusqu'au soir")}]


func _inn_choose(_npc: Node, _choice: String) -> Dictionary:
	if main.inventory_v28.count("piece") < 6:
		return {"texte": "Six pièces le hamac, couverture comprise. Ma tante ne fait pas crédit, et moi non plus. Enfin… elle ne me laisse pas.", "geste": "parle"}
	var h: float = hour()
	var night: bool = h >= 18.0 or h < 6.0
	return {"texte": ("Le hamac du fond, à bâbord. Le Léviathan va te bercer. Bonne nuit !" if night else "Une sieste ? Le hamac du fond. Je te réveille pour la soupe de sept heures."),
		"geste": "salut", "fin": true, "prendre": [["piece", 6]], "_hamac": 8.0 if night else 19.0}


## Appelé par main après un échange réussi (l'auberge).
func after_reply(r: Dictionary, _npc: Node) -> void:
	if r.has("_hamac"):
		main._close_dialogue_v31()
		state["nuits"] = int(state["nuits"]) + 1
		main.temps_v56.sleep_until(float(r["_hamac"]))


# =================================================================== la porte aux Quatre Sceaux

func _register_interactions() -> void:
	var d: Node = main.get("donjon_v35")
	if d == null:
		return
	var I: Array = d._interactions
	I.append({"id": "porte_sceaux", "pos": ile.door_front(), "radius": 6.0, "text": "E : examiner la Porte aux Quatre Sceaux", "vr": "Gâchette : examiner la porte",
		"call": _examine_door})
	if carene != null:
		I.append({"id": "carene_cloche", "pos": carene.bell_pos - Vector3.UP * 1.6, "radius": 1.8, "text": "E : sonner la cloche du bord", "vr": "Gâchette : sonner la cloche",
			"call": _ring_bell})


func _examine_door() -> void:
	var first: bool = not bool(state["porte"])
	state["porte"] = true
	if main.get("sfx_v50") != null:
		main.sfx_v50.here("grille")
	var t: String = "Une porte de pierre haute comme cinq hommes, sans poignée ni serrure. Sur ses deux vantaux, un grand cercle gravé luit faiblement ; autour, quatre creux ronds, vides : les quatre sceaux. Un souffle tiède passe par la fente du milieu, comme si la montagne respirait."
	if not first:
		t = "La Porte aux Quatre Sceaux. Les quatre creux sont toujours vides. Derrière la pierre, très loin, on dirait qu'un cœur bat."
	main.donjon_v35._say(t, 8.0)


func _ring_bell() -> void:
	if main.get("sfx_v50") != null:
		main.sfx_v50.play("cloche", carene.bell_pos)
	main.donjon_v35._say("DONG… DONG… La cloche du Léviathan résonne dans toute la coque. Quelque part, Ewen crie : « C'est pas moi ! »", 4.0)


func trouvailles() -> Dictionary:
	return {"grande_ile": 1 if bool(state["visite"]) else 0, "porte_sceaux": 1 if bool(state["porte"]) else 0}


# =================================================================== vie

func _process(delta: float) -> void:
	if main == null or ile == null:
		return
	_clock += delta
	var p: Vector3 = main._player_pos_v27()
	# l'océan suit le joueur (par pas de 40 m : ses sommets ne glissent pas sous les vagues)
	var oc: Node3D = main.get("ocean")
	if oc != null:
		oc.position.x = snappedf(p.x, 40.0)
		oc.position.z = snappedf(p.z, 40.0)
	if not bool(state["visite"]) and contains(p) and epave != null and epave.Lc(p).x > -90.0 and ile.height(p.x, p.z) > -0.2:
		state["visite"] = true
		main._show_message_v28("La grande île de l'est — Carène, le port dans l'épave du Léviathan")
	_tick_gulls(delta)


func _make_gulls() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.92, 0.9)
	m.roughness = 0.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(9 if pc else 5):
		var g := Node3D.new()
		g.name = "Goeland_v59_%d" % i
		var body := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.09
		cm.height = 0.42
		body.mesh = cm
		body.rotation.x = PI * 0.5
		body.material_override = m
		g.add_child(body)
		for s in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.55, 0.16)
			w.mesh = qm
			w.material_override = m
			w.position = Vector3(s * 0.3, 0.02, 0)
			w.rotation.x = -PI * 0.5
			w.name = "aile_%d" % (1 if s > 0 else 0)
			g.add_child(w)
		add_child(g)
		_gulls.append([g, randf() * TAU, randf_range(18.0, 40.0), randf_range(0.18, 0.35), randf_range(22.0, 38.0)])


func _tick_gulls(delta: float) -> void:
	if epave == null:
		return
	var c: Vector3 = epave.W(Vector3(10.0, 0.0, 0.0))
	for gd in _gulls:
		var g: Node3D = gd[0]
		gd[1] = float(gd[1]) + delta * float(gd[3])
		var a: float = float(gd[1])
		var r: float = float(gd[2])
		var pos := Vector3(c.x + cos(a) * r, float(gd[4]) + sin(a * 2.3) * 2.0, c.z + sin(a) * r * 0.7)
		var nxt := Vector3(c.x + cos(a + 0.05) * r, pos.y, c.z + sin(a + 0.05) * r * 0.7)
		g.position = pos
		g.look_at(nxt, Vector3.UP)
		var flap: float = sin(_clock * 7.0 + a * 10.0) * 0.5
		(g.get_child(1) as Node3D).rotation.z = flap
		(g.get_child(2) as Node3D).rotation.z = -flap


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return state.duplicate()


func load_data(d: Dictionary) -> void:
	state = {"visite": bool(d.get("visite", false)), "porte": bool(d.get("porte", false)), "nuits": int(d.get("nuits", 0))}
	_claims.clear()
	for n in habitants:
		n.slot = -2

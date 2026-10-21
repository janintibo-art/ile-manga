extends Node
## V58 : la magie de téléportation, cadeau de la reine des fées (journal_v56, drapeau
## « teleportation »). On retourne en un instant dans un lieu déjà visité : T au PC, ou le
## carnet (onglet Carte, « Se téléporter »), au laser en VR.
## Les lieux visités se notent tout seuls quand on y passe (et d'après les trouvailles des
## aventures déjà vécues) ; ils sont enregistrés avec la partie.

const PLACES := [
	["village", "Le village"], ["teuf", "La plage de la teuf"], ["jungle", "L'île de la jungle"], ["elfes", "Le Bois-Doré"],
	["nains", "Forgefer"], ["ciel", "L'île flottante"], ["azur", "Port-Azur"], ["atlantide", "L'Atlantide"], ["fees", "Le royaume des fées"],
	["carene", "Carène"], ["porte_sceaux", "La Porte aux Quatre Sceaux"], ["tazira", "Tazira"],
]

var main: Node
var visited: Dictionary = {"village": true}
var busy: bool = false
var _clock: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node


func known() -> bool:
	var j: Node = main.get("journal_v56")
	return j != null and bool(j.flags.get("teleportation", false))


func place_name(id: String) -> String:
	for p in PLACES:
		if str(p[0]) == id:
			return str(p[1])
	return id


## [position des pieds, regard] du point d'arrivée, ou [] si le lieu n'existe pas.
func spot(id: String) -> Array:
	match id:
		"village":
			return [Vector3(2.0, maxf(0.0, main._height_at(2.0, 8.0)) + 0.1, 8.0), Vector3(0, 0, -1)]
		"teuf":
			var fe: Node = main.get("feerie_v58")
			if fe != null:
				return fe.beach_spot()
			return []
		"jungle":
			var j: Node = main.get("jungle_v29")
			if j == null:
				return []
			var a: Vector3 = j.dock_start
			var b: Vector3 = j.dock_end
			var land: Vector3 = a + (a - b).normalized() * 3.0
			land.y = main._height_at(land.x, land.z) + 0.1
			return [land, (land - a).normalized() * Vector3(1, 0, 1)]
		"elfes":
			var el: Node = main.get("elfes_v41")
			if el == null or el.ile == null:
				return []
			var g: Vector3 = el.ile.glade_world()
			var at: Vector3 = g + Vector3(0, 0, 22.0)
			at.y = el.ile.height(at.x, at.z) + 0.1
			return [at, (g - at).normalized() * Vector3(1, 0, 1)]
		"nains":
			var n: Node = main.get("nains_v46")
			return n.respawn_point() if n != null and n.get("forge_root") != null else []
		"ciel":
			var c: Node = main.get("ciel_v54")
			return c.respawn_point() if c != null else []
		"azur":
			var az: Node = main.get("azur_v56")
			return az.respawn_point() if az != null and az.get("port") != null and az.port != null else []
		"atlantide":
			var m: Node = main.get("mer_v55")
			return m.atl.respawn_point() if m != null and m.atl != null else []
		"fees":
			var f: Node = main.get("feerie_v58")
			return [f.glade_spot(), Vector3(0, 0, -1)] if f != null else []
		"carene":
			var gr: Node = main.get("grande_v59")
			return gr.respawn_point() if gr != null and gr.get("carene") != null and gr.carene != null else []
		"tazira":
			var gt: Node = main.get("grande_v59")
			return gt.tazira.respawn_point() if gt != null and gt.get("tazira") != null and gt.tazira != null else []
		"porte_sceaux":
			var gp: Node = main.get("grande_v59")
			if gp == null or gp.get("ile") == null or gp.ile == null:
				return []
			var at: Vector3 = gp.ile.door_front() + Basis(Vector3.UP, gp.ile.door_yaw) * Vector3(0, 0, 6.0)
			at.y = gp.ile.height(at.x, at.z) + 0.1
			return [at, (gp.ile.door_pos - at).normalized() * Vector3(1, 0, 1)]
	return []


## Les destinations offertes : [id, nom], dans l'ordre de PLACES, sans le lieu où l'on est.
func destinations() -> Array:
	var out: Array = []
	var here: String = current_place()
	for p in PLACES:
		var id: String = str(p[0])
		if bool(visited.get(id, false)) and id != here and not spot(id).is_empty():
			out.append([id, str(p[1])])
	return out


## Le lieu où se trouve le joueur ("" en mer ou sous terre).
func current_place() -> String:
	var p: Vector3 = main._player_pos_v27()
	var fe: Node = main.get("feerie_v58")
	if fe != null and fe.contains(p):
		return "fees"
	var c: Node = main.get("ciel_v54")
	if c != null and c.on_sky(p):
		return "ciel"
	var m: Node = main.get("mer_v55")
	if m != null and m.atl != null and m.atl.in_dome(p + Vector3.UP):
		return "atlantide"
	var az: Node = main.get("azur_v56")
	if az != null and az.get("ile") != null and az.ile != null and az.contains(p):
		return "azur"
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.get("ile") != null and gr.ile != null and gr.contains(p) and p.y > -10.0:
		var gz: String = str(gr.zone_at(p))
		if gz.begins_with("carene"):
			return "carene"
		if gz.begins_with("tazira"):
			return "tazira"
		if p.distance_to(gr.ile.door_pos) < 30.0:
			return "porte_sceaux"
		return ""
	var n: Node = main.get("nains_v46")
	if n != null and n.ile != null and n.ile.contains(p.x, p.z) and p.y > -10.0:
		return "nains"
	var el: Node = main.get("elfes_v41")
	if el != null and el.ile != null and el.ile.contains(p.x, p.z) and p.y > -10.0:
		return "elfes"
	var j: Node = main.get("jungle_v29")
	if j != null and j.contains(p.x, p.z) and p.y > -10.0:
		return "jungle"
	if Vector2(p.x, p.z).length() < 120.0 and p.y > -20.0:
		var tf: Node = main.get("teuf_v57")
		if tf != null and Vector2(p.x - tf.WALL.x, p.z - tf.WALL.z).length() < 40.0:
			return "teuf"
		return "village"
	return ""


func _process(delta: float) -> void:
	if main == null or not bool(main.get("game_started")):
		return
	_clock += delta
	if _clock < 1.0:
		return
	_clock = 0.0
	var here: String = current_place()
	if here != "":
		visited[here] = true
	# les aventures déjà vécues (parties enregistrées avant la V58)
	var tr: Dictionary = main._npc_ctx_v31().get("trouvailles", {})
	for pair in [["jungle", "trappe_jungle"], ["elfes", "ile_elfes"], ["nains", "ile_nains"], ["ciel", "citadelle"], ["azur", "azur"], ["atlantide", "atlantide"], ["fees", "royaume_fees"], ["carene", "grande_ile"], ["porte_sceaux", "porte_sceaux"], ["tazira", "tazira"]]:
		if int(tr.get(str(pair[1]), 0)) > 0:
			visited[str(pair[0])] = true


## Le voyage : un éclat de lumière, on disparaît, on réapparaît là-bas.
func go(id: String) -> bool:
	if busy or not known():
		return false
	var fe: Node = main.get("feerie_v58")
	if fe != null and not fe._can_travel():
		return false
	var sp: Array = spot(id)
	if sp.is_empty():
		return false
	busy = true
	if main.inventory_v28 != null and main.inventory_v28.opened:
		main.inventory_v28.close()
	if main.fishing_v32 != null:
		main.fishing_v32.cancel("")
	var d: Node = main.donjon_v35
	main.sfx("teleport")
	if main.combat_v28 != null:
		main.combat_v28.puff(main._player_pos_v27() + Vector3.UP * 1.0, Color(0.75, 1.0, 0.85))
	await d._fade_to(1.0, 0.7)
	main.place_player_v35(sp[0], sp[1])
	d.update_inside(true)
	await get_tree().create_timer(0.35).timeout
	await d._fade_to(0.0, 0.9)
	main.sfx("teleport")
	main._show_message_v28("✦ " + place_name(id))
	busy = false
	return true


func serialize() -> Dictionary:
	return {"visites": visited.keys()}


func load_data(d: Dictionary) -> void:
	visited = {"village": true}
	var v: Variant = d.get("visites", [])
	if v is Array:
		for id in v:
			visited[str(id)] = true

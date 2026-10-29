extends Node
## V58 : la magie de téléportation, cadeau de la reine des fées (journal_v56, drapeau
## « teleportation »). On retourne en un instant dans un lieu déjà visité : T au PC, ou le
## carnet (onglet Carte, « Se téléporter »), au laser en VR.
## Les lieux visités se notent tout seuls quand on y passe (et d'après les trouvailles des
## aventures déjà vécues) ; ils sont enregistrés avec la partie.

const PLACES := [
	["village", "Le village"], ["teuf", "La plage de la teuf"], ["jungle", "L'île de la jungle"], ["elfes", "Le Bois-Doré"],
	["nains", "Forgefer"], ["ciel", "L'île flottante"], ["azur", "Port-Azur"], ["atlantide", "L'Atlantide"], ["fees", "Le royaume des fées"],
	["carene", "Carène"], ["porte_sceaux", "La Porte aux Quatre Sceaux"], ["tazira", "Tazira"], ["cliquetis", "Cliquetis"],
	["ramure", "Ramure"], ["arcanelle", "Arcanelle"], ["balafre", "Port-Coutelas"],
	["per_hapy", "Per-Hâpy"], ["yaxche", "Yaxché"], ["aztlan", "Aztlán"],
	["pandemonia", "Pandémonia"], ["pandemonia_port", "Le Port de Cendre"],
	["montjoie", "Montjoie, la Grand-Place"], ["montjoie_port", "Le Port des Mouettes"],
	["boucan", "Port-Boucan, la Place des Palettes"], ["boucan_port", "Le Vieux Bassin de Port-Boucan"],
	["astralys", "Astralys, le Portail d'accueil"], ["astralys_bouee", "La Bouée d'accueil d'Astralys"],
	["moai", "L'Île aux Moaïs, la Plage Blanche"],
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
			# V80 : sur le sentier des lanternes, à l'entrée de la place (et non plus dans le tronc
			# de l'arbre-maison du sud, planté pile à 21 m du centre).
			var to_dock: Vector3 = (el.ile.dock_start - g) * Vector3(1, 0, 1)
			var at: Vector3 = g + (to_dock.normalized() if to_dock.length() > 1.0 else Vector3(0, 0, 1)) * 15.0
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
		"cliquetis":
			var gq: Node = main.get("grande_v59")
			return gq.cliquetis.respawn_point() if gq != null and gq.get("cliquetis") != null and gq.cliquetis != null else []
		"ramure":
			var gm: Node = main.get("grande_v59")
			return gm.ramure.respawn_point() if gm != null and gm.get("ramure") != null and gm.ramure != null else []
		"tazira":
			var gt: Node = main.get("grande_v59")
			return gt.tazira.respawn_point() if gt != null and gt.get("tazira") != null and gt.tazira != null else []
		"balafre":
			var pv: Node = main.get("pirates_v68")
			return pv.respawn_point() if pv != null and pv.get("port") != null and pv.port != null else []
		"pandemonia", "pandemonia_port":
			var br: Node = main.get("braise_v70")
			return br.village_point(id) if br != null and br.get("city") != null and br.city != null else []
		"montjoie", "montjoie_port":
			var mj: Node = main.get("montjoie_v71")
			return mj.village_point(id) if mj != null and mj.get("city") != null and mj.city != null else []
		"astralys", "astralys_bouee":
			var ast: Node = main.get("astralys_v76")
			return ast.village_point(id) if ast != null and ast.get("city") != null and ast.city != null else []
		"moai":
			var mo: Node = main.get("moai_v87")
			return mo.village_point(id) if mo != null and mo.get("ile") != null and mo.ile != null else []
		"boucan", "boucan_port":
			var bo: Node = main.get("boucan_v75")
			return bo.village_point(id) if bo != null and bo.get("city") != null and bo.city != null else []
		"per_hapy", "yaxche", "aztlan":
			var so: Node = main.get("soleils_v69")
			return so.village_point(id) if so != null and so.get("egypte") != null and so.egypte != null else []
		"arcanelle":
			var ar: Node = main.get("arcanelle_v67")
			return ar.respawn_point() if ar != null and ar.get("bourg") != null and ar.bourg != null else []
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
	var pv2: Node = main.get("pirates_v68")
	if pv2 != null and pv2.get("port") != null and pv2.port != null and pv2.contains(p) and p.y > -10.0 and pv2.ile.height(p.x, p.z) > -0.42:
		return "balafre"
	var so2: Node = main.get("soleils_v69")
	if so2 != null and so2.get("egypte") != null and so2.egypte != null and so2.contains(p) and p.y > -10.0 and so2.ile.height(p.x, p.z) > -0.42:
		var pe: String = str(so2.people_at(p))
		if pe != "":
			return {"egypte": "per_hapy", "maya": "yaxche", "azteque": "aztlan"}[pe]
	var br2: Node = main.get("braise_v70")
	if br2 != null and br2.get("city") != null and br2.city != null and br2.contains(p) and p.y > -10.0 and str(br2.people_at(p)) == "cite":
		return "pandemonia_port" if str(br2.zone_at(p)) == "braise_port" else "pandemonia"
	var as2: Node = main.get("astralys_v76")
	if as2 != null and as2.get("city") != null and as2.city != null and as2.contains(p) and str(as2.people_at(p)) == "ville":
		return "astralys"
	var mo2: Node = main.get("moai_v87")
	if mo2 != null and mo2.get("ile") != null and mo2.ile != null and mo2.contains(p) and p.y > -10.0 and mo2.ile.height(p.x, p.z) > -0.42:
		return "moai"
	var bo2: Node = main.get("boucan_v75")
	if bo2 != null and bo2.get("city") != null and bo2.city != null and bo2.contains(p) and p.y > -10.0:
		var bz: String = str(bo2.zone_at(p))
		if bz == "bo_port":
			return "boucan_port"
		if str(bo2.people_at(p)) == "ville":
			return "boucan"
	var mj2: Node = main.get("montjoie_v71")
	if mj2 != null and mj2.get("city") != null and mj2.city != null and mj2.contains(p) and p.y > -10.0:
		var mz: String = str(mj2.zone_at(p))
		if mz == "mj_port":
			return "montjoie_port"
		if str(mj2.people_at(p)) == "ville":
			return "montjoie"
	var ar2: Node = main.get("arcanelle_v67")
	if ar2 != null and ar2.get("bourg") != null and ar2.bourg != null and ar2.contains(p) and p.y > -10.0 and ar2.ile.height(p.x, p.z) > -0.42:
		return "arcanelle"
	var gr: Node = main.get("grande_v59")
	if gr != null and gr.get("ile") != null and gr.ile != null and gr.contains(p) and p.y > -10.0:
		var gz: String = str(gr.zone_at(p))
		if gz.begins_with("carene"):
			return "carene"
		if gz.begins_with("tazira"):
			return "tazira"
		if gz.begins_with("cliquetis"):
			return "cliquetis"
		if gz.begins_with("ramure"):
			return "ramure"
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
	for pair in [["jungle", "trappe_jungle"], ["elfes", "ile_elfes"], ["nains", "ile_nains"], ["ciel", "citadelle"], ["azur", "azur"], ["atlantide", "atlantide"], ["fees", "royaume_fees"], ["carene", "grande_ile"], ["porte_sceaux", "porte_sceaux"], ["tazira", "tazira"], ["cliquetis", "cliquetis"], ["ramure", "ramure"], ["arcanelle", "arcanelle"], ["balafre", "balafre"], ["per_hapy", "soleils_egypte"], ["yaxche", "soleils_maya"], ["aztlan", "soleils_azteque"], ["pandemonia", "pandemonia"], ["montjoie", "montjoie_ville"], ["montjoie_port", "montjoie"], ["boucan", "boucan_ville"], ["boucan_port", "boucan"], ["astralys", "astralys_ville"], ["astralys_bouee", "astralys"], ["moai", "moai"]]:
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

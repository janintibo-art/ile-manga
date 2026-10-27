extends Node
## V78 : le MODE TESTEUR (PC, touche F8) : pour vérifier le jeu sans tout parcourir à pied.
##  - aller sur n'importe quelle île ou grande place (même pas encore visitée) ;
##  - aller à n'importe quel lieu de quête du carnet (objets à ramasser, comptoirs, portes…) ;
##  - aller près de n'importe quel habitant ;
##  - changer l'heure (matin, midi, soir, nuit) ;
##  - invincible (ni coups, ni chutes, ni noyade) ;
##  - 500 pièces de cuivre.
## Tout passe par la fenêtre de dialogue (souris, chiffres, manette) ; rien n'est enregistré
## avec la partie, sauf ce qu'on y gagne (pièces, lieux visités).

const PAGE: int = 7                       # V80 : 7 + Suivants + Précédents + Retour = 10 touches (1…0)

var main: Node
var invincible: bool = false
var _anchor: Node3D
var _list: Array = []                    # [[libellé, valeur], …] de la page en cours
var _list_kind: String = ""
var _page: int = 0


func setup(main_node: Node) -> void:
	main = main_node
	_anchor = Node3D.new()
	_anchor.name = "Testeur_v78"
	add_child(_anchor)


func open_menu() -> void:
	if main == null or main.get("dialogue_v31") == null:
		return
	_anchor.global_position = main._player_pos_v27() + Vector3.UP * 0.2
	var ch: Array = [
		{"id": "iles", "label": "Aller sur une île ou une grande place"},
		{"id": "lieux", "label": "Aller à un lieu de quête (carnet)"},
		{"id": "pnj", "label": "Aller près d'un habitant"},
		{"id": "heure", "label": "Changer l'heure"},
		{"id": "invincible", "label": "Invincible : " + ("OUI (désactiver)" if invincible else "non (activer)")},
		{"id": "pieces", "label": "+ 500 pièces de cuivre"},
		{"id": "fermer", "label": "(Fermer)"},
	]
	main.ask_v69(_anchor, "Mode testeur", "malin", "Où veux-tu aller ?", ch, _pick)


func _pick(id: String) -> void:
	match id:
		"iles":
			_open_list("iles", _islands(), 0)
		"lieux":
			_open_list("lieux", _quest_places(), 0)
		"pnj":
			_open_list("pnj", _npcs(), 0)
		"heure":
			var ch: Array = [{"id": "h:7.5", "label": "Le matin (7 h 30)"}, {"id": "h:12.0", "label": "Midi"},
				{"id": "h:18.5", "label": "Le soir (18 h 30)"}, {"id": "h:22.5", "label": "La nuit (22 h 30)"}, {"id": "menu", "label": "(Retour)"}]
			main.ask_v69(_anchor, "Mode testeur", "malin", "Quelle heure ?", ch, _pick)
		"invincible":
			invincible = not invincible
			main._show_message_v28("Mode testeur : invincible " + ("activé" if invincible else "désactivé") + ".")
			open_menu()
		"pieces":
			var inv: Node = main.get("inventory_v28")
			if inv != null:
				inv.add("piece", 500)
			main._show_message_v28("Mode testeur : + 500 pièces.")
			open_menu()
		"menu":
			open_menu()
		"fermer":
			main._close_dialogue_v31()
		_:
			if id.begins_with("h:"):
				var t: Node = main.get("temps_v56")
				if t != null:
					t.set_hour(float(id.substr(2)))
				main._close_dialogue_v31()
			elif id.begins_with("page:"):
				_open_list(_list_kind, _list, int(id.substr(5)))
			elif id.begins_with("go:"):
				_go(int(id.substr(3)))


func _open_list(kind: String, items: Array, page: int) -> void:
	_list_kind = kind
	_list = items
	_page = clampi(page, 0, maxi(0, (items.size() - 1) / PAGE))
	var ch: Array = []
	var n0: int = _page * PAGE
	for i in range(n0, mini(n0 + PAGE, items.size())):
		ch.append({"id": "go:%d" % i, "label": str(items[i][0])})
	if n0 + PAGE < items.size():
		ch.append({"id": "page:%d" % (_page + 1), "label": "▸ Suivants (%d/%d)" % [_page + 2, (items.size() - 1) / PAGE + 1]})
	if _page > 0:
		ch.append({"id": "page:%d" % (_page - 1), "label": "◂ Précédents"})
	ch.append({"id": "menu", "label": "(Retour)"})
	main.ask_v69(_anchor, "Mode testeur", "malin", "Page %d / %d" % [_page + 1, (items.size() - 1) / PAGE + 1], ch, _pick)


func _go(i: int) -> void:
	if i < 0 or i >= _list.size():
		return
	var v: Variant = _list[i][1]
	main._close_dialogue_v31()
	var tp: Node = main.get("teleport_v58")
	if v is String:
		# une île ou une grande place (le point d'arrivée de la téléportation des fées)
		var sp: Array = tp.spot(str(v)) if tp != null else []
		if sp.is_empty():
			main._show_message_v28("Mode testeur : ce lieu n'existe pas dans cette version.")
			return
		_land(sp[0], sp[1])
		if tp != null:
			tp.visited[str(v)] = true
	elif v is Node3D:
		var n: Node3D = v
		if not is_instance_valid(n):
			return
		var f: Vector3 = -n.global_transform.basis.z
		_land(n.global_position + f * 1.6, -f)
	elif v is Vector3:
		_land(v, Vector3.FORWARD)
	main._show_message_v28("Mode testeur : " + str(_list[i][0]))


## Se poser au mieux près de « at » : sur le sol, hors des murs.
func _land(at: Vector3, face: Vector3) -> void:
	var ae: Node = main.get("aeronef_v76")
	if ae != null and bool(ae.get("riding")) and ae.has_method("force_end"):
		ae.force_end()
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var p: Vector3 = at
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2.5, at - Vector3.UP * 6.0, 1)
	var h: Dictionary = space.intersect_ray(q)
	if not h.is_empty():
		p = h["position"]
	if main.has_method("_solid_at_v77") and main._solid_at_v77(space, p + Vector3.UP * 0.9):
		var free: Variant = main._free_near_v77(space, p)
		if free is Vector3:
			p = free
	main.place_player_v35(p + Vector3.UP * 0.15, face)


func _islands() -> Array:
	var out: Array = []
	var tp: Node = main.get("teleport_v58")
	if tp == null:
		return out
	for pl in tp.PLACES:
		out.append([str(pl[1]), str(pl[0])])
	return out


func _quest_places() -> Array:
	var out: Array = []
	var j: Node = main.get("journal_v56")
	if j == null:
		return out
	var keys: Array = (j.lieux as Dictionary).keys()
	keys.sort()
	for k in keys:
		var v: Variant = j.lieux[k]
		if v is Vector3:
			out.append([str(k).replace("_", " "), v])
	return out


func _npcs() -> Array:
	var out: Array = []
	for n in main.get("npcs_v31"):
		if is_instance_valid(n) and n is Node3D:
			var nm: String = str(n.get("display_name")) if n.get("display_name") != null else str(n.name)
			out.append([nm, n])
	out.sort_custom(func(a, b): return str(a[0]).naturalnocasecmp_to(str(b[0])) < 0)
	return out

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
		{"id": "maisons", "label": "Visiter une maison (choisir l'histoire)"},
		{"id": "moai89", "label": "Le souterrain du Grand Moaï (yeux rendus, on descend)"},
		{"id": "pixel90", "label": "Île Pixelithique : Grosse-Dent (le Cirque des Os)"},
		{"id": "pixel90g", "label": "Île Pixelithique : la Grotte aux Peintures"},
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
		"maisons":
			_open_list("maisons", _house_stories(), 0)
		"moai89":
			_souterrain_v89()
		"pixel90", "pixel90g":
			_pixel_v90(id)
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
	elif v is Array:
		_visit(str((v as Array)[0]))
		return
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


## V81 : les histoires des maisons (on entre dans la maison la plus proche avec celle-là).
func _house_stories() -> Array:
	var out: Array = [["(Au hasard : la maison la plus proche)", [""]]]
	var labels := {"famille": "La famille à table", "fou_rire": "Le fou rire", "pyjama": "Qu'est-ce que tu fiches chez moi ?!", "dormeur": "Le dormeur",
		"abandon": "La maison abandonnée", "fantome": "Le fantôme", "cave": "La cave secrète", "biblio": "La bibliothèque qui pivote",
		"chats": "La dame aux chats", "surprise": "La fête surprise", "inventeur": "L'inventeur", "cache_cache": "Cache-cache",
		"musicien": "Le musicien", "mamie": "Mamie gâteaux", "travaux": "Les travaux", "sportif": "Le sportif",
		"collection": "Le collectionneur", "envers": "La maison à l'envers", "dispute": "La dispute", "mime": "Le mime",
		"coucou": "Les coucous", "vide": "Personne à la maison"}
	var M: Node = main.get("maisons_v81")
	if M == null:
		return out
	for sc in M.Scenes.SCENARIOS:
		out.append([str(labels.get(str(sc[0]), str(sc[0]))), [str(sc[0])]])
	# V82 : les histoires des îles (on va dans la maison la plus proche de la bonne ville)
	var iles := {"chevalier": "Montjoie : le chevalier", "demon_peureux": "Pandémonia : le petit démon peureux", "repetition": "Port-Boucan : la répétition",
		"the": "Tazira : le thé à la menthe", "apesanteur": "Astralys : la pièce en apesanteur", "robot": "Cliquetis : le robot-majordome",
		"tanuki": "Ramure : la théière qui remue la queue", "potion": "Arcanelle : la potion ratée", "perroquet": "Port-Coutelas : le perroquet bavard",
		"bouteille": "Carène : le bateau en bouteille", "chat_sacre": "Per-Hâpy : le chat sacré", "chocolat": "Yaxché : le chocolat",
		"plumes": "Aztlán : l'atelier des plumes", "peintre": "Port-Azur : le peintre", "chant_elfe": "Bois-Doré : la chanteuse elfe",
		"aquarium": "Atlantide : la maison-aquarium"}
	for sc2 in M.Scenes.Iles.SCENARIOS:
		out.append([str(iles.get(str(sc2[0]), str(sc2[0]))), [str(sc2[0])]])
	out.append(["Royaume des fées : chez une fée", ["fee"]])
	# V85 : les boutiques, et les maisons naines de Forgefer
	var v85 := {"boutique": "Une boutique (la ville la plus proche)", "barbe": "Forgefer : le concours de barbe", "tunnel": "Forgefer : le tunnel",
		"berceuse": "Forgefer : la berceuse", "soupe_cailloux": "Forgefer : la soupe aux cailloux"}
	for sc3 in M.Scenes.Echoppes.SCENARIOS:
		out.append([str(v85.get(str(sc3[0]), str(sc3[0]))), [str(sc3[0])]])
	# V88 : chez les petits Moaïs (on va à la porte qui a cette histoire)
	var v88 := {"grimaces": "Moaïs : le concours de grimaces", "blagues": "Moaïs : le cabaret des cailloux", "statues": "Moaïs : 1, 2, 3, Moaï !",
		"sieste": "Moaïs : le dormeur de 800 ans", "four": "Moaïs : le four de terre", "cache": "Moaïs : cache-cache sous les rochers",
		"chorale": "Moaïs : la chorale", "mer": "Moaïs : le petit qui n'a jamais vu la mer", "doyenne": "Moaïs : la doyenne et la légende"}
	for sc4 in M.Scenes.Moais.HISTOIRES:
		out.append([str(v88.get(str(sc4), str(sc4))), [str(sc4)]])
	return out


## V90 : l'Île Pixelithique : à l'entrée du Cirque des Os (Grosse-Dent), ou dans la Grotte aux Peintures.
func _pixel_v90(id: String) -> void:
	var px: Node = main.get("pixel_v90")
	if px == null or px.get("ile") == null or px.ile == null:
		main._show_message_v28("Mode testeur : l'Île Pixelithique n'est pas là.")
		return
	main._close_dialogue_v31()
	if id == "pixel90g":
		if px.grottes != null:
			px.grottes.enter("peintures")
		return
	var a: Array = px.IleScript.CIRQUE
	var at: Vector3 = px._ground(float(a[0]), float(a[1]) + float(a[2]) + 6.0) + Vector3.UP * 0.3
	main.place_player_v35(at, Vector3(0, 0, -1))


## V89 : les deux yeux rendus, la grande porte ouverte, et l'on descend dans le souterrain.
func _souterrain_v89() -> void:
	var mo: Node = main.get("moai_v87")
	if mo == null or mo.get("souterrain") == null or mo.souterrain == null:
		main._show_message_v28("Mode testeur : l'Île aux Moaïs n'est pas là.")
		return
	main._close_dialogue_v31()
	var M: Node = main.get("maisons_v81")
	if M != null and M.inside:
		M._teardown()
	for k in ["legende", "oeil_lac", "oeil_carriere", "porte_ouverte"]:
		mo.state[k] = true
	mo._sync_grand()
	mo.souterrain.enter()


func _visit(sc: String) -> void:
	var M: Node = main.get("maisons_v81")
	if M == null or M.portes.is_empty():
		main._show_message_v28("Mode testeur : pas de maison à visiter ici.")
		return
	if M.inside:
		M._teardown()
	var p: Vector3 = main._player_pos_v27()
	var best: int = 0
	var bd: float = INF
	var styles: Array = []
	for sc2 in M.Scenes.Iles.SCENARIOS + M.Scenes.Echoppes.SCENARIOS:
		if str(sc2[0]) == sc:
			styles = (sc2[2] as Dictionary).get("style", [])
	if sc == "fee":
		styles = ["fee"]
	var fixe: bool = M.Scenes.Moais.has(sc)
	for i in range(M.portes.size()):
		var ok: bool = sc == "" or str(M.portes[i].get("owner", "")) == "" or sc == "fee"
		if not styles.is_empty() and not (str(M.portes[i]["style"]) in styles):
			ok = false
		if fixe and str(M.portes[i].get("histoire", "")) != sc:
			ok = false
		if ok:
			var dd: float = (M.portes[i]["door"] as Vector3).distance_to(p)
			if dd < bd:
				bd = dd
				best = i
	var door: Vector3 = M.portes[best]["door"]
	main.place_player_v35(door + Vector3.UP * 0.1, -(M.portes[best]["out"] as Vector3))
	M.force_scenario = sc
	M.enter(best)


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

extends Node
## V78 : le MODE TESTEUR (PC, touche F8) : pour vérifier le jeu sans tout parcourir à pied.
##  - aller sur n'importe quelle île ou grande place (même pas encore visitée) ;
##  - aller à n'importe quel lieu de quête du carnet (objets à ramasser, comptoirs, portes…) ;
##  - aller près de n'importe quel habitant ;
##  - changer l'heure (matin, midi, soir, nuit) ;
##  - invincible (ni coups, ni chutes, ni noyade) ;
##  - 500 pièces de cuivre ;
##  - V123 : le héros (niveau, caractéristiques, talents, sceaux, sorts), les armes, les outils,
##    la forge, l'Alouette, et « tout remplir » (cœurs, endurance, air, magie).
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
	# V123 : le menu est rangé en sous-menus (voyager, le héros, les armes)
	var ch: Array = [
		{"id": "voyage", "label": "Voyager : îles, lieux de quête, habitants, maisons…"},
		{"id": "heros", "label": "Le héros : niveau, caractéristiques, talents, sceaux, sorts"},
		{"id": "armes_menu", "label": "Armes, outils, forge et Alouette"},
		{"id": "remplir", "label": "Tout remplir : cœurs, endurance, air, magie"},
		{"id": "heure", "label": "Changer l'heure"},
		{"id": "invincible", "label": "Invincible : " + ("OUI (désactiver)" if invincible else "non (activer)")},
		{"id": "pieces", "label": "+ 500 pièces de cuivre"},
		{"id": "fermer", "label": "(Fermer)"},
	]
	main.ask_v69(_anchor, "Mode testeur", "malin", "Que veux-tu faire ?", ch, _pick)


func _menu_voyage() -> void:
	var ch: Array = [
		{"id": "iles", "label": "Aller sur une île ou une grande place"},
		{"id": "lieux", "label": "Aller à un lieu de quête (carnet)"},
		{"id": "pnj", "label": "Aller près d'un habitant"},
		{"id": "maisons", "label": "Visiter une maison (choisir l'histoire)"},
		{"id": "moai89", "label": "Le souterrain du Grand Moaï (yeux rendus, on descend)"},
		{"id": "pixel90", "label": "Île Pixelithique : Grosse-Dent (le Cirque des Os)"},
		{"id": "pixel90g", "label": "Île Pixelithique : la Grotte aux Peintures"},
		{"id": "chateau124", "label": "Sombreval : dans le château du comte (herse levée)"},
		{"id": "menu", "label": "(Retour)"},
	]
	main.ask_v69(_anchor, "Mode testeur", "malin", "Où veux-tu aller ?", ch, _pick)


## V123 : le héros (niveau, caractéristiques, talents, sceaux, sorts).
func _menu_heros() -> void:
	var pr: Node = main.get("progression_v63")
	var lv: int = int(pr.level) if pr != null else 1
	var ch: Array = [
		{"id": "h_niv1", "label": "Niveau + 1  (actuellement niveau %d)" % lv},
		{"id": "h_nivmax", "label": "Niveau maximum (30)"},
		{"id": "h_stats", "label": "Caractéristiques au maximum (cœur, endurance, force, agilité)"},
		{"id": "h_talents", "label": "Tous les talents (double saut, coup chargé, parade parfaite…)"},
		{"id": "h_sceaux", "label": "Les quatre sceaux et leurs pouvoirs (touches 1 à 4)"},
		{"id": "h_sorts", "label": "Tous les sorts d'Arcanelle (touches 5 à 0, V pour lancer)"},
		{"id": "h_tout", "label": "Tout d'un coup (et les armes, les outils, la forge)"},
		{"id": "menu", "label": "(Retour)"},
	]
	main.ask_v69(_anchor, "Mode testeur", "malin", "Le héros", ch, _pick)


## V123 : les armes, les outils, la forge, l'Alouette.
func _menu_armes() -> void:
	var ch: Array = [
		{"id": "a_armes", "label": "Toutes les armes (à choisir dans le sac : I)"},
		{"id": "a_outils", "label": "Tous les outils (masque, palmes, boussoles, sifflet, pelle…)"},
		{"id": "a_forge", "label": "Forge au maximum (lame runique, armure runique)"},
		{"id": "a_alouette", "label": "L'Alouette au dernier niveau"},
		{"id": "menu", "label": "(Retour)"},
	]
	main.ask_v69(_anchor, "Mode testeur", "malin", "Armes, outils et forge", ch, _pick)


func _consts(n: Object) -> Dictionary:
	if n == null or n.get_script() == null:
		return {}
	return (n.get_script() as Script).get_script_constant_map()


func _level_up(to_max: bool) -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null:
		return
	var mx: int = int(_consts(pr).get("MAX_LEVEL", 30))
	pr.set("_retro", true)
	var guard: int = 0
	while int(pr.level) < mx and guard < 40:
		guard += 1
		pr.gain(maxi(1, int(pr.need(int(pr.level))) - int(pr.xp)), "testeur")
		if not to_max:
			break
	pr.set("_retro", false)
	var j: Node = main.get("journal_v56")
	if j != null:
		j.apply_bonuses()


func _all_stats() -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null:
		return
	var c: Dictionary = _consts(pr)
	for s in c.get("STATS", []):
		pr.stats[str(s)] = int(c.get("STAT_MAX", 6))
	pr.apply()


func _all_talents() -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null:
		return
	for t in _consts(pr).get("TALENTS", []):
		pr.talents[str(t["id"])] = true
	pr.apply()


func _all_seals() -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null:
		return
	for s in _consts(pr).get("SEAL_ORDER", []):
		pr.give_seal(str(s))


func _all_spells() -> void:
	var so: Node = main.get("sorts_v67")
	if so == null:
		return
	for s in _consts(so).get("ORDRE", []):
		so.learn(str(s))
	so.mana = float(so.mana_max())


## Toutes les armes (kind "arme") ou tous les outils (kind "outil", "canne") qu'on ne possède qu'en un exemplaire.
func _give_kind(kinds: Array) -> int:
	var inv: Node = main.get("inventory_v28")
	if inv == null:
		return 0
	var n: int = 0
	var items: Dictionary = _consts(inv).get("ITEMS", {})
	for id in items:
		var it: Dictionary = items[id]
		if kinds.has(str(it.get("kind", ""))) and int(it.get("max", 1)) == 1 and int(inv.count(str(id))) == 0:
			inv.add(str(id), 1)
			n += 1
	return n


func _max_forge() -> void:
	var pr: Node = main.get("progression_v63")
	if pr == null:
		return
	var c: Dictionary = _consts(pr)
	pr.forge["arme"] = (c.get("FORGE_ARME", [0]) as Array).size() - 1
	pr.forge["armure"] = (c.get("FORGE_ARMURE", [0]) as Array).size() - 1
	pr.apply()


func _fill_all() -> void:
	var h: Node = main.get("hero_v28")
	if h != null:
		h.heal(999)
		h.stamina = float(h.STAMINA_MAX)
		h.stamina_lock = false
	var mer: Node = main.get("mer_v55")
	if mer != null:
		mer.air = float(mer.AIR_MAX)
	var so: Node = main.get("sorts_v67")
	if so != null:
		so.mana = float(so.mana_max())


func _done(text: String, back: Callable) -> void:
	main._show_message_v28("Mode testeur : " + text)
	if main.has_method("sfx"):
		main.sfx("ui_quete")
	back.call()


func _pick(id: String) -> void:
	match id:
		"voyage":
			_menu_voyage()
		"heros":
			_menu_heros()
		"armes_menu":
			_menu_armes()
		"remplir":
			_fill_all()
			_done("cœurs, endurance, air et magie au maximum.", open_menu)
		"h_niv1":
			_level_up(false)
			_done("niveau %d." % int(main.progression_v63.level), _menu_heros)
		"h_nivmax":
			_level_up(true)
			_done("niveau %d (endurance %d, %d s sous l'eau)." % [int(main.progression_v63.level), int(main.hero_v28.STAMINA_MAX), int(main.mer_v55.AIR_MAX)], _menu_heros)
		"h_stats":
			_all_stats()
			_done("caractéristiques au maximum.", _menu_heros)
		"h_talents":
			_all_talents()
			_done("tous les talents sont appris.", _menu_heros)
		"h_sceaux":
			_all_seals()
			_done("les quatre sceaux : Bourrasque (1), Flamme (2), Rouage (3), Lueur de lune (4).", _menu_heros)
		"h_sorts":
			_all_spells()
			_done("tous les sorts : Lumière (5), Boule de feu (6), Gel (7), Lévitation (8), Télékinésie (9), Soin (0) ; V pour lancer.", _menu_heros)
		"h_tout":
			_level_up(true)
			_all_stats()
			_all_seals()
			_all_talents()
			_all_spells()
			_give_kind(["arme"])
			_give_kind(["outil", "canne"])
			_max_forge()
			_fill_all()
			_done("tout est débloqué : niveau max, talents, sceaux, sorts, armes, outils, forge.", open_menu)
		"a_armes":
			var na: int = _give_kind(["arme"])
			_done("%d arme(s) ajoutée(s) au sac (I pour en choisir une)." % na, _menu_armes)
		"a_outils":
			var no: int = _give_kind(["outil", "canne"])
			_done("%d outil(s) ajouté(s) au sac." % no, _menu_armes)
		"a_forge":
			_max_forge()
			_done("lame runique et armure runique.", _menu_armes)
		"a_alouette":
			var ae: Node = main.get("aeronef_v76")
			if ae != null:
				ae.set_level(4, false)
			_done("l'Alouette est au dernier niveau.", _menu_armes)
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
		"chateau124":
			_chateau_v124()
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


## V124 : tout droit dans le Grand Vestibule du château du comte (la herse levée)
func _chateau_v124() -> void:
	main._close_dialogue_v31()
	var sv: Node = main.get("sombreval_v121")
	if sv == null or sv.get("castle") == null or sv.castle == null:
		main._show_message_v28("Mode testeur : le château du comte n'est pas là.")
		return
	sv.open_gate(false)
	sv.castle.enter()


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

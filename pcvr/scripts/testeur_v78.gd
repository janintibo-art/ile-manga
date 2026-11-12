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
var position_on: bool = false             # V126 : la position à l'écran (lieu, coordonnées)
var _pos_label: Label
var _pos_clock: float = 0.0
const REGLAGES := "user://testeur_v126.cfg"
var _anchor: Node3D
var _list: Array = []                    # [[libellé, valeur], …] de la page en cours
var _list_kind: String = ""
var _page: int = 0
var _donjons: Array = []                 # V134 : les donjons à énigmes (construits à l'entrée)


func setup(main_node: Node) -> void:
	main = main_node
	_anchor = Node3D.new()
	_anchor.name = "Testeur_v78"
	add_child(_anchor)
	# V126 : la position à l'écran reste affichée d'une partie à l'autre si on l'a demandée
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGES) == OK and bool(cfg.get_value("testeur", "position", false)):
		set_position_on(true)


# =================================================================== V126 : où suis-je ?
## En bas à gauche : le lieu, la salle, les coordonnées, la direction du regard, l'heure du jeu
## et la version. Sur une capture d'écran, on sait tout de suite où le bug se trouve.

func set_position_on(on: bool) -> void:
	position_on = on
	var cfg := ConfigFile.new()
	cfg.load(REGLAGES)
	cfg.set_value("testeur", "position", on)
	cfg.save(REGLAGES)
	if on and _pos_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 60
		layer.name = "Position_v126"
		add_child(layer)
		_pos_label = Label.new()
		_pos_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_pos_label.offset_left = 14
		_pos_label.offset_top = -64
		_pos_label.offset_bottom = -10
		_pos_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_pos_label.add_theme_font_size_override("font_size", 15)
		_pos_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
		_pos_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_pos_label.add_theme_constant_override("outline_size", 5)
		_pos_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_pos_label)
	if _pos_label != null:
		_pos_label.visible = on
		_pos_clock = 0.0


func _process(delta: float) -> void:
	if not position_on or _pos_label == null or main == null:
		return
	_pos_clock -= delta
	if _pos_clock > 0.0:
		return
	_pos_clock = 0.25
	_pos_label.text = position_text()


func position_text() -> String:
	var p: Vector3 = main._player_pos_v27()
	var amb: Node = main.get("ambiance_v49")
	var zone: String = str(amb.get("zone")) if amb != null and amb.get("zone") != null else ""
	if zone == "":
		zone = "?"
	var yaw: float = 0.0
	var root: Node3D = main.get("pc_root")
	if root != null:
		var f: Vector3 = -root.global_basis.z
		yaw = fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0)
	var dirs := ["nord", "nord-est", "est", "sud-est", "sud", "sud-ouest", "ouest", "nord-ouest"]
	var dir: String = dirs[int(round(yaw / 45.0)) % 8]
	var hour: String = ""
	var t: Node = main.get("temps_v56")
	if t != null and t.get("hour") != null:
		var h: float = float(t.get("hour"))
		hour = "  •  %02d h %02d" % [int(h), int(fmod(h, 1.0) * 60.0)]
	var parts: PackedStringArray = str(ProjectSettings.get_setting("application/config/name", "")).split(" V")
	var ver: String = parts[parts.size() - 1]
	return "Lieu : %s\nx %.1f   y %.1f   z %.1f   •  regard %s%s  •  V%s" % [zone, p.x, p.y, p.z, dir, hour, ver]


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
		{"id": "position", "label": "Position à l'écran : " + ("OUI (cacher)" if position_on else "non (afficher)")},
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
		{"id": "comte128", "label": "Sombreval : devant la porte du comte (trois rubis posés)"},
		{"id": "cachots128", "label": "Sombreval : les souterrains du château (comte vaincu)"},
		{"id": "faune132v", "label": "Faune sauvage : la plage de l'île du village (crabes, mouettes)"},
		{"id": "faune132e", "label": "Faune sauvage : le Bois-Doré (sangliers, ronceux, loups)"},
		{"id": "faune132n", "label": "Faune sauvage : la Montagne de Feu (salamandres, boucs, chauves-souris)"},
		{"id": "faune133o", "label": "Faune sauvage : les prairies de la grande île (aurochs, loups des plaines)"},
		{"id": "faune133n", "label": "Faune sauvage : les hautes terres de la grande île (ours, boucs)"},
		{"id": "faune133e", "label": "Faune sauvage : la forêt des brumes de la grande île (crapauds, feux follets)"},
		{"id": "faune133s", "label": "Faune sauvage : le désert de la grande île (scorpions, serpents des sables)"},
		{"id": "faune133p", "label": "Faune sauvage : l'Île Al Dente (boulettes, spaghettis, tomates)"},
		{"id": "faune133c", "label": "Faune sauvage : l'Île Crayonnée (gribouillis, taches d'encre, gomme géante)"},
		{"id": "faune135j", "label": "Faune sauvage : l'île de la jungle (singes, mille-pattes, araignées, lucioles)"},
		{"id": "faune135e", "label": "Faune sauvage : le fleuve et le désert égyptiens (crocodiles, scarabées, chacals)"},
		{"id": "faune135m", "label": "Faune sauvage : les collines mayas (coatis, singes, jaguar)"},
		{"id": "faune135a", "label": "Faune sauvage : le lac et le volcan aztèques (aigle, salamandres, axolotls, coyotes)"},
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
		"comte128", "cachots128":
			_comte_v128(id == "cachots128")
		"faune132v", "faune132e", "faune132n":
			_faune_v132({"faune132v": "village", "faune132e": "elfes", "faune132n": "nains"}[id])
		"faune133o", "faune133n", "faune133e", "faune133s":
			_faune_v132("grande", {"faune133o": "ouest", "faune133n": "nord", "faune133e": "est", "faune133s": "sud"}[id])
		"faune133p", "faune133c":
			_faune_v132({"faune133p": "aldente", "faune133c": "crayon"}[id])
		"faune135j":
			_faune_v132("jungle")
		"faune135e", "faune135m", "faune135a":
			_faune_v132("soleils", {"faune135e": "egypte", "faune135m": "maya", "faune135a": "azteque"}[id])
		"heure":
			var ch: Array = [{"id": "h:7.5", "label": "Le matin (7 h 30)"}, {"id": "h:12.0", "label": "Midi"},
				{"id": "h:18.5", "label": "Le soir (18 h 30)"}, {"id": "h:22.5", "label": "La nuit (22 h 30)"}, {"id": "menu", "label": "(Retour)"}]
			main.ask_v69(_anchor, "Mode testeur", "malin", "Quelle heure ?", ch, _pick)
		"invincible":
			invincible = not invincible
			main._show_message_v28("Mode testeur : invincible " + ("activé" if invincible else "désactivé") + ".")
			open_menu()
		"position":
			set_position_on(not position_on)
			main._show_message_v28("Mode testeur : position à l'écran %s." % ("affichée" if position_on else "cachée"))
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


## V128 : tout en haut de la Tour du Comte, devant la porte de fer (les trois rubis posés) ; ou bien
## dans la salle d'armes, devant la grille des souterrains (le comte vaincu, la clé en poche)
## V132 : un coin sauvage de l'île, et quelques bêtes autour (pour les voir tout de suite).
func _faune_v132(ile: String, region: String = "") -> void:
	main._close_dialogue_v31()
	var f: Node = main.get("faune_v132")
	if f == null:
		return
	f.enabled = true
	f._resolve_iles()
	if not f.iles.has(ile):
		main._show_message_v28("Mode testeur : cette île n'est pas là.")
		return
	var c: Vector3 = f.iles[ile]["c"]
	var r: float = float(f.iles[ile]["r"])
	f._refresh_npcs(c)
	# un endroit loin des habitants, sur la terre ferme (sur la plage pour l'île du village)
	var best := Vector3.INF
	for i in range(240 if region != "" else 80):
		var a: float = randf() * TAU
		var d: float = randf_range(0.25, 0.85) * r
		var q := Vector3(c.x + cos(a) * d, 0, c.z + sin(a) * d)
		var h: float = main._height_at(q.x, q.z)
		if ile == "village" and (h < 0.3 or h > 1.8):
			continue
		if ile != "village" and h < 1.5:
			continue
		# V133 : la bonne région de la grande île, sur un terrain pas trop pentu
		if region != "" and f.region_de(ile, q) != region:
			continue
		if ile != "village" and absf(main._height_at(q.x + 3.0, q.z) - h) + absf(main._height_at(q.x, q.z + 3.0) - h) > 2.4:
			continue
		# V135 : côté égyptien, au bord du fleuve (les crocodiles) ; côté aztèque, près du lac (les axolotls)
		if region == "egypte" and _milieu_pres(f, q, "fleuve", 22.0) == Vector3.INF:
			continue
		if region == "azteque" and _milieu_pres(f, q, "lac", 30.0) == Vector3.INF:
			continue
		var ok: bool = true
		for np in f._npc_pos:
			if Vector2((np as Vector3).x - q.x, (np as Vector3).z - q.z).length() < 35.0:
				ok = false
				break
		if ok:
			best = Vector3(q.x, h + 0.2, q.z)
			break
	if best == Vector3.INF:
		main._show_message_v28("Mode testeur : pas de coin sauvage trouvé, réessaie.")
		return
	main.place_player_v35(best, Vector3(0, 0, -1))
	var kinds: Array = {"village": ["crabe_plage", "crabe_plage", "mouette"], "elfes": ["sanglier", "ronceux_sauvage", "loup_bois", "loup_bois"],
		"nains": ["salamandre", "bouc", "chauve_souris_mont", "chauve_souris_mont"],
		"grande:ouest": ["aurochs", "aurochs", "loup_plaine", "loup_plaine"], "grande:nord": ["ours_lande", "bouc", "loup_plaine"],
		"grande:est": ["crapaud_vase", "crapaud_vase", "feu_follet", "feu_follet"], "grande:sud": ["scorpion_dunes", "serpent_sable", "serpent_sable"],
		"aldente": ["boulette", "spaghetti_sauvage", "tomate_kamikaze", "tomate_kamikaze"],
		"crayon": ["gribouillis", "gribouillis", "gribouillis", "tache_encre", "gomme_geante"],
		"jungle": ["singe_hurleur", "singe_hurleur", "mille_pattes", "araignee_geante", "luciole"],
		"soleils:egypte": ["crocodile", "scarabee_geant", "chacal", "chacal"], "soleils:maya": ["coati", "singe_hurleur", "jaguar_sauvage", "luciole"],
		"soleils:azteque": ["aigle_royal", "salamandre", "axolotl", "coyote", "coyote"]}.get(ile + (":" + region if region != "" else ""), [])
	for i in range(kinds.size()):
		var a2: float = TAU * i / kinds.size()
		var q2: Vector3 = best + Vector3(cos(a2) * 14.0, 0, sin(a2) * 14.0)
		q2.y = main._height_at(q2.x, q2.z) + (12.0 if kinds[i] == "mouette" else (2.8 if kinds[i] in ["chauve_souris_mont", "feu_follet"] else 0.1))
		# V135 : le crocodile dans le fleuve, l'axolotl au bord du lac, les lucioles et l'aigle en l'air
		match str(kinds[i]):
			"crocodile", "axolotl":
				var w: Vector3 = _milieu_pres(f, best, "fleuve" if kinds[i] == "crocodile" else "lac", 40.0)
				if w == Vector3.INF:
					continue
				q2 = Vector3(w.x, main._height_at(w.x, w.z) + 0.1, w.z)
			"luciole":
				q2.y += 1.3
			"aigle_royal":
				q2.y += 10.0
		f.spawn(str(kinds[i]), q2)
	main._show_message_v28("Mode testeur : des bêtes sauvages rôdent autour de toi.")


## V135 : le point le plus proche de « centre » (en cercles de plus en plus grands) qui convient au
## milieu demandé (« fleuve », « lac »…), ou Vector3.INF.
func _milieu_pres(f: Node, centre: Vector3, milieu: String, rmax: float) -> Vector3:
	var r: float = 4.0
	while r <= rmax:
		for k in range(16):
			var a: float = TAU * float(k) / 16.0
			var q := Vector3(centre.x + cos(a) * r, 0, centre.z + sin(a) * r)
			if f.milieu_ok(q, main._height_at(q.x, q.z), milieu):
				return q
		r += 3.0
	return Vector3.INF


func _comte_v128(cachots: bool) -> void:
	main._close_dialogue_v31()
	var sv: Node = main.get("sombreval_v121")
	if sv == null or sv.get("castle") == null or sv.castle == null:
		main._show_message_v28("Mode testeur : le château du comte n'est pas là.")
		return
	var C: Node = sv.castle
	C.ensure_built()
	for k in ["mortimer", "ilona", "sigismund", "radu", "tour"]:
		C.state[k] = true
	C.state["poses"] = 3
	if cachots:
		C.state["chambre"] = true
		C.state["comte"] = true
		C.state["cle"] = true
		if main.inventory_v28 != null and int(main.inventory_v28.count("cle_souterrains")) <= 0:
			main.inventory_v28.add("cle_souterrains", 1)
		if sv.has_method("liberer"):
			sv.liberer(false)
	C._apply_state()
	sv.open_gate(false)
	await C.enter()
	if cachots:
		main.place_player_v35(C.W(Vector3(8.0, -7.9, -54.0)), Vector3(0, 0, -1))
	else:
		main.place_player_v35(C.W(Vector3(-1.2, 11.55, -20.5)), Vector3(-1, 0, 0))


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
		# V134 : l'intérieur d'un donjon à énigmes (pyramide, Xibalba, Cinq Soleils, Neuf Cercles,
		# Mille Marches, Usine Grise) n'existe qu'une fois qu'on y est entré : on y entre par la porte
		# au lieu de tomber dans le vide.
		var dj: Node = _donjon_vers(v)
		if dj != null:
			dj.enter()
		else:
			_land(v, Vector3.FORWARD)
	elif v is Array:
		_visit(str((v as Array)[0]))
		return
	main._show_message_v28("Mode testeur : " + str(_list[i][0]))


## V134 : le donjon à énigmes pas encore construit dont l'arrivée est à « at » (sinon null).
func _donjon_vers(at: Vector3) -> Node:
	if _donjons.is_empty():
		var pile: Array = [main]
		while not pile.is_empty():
			var n: Node = pile.pop_back()
			if n.has_method("ensure_built") and n.has_method("entry") and n.has_method("enter") and n.get("built") != null:
				_donjons.append(n)
			pile.append_array(n.get_children())
	for d in _donjons:
		if is_instance_valid(d) and d.built != true:
			var e: Array = d.entry()
			if not e.is_empty() and (e[0] as Vector3).distance_to(at) < 6.0:
				return d
	return null


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

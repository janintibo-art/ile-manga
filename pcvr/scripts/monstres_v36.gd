extends Node3D
## V36 : les monstres du Temple englouti (galerie sous la mer).
## Ils apparaissent quand on descend dans le temple et reviennent à chaque nouvelle descente.
## Les deux gardiens de corail de la salle aux colonnes tiennent la grille : quand ils
## tombent, elle se lève (et reste levée, c'est sauvegardé).
## Au PC, les coups font perdre des cœurs (F pour parer, Ctrl pour rouler). En VR aussi :
## des cœurs s'affichent au poignet gauche sous terre, et l'écran rougit quand on est touché.

const MonsterScript = preload("res://scripts/monstre_v36.gd")
const Monster63 = preload("res://scripts/monstre_v63.gd")
const Monster68 = preload("res://scripts/monstre_v68.gd")

## [espèce, x, y, z] dans le repère de la section « village » du temple.
const SPAWNS := [
	["crabe", 12.5, -3.0, -104.0], ["crabe", 19.0, -3.0, -110.0], ["crabe", 14.0, -3.0, -117.0],
	["crabe", 15.0, -3.0, -140.0], ["crabe", 16.0, -3.0, -156.0],
	["gardien", 11.5, -3.0, -183.0], ["gardien", 19.5, -3.0, -183.0], ["crabe", 15.5, -3.0, -176.0],
	["crabe", 15.0, 0.0, -224.0], ["crabe", 16.0, 0.0, -236.0],
	# V39 : le fond du puits et les deux rives du Lac Noir
	["vipere", -5.0, -43.0, -108.5], ["vipere", -8.0, -43.0, -115.0], ["vipere", 6.0, -43.0, -115.6],
	["vipere", -7.0, -43.0, -140.0], ["vipere", 5.0, -43.0, -143.5], ["vipere", 1.5, -43.0, -147.5],
]

## V44 : le Royaume des Racines, sous l'Arbre-Mère (repère du donjon féerique).
const FEE_SPAWNS := [
	["araignee", -21.0, 0.0, -42.5], ["araignee", -31.0, 0.0, -44.0], ["araignee", -20.0, 0.0, -61.0], ["araignee", -32.0, 0.0, -63.0],
	["follet", 11.5, 0.0, -51.5], ["follet", 21.0, 0.0, -47.0], ["follet", 28.5, 0.0, -48.0],
]

var main: Node
var donjon: Node
var active: bool = false
var monsters: Array = []
var kills: int = 0
var _was_inside: bool = false
var _alerted: Dictionary = {}
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect
var _flash_sphere: MeshInstance3D
var _hearts: Label3D
var _rng := RandomNumberGenerator.new()


func setup(main_node: Node, donjon_node: Node) -> void:
	main = main_node
	donjon = donjon_node
	_rng.randomize()
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 25
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(0.8, 0.05, 0.02, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash_rect)


func spawn_all() -> void:
	for m in monsters:
		if is_instance_valid(m):
			m.queue_free()
	monsters.clear()
	if not donjon.sections.has("village"):
		return
	var s: Node3D = donjon.sections["village"]
	for e in SPAWNS:
		var m: CharacterBody3D = MonsterScript.new()
		add_child(m)
		m.setup(self, str(e[0]), s.to_global(Vector3(float(e[1]), float(e[2]) + 0.05, float(e[3]))))
		m.set_meta("salle", "gardiens" if str(e[0]) == "gardien" else "")
		m.died.connect(_on_died)
		monsters.append(m)
	var f: Node = main.elfes_v41.feerique if main.get("elfes_v41") != null and main.elfes_v41.feerique != null else null
	if f != null and f.s != null:
		for e in FEE_SPAWNS:
			var m2: CharacterBody3D = MonsterScript.new()
			add_child(m2)
			m2.setup(self, str(e[0]), f.s.to_global(Vector3(float(e[1]), float(e[2]) + 0.05, float(e[3]))))
			m2.died.connect(_on_died)
			monsters.append(m2)


## V48 : chargement d'une partie : les monstres de la session précédente disparaissent ;
## ils reviendront comme à une nouvelle descente.
func reset_session() -> void:
	for m in monstres_list_copy():
		if is_instance_valid(m):
			m.queue_free()
	monsters.clear()
	_was_inside = false
	active = false


func monstres_list_copy() -> Array:
	return monsters.duplicate()


## V37 : un monstre de plus (les crabes appelés par le Crabe-Roi).
func spawn_extra(kind: String, at: Vector3) -> Node3D:
	# V63 : les créatures de la grande enquête et du Cœur-de-Pierre (monstre_v63.gd)
	# V68 : les monstres de l'Île de la Balafre (crocodiles, squelettes, le Capitaine Sans-Chair)
	var m: CharacterBody3D = Monster68.new() if Monster68.SPECS68.has(kind) else (Monster63.new() if Monster63.SPECS63.has(kind) else MonsterScript.new())
	add_child(m)
	m.setup(self, kind, at)
	m.died.connect(_on_died)
	monsters.append(m)
	m.state = "chasse"
	return m


func alive_count(kind: String = "") -> int:
	var n: int = 0
	for m in monsters:
		if is_instance_valid(m) and m.state != "mort" and (kind == "" or m.kind == kind):
			n += 1
	return n


## V38 : seuls les gardiens de la salle aux colonnes tiennent la grille.
func _gardiens_alive() -> int:
	var n: int = 0
	for m in monsters:
		if is_instance_valid(m) and m.state != "mort" and m.kind == "gardien" and str(m.get_meta("salle", "")) == "gardiens":
			n += 1
	return n


## Première rencontre avec une espèce : un conseil de combat.
func alert(m: Node3D) -> void:
	if _alerted.has(m.kind):
		return
	_alerted[m.kind] = true
	# V63 : les créatures du Cœur-de-Pierre ont leur propre conseil
	if m.has_method("alert_text"):
		var t: String = str(m.alert_text())
		if t != "":
			donjon._say(t, 7.0)
		return
	if m.kind == "crabe":
		donjon._say("Un crabe de roche ! Quand il lève les pinces, recule ou pare (F)… puis frappe-le.", 5.0)
	elif m.kind == "follet":
		donjon._say("Un feu follet ! Quand il se met à briller très fort, il va foncer droit sur toi : écarte-toi, puis frappe-le.", 6.0)
	elif m.kind == "araignee":
		donjon._say("Une araignée de cristal ! Elle se dresse avant de mordre : recule ou pare (F). Ses éclats intéressent sûrement quelqu'un…", 6.0)
	elif m.kind == "golem":
		donjon._say("Un golem des hauteurs ! Quand il lève ses deux poings au-dessus de la tête, il va écraser le sol devant lui : recule ou roule (Ctrl)… puis frappe-le. Tes coups ne l'arrêtent pas.", 7.0)
	elif m.kind == "magma":
		donjon._say("Un élémentaire de magma ! Quand il gonfle et rougeoie, il va bondir sur toi : écarte-toi, puis frappe-le pendant qu'il refroidit.", 6.0)
	elif m.kind == "armure":
		donjon._say("Une armure animée ! Elle est vide… et elle se bat. Quand elle lève l'épée, pare (F) ou roule (Ctrl), puis frappe-la.", 6.0)
	elif m.kind == "gargouille":
		donjon._say("Une gargouille ! Quand elle bat des ailes très vite et se cabre, elle va piquer droit sur toi : écarte-toi, puis frappe-la.", 6.0)
	elif m.kind == "plante":
		donjon._say("Une plante carnivore ! Elle ne bouge pas, mais quand elle recule la tête, elle va mordre loin devant elle : reste hors de portée, puis frappe-la juste après sa morsure.", 7.0)
	elif m.kind == "ronceux":
		donjon._say("Un ronceux ! Ce paquet de ronces marche vers toi et lève ses bras épineux avant de frapper : pare (F) ou recule, puis taille-le en pièces.", 6.0)
	elif m.kind == "plante_mere":
		donjon._say("La Mère-Ronce, la reine des plantes d'Yggdrasil ! Sa morsure porte très loin. Attends qu'elle frappe dans le vide, puis cours la frapper avant qu'elle ne se redresse.", 8.0)
	elif m.kind == "vipere":
		donjon._say("Une vipère des abysses ! Quand elle se love et dresse la tête, elle va bondir droit devant : écarte-toi, ou pare (F).", 6.0)
	else:
		donjon._say("Un gardien de corail se réveille ! Il lève sa lance avant de frapper : roule (Ctrl) ou pare (F). Trois coups d'épée enchaînés font mal.", 6.0)


func hurt_player(amount: int, from_pos: Vector3) -> void:
	var hero: Node = main.hero_v28
	if hero == null:
		return
	var before: int = int(hero.hp)
	hero.hurt(amount, from_pos)
	if int(hero.hp) < before:
		_red_flash()
		if main.xr_active and int(hero.hp) <= 0:
			_vr_faint()


func _red_flash() -> void:
	if main.xr_active:
		if _flash_sphere == null:
			_flash_sphere = MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.22
			sm.height = 0.44
			sm.flip_faces = true
			_flash_sphere.mesh = sm
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.no_depth_test = true
			m.render_priority = 99
			m.albedo_color = Color(0.8, 0.05, 0.02, 0.0)
			_flash_sphere.material_override = m
			main.xr_camera.add_child(_flash_sphere)
		var mat: StandardMaterial3D = _flash_sphere.material_override
		mat.albedo_color.a = 0.4
		create_tween().tween_property(mat, "albedo_color:a", 0.0, 0.45)
	else:
		_flash_rect.color.a = 0.32
		create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.45)


## VR : à bout de forces, on se réveille à l'entrée du temple.
func _vr_faint() -> void:
	var pp: Vector3 = main._player_pos_v27()
	if not (main.get("pirates_v68") != null and main.pirates_v68 != null and main.pirates_v68.contains(pp)):
		donjon._say("Tu t'évanouis… et te réveilles au pied de l'échelle.", 4.0)
	await donjon._fade_to(1.0, 0.6)
	respawn_player()
	await get_tree().create_timer(0.4).timeout
	await donjon._fade_to(0.0, 0.8)


## Réapparition après un évanouissement sous terre : au pied de l'échelle du côté le plus
## proche, cœurs pleins.
func respawn_player() -> void:
	var p: Vector3 = main._player_pos_v27()
	# V68 : sur l'Île de la Balafre (une bagarre perdue, ou les monstres de l'intérieur)
	if main.get("pirates_v68") != null and main.pirates_v68 != null and main.pirates_v68.contains(p):
		main.pirates_v68.on_faint()
		_heal_player()
		return
	# V63 : sous le Cœur-de-Pierre, ou dans un sanctuaire des sceaux
	if main.get("coeur_v63") != null and main.coeur_v63 != null and main.coeur_v63.region_contains(p):
		main.coeur_v63.respawn()
		return
	if main.get("sceaux_v63") != null and main.sceaux_v63 != null and main.sceaux_v63.respawn_here(p):
		return
	# V58 : évanoui dans le royaume des fées (ou dans Yggdrasil)
	if main.get("feerie_v58") != null and main.feerie_v58 != null and main.feerie_v58.contains(p):
		var rf: Array = main.feerie_v58.respawn_point(p)
		main.place_player_v35(rf[0], rf[1])
		_heal_player()
		return
	# V54 : évanoui sur l'île flottante : on se réveille sur l'Aire des Vents.
	if main.get("ciel_v54") != null and main.ciel_v54 != null and main.ciel_v54.on_sky(p):
		var rs: Array = main.ciel_v54.respawn_point()
		main.place_player_v35(rs[0], rs[1])
		_heal_player()
		return
	# V55 : évanoui près de l'Atlantide : on se réveille sous le dôme.
	if main.get("mer_v55") != null and main.mer_v55 != null:
		var ra: Array = main.mer_v55.respawn_for(p)
		if not ra.is_empty():
			main.place_player_v35(ra[0], ra[1])
			_heal_player()
			return
	# V47 : évanoui sur la Montagne de Feu : on se réveille sur la terrasse de Forgefer.
	if main.get("nains_v46") != null and main.nains_v46 != null and not donjon.is_inside(p) and main.nains_v46.ile.contains(p.x, p.z):
		var rp: Array = main.nains_v46.respawn_point()
		main.place_player_v35(rp[0], rp[1])
		_heal_player()
		return
	var best: String = "village"
	var best_d: float = INF
	for id in donjon.spawn:
		var d: float = (donjon.spawn[id][0] as Vector3).distance_to(p)
		if d < best_d:
			best_d = d
			best = id
	main.place_player_v35(donjon.spawn[best][0], donjon.spawn[best][1])
	_heal_player()


func _heal_player() -> void:
	var hero: Node = main.hero_v28
	if hero != null:
		hero.hp = hero.HP_MAX
		hero.stamina = hero.STAMINA_MAX
		hero.state = "sol"
		hero.hurt_cooldown = 0.0
		hero.health_changed.emit(hero.hp, hero.HP_MAX)


func _on_died(m: Node3D) -> void:
	kills += 1
	donjon.state["victoires"] = int(donjon.state.get("victoires", 0)) + 1
	# V63 : de l'expérience pour chaque monstre vaincu
	if main.get("progression_v63") != null and main.progression_v63 != null:
		main.progression_v63.on_kill(str(m.kind), m.global_position + Vector3.UP * 1.2)
	var gains: Array = []
	if m.has_method("loot"):
		gains = m.loot(_rng)
	elif m.kind == "crabe":
		if _rng.randf() < 0.45:
			gains.append(["piece", _rng.randi_range(1, 3)])
		if _rng.randf() < 0.1:
			gains.append(["perle", 1])
	elif m.kind == "follet":
		gains.append(["piece", _rng.randi_range(1, 4)])
	elif m.kind == "araignee":
		if _rng.randf() < 0.75:
			gains.append(["eclat_cristal", 1])
		if _rng.randf() < 0.5:
			gains.append(["piece", _rng.randi_range(1, 3)])
	elif m.kind == "golem":
		gains.append(["rune_golem", 1])
		gains.append(["piece", _rng.randi_range(3, 7)])
		if _rng.randf() < 0.4:
			gains.append(["minerai_fer", 1])
	elif m.kind == "magma":
		if _rng.randf() < 0.75:
			gains.append(["coeur_magma", 1])
		gains.append(["piece", _rng.randi_range(2, 5)])
		if _rng.randf() < 0.3:
			gains.append(["obsidienne", 1])
	elif m.kind == "armure":
		gains.append(["piece", _rng.randi_range(4, 9)])
		if _rng.randf() < 0.3:
			gains.append(["piece_or", 1])
	elif m.kind == "gargouille":
		gains.append(["piece", _rng.randi_range(2, 5)])
		if _rng.randf() < 0.2:
			gains.append(["rubis", 1])
	elif m.kind == "plante" or m.kind == "ronceux":
		gains.append(["piece", _rng.randi_range(1, 4)])
		if _rng.randf() < 0.2:
			gains.append(["baies", 1])
	elif m.kind == "plante_mere":
		gains.append(["piece", _rng.randi_range(12, 20)])
		gains.append(["piece_or", 1])
	elif m.kind == "vipere":
		gains.append(["piece", _rng.randi_range(2, 5)])
		if _rng.randf() < 0.15:
			gains.append(["perle", 1])
	else:
		gains.append(["piece", _rng.randi_range(4, 8)])
		if _rng.randf() < 0.3:
			gains.append(["rubis", 1])
		elif _rng.randf() < 0.3:
			gains.append(["piece_or", 1])
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			parts.append("+%d %s" % [got, str(main.inventory_v28.ITEMS[str(g[0])]["name"])])
	if not parts.is_empty() and main.combat_v28 != null:
		main.combat_v28.float_text(m.global_position + Vector3.UP * 1.6, "  ".join(parts), Color(1.0, 0.9, 0.5))
	if m.kind == "gardien" and str(m.get_meta("salle", "")) == "gardiens" and _gardiens_alive() == 0 and not bool(donjon.state.get("grille", false)):
		donjon.open_grille()


func _process(delta: float) -> void:
	if main == null or donjon == null:
		return
	var inside: bool = bool(donjon.inside)
	# Nouvelle descente : les monstres sont de retour.
	if inside and not _was_inside:
		spawn_all()
	_was_inside = inside
	# V47 : dehors aussi, sur les hauteurs de la Montagne de Feu (golems, élémentaires).
	var outdoor: bool = not inside and main.get("nains_v46") != null and main.nains_v46 != null and main.nains_v46.hostile_zone(main._player_pos_v27())
	# V54 : dans la Citadelle des Nuées
	if not inside and main.get("ciel_v54") != null and main.ciel_v54 != null and main.ciel_v54.hostile_zone(main._player_pos_v27()):
		outdoor = true
	# V58 : dans Yggdrasil
	if not inside and main.get("feerie_v58") != null and main.feerie_v58 != null and main.feerie_v58.hostile_zone(main._player_pos_v27()):
		outdoor = true
	# V63 : les combats de la grande enquête (au bord de la grande mare de Ramure…)
	if not inside and main.get("sceaux_v63") != null and main.sceaux_v63 != null and main.sceaux_v63.hostile_zone(main._player_pos_v27()):
		outdoor = true
	# V68 : l'intérieur de l'Île de la Balafre (les repaires des monstres), et les bagarres
	if not inside and main.get("pirates_v68") != null and main.pirates_v68 != null and main.pirates_v68.hostile_zone(main._player_pos_v27()):
		outdoor = true
	active = (inside or outdoor) and main.game_started and (main.game_menu == null or not main.game_menu.opened) \
		and (main.dialogue_v31 == null or not main.dialogue_v31.opened) and not bool(donjon.get("_busy"))
	if main.xr_active and main.hero_v28 != null:
		main.hero_v28.hurt_cooldown = maxf(float(main.hero_v28.hurt_cooldown) - delta, 0.0)
		_vr_hearts(inside or outdoor)


func _vr_hearts(inside: bool) -> void:
	if _hearts == null:
		_hearts = Label3D.new()
		_hearts.font_size = 48
		_hearts.pixel_size = 0.0012
		_hearts.outline_size = 8
		_hearts.modulate = Color(1.0, 0.3, 0.3)
		_hearts.no_depth_test = true
		_hearts.position = Vector3(0, 0.07, 0.05)
		_hearts.rotation_degrees = Vector3(-60, 0, 0)
		main.left_hand.add_child(_hearts)
	_hearts.visible = inside
	if inside:
		var hp: int = int(main.hero_v28.hp)
		var text: String = ""
		# V63 : autant de cœurs que le héros en a gagné
		for k in range(int(main.hero_v28.HP_MAX) / 2):
			text += "♥" if hp >= (k + 1) * 2 else ("♡" if hp <= k * 2 else "❥")
		_hearts.text = text


## Sauvegarde : seulement le compte des victoires (les monstres reviennent à chaque descente).
func serialize() -> Dictionary:
	return {"victoires": kills}


func load_data(d: Dictionary) -> void:
	kills = int(d.get("victoires", 0))

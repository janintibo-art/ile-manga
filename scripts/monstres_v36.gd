extends Node3D
## V36 : les monstres du Temple englouti (galerie sous la mer).
## Ils apparaissent quand on descend dans le temple et reviennent à chaque nouvelle descente.
## Les deux gardiens de corail de la salle aux colonnes tiennent la grille : quand ils
## tombent, elle se lève (et reste levée, c'est sauvegardé).
## Au PC, les coups font perdre des cœurs (F pour parer, Ctrl pour rouler). En VR aussi :
## des cœurs s'affichent au poignet gauche sous terre, et l'écran rougit quand on est touché.

const MonsterScript = preload("res://scripts/monstre_v36.gd")

## [espèce, x, y, z] dans le repère de la section « village » du temple.
const SPAWNS := [
	["crabe", 12.5, -3.0, -104.0], ["crabe", 19.0, -3.0, -110.0], ["crabe", 14.0, -3.0, -117.0],
	["crabe", 15.0, -3.0, -140.0], ["crabe", 16.0, -3.0, -156.0],
	["gardien", 11.5, -3.0, -183.0], ["gardien", 19.5, -3.0, -183.0], ["crabe", 15.5, -3.0, -176.0],
	["crabe", 15.0, 0.0, -224.0], ["crabe", 16.0, 0.0, -236.0],
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


## V37 : un monstre de plus (les crabes appelés par le Crabe-Roi).
func spawn_extra(kind: String, at: Vector3) -> Node3D:
	var m: CharacterBody3D = MonsterScript.new()
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


## Première rencontre avec une espèce : un conseil de combat.
func alert(m: Node3D) -> void:
	if _alerted.has(m.kind):
		return
	_alerted[m.kind] = true
	if m.kind == "crabe":
		donjon._say("Un crabe de roche ! Quand il lève les pinces, recule ou pare (F)… puis frappe-le.", 5.0)
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
	donjon._say("Tu t'évanouis… et te réveilles au pied de l'échelle.", 4.0)
	await donjon._fade_to(1.0, 0.6)
	respawn_player()
	await get_tree().create_timer(0.4).timeout
	await donjon._fade_to(0.0, 0.8)


## Réapparition après un évanouissement sous terre : au pied de l'échelle du côté le plus
## proche, cœurs pleins.
func respawn_player() -> void:
	var p: Vector3 = main._player_pos_v27()
	var best: String = "village"
	var best_d: float = INF
	for id in donjon.spawn:
		var d: float = (donjon.spawn[id][0] as Vector3).distance_to(p)
		if d < best_d:
			best_d = d
			best = id
	main.place_player_v35(donjon.spawn[best][0], donjon.spawn[best][1])
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
	var gains: Array = []
	if m.kind == "crabe":
		if _rng.randf() < 0.45:
			gains.append(["piece", _rng.randi_range(1, 3)])
		if _rng.randf() < 0.1:
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
	if m.kind == "gardien" and alive_count("gardien") == 0 and not bool(donjon.state.get("grille", false)):
		donjon.open_grille()


func _process(delta: float) -> void:
	if main == null or donjon == null:
		return
	var inside: bool = bool(donjon.inside)
	# Nouvelle descente : les monstres sont de retour.
	if inside and not _was_inside:
		spawn_all()
	_was_inside = inside
	active = inside and main.game_started and (main.game_menu == null or not main.game_menu.opened) \
		and (main.dialogue_v31 == null or not main.dialogue_v31.opened) and not bool(donjon.get("_busy"))
	if main.xr_active and main.hero_v28 != null:
		main.hero_v28.hurt_cooldown = maxf(float(main.hero_v28.hurt_cooldown) - delta, 0.0)
		_vr_hearts(inside)


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
		for k in range(5):
			text += "♥" if hp >= (k + 1) * 2 else ("♡" if hp <= k * 2 else "❥")
		_hearts.text = text


## Sauvegarde : seulement le compte des victoires (les monstres reviennent à chaque descente).
func serialize() -> Dictionary:
	return {"victoires": kills}


func load_data(d: Dictionary) -> void:
	kills = int(d.get("victoires", 0))

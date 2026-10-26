extends Node3D
## V32 : le mode pêche.
## Canne en main (donnée par Barnabé), face à l'eau :
##  1. MAINTENIR le clic (gâchette en VR) pour armer : plus on attend, plus on lance loin ;
##     RELÂCHER pour lancer. Le flotteur doit tomber dans l'eau (au moins 35 cm de fond).
##  2. ATTENDRE : le flotteur frétille parfois (touches légères)… puis plonge : ÇA MORD !
##  3. CLIQUER tout de suite pour ferrer (moins d'une seconde).
##  4. COMBAT : maintenir le clic pour mouliner. La tension monte quand on mouline et quand le
##     poisson tire ; la garder dans la zone verte. Trop tendue : la ligne casse. Trop molle
##     trop longtemps : le poisson se décroche. La jauge de prise pleine : poisson attrapé !
## Les espèces dépendent de l'endroit : côte du village, baie de la jungle, eau profonde.

signal caught(item_id: String, kg: float)

const WATER: float = -0.42
const MIN_DEPTH: float = 0.35
const CAST_MIN: float = 4.0
const CAST_MAX: float = 16.0
const BITE_WINDOW: float = 0.9

## poids (kg), force (0..1 : difficulté du combat), présence selon la zone.
const FISH := {
	"sardine": {"poids": [0.08, 0.25], "force": 0.22, "zones": {"village": 5.0, "jungle": 4.0, "profond": 1.5}},
	"maquereau": {"poids": [0.3, 1.0], "force": 0.38, "zones": {"village": 3.0, "jungle": 2.5, "profond": 2.5}},
	"dorade": {"poids": [0.4, 2.2], "force": 0.52, "zones": {"village": 1.6, "jungle": 1.3, "profond": 2.0}},
	"bar": {"poids": [0.6, 3.0], "force": 0.58, "zones": {"village": 1.2, "jungle": 0.6, "profond": 1.8}},
	"poisson_perroquet": {"poids": [0.6, 2.5], "force": 0.55, "zones": {"jungle": 1.5}},
	"merou": {"poids": [3.0, 14.0], "force": 0.82, "zones": {"profond": 0.8}},
	"poisson_lune": {"poids": [8.0, 20.0], "force": 0.93, "zones": {"profond": 0.06, "jungle": 0.03, "village": 0.02}},
	"vieille_botte": {"poids": [0.6, 1.2], "force": 0.08, "zones": {"village": 0.6, "jungle": 0.6, "profond": 0.3}},
}

var main: Node
var state: String = "repos"            # repos, charge, vol, attente, touche, combat
var power: float = 0.0
var held: bool = false                  # clic (ou gâchette) maintenu
var cast_origin: Vector3
var target: Vector3
var fly_from: Vector3
var fly_t: float = 0.0
var wait_clock: float = 0.0
var nibble_clock: float = 0.0
var dip: float = 0.0
var fish_id: String = ""
var fish_kg: float = 0.0
var force: float = 0.0
var tension: float = 0.3
var progress: float = 0.0
var slack: float = 0.0
var pull: float = 0.0
var pull_clock: float = 0.0
var zone: String = "village"
var stats := {"total": 0, "especes": {}, "record_id": "", "record_kg": 0.0}
var _clock: float = 0.0
var _bobber: Node3D
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _trophy: Node3D
var _trophy_clock: float = 0.0
var _rng := RandomNumberGenerator.new()
# Affichage PC
var _layer: CanvasLayer
var _status: Label
var _power_bar: ColorRect
var _power_fill: ColorRect
var _fight: Control
var _tension_mark: ColorRect
var _progress_fill: ColorRect
# Affichage VR
var _vr_label: Label3D


var _reel_clock: float = 0.0

func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	_make_bobber()
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.name = "Ligne_v32"
	_line.mesh = _line_mesh
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.92, 0.92, 0.88, 0.85)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_line.material_override = lm
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	if main.xr_active:
		_vr_label = Label3D.new()
		_vr_label.font_size = 34
		_vr_label.pixel_size = 0.0012
		_vr_label.outline_size = 10
		_vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_vr_label.no_depth_test = true
		_vr_label.position = Vector3(0, 0.16, -0.1)
		_vr_label.visible = false
		main.right_hand.add_child(_vr_label)
	else:
		_build_ui()


# =================================================================== objets

func _make_bobber() -> void:
	_bobber = Node3D.new()
	_bobber.name = "Flotteur_v32"
	_bobber.visible = false
	add_child(_bobber)
	var top := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.06
	s.height = 0.12
	top.mesh = s
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.95, 0.95, 0.92)
	white.emission_enabled = true
	white.emission = Color(0.95, 0.95, 0.9)
	white.emission_energy_multiplier = 0.25
	top.material_override = white
	top.position.y = 0.02
	top.scale = Vector3(1, 0.8, 1)
	_bobber.add_child(top)
	var bottom := MeshInstance3D.new()
	bottom.mesh = s
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.12, 0.08)
	red.emission_enabled = true
	red.emission = Color(0.85, 0.12, 0.08)
	red.emission_energy_multiplier = 0.3
	bottom.material_override = red
	bottom.position.y = -0.015
	bottom.scale = Vector3(1, 0.7, 1)
	_bobber.add_child(bottom)
	var stick := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.006
	c.bottom_radius = 0.006
	c.height = 0.08
	stick.mesh = c
	stick.material_override = red
	stick.position.y = 0.1
	_bobber.add_child(stick)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 9
	_layer.visible = false
	add_child(_layer)
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_status.offset_top = -215
	_status.offset_bottom = -185
	_status.offset_left = -400
	_status.offset_right = 400
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 22)
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 6)
	_layer.add_child(_status)
	_power_bar = _bar(Vector2(-160, -150), Vector2(320, 16), Color(0, 0, 0, 0.55))
	_power_fill = ColorRect.new()
	_power_fill.color = Color(0.98, 0.76, 0.32)
	_power_fill.size = Vector2(0, 16)
	_power_bar.add_child(_power_fill)
	_fight = Control.new()
	_fight.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_layer.add_child(_fight)
	var tension_bg := _bar(Vector2(-200, -150), Vector2(400, 22), Color(0.75, 0.2, 0.15, 0.85), _fight)
	var green := ColorRect.new()
	green.color = Color(0.25, 0.75, 0.3, 0.9)
	green.position = Vector2(400 * 0.2, 0)
	green.size = Vector2(400 * 0.55, 22)
	tension_bg.add_child(green)
	var amber := ColorRect.new()
	amber.color = Color(0.95, 0.7, 0.2, 0.9)
	amber.position = Vector2(400 * 0.75, 0)
	amber.size = Vector2(400 * 0.13, 22)
	tension_bg.add_child(amber)
	_tension_mark = ColorRect.new()
	_tension_mark.color = Color(1, 1, 1)
	_tension_mark.size = Vector2(6, 30)
	_tension_mark.position = Vector2(0, -4)
	tension_bg.add_child(_tension_mark)
	var tl := Label.new()
	tl.text = "Tension de la ligne"
	tl.position = Vector2(0, -24)
	tl.add_theme_font_size_override("font_size", 14)
	tension_bg.add_child(tl)
	var prog_bg := _bar(Vector2(-200, -112), Vector2(400, 12), Color(0, 0, 0, 0.55), _fight)
	_progress_fill = ColorRect.new()
	_progress_fill.color = Color(0.45, 0.8, 1.0)
	_progress_fill.size = Vector2(0, 12)
	prog_bg.add_child(_progress_fill)


func _bar(pos: Vector2, size: Vector2, col: Color, parent: Control = null) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.position = pos
	r.size = size
	if parent == null:
		var holder := Control.new()
		holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_layer.add_child(holder)
		holder.add_child(r)
	else:
		parent.add_child(r)
	return r


# =================================================================== état du joueur

func rod_in_hand() -> bool:
	return main.inventory_v28 != null and main.inventory_v28.equipped == "canne_peche"


func _can_fish() -> bool:
	if not main.game_started or not rod_in_hand():
		return false
	if main.game_menu != null and main.game_menu.opened:
		return false
	if main.inventory_v28.opened or (main.dialogue_v31 != null and main.dialogue_v31.opened):
		return false
	if main.boat_v29 != null and main.boat_v29.driving:
		return false
	# V55 : pas de pêche en nageant
	var sea: Node = main.get("mer_v55")
	if sea != null and bool(sea.swimming):
		return false
	# V54 : pas de pêche à 150 m au-dessus de l'océan (ni sur le dos de Ventaile)
	var sky: Node = main.get("ciel_v54")
	if sky != null and (bool(sky.riding) or sky.on_sky(_player_pos())):
		return false
	var ae: Node = main.get("aeronef_v76")
	if ae != null and bool(ae.riding):
		return false
	if not main.xr_active and main.hero_v28 != null and not main.hero_v28.state in ["sol", "peche"]:
		return false
	return true


## Un menu, l'inventaire, un dialogue ou le bateau interrompent la pêche.
func _busy() -> bool:
	if main.game_menu != null and main.game_menu.opened:
		return true
	if main.inventory_v28.opened or (main.dialogue_v31 != null and main.dialogue_v31.opened):
		return true
	return main.boat_v29 != null and main.boat_v29.driving


func _player_pos() -> Vector3:
	return main.xr_camera.global_position if main.xr_active else main.pc_root.global_position


func _aim() -> Vector3:
	var f: Vector3
	if main.xr_active:
		f = -main.right_hand.global_basis.z
	else:
		f = main.hero_v28.facing
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func _rod_tip() -> Vector3:
	var holder: Node = null
	if main.xr_active:
		holder = main.right_hand.get_node_or_null("Arme_VR_v28")
	elif main.hero_v28 != null:
		holder = main.hero_v28.sword_holder
	if holder != null:
		var tip: Node3D = holder.find_child("Pointe", true, false) as Node3D
		if tip != null:
			return tip.global_position
	return _player_pos() + Vector3.UP * 2.0 + _aim() * 1.2


func _depth_at(p: Vector3) -> float:
	return WATER - main._height_at(p.x, p.z)


func _zone_at(p: Vector3) -> String:
	if _depth_at(p) > 2.2:
		return "profond"
	if main.jungle_v29 != null and main.jungle_v29.contains(p.x, p.z) and Vector2(p.x, p.z).length() > 120.0:
		return "jungle"
	return "village"


# =================================================================== entrées

func _unhandled_input(event: InputEvent) -> void:
	if main == null or main.xr_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not _can_fish() and state == "repos":
			return
		press(event.pressed)


## Clic (PC) ou gâchette (VR) : appui / relâchement.
func press(down: bool) -> void:
	if down == held:
		return
	held = down
	if down:
		match state:
			"repos":
				if _can_fish():
					state = "charge"
					power = 0.0
					_pose("peche_armer")
			"attente":
				_reel_in("Tu remontes la ligne.")
			"touche":
				_hook()
	else:
		if state == "charge":
			_cast()


func vr_tick(trigger: float) -> void:
	press(trigger > 0.7)


# =================================================================== déroulé

func _process(delta: float) -> void:
	if main == null:
		return
	_clock += delta
	if state != "repos" and (not rod_in_hand() or _busy()):
		cancel("")
	match state:
		"charge":
			power = minf(power + delta / 1.2, 1.0)
		"vol":
			_fly(delta)
		"attente":
			_wait(delta)
		"touche":
			_bite(delta)
		"combat":
			_fight_tick(delta)
	if state in ["attente", "touche", "combat"]:
		if _player_pos().distance_to(cast_origin) > (1.6 if main.xr_active else 0.8):
			cancel("Tu t'es éloigné : la ligne remonte.")
	_trophy_tick(delta)
	_draw_line()
	_update_ui()


func _pose(name: String) -> void:
	if not main.xr_active and main.hero_v28 != null:
		main.hero_v28.fishing_pose(name)


func _cast() -> void:
	var start: Vector3 = _player_pos()
	if main.has_method("sfx"):
		main.sfx("lancer", start + Vector3.UP * 1.5)
	var aim: Vector3 = _aim()
	var dist: float = lerpf(CAST_MIN, CAST_MAX, power)
	# On cherche l'eau dans la direction visée, du plus loin au plus près.
	var spot := Vector3.INF
	var d: float = dist
	while d >= 2.0:
		var p: Vector3 = start + aim * d
		if _depth_at(p) >= MIN_DEPTH:
			spot = p
			break
		d -= 0.5
	if spot == Vector3.INF:
		state = "repos"
		_pose("")
		_say("Pas d'eau assez profonde devant toi.", 2.5)
		return
	cast_origin = start
	target = Vector3(spot.x, WATER, spot.z)
	fly_from = _rod_tip()
	fly_t = 0.0
	state = "vol"
	_bobber.visible = true
	_pose("peche_lancer")


func _fly(delta: float) -> void:
	var duration: float = 0.45 + fly_from.distance_to(target) * 0.03
	fly_t += delta / duration
	var u: float = clampf(fly_t, 0.0, 1.0)
	var p: Vector3 = fly_from.lerp(target, u)
	p.y += sin(u * PI) * (1.5 + fly_from.distance_to(target) * 0.12)
	_bobber.global_position = p
	if u >= 1.0:
		_splash(target)
		zone = _zone_at(target)
		state = "attente"
		wait_clock = _rng.randf_range(4.0, 12.0) * (0.75 if zone == "profond" else 1.0)
		nibble_clock = _rng.randf_range(1.5, 3.5)
		_pose("peche_tenir")
		_say("Le flotteur est à l'eau. Patience…", 2.5)


func _wait(delta: float) -> void:
	wait_clock -= delta
	nibble_clock -= delta
	dip = move_toward(dip, 0.0, delta * 0.5)
	if nibble_clock <= 0.0 and wait_clock > 1.0:
		dip = 0.06                       # petite touche : le flotteur frétille
		nibble_clock = _rng.randf_range(1.2, 3.5)
	if wait_clock <= 0.0:
		_choose_fish()
		state = "touche"
		wait_clock = BITE_WINDOW * (1.0 - force * 0.25)
		dip = 0.28
		_splash(_bobber.global_position)
		_say("ÇA MORD ! Vite, " + ("gâchette !" if main.xr_active else "clic !"), BITE_WINDOW)
	_float_bobber()


func _bite(delta: float) -> void:
	wait_clock -= delta
	_float_bobber()
	if wait_clock <= 0.0:
		state = "attente"
		wait_clock = _rng.randf_range(4.0, 10.0)
		dip = 0.0
		_say("Raté… le poisson a filé avec l'appât. Il en reviendra un autre.", 2.5)


func _choose_fish() -> void:
	var total: float = 0.0
	for id in FISH:
		total += float((FISH[id]["zones"] as Dictionary).get(zone, 0.0))
	var r: float = _rng.randf() * total
	fish_id = "sardine"
	for id in FISH:
		r -= float((FISH[id]["zones"] as Dictionary).get(zone, 0.0))
		if r <= 0.0:
			fish_id = id
			break
	var w: Array = FISH[fish_id]["poids"]
	# Les gros spécimens sont plus rares (tirage biaisé vers le bas).
	fish_kg = snappedf(lerpf(float(w[0]), float(w[1]), pow(_rng.randf(), 1.8)), 0.01)
	force = float(FISH[fish_id]["force"])


func _hook() -> void:
	if main.has_method("sfx"):
		main.sfx("ferrage", _player_pos() + Vector3.UP * 1.3)
	state = "combat"
	tension = 0.45
	progress = 0.0
	slack = 0.0
	pull = 0.0
	pull_clock = 0.0
	dip = 0.0
	_pose("peche_mouliner")
	_say("Ferré ! Garde la tension dans le vert.", 2.0)


func _fight_tick(delta: float) -> void:
	# Le poisson tire par à-coups, d'autant plus fort qu'il est gros et combatif.
	pull_clock -= delta
	if pull_clock <= 0.0:
		pull = _rng.randf_range(0.0, 1.0) * force * (1.4 if _rng.randf() < 0.25 else 0.8)
		pull_clock = _rng.randf_range(0.4, 1.4)
	var reel: bool = held
	# Mouliner tend la ligne, relâcher la détend ; les à-coups du poisson la tendent aussi.
	tension += ((0.3 if reel else -0.7) + pull * 0.9 - 0.15) * delta
	tension = clampf(tension, 0.0, 1.0)
	var in_green: bool = tension > 0.2 and tension < 0.75
	if reel:
		# V50 : le cliquetis du moulinet
		_reel_clock -= delta
		if _reel_clock <= 0.0:
			_reel_clock = 0.16
			if main.has_method("sfx"):
				main.sfx("moulinet", _player_pos() + Vector3.UP * 1.2)
		progress += delta * (0.2 - force * 0.1) * (1.0 if in_green else 0.35)
	else:
		progress -= delta * 0.03 * force
	progress = clampf(progress, 0.0, 1.0)
	slack = slack + delta if tension < 0.08 else 0.0
	_pose("peche_mouliner" if reel else "peche_tenir")
	# Le flotteur est entraîné vers le joueur et tiré de côté par le poisson.
	var to_player: Vector3 = cast_origin - target
	to_player.y = 0.0
	var side: Vector3 = to_player.normalized().cross(Vector3.UP)
	var p: Vector3 = target + to_player * progress * 0.8 + side * sin(_clock * 3.1) * pull * 0.8
	_bobber.global_position = Vector3(p.x, WATER - 0.05 + sin(_clock * 9.0) * 0.04, p.z)
	if _rng.randf() < delta * 3.0:
		_splash(_bobber.global_position)
	if tension >= 1.0:
		_end("Crac ! La ligne a cassé…")
	elif slack > 2.8:
		_end("Le poisson s'est décroché.")
	elif progress >= 1.0:
		_landed()


func _landed() -> void:
	if main.has_method("sfx"):
		main.sfx("gros_plouf", _player_pos() + Vector3.UP * 0.5)
	var got: int = main.inventory_v28.add(fish_id, 1)
	var info: Dictionary = main.inventory_v28.ITEMS[fish_id]
	stats["total"] = int(stats["total"]) + 1
	var esp: Dictionary = stats["especes"]
	esp[fish_id] = int(esp.get(fish_id, 0)) + 1
	var record: bool = fish_id != "vieille_botte" and fish_kg > float(stats["record_kg"])
	if record:
		stats["record_id"] = fish_id
		stats["record_kg"] = fish_kg
	var kg_text: String = ("%.2f kg" % fish_kg).replace(".", ",")
	var text: String
	if fish_id == "vieille_botte":
		text = "Une vieille botte… Bon. Ça compte quand même ?"
	else:
		text = str(info["name"]) + " ! " + kg_text + ("  — nouveau record !" if record else "")
	if got <= 0:
		text += " (inventaire plein, tu le relâches)"
	caught.emit(fish_id, fish_kg)
	_show_trophy(fish_id)
	_end(text)


func _end(text: String) -> void:
	state = "repos"
	held = false
	_bobber.visible = false
	_pose("")
	if text != "":
		_say(text, 3.5)


func _reel_in(text: String) -> void:
	_end(text)


## Interrompt la pêche (on bouge, on range la canne, on ouvre un menu…).
func cancel(text: String) -> void:
	if state == "repos":
		return
	_end(text)


func _float_bobber() -> void:
	var p: Vector3 = target
	_bobber.global_position = Vector3(p.x, WATER + 0.01 + sin(_clock * 2.2) * 0.025 - dip + sin(_clock * 25.0) * dip * 0.3, p.z)


func _splash(at: Vector3) -> void:
	if main.has_method("sfx"):
		main.sfx("plouf", at)
	if main.combat_v28 != null:
		main.combat_v28.puff(at + Vector3.UP * 0.05, Color(0.85, 0.92, 1.0))


# =================================================================== ligne, trophée, affichage

func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	if state in ["repos", "charge"] or not _bobber.visible:
		return
	var a: Vector3 = _rod_tip()
	var b: Vector3 = _bobber.global_position + Vector3.UP * 0.1
	var sag: float = 0.05 if state == "combat" and tension > 0.3 else 0.6
	var pts: Array = []
	for i in range(17):
		var u: float = float(i) / 16.0
		var p: Vector3 = a.lerp(b, u)
		p.y -= sin(u * PI) * sag * clampf(a.distance_to(b) / 10.0, 0.2, 1.5)
		pts.append(p)
	# Ruban fin tourné vers la caméra (une ligne d'un pixel disparaît au loin).
	var cam: Camera3D = get_viewport().get_camera_3d()
	var eye: Vector3 = cam.global_position if cam != null else a + Vector3.UP
	_line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		var tangent: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side: Vector3 = (p - eye).cross(tangent)
		side = side.normalized() if side.length() > 0.0001 else Vector3.RIGHT
		var w: float = maxf(0.004, p.distance_to(eye) * 0.0012)
		_line_mesh.surface_add_vertex(p - side * w)
		_line_mesh.surface_add_vertex(p + side * w)
	_line_mesh.surface_end()


func _show_trophy(id: String) -> void:
	if _trophy != null:
		_trophy.queue_free()
	_trophy = main.inventory_v28.make_model(id)
	add_child(_trophy)
	_trophy_clock = 2.5
	var s: float = clampf(0.6 + fish_kg * 0.05, 0.6, 1.6) if id != "vieille_botte" else 1.0
	_trophy.scale = Vector3.ONE * s


func _trophy_tick(delta: float) -> void:
	if _trophy == null:
		return
	_trophy_clock -= delta
	var base: Vector3 = _player_pos() + (Vector3.UP * (2.25 if not main.xr_active else -0.1)) + _aim() * (0.3 if not main.xr_active else 0.7)
	_trophy.global_position = base
	_trophy.rotation.y += delta * 2.0
	if _trophy_clock <= 0.0:
		_trophy.queue_free()
		_trophy = null


var _say_text: String = ""
var _say_clock: float = 0.0


func _say(text: String, seconds: float) -> void:
	_say_text = text
	_say_clock = seconds


func _bar_text(v: float, n: int = 12) -> String:
	var k: int = int(round(clampf(v, 0.0, 1.0) * n))
	return "■".repeat(k) + "□".repeat(n - k)


func _update_ui() -> void:
	_say_clock -= get_process_delta_time()
	var hint: String = ""
	match state:
		"charge":
			hint = "Relâche pour lancer"
		"attente":
			hint = "Attends la touche…  (clic : remonter)" if not main.xr_active else "Attends la touche…"
		"combat":
			hint = "Maintiens pour mouliner, relâche si ça tire trop"
	var text: String = _say_text if _say_clock > 0.0 else hint
	if main.xr_active:
		if _vr_label == null:
			return
		_vr_label.visible = state != "repos" or _say_clock > 0.0
		var lines: Array = [text]
		if state == "charge":
			lines.append("Force  " + _bar_text(power))
		elif state == "combat":
			var t_word: String = "OK" if tension > 0.2 and tension < 0.75 else ("TROP TENDU !" if tension >= 0.75 else "trop mou")
			lines.append("Tension " + _bar_text(tension) + "  " + t_word)
			lines.append("Prise   " + _bar_text(progress))
		_vr_label.text = "\n".join(lines)
		return
	if _layer == null:
		return
	_layer.visible = rod_in_hand() and main.game_started and (state != "repos" or _say_clock > 0.0)
	_status.text = text
	_power_bar.visible = state == "charge"
	_power_fill.size.x = 320.0 * power
	_fight.visible = state == "combat"
	_tension_mark.position.x = 400.0 * tension - 3.0
	_progress_fill.size.x = 400.0 * progress


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	return stats.duplicate(true)


func load_data(d: Dictionary) -> void:
	stats = {"total": 0, "especes": {}, "record_id": "", "record_kg": 0.0}
	if d.is_empty():
		return
	stats["total"] = int(d.get("total", 0))
	stats["especes"] = d.get("especes", {}) if d.get("especes", {}) is Dictionary else {}
	stats["record_id"] = str(d.get("record_id", ""))
	stats["record_kg"] = float(d.get("record_kg", 0.0))

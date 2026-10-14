extends Node3D
## V33 : creuser avec la pelle achetée chez Octave.
## Pelle en main : clic (PC) ou gâchette (VR) devant soi, sur du sable ou de la terre.
## Chaque coin de sol (carreau de 1,5 m) ne se creuse qu'une fois : le trou reste, et il est
## gardé dans la sauvegarde. Ce qu'on trouve dépend du terrain :
##  - plage (près de l'eau) : coquillages, pièces perdues, vieux trésors de naufragés ;
##  - terre de l'intérieur : cailloux, bâtons, champignons, parfois une bourse enterrée.

signal found(item_id: String, n: int)

const CELL: float = 1.5
const WATER: float = -0.42
const MAX_HOLES: int = 400

## [objet, nombre min, nombre max, poids] ; "" = rien.
const LOOT := {
	"plage": [["", 0, 0, 34.0], ["coquillage", 1, 2, 30.0], ["piece", 1, 3, 18.0], ["caillou", 1, 1, 10.0], ["piece", 6, 12, 3.0], ["vieille_botte", 1, 1, 1.5]],
	"terre": [["", 0, 0, 36.0], ["caillou", 1, 2, 22.0], ["baton", 1, 1, 12.0], ["champignon", 1, 1, 12.0], ["piece", 1, 2, 12.0], ["piece", 5, 10, 2.5]],
}

var main: Node
var holes: Dictionary = {}          # "cx_cz" -> true
var _hole_nodes: Dictionary = {}
var _busy: float = 0.0
var _rng := RandomNumberGenerator.new()
var _dirt: StandardMaterial3D
var _sand: StandardMaterial3D
var _dark: StandardMaterial3D
var _vr_label: Label3D
var _vr_clock: float = 0.0


func setup(main_node: Node) -> void:
	main = main_node
	_rng.randomize()
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color(0.16, 0.11, 0.07)
	_dark.roughness = 1.0
	_dirt = StandardMaterial3D.new()
	_dirt.albedo_color = Color(0.36, 0.26, 0.17)
	_dirt.roughness = 1.0
	_sand = StandardMaterial3D.new()
	_sand.albedo_color = Color(0.78, 0.68, 0.5)
	_sand.roughness = 1.0


func _process(delta: float) -> void:
	_busy = maxf(_busy - delta, 0.0)
	if _vr_clock > 0.0:
		_vr_clock -= delta
		if _vr_clock <= 0.0 and _vr_label != null:
			_vr_label.visible = false


func _key(p: Vector3) -> String:
	return "%d_%d" % [int(floor(p.x / CELL)), int(floor(p.z / CELL))]


## Sol creusable sous ce point : {pos, terrain} ou {} (eau, rocher, plancher…).
func ground_at(p: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 2.5, 1))
	if hit.is_empty() or hit.normal.y < 0.75:
		return {}
	var n: String = str(hit.collider.name)
	if n != "Sol_collision_v11" and n != "Sol_jungle_v29":
		return {}
	if hit.position.y < WATER + 0.12:
		return {}
	var beach: bool = hit.position.y < 1.4
	return {"pos": hit.position, "terrain": "plage" if beach else "terre"}


func _say(text: String) -> void:
	main._show_message_v28(text)
	# En VR, le message flotte au-dessus de la main droite quelques secondes.
	if main.xr_active and main.right_hand != null:
		if _vr_label == null:
			_vr_label = Label3D.new()
			_vr_label.font_size = 34
			_vr_label.pixel_size = 0.0012
			_vr_label.outline_size = 10
			_vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_vr_label.no_depth_test = true
			_vr_label.position = Vector3(0, 0.2, -0.1)
			main.right_hand.add_child(_vr_label)
		_vr_label.text = text
		_vr_label.visible = true
		_vr_clock = 3.0


## PC : le héros plante sa pelle juste devant lui.
func dig_hero() -> void:
	var hero = main.hero_v28
	var spot: Vector3 = main.pc_root.global_position + hero.facing * 0.75
	if _check(spot):
		hero.play_action("creuser", spot)
		_dig_after(spot, 0.6)


## VR : on creuse là où pointe la pelle (sous la main droite, devant soi).
func dig_vr() -> void:
	var f: Vector3 = -main.right_hand.global_basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	var head: Vector3 = main.xr_camera.global_position
	var spot := Vector3(head.x, main.vr_body.global_position.y, head.z) + f * 0.7
	if _check(spot):
		_dig_after(spot, 0.35)


func _check(spot: Vector3) -> bool:
	if _busy > 0.0:
		return false
	var g: Dictionary = ground_at(spot)
	if g.is_empty():
		_say("Impossible de creuser ici : il faut du sable ou de la terre.")
		_busy = 0.8
		return false
	if holes.has(_key(g["pos"])):
		_say("Tu as déjà creusé ici. Essaie un peu plus loin.")
		_busy = 0.8
		return false
	_busy = 1.3
	return true


func _dig_after(spot: Vector3, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	var g: Dictionary = ground_at(spot)
	if g.is_empty() or holes.has(_key(g["pos"])):
		return
	var key: String = _key(g["pos"])
	holes[key] = str(g["terrain"])
	_make_hole(key, g["pos"], str(g["terrain"]))
	if main.combat_v28 != null:
		main.combat_v28.puff(g["pos"] + Vector3.UP * 0.1, Color(0.62, 0.5, 0.36) if g["terrain"] == "terre" else Color(0.9, 0.82, 0.62))
	var pick: Array = _roll(str(g["terrain"]))
	if str(pick[0]) == "":
		_say(["Rien… que du sable." if g["terrain"] == "plage" else "Rien… que de la terre.", "Pas de chance cette fois.", "Rien ici. Le trésor est sûrement à côté."][_rng.randi() % 3])
		return
	var n: int = _rng.randi_range(int(pick[1]), int(pick[2]))
	var got: int = main.inventory_v28.add(str(pick[0]), n)
	var name: String = str(main.inventory_v28.ITEMS[str(pick[0])]["name"])
	if got <= 0:
		_say("Tu trouves : " + name + "… mais ton sac est plein.")
		return
	if str(pick[0]) == "piece" and n >= 5:
		_say("Un trésor enterré ! %d pièces de cuivre !" % got)
	else:
		_say("Tu trouves : " + name + ("" if got == 1 else " ×%d" % got) + " !")
	found.emit(str(pick[0]), got)


func _roll(terrain: String) -> Array:
	var table: Array = LOOT.get(terrain, LOOT["terre"])
	var total: float = 0.0
	for e in table:
		total += float(e[3])
	var r: float = _rng.randf() * total
	for e in table:
		r -= float(e[3])
		if r <= 0.0:
			return e
	return table[0]


func _make_hole(key: String, at: Vector3, terrain: String) -> void:
	if _hole_nodes.has(key):
		return
	var root := Node3D.new()
	root.name = "Trou_" + key
	add_child(root)
	root.global_position = at
	root.rotation.y = float(hash(key) % 628) / 100.0
	# Le trou : un disque sombre à peine enfoncé ; à côté, le tas de terre rejetée.
	var hole := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.32
	c.bottom_radius = 0.26
	c.height = 0.04
	c.radial_segments = 14
	hole.mesh = c
	hole.material_override = _dark
	hole.position = Vector3(0, 0.005, 0)
	hole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hole)
	var mound := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.3
	s.height = 0.6
	mound.mesh = s
	mound.material_override = _sand if terrain == "plage" else _dirt
	mound.position = Vector3(0.5, -0.05, 0.05)
	mound.scale = Vector3(1.1, 0.3, 0.8)
	root.add_child(mound)
	_hole_nodes[key] = root


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var out := {}
	for k in holes:
		out[k] = holes[k]
	return {"trous": out}


func load_data(d: Dictionary) -> void:
	for k in _hole_nodes:
		(_hole_nodes[k] as Node).queue_free()
	_hole_nodes.clear()
	holes.clear()
	var t: Variant = d.get("trous", {})
	if not (t is Dictionary):
		return
	for k in t:
		if holes.size() >= MAX_HOLES:
			break
		holes[str(k)] = str(t[k])
	_rebuild.call_deferred()


## Les trous d'une partie chargée réapparaissent au centre de leur carreau.
func _rebuild() -> void:
	for k in holes:
		var parts: PackedStringArray = str(k).split("_")
		if parts.size() != 2:
			continue
		var x: float = (float(parts[0]) + 0.5) * CELL
		var z: float = (float(parts[1]) + 0.5) * CELL
		var g: Dictionary = ground_at(Vector3(x, main._height_at(x, z) + 0.5, z))
		if not g.is_empty():
			_make_hole(str(k), g["pos"], str(holes[k]))

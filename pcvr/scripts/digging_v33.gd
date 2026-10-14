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
# V34 : petits trésors enfouis, signalés par une croix de bois et un scintillement.
const ACTIVE_TREASURES: int = 5
var treasure_spots: Array = []      # positions monde (déterministes)
var treasure_order: Array = []      # ordre dans lequel les cachettes apparaissent
var treasures_found: Array = []     # indices déjà déterrés (cycle en cours)
var treasures_total: int = 0        # trésors trouvés depuis le début de la partie
var mouette_spot: Vector3 = Vector3.INF
var mouette_found: bool = false
var _markers: Dictionary = {}       # indice -> Node3D
var _mouette_marker: Node3D
var _gold: StandardMaterial3D


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
	if _treasure_near(g["pos"]) != -1 or _mouette_near(g["pos"]) or _trap_near(g["pos"]) != "":
		_busy = 1.3
		return true
	if holes.has(_key(g["pos"])):
		_say("Tu as déjà creusé ici. Essaie un peu plus loin.")
		_busy = 0.8
		return false
	_busy = 1.3
	return true


func _dig_after(spot: Vector3, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	var g: Dictionary = ground_at(spot)
	if g.is_empty():
		return
	var key: String = _key(g["pos"])
	var ti: int = _treasure_near(g["pos"])
	var big: bool = _mouette_near(g["pos"])
	if holes.has(key) and ti == -1 and not big and _trap_near(g["pos"]) == "":
		return
	if not holes.has(key):
		holes[key] = str(g["terrain"])
		_make_hole(key, g["pos"], str(g["terrain"]))
	var trap: String = _trap_near(g["pos"])
	if trap != "":
		main.donjon_v35.reveal_trap(trap)
		return
	if big:
		_dig_mouette(g["pos"])
		return
	if ti != -1:
		_dig_treasure(ti, g["pos"])
		return
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


# =================================================================== V34 : trésors

## Cachettes (déterministes) : sur l'île du village et dans la jungle, sur du sol nu.
func plant_treasures() -> void:
	_gold = StandardMaterial3D.new()
	_gold.albedo_color = Color(1.0, 0.85, 0.35)
	_gold.emission_enabled = true
	_gold.emission = Color(1.0, 0.8, 0.3)
	_gold.emission_energy_multiplier = 3.0
	_gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var rng := RandomNumberGenerator.new()
	rng.seed = 5151
	treasure_spots.clear()
	var tries: int = 0
	while treasure_spots.size() < 14 and tries < 1500:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(12.0, 58.0)
		_try_spot(Vector3(cos(a) * r, 0, 4.0 + sin(a) * r))
	var j: Node = main.jungle_v29
	# Jungle : les cachettes préparées avant la forêt (dans de petites clairières).
	for q in main.treasure_jungle_v34:
		_try_spot(q)
	# Ordre d'apparition mélangé une fois pour toutes.
	treasure_order = range(treasure_spots.size())
	for i in range(treasure_order.size() - 1, 0, -1):
		var k: int = rng.randi_range(0, i)
		var tmp: int = treasure_order[i]
		treasure_order[i] = treasure_order[k]
		treasure_order[k] = tmp
	# Le coffre de paie de la Mouette Têtue : côté mer, à une vingtaine de pas du fromager
	# d'Octave, entre trois pierres plates (Barnabé l'avait noté sur sa carte).
	if main.mouette_spot_v34 != Vector3.INF:
		var gm: Dictionary = ground_at(main.mouette_spot_v34 + Vector3.UP * 0.5)
		if not gm.is_empty() and _free(gm["pos"]):
			mouette_spot = gm["pos"]
	if mouette_spot == Vector3.INF and not main.tree_spot_v33.is_empty() and j != null:
		var c: Vector3 = main.tree_spot_v33["pos"]
		var out: Vector3 = c - j.CENTER
		out.y = 0.0
		out = out.normalized()
		for d in [16.0, 14.0, 18.0, 12.0, 20.0, 22.0]:
			for side in [0.0, 3.0, -3.0]:
				var p: Vector3 = c + out * d + out.cross(Vector3.UP) * side
				var g: Dictionary = ground_at(Vector3(p.x, main._height_at(p.x, p.z) + 0.5, p.z))
				if not g.is_empty() and _free(g["pos"]):
					mouette_spot = g["pos"]
					break
			if mouette_spot != Vector3.INF:
				break
	_refresh_markers()
	print("ILE_MANGA_V34: ", treasure_spots.size(), " cachettes de trésor, coffre de la Mouette ", mouette_spot)


func _free(p: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = (main as Node3D).get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.9
	q.shape = sph
	q.collision_mask = 1
	q.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 1.2)
	return space.intersect_shape(q, 1).is_empty()


func _try_spot(p: Vector3) -> void:
	var g: Dictionary = ground_at(Vector3(p.x, main._height_at(p.x, p.z) + 0.5, p.z))
	if g.is_empty() or not _free(g["pos"]):
		return
	for q in treasure_spots:
		if (q as Vector3).distance_to(g["pos"]) < 12.0:
			return
	for npc in main.npcs_v31:
		for k in npc.points:
			if (npc.points[k] as Vector3).distance_to(g["pos"]) < 3.0:
				return
	treasure_spots.append(g["pos"])


func active_treasures() -> Array:
	var out: Array = []
	for i in treasure_order:
		if not treasures_found.has(i):
			out.append(i)
			if out.size() >= ACTIVE_TREASURES:
				break
	return out


## V35 : une trappe du Temple englouti encore enterrée sous ce point ?
func _trap_near(p: Vector3) -> String:
	if main.get("donjon_v35") == null:
		return ""
	return main.donjon_v35.buried_trap_near(p)


func _treasure_near(p: Vector3) -> int:
	for i in active_treasures():
		var q: Vector3 = treasure_spots[i]
		if Vector2(q.x - p.x, q.z - p.z).length() < 1.4 and absf(q.y - p.y) < 1.5:
			return i
	return -1


func _mouette_near(p: Vector3) -> bool:
	if mouette_found or mouette_spot == Vector3.INF:
		return false
	return Vector2(mouette_spot.x - p.x, mouette_spot.z - p.z).length() < 1.6 and absf(mouette_spot.y - p.y) < 1.5


## PC : invite quand on tient la pelle tout près d'une cachette.
func prompt(p: Vector3) -> String:
	if main.inventory_v28.equipped != "pelle":
		return ""
	if _treasure_near(p) != -1 or _mouette_near(p) or _trap_near(p) != "":
		return "Clic : creuser ici !"
	return ""


func _refresh_markers() -> void:
	var act: Array = active_treasures()
	for i in _markers.keys():
		if not act.has(i):
			(_markers[i] as Node).queue_free()
			_markers.erase(i)
	for i in act:
		if not _markers.has(i):
			_markers[i] = _make_marker(treasure_spots[i], i)
	if _mouette_marker == null and mouette_spot != Vector3.INF and not mouette_found:
		_mouette_marker = _make_stones(mouette_spot)
	if _mouette_marker != null and mouette_found:
		_mouette_marker.queue_free()
		_mouette_marker = null


## Croix de deux bâtons posée sur le sol, quelques cailloux, et un scintillement doré.
func _make_marker(at: Vector3, i: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Cachette_%d" % i
	add_child(root)
	root.global_position = at
	root.rotation.y = float(i) * 0.7
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.68, 0.52, 0.32)
	wood.roughness = 0.9
	for a in [45.0, -45.0]:
		var stick := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.07, 0.05, 0.85)
		stick.mesh = b
		stick.material_override = wood
		stick.rotation_degrees = Vector3(0, a, 0)
		stick.position.y = 0.03 + (0.03 if a > 0 else 0.0)
		root.add_child(stick)
	var pebble := StandardMaterial3D.new()
	pebble.albedo_color = Color(0.6, 0.58, 0.54)
	for k in range(3):
		var mi := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.07
		sp.height = 0.08
		mi.mesh = sp
		mi.material_override = pebble
		var ang: float = TAU * k / 3.0 + 0.4
		mi.position = Vector3(cos(ang) * 0.55, 0.02, sin(ang) * 0.55)
		root.add_child(mi)
	var sparkle := CPUParticles3D.new()
	sparkle.amount = 8
	sparkle.lifetime = 1.4
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 0.3
	sparkle.direction = Vector3.UP
	sparkle.spread = 20.0
	sparkle.initial_velocity_min = 0.1
	sparkle.initial_velocity_max = 0.3
	sparkle.gravity = Vector3.ZERO
	sparkle.scale_amount_min = 0.6
	sparkle.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	q.material = _gold
	sparkle.mesh = q
	sparkle.position.y = 0.15
	sparkle.visibility_range_end = 30.0
	root.add_child(sparkle)
	return root


func _make_stones(at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Trois_pierres_plates"
	add_child(root)
	root.global_position = at
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.54, 0.5)
	stone.roughness = 0.95
	for k in range(3):
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.28
		c.bottom_radius = 0.32
		c.height = 0.08
		c.radial_segments = 7
		mi.mesh = c
		mi.material_override = stone
		var ang: float = TAU * k / 3.0
		mi.position = Vector3(cos(ang) * 1.0, 0.03, sin(ang) * 1.0)
		mi.rotation = Vector3(0.05, ang, 0.04)
		root.add_child(mi)
	return root


func _dig_treasure(i: int, at: Vector3) -> void:
	treasures_found.append(i)
	treasures_total += 1
	if treasures_found.size() >= treasure_spots.size():
		treasures_found.clear()
	_refresh_markers()
	var coins: int = _rng.randi_range(6, 14)
	var gains: Array = [["piece", coins]]
	var r: float = _rng.randf()
	if r < 0.4:
		gains.append(["perle", 1])
	elif r < 0.65:
		gains.append(["bague", 1])
	elif r < 0.8:
		gains.append(["rubis", 1])
	else:
		gains.append(["piece_or", _rng.randi_range(1, 2)])
	_chest(at, false)
	_say("Un petit trésor ! Le coffret contient : " + _give(gains))
	found.emit("tresor", 1)


func _dig_mouette(at: Vector3) -> void:
	mouette_found = true
	treasures_total += 1
	_refresh_markers()
	_chest(at, true)
	_say("LE COFFRE DE PAIE DE LA MOUETTE TÊTUE ! " + _give([["piece", 50], ["piece_or", 3], ["rubis", 1], ["bague", 1]]))
	found.emit("mouette", 1)


func _give(gains: Array) -> String:
	var parts: Array = []
	for g in gains:
		var got: int = main.inventory_v28.add(str(g[0]), int(g[1]))
		if got > 0:
			var name: String = str(main.inventory_v28.ITEMS[str(g[0])]["name"])
			parts.append(("%d pièces" % got) if str(g[0]) == "piece" else name + ("" if got == 1 else " ×%d" % got))
	return ", ".join(parts) + "." if not parts.is_empty() else "… mais ton sac est plein !"


## Le coffre sort du trou, s'ouvre en brillant, puis redescend.
func _chest(at: Vector3, big: bool) -> void:
	var k: float = 1.6 if big else 1.0
	var root := Node3D.new()
	root.name = "Coffre_trouve"
	add_child(root)
	root.global_position = at + Vector3.DOWN * 0.45 * k
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.26, 0.14)
	wood.roughness = 0.8
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.8, 0.62, 0.25)
	brass.metallic = 0.6
	brass.roughness = 0.35
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.28, 0.32) * k
	box.mesh = bm
	box.material_override = wood
	box.position.y = 0.14 * k
	root.add_child(box)
	for x in [-0.18, 0.18]:
		var band := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.04, 0.29, 0.33) * k
		band.mesh = bb
		band.material_override = brass
		band.position = Vector3(x * k, 0.14 * k, 0)
		root.add_child(band)
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.28 * k, -0.16 * k)
	root.add_child(hinge)
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.5, 0.1, 0.32) * k
	lid.mesh = lm
	lid.material_override = wood
	lid.position = Vector3(0, 0.05 * k, 0.16 * k)
	hinge.add_child(lid)
	var glow := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.42, 0.02, 0.26) * k
	glow.mesh = gm
	glow.material_override = _gold
	glow.position.y = 0.27 * k
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 0.0
	light.omni_range = 3.0 * k
	light.position.y = 0.6 * k
	root.add_child(light)
	var tw := create_tween()
	tw.tween_property(root, "global_position", at + Vector3.UP * 0.02, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(hinge, "rotation:x", -1.9, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(light, "light_energy", 2.5, 0.45)
	tw.tween_interval(3.0 if not big else 5.0)
	tw.tween_property(root, "global_position", at + Vector3.DOWN * 0.6 * k, 0.8)
	tw.tween_callback(root.queue_free)
	if main.combat_v28 != null:
		main.combat_v28.puff(at + Vector3.UP * 0.3, Color(1.0, 0.85, 0.35))


# =================================================================== sauvegarde

func serialize() -> Dictionary:
	var out := {}
	for k in holes:
		out[k] = holes[k]
	return {"trous": out, "tresors": treasures_found.duplicate(), "tresors_total": treasures_total, "mouette": mouette_found}


func load_data(d: Dictionary) -> void:
	for k in _hole_nodes:
		(_hole_nodes[k] as Node).queue_free()
	_hole_nodes.clear()
	holes.clear()
	treasures_found.clear()
	var tf: Variant = d.get("tresors", [])
	if tf is Array:
		for v in tf:
			treasures_found.append(int(v))
	treasures_total = int(d.get("tresors_total", 0))
	mouette_found = bool(d.get("mouette", false))
	if not treasure_spots.is_empty():
		_refresh_markers()
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

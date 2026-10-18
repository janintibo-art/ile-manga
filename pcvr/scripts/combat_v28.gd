extends Node3D
## V28 : cibles de combat.
## Tout ce qui peut être frappé est dans le groupe « cibles_v28 » et possède
## take_hit(dégâts, d'où vient le coup) et un rayon « hit_radius ». Les futurs ennemis
## n'auront qu'à suivre la même règle.
## - Mannequins d'entraînement (aire au nord du village) : vacillent, comptent les dégâts.
## - Jarres en terre près des maisons : se brisent et laissent tomber pièces ou fruits ;
##   elles se reforment au bout de quelques minutes.

const DUMMIES := [Vector2(-6.2, -6.0), Vector2(-3.6, -7.4), Vector2(-1.0, -6.2)]
const JARS := [Vector2(6.2, 2.0), Vector2(6.3, 6.3), Vector2(-7.6, 10.8), Vector2(-7.4, 7.2), Vector2(-3.8, 12.4), Vector2(-4.6, 13.6)]
const JAR_RESPAWN: float = 180.0
var jar_respawn_time: float = JAR_RESPAWN

var main: Node
var inventory: Node
var _mats: Dictionary = {}
var _floaters: Array = []               # chiffres de dégâts qui montent
var _shards: Array = []                 # éclats de jarre
var _vr_prev: Dictionary = {}
var _vr_cool: Dictionary = {}
var critical: bool = false            # V34 : le coup en cours est un coup de grâce


func build(main_node: Node, inv: Node) -> void:
	main = main_node
	inventory = inv
	for i in range(DUMMIES.size()):
		var p: Vector2 = DUMMIES[i]
		_make_dummy(i, Vector3(p.x, main._height_at(p.x, p.y), p.y))
	for i in range(JARS.size()):
		var j: Vector2 = JARS[i]
		_make_jar(i, Vector3(j.x, main._height_at(j.x, j.y), j.y))
	print("ILE_MANGA_V28: ", DUMMIES.size(), " mannequins, ", JARS.size(), " jarres")


func _mat(key: String, color: Color, rough: float = 0.85) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		_mats[key] = m
	return _mats[key]


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _cyl(r_top: float, r_bot: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	return c


func _solid(parent: Node3D, label: String, radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height * 0.5
	body.add_child(cs)
	parent.add_child(body)
	return body


# =================================================================== mannequins

func _make_dummy(i: int, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Mannequin_v28_%d" % i
	root.set_script(preload("res://scripts/target_v28.gd"))
	add_child(root)
	root.global_position = at
	root.rotation.y = atan2(-at.x, 4.0 - at.z)   # tourné vers le village
	var wood := _mat("poteau", Color(0.36, 0.24, 0.14), 0.9)
	var straw := _mat("paille", Color(0.78, 0.66, 0.4), 0.95)
	var sack := _mat("toile", Color(0.62, 0.5, 0.34), 0.95)
	var rope := _mat("corde", Color(0.45, 0.36, 0.22), 0.9)
	_mesh(root, _cyl(0.06, 0.07, 0.5), wood, Vector3(0, 0.25, 0))
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.position = Vector3(0, 0.45, 0)
	root.add_child(pivot)
	_mesh(pivot, _cyl(0.05, 0.05, 1.2), wood, Vector3(0, 0.6, 0))
	_mesh(pivot, _cyl(0.2, 0.24, 0.75), straw, Vector3(0, 0.75, 0))
	_mesh(pivot, _cyl(0.04, 0.04, 1.0), wood, Vector3(0, 1.0, 0), Vector3(0, 0, 90))
	for side in [-1.0, 1.0]:
		_mesh(pivot, _cyl(0.07, 0.06, 0.28), straw, Vector3(side * 0.38, 1.0, 0), Vector3(0, 0, 90))
	for y in [0.48, 1.02]:
		_mesh(pivot, _cyl(0.245, 0.245, 0.04), rope, Vector3(0, y, 0))
	var head := SphereMesh.new()
	head.radius = 0.16
	head.height = 0.34
	_mesh(pivot, head, sack, Vector3(0, 1.32, 0))
	for mi in pivot.get_children():
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_solid(root, "Mannequin_collision", 0.28, 1.75)
	root.setup(self, "mannequin", 0.3, 1.2)


# =================================================================== jarres

func _jar_mesh() -> ArrayMesh:
	if _mats.has("jar_mesh"):
		return _mats["jar_mesh"]
	# Profil tourné (hauteur, rayon) : pied, panse, épaule, col, lèvre.
	var profile := [Vector2(0.0, 0.0), Vector2(0.0, 0.13), Vector2(0.06, 0.2), Vector2(0.22, 0.27), Vector2(0.38, 0.25),
		Vector2(0.5, 0.17), Vector2(0.56, 0.11), Vector2(0.6, 0.12), Vector2(0.62, 0.13), Vector2(0.62, 0.1)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 24
	for k in range(profile.size() - 1):
		for s in range(seg):
			var a0: float = TAU * s / seg
			var a1: float = TAU * (s + 1) / seg
			var p0: Vector2 = profile[k]
			var p1: Vector2 = profile[k + 1]
			var v00 := Vector3(cos(a0) * p0.y, p0.x, sin(a0) * p0.y)
			var v01 := Vector3(cos(a1) * p0.y, p0.x, sin(a1) * p0.y)
			var v10 := Vector3(cos(a0) * p1.y, p1.x, sin(a0) * p1.y)
			var v11 := Vector3(cos(a1) * p1.y, p1.x, sin(a1) * p1.y)
			st.add_vertex(v00); st.add_vertex(v10); st.add_vertex(v11)
			st.add_vertex(v00); st.add_vertex(v11); st.add_vertex(v01)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_mats["jar_mesh"] = mesh
	return mesh


func _make_jar(i: int, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Jarre_v28_%d" % i
	root.set_script(preload("res://scripts/target_v28.gd"))
	add_child(root)
	root.global_position = at
	root.rotation.y = i * 1.3
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	root.add_child(pivot)
	var terra := _mat("terre_cuite", Color(0.66, 0.36, 0.22), 0.8)
	var mi := _mesh(pivot, _jar_mesh(), terra, Vector3.ZERO)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var band := _mesh(pivot, _cyl(0.272, 0.272, 0.03, 24), _mat("frise", Color(0.42, 0.22, 0.13)), Vector3(0, 0.33, 0))
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid(root, "Jarre_collision", 0.26, 0.62)
	root.setup(self, "jarre", 0.28, 0.35)


## Appelé par une jarre brisée.
func jar_broken(jar: Node3D) -> void:
	var at: Vector3 = jar.global_position
	for k in range(9):
		var shard := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(randf_range(0.06, 0.14), 0.02, randf_range(0.05, 0.12))
		shard.mesh = b
		shard.material_override = _mat("terre_cuite", Color(0.66, 0.36, 0.22), 0.8)
		add_child(shard)
		shard.global_position = at + Vector3(0, 0.3, 0)
		var a: float = randf() * TAU
		_shards.append({"node": shard, "vel": Vector3(cos(a) * randf_range(1.2, 2.6), randf_range(1.5, 3.2), sin(a) * randf_range(1.2, 2.6)), "spin": Vector3(randf(), randf(), randf()) * 9.0, "life": 0.0, "ground": main._height_at(at.x, at.z)})
	# Butin : souvent une pièce, parfois un fruit.
	if inventory != null:
		var roll: float = randf()
		var id: String = "piece" if roll < 0.6 else ("pomme" if roll < 0.85 else "baies")
		var n: int = randi_range(1, 3) if id == "piece" else 1
		inventory.drop_counter += 1
		var spot: Vector3 = at + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
		spot.y = main._height_at(spot.x, spot.z)
		inventory.spawn_pickup("butin_%d" % inventory.drop_counter, id, n, spot)


# =================================================================== frapper

## Coup porté par le héros PC : toutes les cibles dans l'arc devant lui.
func strike(origin: Vector3, facing: Vector3, reach: float, damage: int) -> int:
	var hits: int = 0
	facing.y = 0.0
	facing = facing.normalized()
	for t in get_tree().get_nodes_in_group("cibles_v28"):
		var target: Node3D = t as Node3D
		if not target.is_hittable():
			continue
		var c: Vector3 = target.global_position + Vector3.UP * float(target.hit_height)
		var off: Vector3 = c - origin
		if absf(off.y) > 1.4:
			continue
		off.y = 0.0
		var d: float = off.length() - float(target.hit_radius)
		if d > reach:
			continue
		if d > 0.25 and facing.dot(off.normalized()) < 0.35:
			continue
		var snd: String = impact_sound(target)
		target.take_hit(damage, origin)
		_impact(snd, c)
		hits += 1
	return hits


## Coup en VR : un point (poing ou lame) qui passe vite à travers une cible.
func strike_point(point: Vector3, radius: float, damage: int, from_pos: Vector3) -> int:
	var hits: int = 0
	for t in get_tree().get_nodes_in_group("cibles_v28"):
		var target: Node3D = t as Node3D
		if not target.is_hittable():
			continue
		var base: Vector3 = target.global_position
		var top_y: float = base.y + float(target.hit_height) * 2.0 + 0.2
		if point.y < base.y - 0.1 or point.y > top_y:
			continue
		if Vector2(point.x - base.x, point.z - base.z).length() <= float(target.hit_radius) + radius:
			var snd: String = impact_sound(target)
			target.take_hit(damage, from_pos)
			_impact(snd, point)
			hits += 1
	return hits


## V50 : le bruit d'un coup selon ce qu'on frappe (chair, carapace, pierre, bois, jarre).
func impact_sound(target: Node) -> String:
	var file: String = str(target.get_script().resource_path.get_file()) if target.get_script() != null else ""
	if file == "arbre_v34.gd":
		return ""                 # l'arbre a son propre bruit (la hache)
	var k: String = str(target.get("kind")) if target.get("kind") != null else ""
	match k:
		"jarre":
			return "jarre_casse"
		"mannequin":
			return "touche_bois"
		"golem":
			return "touche_pierre"
		"crabe", "gardien", "araignee":
			return "touche_carapace"
	if file == "boss_crabe_v37.gd":
		return "touche_carapace"
	if file == "naga_v40.gd":
		return "touche_lourd"
	return "touche_chair"


func _impact(snd: String, at: Vector3) -> void:
	if snd != "" and main != null and main.has_method("sfx"):
		main.sfx(snd, at, 2.0 if critical else 0.0)


## Mains VR : vitesse de chaque main ; au-delà de 2,2 m/s, la main frappe ce qu'elle traverse.
## points : {nom: [position monde, rayon, dégâts, position dans l'espace du joueur]}
## La vitesse se mesure dans l'espace du joueur : marcher au joystick ne frappe pas.
func vr_tick(delta: float, points: Dictionary, head: Vector3) -> void:
	for key in points:
		var p: Vector3 = points[key][0]
		var local_p: Vector3 = points[key][3]
		var prev: Vector3 = _vr_prev.get(key, local_p)
		_vr_prev[key] = local_p
		_vr_cool[key] = maxf(float(_vr_cool.get(key, 0.0)) - delta, 0.0)
		var speed: float = local_p.distance_to(prev) / maxf(delta, 0.001)
		if speed > 2.2 and float(_vr_cool[key]) <= 0.0:
			if strike_point(p, float(points[key][1]), int(points[key][2]), head) > 0:
				_vr_cool[key] = 0.35


# =================================================================== effets

func damage_number(at: Vector3, value: int) -> void:
	var lbl := Label3D.new()
	lbl.text = str(value)
	lbl.font_size = 64
	lbl.pixel_size = 0.004
	lbl.outline_size = 14
	lbl.modulate = Color(1.0, 0.92, 0.5)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	add_child(lbl)
	lbl.global_position = at + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
	_floaters.append({"node": lbl, "life": 0.0})


## V34 : petit texte qui monte (« Toc ! », « Critique ! », messages en VR).
func float_text(at: Vector3, text: String, color: Color = Color(1, 1, 1)) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 44 if text.length() < 16 else 30
	lbl.pixel_size = 0.0035 if text.length() < 16 else 0.0022
	lbl.width = 700
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.outline_size = 12
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	add_child(lbl)
	lbl.global_position = at
	_floaters.append({"node": lbl, "life": -0.8 if text.length() >= 16 else 0.0})


## V34 : chiffre de dégâts d'une autre couleur (coup critique, coup de grâce…).
func damage_number_color(at: Vector3, value: int, color: Color, suffix: String = "") -> void:
	damage_number(at, value)
	var f: Dictionary = _floaters[_floaters.size() - 1]
	(f["node"] as Label3D).modulate = color
	(f["node"] as Label3D).text = str(value) + suffix


func puff(at: Vector3, color: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 18
	p.lifetime = 0.7
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := BoxMesh.new()
	q.size = Vector3(0.05, 0.01, 0.02)
	q.material = _mat("puff_" + color.to_html(), color, 0.9)
	p.mesh = q
	add_child(p)
	p.global_position = at
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _process(delta: float) -> void:
	for i in range(_floaters.size() - 1, -1, -1):
		var f: Dictionary = _floaters[i]
		f["life"] = float(f["life"]) + delta
		var lbl: Label3D = f["node"]
		lbl.global_position += Vector3.UP * delta * 0.9
		lbl.modulate.a = clampf(1.2 - float(f["life"]) * 1.4, 0.0, 1.0)
		if float(f["life"]) > 0.9:
			lbl.queue_free()
			_floaters.remove_at(i)
	for i in range(_shards.size() - 1, -1, -1):
		var s: Dictionary = _shards[i]
		s["life"] = float(s["life"]) + delta
		var node: MeshInstance3D = s["node"]
		var v: Vector3 = s["vel"]
		if node.global_position.y > float(s["ground"]) + 0.01:
			v.y -= 14.0 * delta
			node.global_position += v * delta
			node.rotation += (s["spin"] as Vector3) * delta
			s["vel"] = v
		else:
			node.global_position.y = float(s["ground"]) + 0.01
		if float(s["life"]) > 4.0:
			node.scale = Vector3.ONE * clampf(5.0 - float(s["life"]), 0.0, 1.0)
		if float(s["life"]) > 5.0:
			node.queue_free()
			_shards.remove_at(i)

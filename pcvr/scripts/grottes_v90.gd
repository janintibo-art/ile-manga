extends Node3D
## V90 : les grottes du Clan, dans la face est des Falaises (l'Île Pixelithique). Deux entrées au-dessus
## du Campement ; dedans, en petits cubes comme tout le reste :
##   la Grande Grotte du Clan     le feu du soir, les lits de fourrure, un dormeur qui ronfle, les os,
##                                le tambour de Boum, les mains peintes des enfants ;
##   la Grotte aux Peintures      l'atelier d'Ocre : les murs couverts de peintures (la chasse, les
##                                Long-Cous, Corne-Sur-Nez, Grosse-Dent, le Mont Fumant, les mains) ;
##                                plus tard, le portrait du héros (tout rond !) et sa victoire.
## Comme les maisons (V81), une grotte est construite loin sous la mer quand on entre, et démontée
## quand on sort ; le fond de la grotte, c'est la lumière du jour (on ressort par là).

const Vox = preload("res://scripts/vox_v90.gd")
const IleScript = preload("res://scripts/ile_pixel_v90.gd")
const Caverne = preload("res://scripts/pnj/caverne_v90.gd")
const STAGE := Vector3(6600.0, -260.0, 6000.0)
const NOMS := {"clan": "la Grande Grotte du Clan", "peintures": "la Grotte aux Peintures"}
## Les peintures de la Grotte aux Peintures : [image, angle (degrés, 0 = fond, - : gauche), hauteur]
const MURS := [["chasse", -62.0, 2.0], ["longcou", -95.0, 1.9], ["cornes", -128.0, 2.1], ["grosse_dent", 62.0, 2.0],
	["volcan", 95.0, 1.9], ["mains", 128.0, 2.0], ["lisse", -20.0, 2.2], ["victoire", 20.0, 2.2]]

var main: Node
var pixel: Node                         # pixel_v90 (son état est sauvegardé avec l'île)
var inside: bool = false
var busy: bool = false
var cur: String = ""
var root: Node3D
var _its: Array = []
var _entrees: Dictionary = {}           # id -> {"at", "out"}
var _lights: Array = []
var _t: float = 0.0


func setup(main_node: Node, pixel_node: Node) -> void:
	main = main_node
	pixel = pixel_node
	name = "Grottes_v90"
	# les entrées, contre la falaise
	for g in pixel.GROTTES:
		var id: String = str(g[0])
		var z: float = float(g[1])
		var x: float = IleScript.FALAISE_X + 0.9
		var w: Vector3 = IleScript.W(x, z)
		w.y = pixel.ile.height(w.x + 2.0, w.z)
		Vox.objet(pixel, "entree_grotte", w + Vector3(-0.6, 0.0, 0.0), PI * 0.5)
		_entrees[id] = {"at": w + Vector3(1.6, 0.0, 0.0), "out": Vector3(1, 0, 0)}
		pixel.objets["grotte_" + id] = w + Vector3(2.0, 0, 0)


func register(d: Node) -> void:
	for id in _entrees:
		var e: Dictionary = _entrees[id]
		d._interactions.append({"id": "pixel_grotte_" + str(id), "pos": e["at"], "radius": 2.2,
			"text": "E : entrer dans " + str(NOMS[id]), "vr": "Gâchette : entrer dans " + str(NOMS[id]), "call": enter.bind(str(id)),
			"when": func(): return not inside})


func contains(p: Vector3) -> bool:
	return inside and p.distance_to(STAGE) < 45.0


func place_name(_p: Vector3) -> String:
	return "L'Île Pixelithique, " + str(NOMS.get(cur, "une grotte"))


func respawn_point() -> Array:
	return [STAGE + Vector3(0, 0.15, 7.0), Vector3(0, 0, -1)]


func outside() -> Array:
	var e: Dictionary = _entrees.get(cur, _entrees.get("clan", {}))
	if e.is_empty():
		return pixel.respawn_point()
	var at: Vector3 = e["at"]
	at.y = pixel.ile.height(at.x, at.z) + 0.1
	return [at, e["out"]]


func say(text: String, seconds: float = 6.0) -> void:
	pixel.say(text, seconds)


# =================================================================== entrer, sortir

func enter(id: String) -> void:
	if busy or inside:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	dj._busy = true
	main.sfx("pas_pierre")
	await dj._fade_to(1.0, 0.45)
	cur = id
	_build()
	var at: Array = respawn_point()
	main.place_player_v35(at[0], at[1])
	inside = true
	dj.update_inside(true)
	await get_tree().create_timer(0.3).timeout
	await dj._fade_to(0.0, 0.6)
	dj._busy = false
	busy = false
	var first: bool = not bool(pixel.state.get("grotte_" + id, false))
	pixel.state["grotte_" + id] = true
	if first:
		if id == "clan":
			main._show_message_v28("La Grande Grotte du Clan — ça sent la fumée, la fourrure et la galette de fougère")
		else:
			main._show_message_v28("La Grotte aux Peintures — des bêtes rouges et ocre courent sur les murs")


func leave() -> void:
	if busy or not inside:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	if main.dialogue_v31 != null and main.dialogue_v31.opened:
		main._close_dialogue_v31()
	dj._busy = true
	await dj._fade_to(1.0, 0.45)
	var out: Array = outside()
	teardown()
	main.place_player_v35(out[0], out[1])
	dj.update_inside(true)
	await get_tree().create_timer(0.25).timeout
	await dj._fade_to(0.0, 0.6)
	dj._busy = false
	busy = false


func teardown() -> void:
	var dj: Node = main.get("donjon_v35") if main != null else null
	if dj != null:
		for it in _its:
			dj._interactions.erase(it)
	_its.clear()
	_lights.clear()
	if root != null and is_instance_valid(root):
		root.queue_free()
	root = null
	inside = false


## La grotte a changé (un portrait, une victoire) : on la refait si l'on est dedans.
func refresh() -> void:
	if inside and cur == "peintures":
		_build()


func _act(id: String, pos: Vector3, text: String, cb: Callable, radius: float = 1.8) -> void:
	var it := {"id": id, "pos": pos, "radius": radius, "text": "E : " + text, "vr": "Gâchette : " + text, "call": cb}
	main.get("donjon_v35")._interactions.append(it)
	_its.append(it)


# =================================================================== construction

func _build() -> void:
	var keep: bool = inside
	teardown()
	inside = keep
	root = Node3D.new()
	root.name = "Grotte_" + cur
	add_child(root)
	root.global_position = STAGE
	var mi := MeshInstance3D.new()
	mi.name = "Roche"
	mi.mesh = Vox.mesh("grotte_" + cur)
	mi.material_override = Vox.material()
	root.add_child(mi)
	if mi.mesh != null:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		root.add_child(sb)
		var cs := CollisionShape3D.new()
		var shape: ConcavePolygonShape3D = mi.mesh.create_trimesh_shape()
		shape.backface_collision = true
		cs.shape = shape
		sb.add_child(cs)
	# le fond du tunnel : la lumière du jour (on ressort par là)
	var day := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.2, 3.0)
	day.mesh = qm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(1.0, 0.97, 0.88)
	day.material_override = dm
	root.add_child(day)
	day.position = Vector3(0, 1.4, 9.35 if cur == "clan" else 9.75)
	day.rotation.y = PI
	var sun := OmniLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.6
	sun.omni_range = 9.0
	root.add_child(sun)
	sun.position = Vector3(0, 1.8, 8.0)
	_act("pixel_grotte_sortie", STAGE + Vector3(0, 0, 8.2), "sortir de la grotte", func(): leave(), 1.8)
	if cur == "clan":
		_clan()
	else:
		_peintures()


func _torche(at: Vector3, c: Color = Color(1.0, 0.62, 0.3), e: float = 1.6) -> void:
	var stick := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.04
	cm.height = 0.7
	stick.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.32, 0.22, 0.14)
	stick.material_override = sm
	root.add_child(stick)
	stick.position = at
	stick.rotation.z = 0.25
	var fl := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.22, 0.16)
	fl.mesh = bm
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.75, 0.3)
	fl.material_override = fm
	root.add_child(fl)
	fl.position = at + Vector3(-0.08, 0.42, 0)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = 8.0
	root.add_child(l)
	l.position = at + Vector3(0, 0.6, 0.3)
	_lights.append(l)


func _clan() -> void:
	var f: Vector3 = STAGE + Vector3(0, 0, -1.5)
	Vox.objet(root, "feu", f)
	var fl: GPUParticles3D = pixel._flammes(f, 1.0)
	fl.reparent(root)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.28)
	l.light_energy = 2.6
	l.omni_range = 16.0
	l.shadow_enabled = true
	root.add_child(l)
	l.position = Vector3(0, 1.2, -1.5)
	_lights.append(l)
	for e in [[-6.0, -4.0, 0.4], [6.2, -3.0, 2.7], [-3.0, -6.4, 0.0], [3.6, -6.0, 0.2], [-8.2, -4.0, 1.4], [7.8, 3.5, 2.0]]:
		Vox.objet(root, "peau", STAGE + Vector3(float(e[0]), 0.02, float(e[1])), float(e[2]))
	Vox.objet(root, "tambour", STAGE + Vector3(4.0, 0.0, 1.0), 0.0)
	for k in range(5):
		Vox.objet(root, "os", STAGE + Vector3(randf_range(-6, 6), 0.02, randf_range(-6, 3)), randf() * TAU)
	var dormeur: Node3D = Caverne.spawn(root, main, "grok", "Grok", STAGE + Vector3(-8.0, 0.05, -4.0), Vector3(1, 0, 0), "dormir")
	dormeur.lines = ["Zzz… raptor… Zzz…", "Rrrrr… pfff… Rrrrr…", "Zzz… Grok plus rapide… Zzz…"]
	dormeur.line_every = Vector2(4.0, 7.0)
	dormeur.follow = false
	_torche(STAGE + Vector3(-7.5, 1.4, 2.5))
	_torche(STAGE + Vector3(7.0, 1.4, -3.5))
	# les mains peintes des enfants, près de l'entrée
	_peinture("mains", STAGE + Vector3(-4.6, 2.1, 4.6), Vector3(0.75, 0, -0.65), 1.4)


func _peintures() -> void:
	var c := Vector3(0, 1.0, -4.0)
	var r := Vector3(6.5, 4.4, 9.0)
	for m in MURS:
		var nm: String = str(m[0])
		if nm == "lisse" and not bool(pixel.state.get("portrait", false)):
			continue
		if nm == "victoire" and not bool(pixel.state.get("trex", false)):
			continue
		var a: float = deg_to_rad(float(m[1]))
		var y: float = float(m[2])
		var k: float = sqrt(maxf(0.05, 1.0 - pow((y - c.y) / r.y, 2.0)))
		var d := Vector3(sin(a), 0, -cos(a))
		var p: Vector3 = c + Vector3(d.x * r.x * k, y - c.y, d.z * r.z * k)
		p.y = y
		var n: Vector3 = Vector3(-p.x / (r.x * r.x), 0, -(p.z - c.z) / (r.z * r.z)).normalized()
		_peinture(nm, STAGE + p + n * 0.55, n, 2.6 if nm in ["lisse", "victoire"] else 2.2)
	for e in [[-4.5, -9.0], [4.5, -9.0], [-5.0, 1.0], [5.0, 1.0]]:
		_torche(STAGE + Vector3(float(e[0]), 1.4, float(e[1])), Color(1.0, 0.62, 0.3), 2.2)
	# la lueur des braises au milieu (Ocre peint tard le soir)
	var mid := OmniLight3D.new()
	mid.light_color = Color(1.0, 0.7, 0.45)
	mid.light_energy = 1.2
	mid.omni_range = 15.0
	root.add_child(mid)
	mid.position = Vector3(0, 3.0, -4.0)
	# les pots de couleur d'Ocre
	for k in range(4):
		var pot := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.16
		cm.bottom_radius = 0.12
		cm.height = 0.24
		pot.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = [Color(0.77, 0.42, 0.18), Color(0.63, 0.17, 0.12), Color(0.12, 0.1, 0.09), Color(0.92, 0.89, 0.8)][k]
		pm.roughness = 0.9
		pot.material_override = pm
		root.add_child(pot)
		pot.position = Vector3(-1.2 + k * 0.5, 0.12, -10.5)
	if bool(pixel.state.get("portrait", false)):
		_act("pixel_portrait", STAGE + Vector3(0, 0, -11.0), "regarder ton portrait", func(): say("C'est toi. En carré. Ocre a mis du jaune autour de ta tête : « Toi brille, parce que toi lisse. » Les petits bonshommes autour lèvent les bras. Ils ont l'air très impressionnés.", 8.0), 2.4)


## Une peinture (pixel art, sans flou) posée contre la roche, face à n.
func _peinture(nm: String, at: Vector3, n: Vector3, w: float) -> void:
	var path: String = "res://assets/textures/pixel90/peinture_%s.png" % nm
	if not ResourceLoader.exists(path):
		return
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, w * 40.0 / 64.0)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 0.95
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.3
	mi.material_override = m
	root.add_child(mi)
	mi.global_position = at
	mi.look_at(at + n, Vector3.UP)
	mi.rotate_object_local(Vector3.UP, PI)


func _process(delta: float) -> void:
	if not inside or root == null:
		return
	_t += delta
	for i in range(_lights.size()):
		var l: OmniLight3D = _lights[i]
		if is_instance_valid(l):
			l.light_energy = (2.4 if i == 0 and cur == "clan" else 1.5) + 0.35 * sin(_t * 11.0 + i * 2.0) * sin(_t * 6.3 + i)
	var p: Vector3 = main._player_pos_v27()
	if p.distance_to(STAGE) > 400.0:
		teardown()

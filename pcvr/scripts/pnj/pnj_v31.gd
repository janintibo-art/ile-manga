extends Node3D
## V31 : un habitant de l'île (corps, déplacements, gestes) piloté par le cerveau commun.
## Chaque personnage = ce script + une fiche de personnalité (scripts/pnj/<nom>_v31.gd).
##  - Il va et vient entre quelques points (cabane, terrasse, feu, rivage).
##  - Il interpelle le joueur qui approche, se tourne vers lui, parle avec des gestes.
##  - Il fait partie des cibles de combat : le frapper le fâche… et il s'en souvient.

const Brain = preload("res://scripts/pnj/pnj_brain_v31.gd")
const HeroLib = preload("res://scripts/hero_v28.gd")
const WALK: float = 0.9
const TALK_REACH: float = 2.8

var main: Node
var brain
var profile: Dictionary
var display_name: String = ""
var model: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var floor_offset: float = 0.0
var points: Dictionary = {}
var links: Dictionary = {}
var at_point: String = ""
var route: Array = []
var state: String = "repos"          # repos, marche, parle
var idle_clock: float = 3.0
var gesture_clock: float = 0.0
var bubble: Label3D
var bubble_clock: float = 0.0
var vr_label: Label3D
var called_clock: float = 0.0
var player_was_near: bool = false
var parrot: Node3D
var _parrot_clock: float = 0.0
var _body: AnimatableBody3D
var current_anim: String = ""
# Cible de combat
var hit_radius: float = 0.35
var hit_height: float = 1.0
# V42 : les villageois du Bois-Doré dorment (ni animation ni pensée) quand on est loin.
var sleep_far: float = 0.0
var staff_node: Node3D
var _asleep: bool = false
var face_at: Dictionary = {}          # point -> où regarder quand il s'y repose
var chat_hold: float = 0.0            # bavardage en cours : il reste sur place
static var _npc_bodies: Array[RID] = []


func setup(main_node: Node, profile_data: Dictionary, spots: Dictionary, graph: Dictionary, start: String) -> void:
	main = main_node
	profile = profile_data
	display_name = str(profile.get("nom", "?"))
	name = "PNJ_" + str(profile.get("id", "x"))
	brain = Brain.new()
	brain.setup(profile)
	points = spots
	links = graph
	at_point = start
	_build_body()
	global_position = points[start]
	_snap_to_floor()
	add_to_group("cibles_v28")
	add_to_group("pnj_v31")


# =================================================================== corps

func _build_body() -> void:
	var packed: PackedScene = load("res://assets/models/characters/hero.glb")
	model = packed.instantiate()
	add_child(model)
	model.rotation.y = 0.0
	anim = model.find_child("AnimationPlayer", true, false)
	var found := model.find_children("*", "Skeleton3D", true, false)
	skel = found[0] if found.size() > 0 else null
	# Même bibliothèque d'animations que le héros (poses construites + clips du modèle).
	if anim != null and skel != null:
		var lib = HeroLib.new()
		lib.hero = model
		lib.anim = anim
		lib.skel = skel
		lib._build_animations()
		lib.free()
		for clip in ["Talk_with_Right_Hand_Open", "Stand_and_Drink"]:
			var a: Animation = anim.get_animation(clip)
			if a != null:
				a.loop_mode = Animation.LOOP_LINEAR
	# Teint hâlé de naufragé : le modèle tire ses couleurs de son émission (texture
	# multipliée par la couleur d'émission), c'est donc elle qu'on réchauffe.
	# V33 : chaque fiche peut donner sa teinte ([r, g, b]) ; par défaut, le hâle de Barnabé.
	var tint: Array = profile.get("teinte", [0.95, 0.62, 0.42])
	var tint_c := Color(float(tint[0]), float(tint[1]), float(tint[2]))
	# V41 : les elfes ont leur propre texture (peau claire, vêtements de forêt).
	var skin_tex: Texture2D = null
	var elf: Dictionary = profile.get("elfe", {})
	if not elf.is_empty() and ResourceLoader.exists(str(elf.get("texture", ""))):
		skin_tex = load(str(elf["texture"]))
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in range(m.mesh.get_surface_count()):
			var src: Material = m.mesh.surface_get_material(s)
			if src is StandardMaterial3D:
				var tinted: StandardMaterial3D = (src as StandardMaterial3D).duplicate()
				tinted.albedo_color = Color(tint_c.r, tint_c.g * 0.97, tint_c.b * 0.95)
				tinted.emission = tint_c
				if skin_tex != null:
					tinted.albedo_texture = skin_tex
					tinted.emission_texture = skin_tex
				m.set_surface_override_material(s, tinted)
	# Pieds au sol : décalage mesuré sur la boîte du modèle.
	floor_offset = 0.0
	if skel != null:
		_accessories()
	# V42 : la taille (une enfant elfe : 0,72).
	var size_k: float = float(profile.get("elfe", {}).get("taille", 1.0))
	if absf(size_k - 1.0) > 0.01:
		model.scale = Vector3.ONE * size_k
	_body = AnimatableBody3D.new()
	_body.name = "Corps_collision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	_body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_body.add_child(cs)
	add_child(_body)
	_npc_bodies.append(_body.get_rid())
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 38
	bubble.pixel_size = 0.0028
	bubble.outline_size = 12
	bubble.width = 620
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.position = Vector3(0, 2.35 - (1.0 - size_k) * 1.8, 0)
	bubble.no_depth_test = true
	bubble.visible = false
	add_child(bubble)
	vr_label = Label3D.new()
	vr_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vr_label.font_size = 40
	vr_label.pixel_size = 0.0024
	vr_label.outline_size = 10
	vr_label.position = Vector3(0, 2.0 - (1.0 - size_k) * 1.8, 0)
	vr_label.no_depth_test = true
	vr_label.text = "Gâchette droite : parler à " + display_name.split(" ")[0]
	vr_label.visible = false
	add_child(vr_label)


## Accroche un objet à un os ; offset et orientation donnés dans le repère du personnage
## au repos (cm, X gauche, Y haut, Z avant), objet fabriqué en mètres.
func _attach(bone_name: String, offset_cm: Vector3, node: Node3D, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var b: int = skel.find_bone(bone_name)
	if b < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone_name
	skel.add_child(att)
	var rest: Basis = skel.get_bone_global_rest(b).basis.orthonormalized()
	var holder := Node3D.new()
	holder.transform = Transform3D(rest.inverse() * Basis.from_euler(rot_deg * (PI / 180.0)) * Basis.from_scale(Vector3.ONE * 100.0), rest.inverse() * offset_cm)
	att.add_child(holder)
	holder.add_child(node)


## Accessoires : un peu d'émission, comme le modèle du personnage, pour garder les
## mêmes couleurs que lui sous la lumière bleutée du ciel.
func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.35
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _box_mesh_np(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 18
	return c


func _accessories() -> void:
	# V33 : la tenue dépend du personnage.
	if str(profile.get("id", "")) == "octave":
		_accessories_octave()
		return
	if profile.has("elfe"):
		_accessories_elfe()
		return
	# Chapeau de paille cabossé.
	var hat := Node3D.new()
	var straw := _mat(Color(0.96, 0.7, 0.36), 0.95)
	_part(hat, _cyl(0.36, 0.38, 0.025), straw, Vector3.ZERO)
	_part(hat, _cyl(0.17, 0.21, 0.17), straw, Vector3(0, 0.09, 0))
	_part(hat, _cyl(0.212, 0.212, 0.04), _mat(Color(0.55, 0.12, 0.1)), Vector3(0, 0.035, 0))
	_attach("Head", Vector3(0, 41.0, 1.0), hat, Vector3(-8, 0, 6))
	# Longue barbe grise.
	var beard := Node3D.new()
	var white := _mat(Color(0.95, 0.93, 0.86), 1.0)
	_part(beard, _sphere(0.11), white, Vector3(0, -0.02, 0), Vector3(1.5, 0.7, 0.55))
	_part(beard, _sphere(0.1), white, Vector3(0, -0.15, 0.01), Vector3(1.05, 1.75, 0.45))
	_attach("Head", Vector3(0, -3.0, 15.0), beard, Vector3(6, 0, 0))
	# Gaston, le perroquet, sur l'épaule gauche.
	parrot = Node3D.new()
	var red := _mat(Color(0.82, 0.12, 0.08), 0.6)
	var blue := _mat(Color(0.1, 0.3, 0.75), 0.6)
	var yellow := _mat(Color(0.95, 0.75, 0.15), 0.5)
	_part(parrot, _sphere(0.07), red, Vector3(0, 0.1, 0), Vector3(0.95, 1.35, 1.0))
	for sx in [-1.0, 1.0]:
		_part(parrot, _sphere(0.055), blue, Vector3(sx * 0.055, 0.1, -0.01), Vector3(0.45, 1.3, 1.05), Vector3(0, 0, sx * 10))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.2, 0.015)
	parrot.add_child(head)
	_part(head, _sphere(0.05), red, Vector3.ZERO)
	_part(head, _cyl(0.0, 0.02, 0.055), yellow, Vector3(0, -0.01, 0.055), Vector3.ONE, Vector3(100, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.012), _mat(Color(0.95, 0.95, 0.9), 0.3), Vector3(sx * 0.035, 0.012, 0.03))
	_part(parrot, _cyl(0.035, 0.008, 0.22), blue, Vector3(0, -0.02, -0.07), Vector3.ONE, Vector3(-30, 0, 0))
	_part(parrot, _cyl(0.008, 0.008, 0.05), _mat(Color(0.3, 0.3, 0.3)), Vector3(0.02, 0.0, 0.01))
	_part(parrot, _cyl(0.008, 0.008, 0.05), _mat(Color(0.3, 0.3, 0.3)), Vector3(-0.02, 0.0, 0.01))
	_attach("LeftShoulder", Vector3(13.0, 9.0, -1.0), parrot)


## V41 : silhouette d'elfe — longue chevelure (qui cache la coupe du modèle), oreilles en
## pointe, diadème, longue robe, cape légère et ceinture. Couleurs données par la fiche.
func _accessories_elfe() -> void:
	var elf: Dictionary = profile["elfe"]
	var c_hair: Array = elf.get("cheveux", [0.96, 0.9, 0.72])
	var c_robe: Array = elf.get("robe", [0.16, 0.42, 0.32])
	var c_cape: Array = elf.get("cape", [0.86, 0.9, 0.82])
	var c_jewel: Array = elf.get("bijou", [0.85, 0.88, 0.9])
	var hair := _mat(Color(float(c_hair[0]), float(c_hair[1]), float(c_hair[2])), 0.55)
	var robe := _mat(Color(float(c_robe[0]), float(c_robe[1]), float(c_robe[2])), 0.75)
	var cape := _mat(Color(float(c_cape[0]), float(c_cape[1]), float(c_cape[2])), 0.85)
	var jewel := _mat(Color(float(c_jewel[0]), float(c_jewel[1]), float(c_jewel[2])), 0.25)
	var gem := _mat(Color(0.3, 0.95, 0.6), 0.1)
	gem.emission_energy_multiplier = 1.5
	var tint: Array = profile.get("teinte", [1.0, 0.92, 0.86])
	var skin := _mat(Color(float(tint[0]), float(tint[1]) * 0.94, float(tint[2]) * 0.9), 0.6)
	# Un nouveau visage par-dessus celui du modèle : grands yeux en amande, sourcils fins,
	# petit nez, sourire léger, joues rosées.
	var face := Node3D.new()
	var R: float = 0.228
	_part(face, _sphere(R), skin, Vector3.ZERO)
	var white := _mat(Color(0.98, 0.98, 0.97), 0.3)
	var iris := _mat(Color(float(elf.get("yeux", [0.25, 0.7, 0.5])[0]), float(elf.get("yeux", [0.25, 0.7, 0.5])[1]), float(elf.get("yeux", [0.25, 0.7, 0.5])[2])), 0.2)
	var dark := _mat(Color(0.08, 0.06, 0.06), 0.4)
	dark.emission_energy_multiplier = 0.05
	var shine := _mat(Color(1, 1, 1), 0.1)
	shine.emission_energy_multiplier = 1.5
	var lips := _mat(Color(0.86, 0.45, 0.48), 0.5)
	var blush := _mat(Color(1.0, 0.7, 0.7), 0.8)
	blush.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blush.albedo_color.a = 0.45
	var brow_mat := _mat(Color(float(c_hair[0]) * 0.75, float(c_hair[1]) * 0.7, float(c_hair[2]) * 0.6), 0.7)
	var on_face := func(x: float, y: float, lift: float) -> Vector3:
		return Vector3(x, y, sqrt(maxf(R * R - x * x - y * y, 0.0)) + lift)
	for sx in [-1.0, 1.0]:
		var ex: float = sx * 0.072
		_part(face, _sphere(0.046), white, on_face.call(ex, 0.005, -0.012), Vector3(1.0, 1.25, 0.4))
		_part(face, _sphere(0.033), iris, on_face.call(ex, 0.0, -0.004), Vector3(1.0, 1.2, 0.35))
		_part(face, _sphere(0.017), dark, on_face.call(ex, -0.002, 0.002), Vector3(1.0, 1.2, 0.35))
		_part(face, _sphere(0.009), shine, on_face.call(ex + sx * -0.012, 0.016, 0.006))
		_part(face, _box_mesh_np(Vector3(0.1, 0.012, 0.012)), dark, on_face.call(ex, 0.058, -0.002), Vector3.ONE, Vector3(0, sx * -18.0, sx * -8.0))
		_part(face, _box_mesh_np(Vector3(0.075, 0.01, 0.012)), brow_mat, on_face.call(ex, 0.098, -0.003), Vector3.ONE, Vector3(0, sx * -18.0, sx * 6.0))
		_part(face, _sphere(0.03), blush, on_face.call(sx * 0.11, -0.05, -0.008), Vector3(1.3, 0.8, 0.3))
	_part(face, _sphere(0.011), skin, on_face.call(0.0, -0.035, 0.0), Vector3(0.9, 1.0, 1.0))
	for sx in [-1.0, 1.0]:
		_part(face, _box_mesh_np(Vector3(0.026, 0.008, 0.01)), lips, on_face.call(sx * 0.011, -0.078, -0.002), Vector3.ONE, Vector3(0, sx * -10.0, sx * 14.0))
	_attach("Head", Vector3(0, 18.0, 2.5), face)
	var fringe := Node3D.new()
	_part(fringe, _sphere(0.2), hair, Vector3.ZERO, Vector3(1.15, 0.4, 0.78))
	_attach("Head", Vector3(0, 35.0, 10.0), fringe, Vector3(-20, 0, 0))
	# Chevelure : un volume sur le crâne, puis la coiffure (V42 : long, tresse, chignon, queue, court).
	var head_hair := Node3D.new()
	_part(head_hair, _sphere(0.26), hair, Vector3(0, 0.0, 0.0), Vector3(1.16, 1.06, 0.98))
	var style: String = str(elf.get("coiffure", "long"))
	match style:
		"tresse":
			# Une longue natte dans le dos, nouée d'un ruban, et deux petites mèches.
			for k in range(9):
				var f: float = float(k) / 8.0
				var r: float = lerpf(0.075, 0.045, f)
				_part(head_hair, _sphere(r), hair, Vector3(sin(f * 7.0) * 0.012, -0.12 - f * 0.62, -0.25 - f * 0.05), Vector3(1.0, 1.25, 0.9), Vector3(0, 0, 18.0 if k % 2 == 0 else -18.0))
			_part(head_hair, _cyl(0.035, 0.045, 0.06), jewel, Vector3(0, -0.8, -0.3))
			_part(head_hair, _sphere(0.05), hair, Vector3(0, -0.88, -0.3), Vector3(0.9, 1.4, 0.7))
			for sx in [-1.0, 1.0]:
				_part(head_hair, _sphere(0.06), hair, Vector3(sx * 0.21, -0.12, 0.08), Vector3(0.55, 1.6, 0.6), Vector3(0, 0, sx * 6))
		"chignon":
			# Un chignon haut piqué d'une épingle, la nuque dégagée.
			_part(head_hair, _sphere(0.12), hair, Vector3(0, 0.16, -0.17), Vector3(1.0, 0.9, 0.9))
			_part(head_hair, _cyl(0.008, 0.008, 0.3), jewel, Vector3(0, 0.18, -0.17), Vector3.ONE, Vector3(0, 0, 70))
			_part(head_hair, _sphere(0.02), gem, Vector3(0.15, 0.24, -0.17))
			for sx in [-1.0, 1.0]:
				_part(head_hair, _sphere(0.05), hair, Vector3(sx * 0.215, -0.1, 0.09), Vector3(0.5, 1.5, 0.6), Vector3(0, 0, sx * 4))
		"queue":
			# Queue de cheval haute, tenue par un anneau.
			_part(head_hair, _cyl(0.05, 0.05, 0.05), jewel, Vector3(0, 0.08, -0.26), Vector3.ONE, Vector3(-60, 0, 0))
			for k in range(6):
				var f2: float = float(k) / 5.0
				_part(head_hair, _sphere(lerpf(0.08, 0.04, f2)), hair, Vector3(0, 0.02 - f2 * 0.5, -0.32 - sin(f2 * 1.6) * 0.06), Vector3(1.0, 1.7, 0.85), Vector3(-10, 0, 0))
		"court":
			# Cheveux courts : un casque de mèches, la nuque couverte.
			_part(head_hair, _sphere(0.2), hair, Vector3(0, -0.1, -0.12), Vector3(1.15, 0.85, 0.8))
			for sx in [-1.0, 1.0]:
				_part(head_hair, _sphere(0.07), hair, Vector3(sx * 0.21, -0.06, 0.04), Vector3(0.45, 1.0, 0.8))
		_:
			# Long rideau dans le dos et deux longues mèches devant.
			_part(head_hair, _sphere(0.2), hair, Vector3(0, -0.34, -0.1), Vector3(1.05, 2.1, 0.42), Vector3(8, 0, 0))
			for sx in [-1.0, 1.0]:
				_part(head_hair, _sphere(0.08), hair, Vector3(sx * 0.2, -0.2, 0.08), Vector3(0.55, 2.3, 0.6), Vector3(0, 0, sx * 6))
	_attach("Head", Vector3(0, 30.0, -7.0), head_hair)
	# Oreilles en pointe
	for sx in [-1.0, 1.0]:
		var ear := Node3D.new()
		_part(ear, _cyl(0.0, 0.035, 0.17), skin, Vector3(0, 0.07, 0))
		_attach("Head", Vector3(sx * 22.5, 19.0, 3.0), ear, Vector3(-12, 0, sx * -62))
	# Diadème d'argent et sa pierre verte
	var circlet := Node3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.205
	tm.outer_radius = 0.222
	tm.rings = 24
	tm.ring_segments = 6
	_part(circlet, tm, jewel, Vector3.ZERO)
	_part(circlet, _sphere(0.025), gem, Vector3(0, 0.0, 0.215), Vector3(1.0, 1.3, 0.6))
	_attach("Head", Vector3(0, 26.0, 1.0), circlet, Vector3(-12, 0, 0))
	# Corsage, longue robe évasée, ceinture
	var bodice := Node3D.new()
	_part(bodice, _sphere(0.21), robe, Vector3.ZERO, Vector3(1.0, 1.05, 0.78))
	_attach("Spine02", Vector3(0, 0.0, 2.0), bodice)
	var skirt := Node3D.new()
	if str(elf.get("silhouette", "robe")) == "tunique":
		# V42 : tunique courte à mi-cuisse, galon brodé (les jambes restent libres).
		_part(skirt, _cyl(0.2, 0.3, 0.36), robe, Vector3(0, -0.17, 0))
		_part(skirt, _cyl(0.302, 0.31, 0.04), jewel, Vector3(0, -0.34, 0))
	else:
		_part(skirt, _cyl(0.2, 0.4, 0.8), robe, Vector3(0, -0.4, 0))
		_part(skirt, _cyl(0.405, 0.42, 0.06), jewel, Vector3(0, -0.78, 0))
	_attach("Hips", Vector3(0, 4.0, 0.0), skirt)
	var belt := Node3D.new()
	var bm := TorusMesh.new()
	bm.inner_radius = 0.18
	bm.outer_radius = 0.21
	_part(belt, bm, jewel, Vector3.ZERO)
	_attach("Hips", Vector3(0, 6.0, 0.0), belt)
	# Cape légère sur les épaules
	var mantle := Node3D.new()
	_part(mantle, _sphere(0.22), cape, Vector3(0, -0.25, 0), Vector3(1.3, 2.4, 0.14))
	_attach("Spine02", Vector3(0, 6.0, -13.0), mantle, Vector3(-6, 0, 0))
	# V42 : l'arc et le carquois dans le dos (Thalion), le bâton de l'Ancien (Faelar).
	if bool(elf.get("arc", false)):
		var wood := _mat(Color(0.5, 0.34, 0.2), 0.6)
		var bow := Node3D.new()
		var n_seg: int = 10
		for k in range(n_seg):
			var a0: float = lerpf(-1.05, 1.05, float(k) / n_seg)
			var a1: float = lerpf(-1.05, 1.05, float(k + 1) / n_seg)
			# L'arc est porté à plat contre le dos : sa courbe se voit de derrière.
			var p0 := Vector3((1.0 - cos(a0)) * 0.3, sin(a0) * 0.62, 0.0)
			var p1 := Vector3((1.0 - cos(a1)) * 0.3, sin(a1) * 0.62, 0.0)
			var mid: Vector3 = (p0 + p1) * 0.5
			var seg: Vector3 = p1 - p0
			_part(bow, _cyl(0.016, 0.018, seg.length() + 0.01), wood, mid, Vector3.ONE, Vector3(0, 0, -rad_to_deg(atan2(seg.x, seg.y))))
		var tip_y: float = sin(1.05) * 0.62
		var tip_x: float = (1.0 - cos(1.05)) * 0.3
		_part(bow, _cyl(0.003, 0.003, tip_y * 2.0), _mat(Color(0.9, 0.88, 0.8), 0.9), Vector3(tip_x, 0, 0))
		_attach("Spine02", Vector3(-2.0, 2.0, -21.0), bow, Vector3(0, 0, 28))
		var quiver := Node3D.new()
		_part(quiver, _cyl(0.06, 0.05, 0.5), _mat(Color(0.4, 0.26, 0.15), 0.85), Vector3.ZERO)
		_part(quiver, _cyl(0.062, 0.062, 0.03), jewel, Vector3(0, 0.2, 0))
		for k in range(5):
			var ox: float = (k - 2) * 0.022
			_part(quiver, _cyl(0.004, 0.004, 0.18), wood, Vector3(ox, 0.32, (k % 2) * 0.02 - 0.01))
			_part(quiver, _box_mesh_np(Vector3(0.002, 0.06, 0.03)), _mat(Color(0.95, 0.95, 0.92), 0.9), Vector3(ox, 0.38, (k % 2) * 0.02 - 0.01))
		_attach("Spine02", Vector3(-6.0, 4.0, -18.0), quiver, Vector3(0, 0, -25))
	if bool(elf.get("baton", false)):
		var staff := Node3D.new()
		var oak := _mat(Color(0.42, 0.3, 0.2), 0.85)
		_part(staff, _cyl(0.02, 0.026, 1.75), oak, Vector3(0, 0.0, 0))
		_part(staff, _sphere(0.05), oak, Vector3(0, 0.88, 0), Vector3(1.2, 0.8, 1.2))
		var orb := _mat(Color(0.75, 1.0, 0.85), 0.1)
		orb.emission_energy_multiplier = 2.0
		_part(staff, _sphere(0.045), orb, Vector3(0, 0.96, 0))
		for k in range(4):
			var aa: float = TAU * k / 4.0
			_part(staff, _cyl(0.006, 0.01, 0.16), oak, Vector3(cos(aa) * 0.04, 0.96, sin(aa) * 0.04), Vector3.ONE, Vector3(sin(aa) * 25.0, 0, -cos(aa) * 25.0))
		# Planté à côté de lui, à portée de la main droite (tenu à la main, il traverserait
		# le corps dans les poses bras croisés).
		staff_node = staff
		model.add_child(staff)
		staff.position = Vector3(-0.42, 0.86, 0.16)
		staff.rotation_degrees = Vector3(4, 0, 5)


## V33 : Octave Taillefer — lunettes de forge sur le front, grosse moustache, tablier de
## cuir, marteau à la ceinture, et Clou, son ouistiti, sur l'épaule droite.
func _accessories_octave() -> void:
	var leather := _mat(Color(0.36, 0.22, 0.12), 0.85)
	var brass := _mat(Color(0.75, 0.58, 0.25), 0.35)
	var glass := _mat(Color(0.35, 0.55, 0.5), 0.15)
	# Lunettes de forge relevées sur le front
	var goggles := Node3D.new()
	for sx in [-1.0, 1.0]:
		_part(goggles, _cyl(0.05, 0.05, 0.035), brass, Vector3(sx * 0.062, 0, 0), Vector3.ONE, Vector3(90, 0, 0))
		_part(goggles, _cyl(0.04, 0.04, 0.04), glass, Vector3(sx * 0.062, 0, 0.003), Vector3.ONE, Vector3(90, 0, 0))
	_part(goggles, _cyl(0.012, 0.012, 0.03), brass, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, 90))
	_attach("Head", Vector3(0, 29.0, 18.0), goggles, Vector3(-28, 0, 0))
	# Moustache broussailleuse poivre et sel
	var stache := Node3D.new()
	var grey := _mat(Color(0.55, 0.5, 0.46), 1.0)
	for sx in [-1.0, 1.0]:
		_part(stache, _sphere(0.055), grey, Vector3(sx * 0.055, 0, 0), Vector3(1.5, 0.55, 0.7), Vector3(0, 0, sx * -18))
	_attach("Head", Vector3(0, 9.0, 19.0), stache, Vector3(5, 0, 0))
	# Tablier de cuir (bavette sur la poitrine, pan sur les cuisses)
	var bib := Node3D.new()
	_part(bib, _sphere(0.2), leather, Vector3.ZERO, Vector3(0.95, 1.0, 0.12))
	_attach("Spine02", Vector3(0, 2.0, 13.0), bib)
	var skirt := Node3D.new()
	_part(skirt, _sphere(0.22), leather, Vector3.ZERO, Vector3(0.95, 1.25, 0.1))
	_attach("Hips", Vector3(0, -14.0, 13.0), skirt, Vector3(8, 0, 0))
	# Marteau à la ceinture
	var hammer := Node3D.new()
	_part(hammer, _cyl(0.014, 0.016, 0.3), _mat(Color(0.5, 0.34, 0.2), 0.8), Vector3.ZERO)
	_part(hammer, _cyl(0.03, 0.03, 0.12), _mat(Color(0.3, 0.3, 0.32), 0.4), Vector3(0, -0.15, 0), Vector3.ONE, Vector3(0, 0, 90))
	_attach("Hips", Vector3(-17.0, -2.0, 4.0), hammer, Vector3(0, 0, 8))
	# Clou, le ouistiti, assis sur l'épaule droite (sa tête bouge, comme Gaston)
	parrot = Node3D.new()
	var fur := _mat(Color(0.42, 0.3, 0.2), 1.0)
	var face := _mat(Color(0.85, 0.72, 0.58), 0.9)
	_part(parrot, _sphere(0.07), fur, Vector3(0, 0.08, 0), Vector3(1.0, 1.25, 0.95))
	for sx in [-1.0, 1.0]:
		_part(parrot, _cyl(0.018, 0.016, 0.1), fur, Vector3(sx * 0.05, 0.0, 0.04), Vector3.ONE, Vector3(-70, 0, 0))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.19, 0.01)
	parrot.add_child(head)
	_part(head, _sphere(0.055), fur, Vector3.ZERO)
	_part(head, _sphere(0.038), face, Vector3(0, -0.005, 0.03), Vector3(1.0, 0.9, 0.6))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.022), face, Vector3(sx * 0.055, 0.01, 0), Vector3(0.5, 1.0, 1.0))
		_part(head, _sphere(0.009), _mat(Color(0.05, 0.04, 0.03), 0.2), Vector3(sx * 0.016, 0.01, 0.058))
	# Longue queue enroulée
	for k in range(6):
		var t: float = float(k) / 5.0
		_part(parrot, _sphere(0.016), fur, Vector3(-0.02 - t * 0.04, -0.02 - t * 0.2 + sin(t * 3.0) * 0.03, -0.06 - sin(t * 2.5) * 0.06))
	_attach("RightShoulder", Vector3(-13.0, 9.0, -1.0), parrot)


# =================================================================== sol et déplacement

func _snap_to_floor() -> void:
	var p: Vector3 = global_position
	var space := get_world_3d().direct_space_state
	# V42 : les rayons ignorent tous les habitants (on ne grimpe pas sur la tête d'un voisin).
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 3.0, 1, _npc_bodies)
	var hit := space.intersect_ray(q)
	var y: float
	if not hit.is_empty():
		y = hit.position.y
	else:
		# V42 : entre deux planches d'une passerelle, le rayon passe dans la fente : on garde
		# la hauteur (on ne tombe au sol que si l'on était déjà presque au sol).
		var g: float = main._height_at(p.x, p.z)
		y = g if p.y - floor_offset - g < 1.5 else p.y - floor_offset
	global_position = Vector3(p.x, y + floor_offset, p.z)
	_body.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _face(dir: Vector3, delta: float, speed: float = 6.0) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * speed, 0.0, 1.0))


func _play(name_anim: String, blend: float = 0.25, speed: float = 1.0, from: float = -1.0) -> void:
	if anim == null or not anim.has_animation(name_anim):
		return
	if name_anim != current_anim or from >= 0.0:
		anim.play(name_anim, blend, speed)
		if from >= 0.0:
			anim.seek(from, true)
		current_anim = name_anim
	else:
		anim.play(name_anim, blend, speed)


## Chemin dans le graphe des points (parcours en largeur).
func _route_to(goal: String) -> Array:
	var prev := {at_point: ""}
	var queue: Array = [at_point]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == goal:
			break
		for nb in links.get(cur, []):
			if not prev.has(nb):
				prev[nb] = cur
				queue.append(nb)
	if not prev.has(goal):
		return []
	var path: Array = []
	var c: String = goal
	while c != at_point:
		path.push_front(c)
		c = prev[c]
	return path


# =================================================================== comportement

func _process(delta: float) -> void:
	if sleep_far > 0.0:
		var far: bool = global_position.distance_to(main._player_pos_v27()) > sleep_far
		if far != _asleep:
			_asleep = far
			model.visible = not far
			if anim != null:
				if far:
					if anim.is_playing():
						anim.pause()
				else:
					current_anim = ""          # l'animation repart au réveil (_idle_anim ou _walk)
		if far:
			return
	brain.tick(delta)
	_parrot_tick(delta)
	if bubble_clock > 0.0:
		bubble_clock -= delta
		bubble.modulate.a = clampf(bubble_clock, 0.0, 1.0)
		if bubble_clock <= 0.0:
			bubble.visible = false
	called_clock = maxf(called_clock - delta, 0.0)
	gesture_clock = maxf(gesture_clock - delta, 0.0)
	var player: Vector3 = main._player_pos_v27()
	var to_player: Vector3 = player - global_position
	var dist: float = Vector2(to_player.x, to_player.z).length()
	if vr_label != null:
		vr_label.visible = main.xr_active and state != "parle" and dist < TALK_REACH
	# Interpellation quand on arrive dans les parages.
	var near: bool = dist < 10.0 and absf(to_player.y) < 6.0
	if near and not player_was_near and called_clock <= 0.0 and state != "parle":
		# V42 : au village elfe, un seul habitant à la fois interpelle le joueur.
		var now: int = Time.get_ticks_msec()
		if sleep_far <= 0.0 or now - int(main.get_meta("pnj_appel_v42", -100000)) > 2500:
			var line: String = brain.call_out(main._npc_ctx_v31())
			if line != "":
				say_bubble(line, 4.5)
				if sleep_far > 0.0:
					main.set_meta("pnj_appel_v42", now)
		called_clock = 75.0
	player_was_near = near
	match state:
		"parle":
			_face(to_player, delta)
			if gesture_clock <= 0.0:
				_play("Talk_with_Right_Hand_Open", 0.3, 0.9)
		"marche":
			_walk(delta, dist)
		_:
			chat_hold = maxf(chat_hold - delta, 0.0)
			if dist < 4.0:
				_face(to_player, delta, 3.0)
			elif face_at.has(at_point) and chat_hold <= 0.0:
				_face(face_at[at_point] - global_position, delta, 2.0)
			if gesture_clock <= 0.0:
				_idle_anim()
			idle_clock -= delta
			if idle_clock <= 0.0 and dist > 3.0 and chat_hold <= 0.0:
				_pick_destination()


func _idle_anim() -> void:
	var fam: String = brain.humeur_famille()
	if fam == "joie" and randf() < 0.002:
		gesture("rire")
	elif randf() < 0.0015:
		_play("Stand_and_Drink", 0.4)
		gesture_clock = 8.0
	elif current_anim != "v28/idle" and current_anim != "Stand_and_Drink":
		_play("v28/idle", 0.4, 0.8 if fam in ["triste", "colere"] else 1.0)
	elif current_anim == "Stand_and_Drink" and gesture_clock <= 0.0:
		_play("v28/idle", 0.4)


func _pick_destination() -> void:
	var options: Array = points.keys().filter(func(k): return k != at_point and k != "marche")
	if options.is_empty():
		idle_clock = 6.0
		return
	route = _route_to(options[randi() % options.size()])
	if route.is_empty():
		idle_clock = 6.0
		return
	state = "marche"


func _walk(delta: float, player_dist: float) -> void:
	if player_dist < 2.4 or route.is_empty():
		state = "repos"
		idle_clock = randf_range(5.0, 11.0)
		return
	var goal: Vector3 = points[route[0]]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.15:
		at_point = route.pop_front()
		if route.is_empty():
			state = "repos"
			idle_clock = randf_range(6.0, 14.0)
		return
	_face(to_goal, delta, 5.0)
	var step: Vector3 = to_goal.normalized() * minf(WALK * delta, to_goal.length())
	global_position += step
	_snap_to_floor()
	_play("Walking", 0.3, WALK / 1.0)


func gesture(kind: String) -> void:
	match kind:
		"salut":
			_play("Formal_Bow", 0.2, 1.3, 0.4)
			gesture_clock = 2.4
		"rire":
			_play("Motivational_Cheer", 0.2, 1.1, 0.6)
			gesture_clock = 2.8
		"colere":
			_play("v28/hurt", 0.1, 0.7, 0.0)
			gesture_clock = 0.8
		_:
			gesture_clock = 0.0


func say_bubble(text: String, seconds: float) -> void:
	bubble.text = text
	bubble.visible = true
	bubble.modulate.a = 1.0
	bubble_clock = seconds


func begin_talk() -> void:
	state = "parle"
	route.clear()
	bubble.visible = false
	bubble_clock = 0.0


func end_talk() -> void:
	state = "repos"
	idle_clock = randf_range(4.0, 8.0)
	gesture_clock = 0.0


func _parrot_tick(delta: float) -> void:
	if parrot == null:
		return
	_parrot_clock += delta
	var head: Node3D = parrot.get_node_or_null("Tete")
	if head != null:
		head.rotation.y = sin(_parrot_clock * 1.7) * 0.6 + sin(_parrot_clock * 5.3) * 0.15
		head.rotation.x = sin(_parrot_clock * 2.3) * 0.15
	parrot.rotation.z = sin(_parrot_clock * 1.1) * 0.05


# =================================================================== combat

func is_hittable() -> bool:
	return true


func take_hit(_damage: int, from_pos: Vector3) -> void:
	var line: String = brain.hit(main._npc_ctx_v31())
	say_bubble(line, 3.5)
	gesture("colere")
	_face(from_pos - global_position, 1.0, 50.0)
	if state == "parle":
		main._close_dialogue_v31()


func serialize() -> Dictionary:
	return brain.serialize()


func load_data(d: Dictionary) -> void:
	brain.load_data(d)

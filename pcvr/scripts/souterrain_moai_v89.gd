extends Node3D
## V89 : sous le Grand Moaï, le souterrain mystique. On y descend quand on lui a rendu ses deux
## yeux de corail (moai_v87) : la dalle de son ventre s'enfonce, un escalier tourne dans un puits
## rond autour d'un pilier gravé, et l'on arrive dans un couloir qui serpente (les quatre
## fresques sur leurs stèles : chacune dit un vers de l'histoire du monde) jusqu'à la Salle du
## Chant : une grande caverne en dôme, des veines de lumière dans la roche, des cristaux, des vers
## luisants au plafond et, au milieu, une vasque d'eau qui dort.
##   Énigme 1 : les quatre pierres gravées autour de la vasque (le Soleil, l'Homme-Oiseau, les
##              Poissons, la Tortue), à toucher dans l'ordre des fresques. La vasque s'éveille, et
##              avec elle l'Écho, la voix des pierres (un petit Moaï de lumière).
##   Énigme 2 : l'Écho chante sur les cinq Pierres-qui-Chantent ; on répète ses chansons
##              (trois, de plus en plus longues). La dalle du fond s'enfonce.
##   Le Cœur du Chant : la petite salle ronde du trésor (un coffre, des pièces d'or, l'Ancêtre de
##              corail), et un courant d'air qui remonte à la surface.
## Pas de combat. Tout est construit loin sous la mer (STAGE), comme les maisons (V81), quand on
## descend, et démonté quand on remonte. La roche vient de tools/generate_souterrain_v89.py.

const Statue = preload("res://scripts/moai_statue_v87.gd")
const Corps = preload("res://scripts/pnj/corps_v64.gd")
const BIN := "res://assets/models/moai89/grotte.bin"
const ROCHE_SHADER := "res://shaders/grotte_v89.gdshader"
const STAGE := Vector3(6000.0, -260.0, 6700.0)

## Le puits et son escalier (repère du souterrain : sol du puits à y = 0, z vers la salle)
const TOP_Y: float = 15.0
const TH0: float = PI
const TURNS: float = 1.5
const R_IN: float = 0.95
const R_OUT: float = 4.6
const N_STEPS: int = 60
## Le couloir (même ligne que l'outil), la salle, la vasque, la dalle, le Cœur du Chant
const COULOIR := [Vector3(0.0, 0.0, 2.0), Vector3(1.5, -0.3, 10.0), Vector3(-1.8, -1.0, 18.0), Vector3(-0.5, -1.8, 26.0),
	Vector3(1.5, -2.5, 33.0), Vector3(0.5, -3.0, 40.0), Vector3(0.0, -3.0, 46.0)]
const SALLE := Vector3(0.0, -3.0, 58.0)
const VASQUE_R: float = 4.6
const DALLE_Z: float = 76.0
const COEUR := Vector3(0.0, -3.0, 85.5)

## Les quatre fresques : l'ordre du monde (la bonne réponse), et leurs vers.
const ORDRE := ["soleil", "oiseau", "poissons", "tortue"]
const NOMS := {"soleil": "le Soleil", "oiseau": "l'Homme-Oiseau", "poissons": "les Poissons", "tortue": "la Tortue"}
const VERS := {
	"soleil": "« Au commencement, l'Œil du Soleil s'ouvrit sur la grande eau, et la mer fut chaude. »",
	"oiseau": "« Alors l'Homme-Oiseau s'envola, le deuxième, pour chercher la terre au-delà des vagues. »",
	"poissons": "« Les Poissons, les troisièmes, dansèrent dans son ombre pour lui montrer le chemin. »",
	"tortue": "« Et la Tortue, la dernière, porta les Anciens jusqu'au rivage. Quand les quatre parlent dans cet ordre, la pierre écoute. »",
}
## Dans le couloir, les stèles ne sont pas dans l'ordre : [fresque, segment, position sur le segment, côté]
const STELES := [["tortue", 0, 0.75, 1.0], ["soleil", 1, 0.55, -1.0], ["poissons", 2, 0.6, 1.0], ["oiseau", 3, 0.6, -1.0]]
## Autour de la vasque, de gauche à droite (vu du couloir) : pas dans l'ordre non plus
const SOCLES := [["poissons", -142.0], ["soleil", -164.0], ["tortue", 164.0], ["oiseau", 142.0]]
## Les cinq Pierres-qui-Chantent (au fond de la salle) : [angle, couleur]
const PIERRES := [[-52.0, Color(1.0, 0.45, 0.38)], [-26.0, Color(1.0, 0.72, 0.3)], [0.0, Color(0.45, 1.0, 0.55)],
	[26.0, Color(0.3, 0.9, 1.0)], [52.0, Color(0.7, 0.5, 1.0)]]
## Les trois chansons de l'Écho
const CHANSONS := [[2, 0, 4], [1, 3, 0, 2], [4, 2, 3, 1, 0]]
const TRESOR := [["caillou_chantant", 1], ["perle_lumiere", 1], ["corail_rouge", 2], ["piece_or", 3], ["piece", 80]]

var main: Node
var moai: Node                          # moai_v87 (son état est sauvegardé avec l'île)
var inside: bool = false
var busy: bool = false
var root: Node3D
var visits: int = 0
var _its: Array = []
var _rock_mat: ShaderMaterial
var _socles: Dictionary = {}            # fresque -> {"glow": material, "light": OmniLight3D}
var _pierres: Array = []                # {"node", "mat", "light", "pos"}
var _entree: Array = []                 # fresques touchées (énigme 1)
var _vasque_light: OmniLight3D
var _vasque_mat: ShaderMaterial
var _echo: Node3D
var _echo_light: OmniLight3D
var _dalle: Node3D
var _coffre_hinge: Node3D
var _chant_round: int = -1              # -1 : pas de partie ; sinon la chanson en cours
var _chant_pos: int = 0
var _chant_playing: bool = false
var _t: float = 0.0
var _data: Dictionary = {}


func setup(main_node: Node, moai_node: Node) -> void:
	main = main_node
	moai = moai_node
	name = "Souterrain_moai_v89"


func st() -> Dictionary:
	return moai.state


static func L(x: float, y: float, z: float) -> Vector3:
	return STAGE + Vector3(x, y, z)


func contains(p: Vector3) -> bool:
	return inside and p.distance_to(STAGE + Vector3(0, 0, 45)) < 90.0


## Le nom des lieux d'en bas (pour le carnet).
func place_name(p: Vector3) -> String:
	var l: Vector3 = p - STAGE
	if l.z < 6.0:
		return "L'Île aux Moaïs, l'escalier du Grand Moaï"
	if l.z < 44.0:
		return "L'Île aux Moaïs, le couloir des fresques"
	if l.z > 77.0:
		return "L'Île aux Moaïs, le Cœur du Chant"
	return "L'Île aux Moaïs, la Salle du Chant"


## Où l'on arrive : sur le palier, en haut de l'escalier.
func arrive_point() -> Array:
	var a: float = TH0 - 0.55
	return [L(cos(a) * 2.7, TOP_Y + 0.15, sin(a) * 2.7), Vector3(-sin(a), 0, cos(a))]


## Évanoui en bas (on ne peut pas, mais au cas où : une chute) : au bout du couloir.
func respawn_point() -> Array:
	return [L(0.3, -2.85, 43.0), Vector3(0, 0, 1)]


# =================================================================== descendre, remonter

func enter() -> void:
	if busy or inside:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	dj._busy = true
	main.sfx("pierre_glisse")
	await dj._fade_to(1.0, 0.6)
	_build()
	var at: Array = arrive_point()
	main.place_player_v35(at[0], at[1])
	inside = true
	dj.update_inside(true)
	await get_tree().create_timer(0.4).timeout
	await dj._fade_to(0.0, 0.9)
	dj._busy = false
	busy = false
	visits += 1
	if not bool(st().get("souterrain", false)):
		st()["souterrain"] = true
		main._show_message_v28("Le souterrain du Grand Moaï — un escalier qui tourne et descend dans le noir… et, tout en bas, quelque chose qui chante")
		if main.has_method("jingle"):
			main.jingle("decouverte")


func leave(text: String = "") -> void:
	if busy or not inside:
		return
	busy = true
	var dj: Node = main.get("donjon_v35")
	if main.dialogue_v31 != null and main.dialogue_v31.opened:
		main._close_dialogue_v31()
	dj._busy = true
	main.sfx("pierre_glisse")
	await dj._fade_to(1.0, 0.6)
	var out: Array = moai.door_outside()
	teardown()
	main.place_player_v35(out[0], out[1])
	dj.update_inside(true)
	await get_tree().create_timer(0.3).timeout
	await dj._fade_to(0.0, 0.8)
	dj._busy = false
	busy = false
	if text != "":
		say(text, 6.0)


func teardown() -> void:
	var dj: Node = main.get("donjon_v35") if main != null else null
	if dj != null:
		for it in _its:
			dj._interactions.erase(it)
	_its.clear()
	if root != null and is_instance_valid(root):
		root.queue_free()
	root = null
	_echo = null
	_dalle = null
	_pierres.clear()
	_socles.clear()
	_entree.clear()
	_chant_round = -1
	_chant_playing = false
	inside = false


func say(text: String, seconds: float = 6.0) -> void:
	var d: Node = main.get("donjon_v35")
	if d != null and d.has_method("_say"):
		d._say(text, seconds)
	else:
		main._show_message_v28(text)


func _act(id: String, pos: Vector3, text: String, cb: Callable, radius: float = 1.6, when: Variant = null) -> Dictionary:
	var it := {"id": id, "pos": pos, "radius": radius, "text": "E : " + text, "vr": "Gâchette : " + text, "call": cb}
	if when != null:
		it["when"] = when
	main.get("donjon_v35")._interactions.append(it)
	_its.append(it)
	return it


# =================================================================== construction

func _build() -> void:
	teardown()
	var t0: int = Time.get_ticks_msec()
	root = Node3D.new()
	root.name = "Souterrain_v89"
	add_child(root)
	root.global_position = STAGE
	_data = Corps.read_bin(BIN)
	_rock()
	_escalier()
	_couloir()
	_salle()
	_coeur()
	_decor()
	print("ILE_MANGA_V89: le souterrain du Grand Moaï est prêt (%d ms)" % (Time.get_ticks_msec() - t0))


## La roche (le maillage taillé par l'outil) et sa collision.
func _rock() -> void:
	if _data.is_empty():
		push_warning("V89 : la roche du souterrain manque (" + BIN + ")")
		return
	_rock_mat = ShaderMaterial.new()
	_rock_mat.shader = load(ROCHE_SHADER)
	_rock_mat.set_shader_parameter("roche_tex", load("res://assets/textures/terrain/rock.jpg"))
	_rock_mat.set_shader_parameter("roche_n", load("res://assets/textures/terrain/rock_n.png"))
	_rock_mat.set_shader_parameter("sable_tex", load("res://assets/textures/terrain/sand.jpg"))
	_rock_mat.set_shader_parameter("sable_n", load("res://assets/textures/terrain/sand_n.png"))
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_CELLULAR
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fn.frequency = 0.012
	fn.seed = 89
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.generate_mipmaps = true
	nt.noise = fn
	_rock_mat.set_shader_parameter("fissures", nt)
	_rock_mat.set_shader_parameter("origine", STAGE)
	_rock_mat.set_shader_parameter("eveil", 1.0 if bool(st().get("chant", false)) else (0.45 if bool(st().get("fresques", false)) else 0.0))
	var sb := StaticBody3D.new()
	sb.name = "Roche_collision"
	sb.collision_layer = 1
	sb.collision_mask = 0
	root.add_child(sb)
	var k: int = 0
	for part in _data.get("parts", []):
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = part["v"]
		arr[Mesh.ARRAY_NORMAL] = part["n"]
		arr[Mesh.ARRAY_COLOR] = part["c"]
		arr[Mesh.ARRAY_INDEX] = part["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.name = "Roche_%d" % k
		mi.mesh = am
		mi.material_override = _rock_mat
		root.add_child(mi)
		var cs := CollisionShape3D.new()
		var shape: ConcavePolygonShape3D = am.create_trimesh_shape()
		shape.backface_collision = true
		cs.shape = shape
		sb.add_child(cs)
		k += 1


func _stone(key: String = "ahu", tint: Color = Color(0.62, 0.58, 0.55)) -> Material:
	return Statue.stone_mat(key, tint)


func _glow(c: Color, energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.roughness = 0.25
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _light(at: Vector3, c: Color, energy: float, rng: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.light_volumetric_fog_energy = 1.4
	root.add_child(l)
	l.position = at
	return l


func _box(at: Vector3, size: Vector3, mat: Material, collide: bool = true, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	root.add_child(mi)
	mi.position = at
	mi.rotation = rot
	if collide:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		mi.add_child(sb)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
	return mi


# ------------------------------------------------------------------- le puits et son escalier

static func ramp_y(th: float) -> float:
	var dth: float = TURNS * TAU / N_STEPS
	return clampf(TOP_Y - ((th - TH0) / dth - 0.5) * (TOP_Y / N_STEPS), 0.0, TOP_Y)


func _escalier() -> void:
	var dth: float = TURNS * TAU / N_STEPS
	var rise: float = TOP_Y / N_STEPS
	var stone: Material = _stone("pierre_moai", Color(0.62, 0.58, 0.54))
	# les marches : des coins de pierre posés en spirale autour du pilier
	var stl := SurfaceTool.new()
	stl.begin(Mesh.PRIMITIVE_TRIANGLES)
	stl.set_smooth_group(-1)
	for k in range(N_STEPS):
		var a0: float = TH0 + k * dth
		var a1: float = a0 + dth
		var y1: float = TOP_Y - k * rise
		_wedge(stl, a0, a1, y1 - 0.34, y1, R_IN, R_OUT)
	# le palier du haut
	_wedge(stl, TH0 - 1.35, TH0, TOP_Y - 0.5, TOP_Y, R_IN, R_OUT)
	stl.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Escalier"
	mi.mesh = stl.commit()
	mi.material_override = stone
	root.add_child(mi)
	# la collision : une rampe lisse qui passe au bord des marches (et le palier)
	var faces := PackedVector3Array()
	var a: float = TH0 - 1.35
	var da: float = 0.05
	while a < TH0 + TURNS * TAU + dth:
		var b: float = a + da
		var ya: float = TOP_Y if a < TH0 else ramp_y(a)
		var yb: float = TOP_Y if b < TH0 else ramp_y(b)
		var p0 := Vector3(cos(a) * R_IN, ya, sin(a) * R_IN)
		var p1 := Vector3(cos(a) * R_OUT, ya, sin(a) * R_OUT)
		var p2 := Vector3(cos(b) * R_OUT, yb, sin(b) * R_OUT)
		var p3 := Vector3(cos(b) * R_IN, yb, sin(b) * R_IN)
		faces.append_array([p0, p1, p2, p0, p2, p3])
		a = b
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	root.add_child(sb)
	var cs := CollisionShape3D.new()
	var cps := ConcavePolygonShape3D.new()
	cps.backface_collision = true
	cps.set_faces(faces)
	cs.shape = cps
	sb.add_child(cs)
	# le pilier gravé, et ses anneaux de signes qui luisent
	var pil := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = R_IN + 0.02
	cm.bottom_radius = R_IN + 0.12
	cm.height = 20.0
	cm.radial_segments = 32
	pil.mesh = cm
	pil.material_override = _stone("pierre_moai", Color(0.6, 0.57, 0.53))
	root.add_child(pil)
	pil.position = Vector3(0, 10.0, 0)
	var ps := StaticBody3D.new()
	ps.collision_layer = 1
	ps.collision_mask = 0
	pil.add_child(ps)
	var pcs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = R_IN + 0.08
	cyl.height = 20.0
	pcs.shape = cyl
	ps.add_child(pcs)
	var ring_mat: StandardMaterial3D = _glow(Color(0.3, 0.9, 0.95), 1.6)
	for hy in [2.5, 7.5, 12.5, 17.5]:
		for g in range(12):
			var ga: float = TAU * g / 12.0 + hy
			var gl := MeshInstance3D.new()
			var gb := BoxMesh.new()
			gb.size = Vector3(0.09, 0.32 if g % 3 == 0 else 0.18, 0.03)
			gl.mesh = gb
			gl.material_override = ring_mat
			root.add_child(gl)
			var rr: float = R_IN + 0.06 - (hy / 20.0) * 0.1
			gl.position = Vector3(cos(ga) * rr, hy, sin(ga) * rr)
			gl.rotation = Vector3(0, -ga + PI * 0.5, 0)
	# les lampes de corail le long du mur
	for j in range(5):
		var la: float = TH0 + 0.5 + j * (TURNS * TAU - 0.8) / 4.0
		var ly: float = ramp_y(la) + 2.3
		var lp := Vector3(cos(la) * 3.95, ly, sin(la) * 3.95)
		var coral := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.26
		coral.mesh = sm
		coral.material_override = _glow(Color(1.0, 0.5, 0.38), 3.0)
		root.add_child(coral)
		coral.position = lp
		var cup := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.2
		cc.bottom_radius = 0.06
		cc.height = 0.18
		cup.mesh = cc
		cup.material_override = stone
		root.add_child(cup)
		cup.position = lp + Vector3(0, -0.15, 0)
		_light(lp + Vector3(-cos(la), 0.1, -sin(la)) * 0.4, Color(1.0, 0.62, 0.45), 1.3, 7.0)
	# en haut : la lumière du jour, par la porte du Grand Moaï
	var da2: float = TH0 - 0.95
	var door := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.2, 3.4)
	door.mesh = qm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(1.0, 0.96, 0.86)
	door.material_override = dm
	root.add_child(door)
	door.position = Vector3(cos(da2) * 4.05, TOP_Y + 1.75, sin(da2) * 4.05)
	door.look_at(root.global_position + Vector3(0, TOP_Y + 1.75, 0), Vector3.UP)
	door.rotate_object_local(Vector3.UP, PI)
	var sun := SpotLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 4.0
	sun.spot_range = 16.0
	sun.spot_angle = 38.0
	sun.shadow_enabled = true
	sun.light_volumetric_fog_energy = 2.5
	root.add_child(sun)
	sun.position = Vector3(cos(da2) * 3.6, TOP_Y + 3.0, sin(da2) * 3.6)
	sun.look_at(root.global_position + Vector3(0, TOP_Y - 3.0, 0), Vector3.UP)
	_act("souterrain_remonter", L(cos(da2) * 3.2, TOP_Y, sin(da2) * 3.2), "remonter à la surface", func(): leave(), 1.9)


## Un coin de pierre (une marche) entre deux angles, deux hauteurs et deux rayons.
func _wedge(stl: SurfaceTool, a0: float, a1: float, y0: float, y1: float, r0: float, r1: float) -> void:
	var n: int = maxi(2, int(ceil((a1 - a0) / 0.08)))
	for i in range(n):
		var b0: float = a0 + (a1 - a0) * i / n
		var b1: float = a0 + (a1 - a0) * (i + 1) / n
		var i0 := Vector3(cos(b0) * r0, 0, sin(b0) * r0)
		var o0 := Vector3(cos(b0) * r1, 0, sin(b0) * r1)
		var i1 := Vector3(cos(b1) * r0, 0, sin(b1) * r0)
		var o1 := Vector3(cos(b1) * r1, 0, sin(b1) * r1)
		var up := Vector3(0, y1, 0)
		var dn := Vector3(0, y0, 0)
		_quad(stl, i0 + up, i1 + up, o1 + up, o0 + up)      # dessus
		_quad(stl, o0 + dn, o1 + dn, i1 + dn, i0 + dn)      # dessous
		_quad(stl, o0 + dn, o0 + up, o1 + up, o1 + dn)      # côté (dans le mur)
		_quad(stl, i1 + dn, i1 + up, i0 + up, i0 + dn)      # côté du pilier
	var a := Vector3(cos(a0), 0, sin(a0))
	var b := Vector3(cos(a1), 0, sin(a1))
	_quad(stl, a * r0 + Vector3(0, y0, 0), a * r0 + Vector3(0, y1, 0), a * r1 + Vector3(0, y1, 0), a * r1 + Vector3(0, y0, 0))
	_quad(stl, b * r1 + Vector3(0, y0, 0), b * r1 + Vector3(0, y1, 0), b * r0 + Vector3(0, y1, 0), b * r0 + Vector3(0, y0, 0))


## Un quadrilatère p0 p1 p2 p3 (dans le sens inverse des aiguilles d'une montre vu de devant) ; on
## l'écrit à l'envers : pour Godot, la face avant tourne dans le sens des aiguilles d'une montre.
func _quad(stl: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> void:
	for p in [p0, p2, p1, p0, p3, p2]:
		stl.set_uv(Vector2(p.x + p.z, p.y) * 0.5)
		stl.add_vertex(p)


# ------------------------------------------------------------------- le couloir des fresques

func _fresque_mat(id: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 lueur : source_color = vec3(0.3, 0.95, 0.9);
uniform float force = 1.2;
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float trait = smoothstep(0.08, 0.22, c.r - c.b) ;
	float respire = 0.75 + 0.25 * sin(TIME * 1.1 + UV.x * 2.0);
	ALBEDO = c * 0.8;
	ROUGHNESS = 0.9;
	EMISSION = lueur * trait * force * respire;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", load("res://assets/textures/moai/fresque_" + id + ".png"))
	return m


## Un point du couloir : segment k, position t ; renvoie [point au sol, direction du couloir].
static func couloir_at(k: int, t: float) -> Array:
	var a: Vector3 = COULOIR[k]
	var b: Vector3 = COULOIR[k + 1]
	var d: Vector3 = b - a
	d.y = 0.0
	return [a.lerp(b, t), d.normalized()]


func _couloir() -> void:
	for s in STELES:
		var id: String = str(s[0])
		var ct: Array = couloir_at(int(s[1]), float(s[2]))
		var c: Vector3 = ct[0]
		var dir: Vector3 = ct[1]
		var side: Vector3 = dir.cross(Vector3.UP).normalized() * float(s[3])
		var at: Vector3 = c + side * 1.45
		var face: Vector3 = -side
		var yaw: float = atan2(face.x, face.z)
		var stele := Node3D.new()
		stele.name = "Stele_" + id
		root.add_child(stele)
		stele.position = at
		stele.rotation = Vector3(0, yaw, 0)
		var slab := _box(Vector3.ZERO, Vector3(1.5, 2.5, 0.32), _stone("ahu", Color(0.72, 0.68, 0.62)), true)
		slab.reparent(stele, false)
		slab.position = Vector3(0, 1.25, 0)
		var base := _box(Vector3.ZERO, Vector3(1.8, 0.3, 0.6), _stone("ahu", Color(0.55, 0.52, 0.5)), false)
		base.reparent(stele, false)
		base.position = Vector3(0, 0.15, 0)
		var pic := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.2, 1.2)
		pic.mesh = qm
		pic.material_override = _fresque_mat(id)
		stele.add_child(pic)
		pic.position = Vector3(0, 1.45, 0.165)
		# une petite lampe de corail sur la stèle
		var coral := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.2
		coral.mesh = sm
		coral.material_override = _glow(Color(0.35, 0.95, 0.9), 3.0)
		stele.add_child(coral)
		coral.position = Vector3(0, 2.62, 0.0)
		var l: OmniLight3D = _light(Vector3.ZERO, Color(0.45, 0.95, 0.9), 1.1, 5.5)
		l.reparent(stele, false)
		l.position = Vector3(0, 2.7, 0.7)
		_act("souterrain_fresque_" + id, L(at.x, at.y, at.z) + face * 1.2, "lire la fresque", _lire.bind(id), 1.8)


func _lire(id: String) -> void:
	main.sfx("ui_ouvrir")
	say("Sous le dessin de " + str(NOMS[id]) + ", des signes gravés. Tu les déchiffres lentement : " + str(VERS[id]), 9.0)


# ------------------------------------------------------------------- la Salle du Chant

func _salle() -> void:
	var c: Vector3 = SALLE
	# la vasque : une eau qui dort, puis qui luit
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2((VASQUE_R + 0.35) * 2.2, (VASQUE_R + 0.35) * 2.2)
	pm.subdivide_width = 1
	pm.subdivide_depth = 1
	water.mesh = pm
	_vasque_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform float eveil = 0.0;
uniform float rayon = 4.9;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 a = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(a), h(a + vec2(1, 0)), f.x), mix(h(a + vec2(0, 1)), h(a + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 p = (UV - 0.5) * rayon * 2.2;
	float r = length(p);
	if (r > rayon) { discard; }
	float t = TIME * 0.35;
	float c1 = n(p * 1.7 + vec2(t, -t * 0.7));
	float c2 = n(p * 2.9 - vec2(t * 0.8, t * 0.5));
	float caust = pow(1.0 - abs(c1 - c2), 6.0);
	float ring = 0.5 + 0.5 * sin(r * 5.0 - TIME * 1.6);
	vec3 deep = vec3(0.02, 0.09, 0.11);
	vec3 glow = vec3(0.2, 0.95, 0.9);
	ALBEDO = deep;
	ROUGHNESS = 0.04;
	SPECULAR = 0.7;
	ALPHA = 0.82;
	float k = 0.18 + eveil * (0.55 + 0.35 * ring * (1.0 - r / rayon));
	EMISSION = glow * (caust * 0.9 + 0.25) * k;
	NORMAL_MAP = vec3(0.5 + (c1 - 0.5) * 0.15, 0.5 + (c2 - 0.5) * 0.15, 1.0);
}
"""
	_vasque_mat.shader = sh
	_vasque_mat.set_shader_parameter("rayon", VASQUE_R + 0.35)
	water.material_override = _vasque_mat
	root.add_child(water)
	water.position = c + Vector3(0, -0.16, 0)
	_vasque_light = _light(c + Vector3(0, 0.6, 0), Color(0.3, 0.95, 0.9), 0.5, 15.0, true)
	# trois lueurs hautes, très douces, qui dessinent le dôme (la roche, les stalactites)
	_light(c + Vector3(-8.0, 6.0, -5.0), Color(0.35, 0.8, 0.85), 0.7, 17.0)
	_light(c + Vector3(9.0, 7.0, 6.0), Color(0.55, 0.45, 0.95), 0.6, 17.0)
	_light(c + Vector3(0.0, 9.5, 2.0), Color(0.4, 0.75, 1.0), 0.5, 16.0)
	# les pierres du bord de la vasque
	var rim: Material = _stone("ahu", Color(0.5, 0.48, 0.47))
	for i in range(16):
		var a: float = TAU * i / 16.0 + 0.1
		var rp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.45
		sm.height = 0.6
		rp.mesh = sm
		rp.material_override = rim
		root.add_child(rp)
		rp.position = c + Vector3(cos(a) * (VASQUE_R + 0.45), -0.05, sin(a) * (VASQUE_R + 0.45))
		rp.scale = Vector3(1.0 + 0.4 * sin(i * 2.3), 0.7, 1.0 + 0.3 * cos(i * 1.7))
		rp.rotation.y = a
	# énigme 1 : les quatre pierres gravées
	var solved1: bool = bool(st().get("fresques", false))
	for s in SOCLES:
		var id: String = str(s[0])
		var a2: float = deg_to_rad(float(s[1]))
		var off := Vector3(sin(a2), 0, cos(a2))
		var at: Vector3 = c + off * 7.2
		var socle := Node3D.new()
		socle.name = "Socle_" + id
		root.add_child(socle)
		socle.position = at
		socle.rotation.y = atan2(off.x, off.z) + PI
		var col := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.42
		cm.bottom_radius = 0.55
		cm.height = 1.05
		cm.radial_segments = 8
		col.mesh = cm
		col.material_override = _stone("ahu", Color(0.66, 0.62, 0.58))
		socle.add_child(col)
		col.position = Vector3(0, 0.52, 0)
		var top := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = 0.06
		top.mesh = cyl
		var fm: ShaderMaterial = _fresque_mat(id)
		fm.set_shader_parameter("force", 2.6 if solved1 else 0.25)
		top.material_override = fm
		socle.add_child(top)
		top.position = Vector3(0, 1.08, 0)
		top.rotation = Vector3(deg_to_rad(-28.0), 0, 0)
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		socle.add_child(sb)
		var cs := CollisionShape3D.new()
		var cys := CylinderShape3D.new()
		cys.radius = 0.55
		cys.height = 1.1
		cs.shape = cys
		cs.position = Vector3(0, 0.55, 0)
		sb.add_child(cs)
		var l: OmniLight3D = _light(at + Vector3(0, 1.6, 0) + off * 0.5, Color(0.4, 0.95, 0.9), 0.9 if solved1 else 0.0, 4.0)
		_socles[id] = {"mat": fm, "light": l}
		_act("souterrain_socle_" + id, L(at.x, at.y, at.z) + off * 0.9, "toucher la pierre de " + str(NOMS[id]), _press.bind(id), 1.3,
			func(): return not bool(st().get("fresques", false)))
	# énigme 2 : les cinq Pierres-qui-Chantent
	for i in range(PIERRES.size()):
		var a3: float = deg_to_rad(float(PIERRES[i][0]))
		var off2 := Vector3(sin(a3), 0, cos(a3))
		var at2: Vector3 = c + off2 * 8.6
		var col2: Color = PIERRES[i][1]
		var men := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = 0.28
		cm2.bottom_radius = 0.6
		cm2.height = 2.6
		cm2.radial_segments = 7
		men.mesh = cm2
		men.material_override = _stone("pierre_moai", Color(0.62, 0.6, 0.58))
		root.add_child(men)
		men.position = at2 + Vector3(0, 1.25, 0)
		men.rotation = Vector3(0.05 * sin(i * 3.1), i * 0.9, 0.06 * cos(i * 2.2))
		var band := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.44
		tm.outer_radius = 0.5
		band.mesh = tm
		var bmat: StandardMaterial3D = _glow(col2, 0.4 if bool(st().get("fresques", false)) else 0.05)
		band.material_override = bmat
		men.add_child(band)
		band.position = Vector3(0, -0.15, 0)
		band.scale = Vector3(1.0, 1.0, 1.0)
		var rune := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(0.14, 0.7, 0.05)
		rune.mesh = rb
		rune.material_override = bmat
		men.add_child(rune)
		rune.position = Vector3(0, 0.55, 0.42)
		var sb2 := StaticBody3D.new()
		sb2.collision_layer = 1
		sb2.collision_mask = 0
		men.add_child(sb2)
		var cs2 := CollisionShape3D.new()
		var cys2 := CylinderShape3D.new()
		cys2.radius = 0.55
		cys2.height = 2.6
		cs2.shape = cys2
		sb2.add_child(cs2)
		var l2: OmniLight3D = _light(at2 + Vector3(0, 1.4, 0) - off2 * 0.9, col2, 0.0, 4.5)
		_pierres.append({"node": men, "mat": bmat, "light": l2, "pos": L(at2.x, at2.y, at2.z), "col": col2})
		_act("souterrain_pierre_%d" % i, L(at2.x, at2.y, at2.z) - off2 * 1.0, "faire chanter la pierre", _touch_pierre.bind(i), 1.25)
	# l'Écho (s'il est réveillé)
	if bool(st().get("fresques", false)):
		_spawn_echo(false)
		_set_vasque(1.0, 0.0)
	# la dalle du fond
	_dalle = Node3D.new()
	_dalle.name = "Dalle_du_Chant"
	root.add_child(_dalle)
	_dalle.position = Vector3(0, -3.0, DALLE_Z)
	var slab := _box(Vector3.ZERO, Vector3(4.8, 4.4, 0.7), _stone("ahu", Color(0.74, 0.7, 0.66)), true)
	slab.reparent(_dalle, false)
	slab.position = Vector3(0, 2.2, 0)
	var ring := MeshInstance3D.new()
	var tm2 := TorusMesh.new()
	tm2.inner_radius = 0.85
	tm2.outer_radius = 0.95
	ring.mesh = tm2
	ring.material_override = _glow(Color(0.3, 0.9, 0.95), 1.4)
	_dalle.add_child(ring)
	ring.position = Vector3(0, 2.3, -0.37)
	ring.rotation = Vector3(PI * 0.5, 0, 0)
	for k in range(5):
		var gl := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.1, 0.36, 0.04)
		gl.mesh = gb
		gl.material_override = _glow(PIERRES[k][1], 1.6)
		_dalle.add_child(gl)
		var ga: float = TAU * k / 5.0 + PI * 0.5
		gl.position = Vector3(cos(ga) * 0.55, 2.3 + sin(ga) * 0.55, -0.37)
		gl.rotation = Vector3(0, 0, ga + PI * 0.5)
	if bool(st().get("chant", false)):
		_dalle.position.y = -7.6


func _set_vasque(eveil: float, seconds: float) -> void:
	if _vasque_mat == null:
		return
	if seconds <= 0.0:
		_vasque_mat.set_shader_parameter("eveil", eveil)
		_vasque_light.light_energy = 0.5 + 2.6 * eveil
		return
	var tw := root.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(v): _vasque_mat.set_shader_parameter("eveil", v), 0.0, eveil, seconds)
	tw.tween_property(_vasque_light, "light_energy", 0.5 + 2.6 * eveil, seconds)


func _veines(v: float, seconds: float) -> void:
	if _rock_mat == null:
		return
	var from: float = float(_rock_mat.get_shader_parameter("eveil"))
	var tw := root.create_tween()
	tw.tween_method(func(x): _rock_mat.set_shader_parameter("eveil", x), from, v, seconds)


## Énigme 1 : toucher les pierres gravées dans l'ordre du monde.
func _press(id: String) -> void:
	if bool(st().get("fresques", false)) or id in _entree:
		return
	_entree.append(id)
	var k: int = _entree.size() - 1
	var e: Dictionary = _socles[id]
	(e["mat"] as ShaderMaterial).set_shader_parameter("force", 2.6)
	(e["light"] as OmniLight3D).light_energy = 1.0
	main.sfx("chant_%d" % [1, 2, 3, 4][k], e["light"].global_position)
	if str(ORDRE[k]) != id:
		# pas le bon ordre : tout s'éteint, doucement
		await get_tree().create_timer(0.9).timeout
		if root == null:
			return
		main.sfx("pierre_glisse", L(SALLE.x, SALLE.y, SALLE.z))
		for k2 in _socles:
			(_socles[k2]["mat"] as ShaderMaterial).set_shader_parameter("force", 0.25)
			(_socles[k2]["light"] as OmniLight3D).light_energy = 0.0
		_entree.clear()
		say(["La vasque frémit… puis se tait. Ce n'est pas l'ordre du monde.", "Les pierres s'éteignent une à une. Les fresques du couloir racontent peut-être l'histoire dans le bon ordre…",
			"Rien. Juste l'écho de ta propre main sur la pierre. Au commencement, il y avait…"][randi() % 3], 6.0)
		return
	if _entree.size() < ORDRE.size():
		return
	# les quatre, dans l'ordre : la vasque s'éveille
	st()["fresques"] = true
	await get_tree().create_timer(0.8).timeout
	if root == null:
		return
	main.sfx("sceau_eveil", L(SALLE.x, SALLE.y, SALLE.z))
	_set_vasque(1.0, 3.5)
	_veines(0.45, 4.0)
	for i in range(_pierres.size()):
		var p: Dictionary = _pierres[i]
		var tw := root.create_tween()
		tw.tween_interval(0.6 + i * 0.45)
		tw.tween_property(p["mat"], "emission_energy_multiplier", 0.4, 1.2)
	say("L'eau de la vasque s'allume, de bleu, de vert, de turquoise. Au fond de la salle, les cinq grandes pierres se mettent à luire… et quelque chose sort de l'eau.", 8.0)
	await get_tree().create_timer(3.0).timeout
	if root == null:
		return
	_spawn_echo(true)


# ------------------------------------------------------------------- l'Écho et les Pierres-qui-Chantent

func _spawn_echo(appear: bool) -> void:
	if _echo != null:
		return
	var Mini = load("res://scripts/pnj/mini_moai_v88.gd")
	var at: Vector3 = L(SALLE.x, SALLE.y + 0.25, SALLE.z)
	_echo = Mini.spawn(root, main, "L'Écho", at, Vector3(0, 0, -1), "debout", {"h": 1.25, "parure": "fleurs"})
	var ghost: StandardMaterial3D = _glow(Color(0.3, 0.9, 0.85), 0.85, 0.6)
	ghost.rim_enabled = true
	ghost.rim = 0.8
	for mi in _echo.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = ghost
	_echo.lines = ["Ooooh…", "Écoute la pierre…", "La la… laaa…", "Mille ans que je n'avais pas parlé !", "Hi hi ! L'eau chatouille."]
	_echo.line_every = Vector2(8.0, 15.0)
	_echo_light = _light(SALLE + Vector3(0, 1.6, 0), Color(0.5, 1.0, 0.95), 1.4, 7.0)
	_act("souterrain_echo", L(SALLE.x, SALLE.y, SALLE.z), "parler à l'Écho", _talk_echo, VASQUE_R + 2.4,
		func(): return not _chant_playing)
	if appear:
		main.sfx("esprit", at)
		_echo.scale = Vector3.ONE * 0.05
		var tw := root.create_tween()
		tw.tween_property(_echo, "scale", Vector3.ONE, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(1.8).timeout
		if _echo != null:
			_echo.say("Ooooh ! Quelqu'un a réveillé la vasque !", 4.0)
			_echo.gesture("joie", 2.0)


func _talk_echo() -> void:
	if _echo == null or _chant_playing:
		return
	_echo.begin_talk()
	if bool(st().get("chant", false)):
		var lignes: Array = ["La salle chante, grâce à toi. Écoute : même les gouttes tombent en rythme, maintenant.",
			"Tu sais ce qui est plus vieux que les Moaïs ? … Les cailloux. Hi hi ! Ils ne s'en vantent jamais.",
			"Le Grand Moaï te voit, avec ses yeux de corail. Il a l'air content. Enfin… pour une montagne."]
		main.ask_v69(_echo, "L'Écho", "de bonne humeur", str(lignes[randi() % lignes.size()]), [{"id": "fermer", "label": "Au revoir, l'Écho !"}], _echo_bye)
		return
	var txt: String = "Ooooh, un visiteur ! Ça faisait mille ans que personne n'avait réveillé la vasque. Je suis l'Écho, la voix des pierres. Les cinq Pierres-qui-Chantent ont oublié leurs chansons… Je chante, tu répètes : tu touches les pierres dans le même ordre que moi. D'accord ?"
	if _chant_round > 0:
		txt = "On reprend ? Tu en étais à la chanson %d sur 3." % (_chant_round + 1)
	main.ask_v69(_echo, "L'Écho", "malin", txt, [{"id": "go", "label": "Je t'écoute !"}, {"id": "fermer", "label": "Plus tard."}], _echo_choice)


func _echo_bye(_id: String) -> void:
	main._close_dialogue_v31()
	if _echo != null:
		_echo.end_talk()


func _echo_choice(id: String) -> void:
	main._close_dialogue_v31()
	if _echo != null:
		_echo.end_talk()
	if id != "go":
		return
	if _chant_round < 0:
		_chant_round = 0
	_sing_round()


## L'Écho chante la chanson en cours (les pierres s'allument une à une), puis c'est à toi.
func _sing_round() -> void:
	if _echo == null or _chant_round < 0:
		return
	_chant_playing = true
	_chant_pos = 0
	var song: Array = CHANSONS[_chant_round]
	_echo.say(["Écoute bien…", "Une plus longue, maintenant…", "La dernière, la plus belle !"][_chant_round], 2.5)
	await get_tree().create_timer(1.6).timeout
	for i in song:
		if root == null or _echo == null:
			return
		_sing_note(int(i), 0.75)
		_echo.gesture("salut", 0.6)
		await get_tree().create_timer(0.95).timeout
	if _echo != null:
		_echo.say("À toi !", 2.0)
	_chant_playing = false


func _sing_note(i: int, seconds: float) -> void:
	var p: Dictionary = _pierres[i]
	main.sfx("chant_%d" % i, p["pos"])
	var mat: StandardMaterial3D = p["mat"]
	var l: OmniLight3D = p["light"]
	var base: float = 0.4 if bool(st().get("fresques", false)) else 0.05
	mat.emission_energy_multiplier = 4.5
	l.light_energy = 3.0
	var tw := root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "emission_energy_multiplier", base, seconds)
	tw.tween_property(l, "light_energy", 0.0, seconds)


func _touch_pierre(i: int) -> void:
	if _chant_playing:
		return
	_sing_note(i, 0.9)
	if not bool(st().get("fresques", false)):
		if randf() < 0.4:
			say("La pierre chante, toute seule, une note grave et douce… mais personne ne lui répond.", 4.0)
		return
	if bool(st().get("chant", false)) or _chant_round < 0 or _echo == null:
		return
	var song: Array = CHANSONS[_chant_round]
	if int(song[_chant_pos]) != i:
		_chant_playing = true
		await get_tree().create_timer(0.7).timeout
		if _echo == null:
			return
		_echo.gesture("rire", 2.0)
		_echo.say(["Hi hi ! Ça, c'était la chanson du crapaud enrhumé !", "Presque ! Les pierres ont pouffé de rire.", "Oups ! On recommence : écoute bien…"][randi() % 3], 3.0)
		await get_tree().create_timer(2.6).timeout
		_sing_round()
		return
	_chant_pos += 1
	if _chant_pos < song.size():
		return
	# chanson réussie
	_chant_playing = true
	await get_tree().create_timer(0.8).timeout
	if _echo == null:
		return
	_echo.gesture("applaudir", 2.0)
	if _chant_round < CHANSONS.size() - 1:
		_echo.say(["Ooooh, joli !", "Magnifique ! Tu as une voix de pierre !"][_chant_round], 2.6)
		_chant_round += 1
		await get_tree().create_timer(2.4).timeout
		_sing_round()
		return
	_chant_round = -1
	_chant_playing = false
	_open_dalle()


## Énigme 2 réussie : la salle chante, la dalle du fond s'enfonce.
func _open_dalle() -> void:
	st()["chant"] = true
	for i in range(_pierres.size()):
		var tw := root.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_callback(_sing_note.bind(i, 2.5))
	_veines(1.0, 5.0)
	_echo.say("LA SALLE CHANTE !", 4.0)
	_echo.gesture("joie", 3.0)
	await get_tree().create_timer(2.0).timeout
	if root == null or _dalle == null:
		return
	main.sfx("grande_porte", L(0, -1.0, DALLE_Z))
	var tw2 := root.create_tween()
	tw2.tween_property(_dalle, "position:y", -7.6, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	say("Toute la caverne chante, d'une seule voix grave et douce. Les veines de la roche s'allument jusqu'au plafond… Au fond de la salle, la grande dalle s'enfonce dans le sol. « Le Cœur du Chant est à toi, ami des Moaïs. »", 9.0)
	if main.has_method("jingle"):
		main.jingle("decouverte")


# ------------------------------------------------------------------- le Cœur du Chant

func _coeur() -> void:
	var c: Vector3 = COEUR
	# l'Ancêtre de corail, au fond, qui veille sur le trésor
	var anc: Node3D = Statue.make(root, L(c.x, c.y, c.z + 3.6), Vector3(0, 0, -1), {"h": 2.8, "v": 1, "yeux": true, "pukao": true, "nom": "Ancetre_de_corail",
		"teinte": Color(1.25, 0.72, 0.62)})
	anc.global_position.y -= 0.05
	_light(c + Vector3(0, 3.4, 2.0), Color(1.0, 0.8, 0.5), 2.2, 9.0, true)
	_light(c + Vector3(-2.5, 1.0, -1.0), Color(0.4, 0.95, 0.9), 0.8, 6.0)
	# le coffre
	var ob: Node = main.get("objets_v66")
	var chest := Node3D.new()
	chest.name = "Coffre_du_Chant"
	root.add_child(chest)
	chest.position = c + Vector3(0, 0, 1.6)
	chest.rotation.y = PI
	var body := MeshInstance3D.new()
	_coffre_hinge = Node3D.new()
	_coffre_hinge.position = Vector3(0, 0.46, -0.275)
	chest.add_child(body)
	chest.add_child(_coffre_hinge)
	var lid := MeshInstance3D.new()
	if ob != null and ob.has_method("_chest_mesh"):
		body.mesh = ob._chest_mesh("corps")
		lid.mesh = ob._chest_mesh("couvercle")
	_coffre_hinge.add_child(lid)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	chest.add_child(sb)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.92, 0.72, 0.57)
	cs.shape = bs
	cs.position = Vector3(0, 0.36, 0)
	sb.add_child(cs)
	if bool(st().get("tresor", false)):
		_coffre_hinge.rotation.x = -1.95
	_act("souterrain_coffre", L(c.x, c.y, c.z + 0.5), "ouvrir le coffre du Cœur du Chant", _open_coffre, 1.6, func(): return not bool(st().get("tresor", false)))
	# des pièces d'or tout autour (un trésor, un vrai)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.78, 0.32)
	gold.metallic = 1.0
	gold.roughness = 0.28
	var cm := CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.045
	cm.height = 0.008
	cm.radial_segments = 12
	cm.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = 140
	var rng := RandomNumberGenerator.new()
	rng.seed = 8989
	for i in range(140):
		var a: float = rng.randf() * TAU
		var r: float = 0.55 + pow(rng.randf(), 1.5) * 1.6
		var pile: float = maxf(0.0, 0.12 - r * 0.05) * rng.randf()
		var tr := Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))),
			c + Vector3(0, 0.0, 1.6) + Vector3(cos(a) * r, 0.01 + pile, sin(a) * r * 0.7))
		mm.set_instance_transform(i, tr)
	var coins := MultiMeshInstance3D.new()
	coins.multimesh = mm
	coins.material_override = gold
	root.add_child(coins)
	# le courant d'air qui remonte à la surface (une fissure de lumière)
	var crack := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.2, 2.6)
	crack.mesh = qm
	var cmat := StandardMaterial3D.new()
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.albedo_color = Color(0.95, 0.85, 0.65)
	crack.material_override = cmat
	root.add_child(crack)
	crack.position = c + Vector3(-4.9, 1.6, 0.6)
	crack.rotation = Vector3(0, PI * 0.5, 0.08)
	_light(c + Vector3(-4.2, 1.8, 0.6), Color(1.0, 0.93, 0.8), 1.4, 5.0)
	_act("souterrain_sortie", L(c.x - 3.8, c.y, c.z + 0.6), "suivre le courant d'air jusqu'à la surface", func(): leave("Un long boyau qui monte, des marches taillées… et la lumière du jour, devant le Grand Moaï."), 1.8)


func _open_coffre() -> void:
	if bool(st().get("tresor", false)):
		return
	st()["tresor"] = true
	main.sfx("coffre", _coffre_hinge.global_position)
	var tw := root.create_tween()
	tw.tween_property(_coffre_hinge, "rotation:x", -1.95, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if main.has_method("jingle"):
		main.jingle("decouverte")
	await get_tree().create_timer(0.9).timeout
	var mv: Node = main.get("maisons_v81")
	if mv != null:
		mv.give(TRESOR, "Le trésor du Cœur du Chant ! ")
	await get_tree().create_timer(6.5).timeout
	say("Au fond du coffre, gravé dans le bois : « À celui qui a rendu ses yeux au Grand Moaï, et sa voix à la Salle du Chant. Merci. — Les Anciens (et les petits Moaïs, qui ont aidé à porter). »", 9.0)


# ------------------------------------------------------------------- les cristaux, les vers luisants, la mousse

## Une stalactite : une goutte de pierre tournée (pointe en bas, base en haut, hauteur 1), bosselée.
func _goutte_de_pierre() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 10
	var rings: int = 9
	var pts: Array = []
	for r in range(rings + 1):
		var t: float = float(r) / rings
		var row: Array = []
		for k in range(seg + 1):
			var a: float = TAU * k / seg
			var rad: float = pow(t, 1.5) * (1.0 + 0.16 * sin(a * 3.0 + t * 7.0) + 0.1 * sin(a * 5.0 - t * 11.0))
			if r == 0:
				rad = 0.0
			row.append(Vector3(cos(a) * rad, t - 0.5, sin(a) * rad))
		pts.append(row)
	for r in range(rings):
		for k in range(seg):
			var p0: Vector3 = pts[r][k]
			var p1: Vector3 = pts[r][k + 1]
			var p2: Vector3 = pts[r + 1][k + 1]
			var p3: Vector3 = pts[r + 1][k]
			for p in [p0, p1, p2, p0, p2, p3]:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


func _inst_shader(kind: String) -> Shader:
	var sh := Shader.new()
	match kind:
		"cristal":
			sh.code = """
shader_type spatial;
render_mode specular_schlick_ggx;
uniform float force = 2.2;
void fragment() {
	float r = 0.75 + 0.25 * sin(TIME * 0.9 + COLOR.a * 40.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = COLOR.rgb * 0.25;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = COLOR.rgb * force * r * (0.45 + 0.8 * fres);
}
"""
		"vers":
			sh.code = """
shader_type spatial;
render_mode unshaded;
void fragment() {
	float tw = 0.55 + 0.45 * sin(TIME * (0.6 + COLOR.a) + COLOR.a * 60.0);
	ALBEDO = COLOR.rgb * (1.6 + 2.2 * tw);
}
"""
		_:
			sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d) * 2.0;
	float s = pow(clamp(1.0 - r, 0.0, 1.0), 2.2);
	ALBEDO = COLOR.rgb * s * 0.75 * (0.7 + 0.3 * sin(TIME * 0.5 + COLOR.a * 30.0));
}
"""
	return sh


func _decor() -> void:
	if _data.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 8990
	var wet := StandardMaterial3D.new()
	wet.albedo_color = Color(0.26, 0.24, 0.23)
	wet.roughness = 0.22
	wet.metallic_specular = 0.6
	if ResourceLoader.exists("res://assets/textures/terrain/rock.jpg"):
		wet.albedo_texture = load("res://assets/textures/terrain/rock.jpg")
		wet.uv1_triplanar = true
		wet.uv1_scale = Vector3.ONE * 0.6
	# les stalactites et les stalagmites (une goutte de pierre tournée, un peu bosselée), dans la même
	# roche que les parois (la couleur d'instance dit : ouverte, un peu mouillée, pas du sol)
	var cone: ArrayMesh = _goutte_de_pierre()
	for kind in ["stalac", "stalag"]:
		var arr: PackedFloat32Array = _data.get(kind, PackedFloat32Array())
		var n: int = arr.size() / 4
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = cone
		mm.instance_count = n
		for i in range(n):
			var p := Vector3(arr[i * 4], arr[i * 4 + 1], arr[i * 4 + 2])
			var ln: float = arr[i * 4 + 3]
			var w: float = ln * rng.randf_range(0.16, 0.26)
			var b := Basis.from_euler(Vector3(rng.randf_range(-0.08, 0.08), rng.randf() * TAU, rng.randf_range(-0.08, 0.08))).scaled(Vector3(w, ln, w))
			var at: Vector3 = p + Vector3.DOWN * ln * 0.5 + Vector3.UP * 0.15
			if kind == "stalag":
				b = Basis(Vector3.RIGHT, PI) * b
				at = p + Vector3.UP * (ln * 0.5 - 0.1)
			mm.set_instance_transform(i, Transform3D(b, at))
			mm.set_instance_color(i, Color(0.9, 0.55, 0.0, 0.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = kind
		mmi.multimesh = mm
		mmi.material_override = _rock_mat if _rock_mat != null else wet
		root.add_child(mmi)
	# les grappes de cristaux (et quelques lumières dans leurs couleurs)
	var cols: Array = [Color(0.35, 0.95, 0.9), Color(0.55, 0.45, 1.0), Color(0.3, 0.7, 1.0), Color(1.0, 0.5, 0.6)]
	var cp: PackedVector3Array = _data.get("cristaux", PackedVector3Array())
	var cn: PackedVector3Array = _data.get("cristaux_n", PackedVector3Array())
	var prism := CylinderMesh.new()
	prism.top_radius = 0.0
	prism.bottom_radius = 1.0
	prism.height = 1.0
	prism.radial_segments = 6
	prism.rings = 1
	var cmm := MultiMesh.new()
	cmm.transform_format = MultiMesh.TRANSFORM_3D
	cmm.use_colors = true
	cmm.mesh = prism
	var per: int = 7
	cmm.instance_count = cp.size() * per
	var lights: int = 0
	for i in range(cp.size()):
		var col: Color = cols[i % cols.size()]
		var nrm: Vector3 = (cn[i] * 0.6 + Vector3.UP * 0.6).normalized()
		for j in range(per):
			var ax: Vector3 = (nrm + Vector3(rng.randf_range(-0.55, 0.55), rng.randf_range(-0.2, 0.4), rng.randf_range(-0.55, 0.55))).normalized()
			var ln2: float = rng.randf_range(0.25, 0.95) * (1.4 if j == 0 else 1.0)
			var w2: float = ln2 * rng.randf_range(0.12, 0.2)
			var y_ax: Vector3 = ax
			var x_ax: Vector3 = y_ax.cross(Vector3.FORWARD if absf(y_ax.z) < 0.9 else Vector3.RIGHT).normalized()
			var z_ax: Vector3 = x_ax.cross(y_ax).normalized()
			var b2 := Basis(x_ax * w2, y_ax * ln2, z_ax * w2)
			var at2: Vector3 = cp[i] + y_ax * ln2 * 0.45 - cn[i] * 0.12
			cmm.set_instance_transform(i * per + j, Transform3D(b2, at2))
			var cc := Color(col.r, col.g, col.b, rng.randf())
			cmm.set_instance_color(i * per + j, cc)
		if i % 4 == 0 and lights < 14:
			lights += 1
			_light(cp[i] + cn[i] * 0.9 + Vector3.UP * 0.5, col, 1.1, 5.5)
	var cmi := MultiMeshInstance3D.new()
	cmi.name = "Cristaux"
	cmi.multimesh = cmm
	var cmat := ShaderMaterial.new()
	cmat.shader = _inst_shader("cristal")
	cmi.material_override = cmat
	root.add_child(cmi)
	# les vers luisants du plafond
	var vp: PackedVector3Array = _data.get("vers", PackedVector3Array())
	var dot := SphereMesh.new()
	dot.radius = 0.035
	dot.height = 0.07
	dot.radial_segments = 6
	dot.rings = 3
	var vmm := MultiMesh.new()
	vmm.transform_format = MultiMesh.TRANSFORM_3D
	vmm.use_colors = true
	vmm.mesh = dot
	vmm.instance_count = vp.size() * 2
	for i in range(vp.size()):
		for j in range(2):
			var hang: float = rng.randf_range(0.05, 0.6)
			var off := Vector3(rng.randf_range(-0.4, 0.4), -hang, rng.randf_range(-0.4, 0.4))
			vmm.set_instance_transform(i * 2 + j, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.6, 1.3)), vp[i] + off))
			var g: float = rng.randf()
			vmm.set_instance_color(i * 2 + j, Color(0.35 + 0.2 * g, 0.85, 0.95 - 0.2 * g, rng.randf()))
	var vmi := MultiMeshInstance3D.new()
	vmi.name = "Vers_luisants"
	vmi.multimesh = vmm
	var vmat := ShaderMaterial.new()
	vmat.shader = _inst_shader("vers")
	vmi.material_override = vmat
	vmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(vmi)
	# la mousse qui luit au pied des parois
	var mp: PackedVector3Array = _data.get("mousse", PackedVector3Array())
	var mn: PackedVector3Array = _data.get("mousse_n", PackedVector3Array())
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var mmm := MultiMesh.new()
	mmm.transform_format = MultiMesh.TRANSFORM_3D
	mmm.use_colors = true
	mmm.mesh = quad
	mmm.instance_count = mp.size()
	for i in range(mp.size()):
		var nz: Vector3 = mn[i]
		var xa: Vector3 = nz.cross(Vector3.UP if absf(nz.y) < 0.9 else Vector3.RIGHT).normalized()
		var ya: Vector3 = nz.cross(xa).normalized()
		var s: float = rng.randf_range(0.05, 0.16)
		mmm.set_instance_transform(i, Transform3D(Basis(xa * s, ya * s, nz), mp[i] + nz * 0.04))
		var g2: float = rng.randf()
		mmm.set_instance_color(i, Color(0.25 + 0.3 * g2, 0.9, 0.55 + 0.3 * (1.0 - g2), rng.randf()))
	var mmi2 := MultiMeshInstance3D.new()
	mmi2.name = "Mousse"
	mmi2.multimesh = mmm
	var mmat := ShaderMaterial.new()
	mmat.shader = _inst_shader("mousse")
	mmi2.material_override = mmat
	mmi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi2)
	# des poussières de lumière qui flottent dans la salle
	var parts := GPUParticles3D.new()
	parts.name = "Lucioles"
	parts.amount = 220
	parts.lifetime = 14.0
	parts.preprocess = 14.0
	parts.visibility_aabb = AABB(Vector3(-20, -6, -20), Vector3(40, 22, 40))
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(14, 6, 13)
	pmat.gravity = Vector3(0, 0.02, 0)
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.05
	pmat.initial_velocity_max = 0.25
	pmat.turbulence_enabled = true
	pmat.turbulence_noise_strength = 0.4
	pmat.scale_min = 0.6
	pmat.scale_max = 1.4
	parts.process_material = pmat
	var pm := SphereMesh.new()
	pm.radius = 0.025
	pm.height = 0.05
	pm.radial_segments = 6
	pm.rings = 3
	var pmm := StandardMaterial3D.new()
	pmm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmm.albedo_color = Color(0.6, 1.0, 0.95)
	pm.material = pmm
	parts.draw_pass_1 = pm
	root.add_child(parts)
	parts.position = SALLE + Vector3(0, 5.0, 0)


func _process(delta: float) -> void:
	if not inside or root == null:
		return
	_t += delta
	if _echo != null and is_instance_valid(_echo):
		# l'Écho flotte au-dessus de l'eau
		_echo.global_position.y = STAGE.y + SALLE.y + 0.3 + sin(_t * 1.3) * 0.12
		if _echo_light != null:
			_echo_light.light_energy = 1.2 + 0.3 * sin(_t * 2.0)
	# tombé dans un trou de la roche ? (ça ne devrait pas arriver) : au bout du couloir
	var p: Vector3 = main._player_pos_v27()
	if p.distance_to(STAGE) > 400.0:
		teardown()
	elif p.y < STAGE.y - 12.0:
		var rp: Array = respawn_point()
		main.place_player_v35(rp[0], rp[1])

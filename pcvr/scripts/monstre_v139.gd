extends "res://scripts/monstre_v138.gd"
## V139 : la faune des îles des villes : l'Île du Boucan, Néopolis, Sombreval et la Cité des Nuées.
## (Les bêtes d'avant passent toujours par leurs fichiers : on ne fait ici que les nouvelles.)
## Des caractères nouveaux :
##  - grouillant (les rats) : une petite bande qui fouille la friche ; le héros approche, ils
##    s'égaillent, puis se tapissent un moment avant de ressortir ;
##  - chat (le chat errant) : il se prélasse ; si le héros reste tranquille près de lui, il vient
##    se frotter à ses jambes en ronronnant, puis le suit un moment. Celui qui court vers lui le fait
##    fuir ; un coup, et il crache. On ne peut pas lui faire de mal ;
##  - le chat noir de Sombreval fait de même… et, quand le héros marche, il lui coupe la route ;
##  - nuée (les pigeons) : ils picorent sur les places ; le héros passe trop près, ou court, et ils
##    s'envolent tous ensemble, tournent, puis se reposent plus loin ;
##  - flottille (la cane et ses canetons, sur l'étang de la Cité des Nuées) : les canetons suivent
##    leur mère à la file ; si le héros reste au bord, elle s'approche en cancanant ; s'il s'agite,
##    toute la famille file de l'autre côté de l'étang.

const SPECS139 := {
	"rat": {"pv": 4, "vitesse": 3.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 5.0, "laisse": 30.0,
		"rayon": 0.6, "haut": 0.1, "nom": "Rats", "genre": "grouillant", "col": ["boule", 0.15, 0.15]},
	"chat_errant": {"pv": 99, "vitesse": 2.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 6.0, "laisse": 40.0,
		"rayon": 0.35, "haut": 0.25, "nom": "Chat errant", "genre": "chat", "col": ["boite", Vector3(0.2, 0.3, 0.5)]},
	"chat_noir": {"pv": 99, "vitesse": 2.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 6.0, "laisse": 40.0,
		"rayon": 0.35, "haut": 0.25, "nom": "Chat noir", "genre": "chat", "col": ["boite", Vector3(0.2, 0.3, 0.5)]},
	"pigeon": {"pv": 99, "vitesse": 5.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 4.0, "laisse": 60.0,
		"rayon": 1.0, "haut": 0.1, "nom": "Pigeons", "genre": "nuee", "col": ["boule", 0.3, 0.1]},
	"canard": {"pv": 99, "vitesse": 0.8, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 6.0, "laisse": 30.0,
		"rayon": 0.4, "haut": 0.0, "nom": "Cane et canetons", "genre": "flottille", "vol": true, "col": ["boule", 0.3, 0.0]},
}
const SOUNDS139 := {
	"rat": ["rat_couine", "rat_couine"], "chat_errant": ["chat_miaou", "chat_crache"], "chat_noir": ["chat_miaou", "chat_crache"],
	"pigeon": ["pigeon", ""], "canard": ["canard_cancan", ""],
}
const GENRES139 := ["grouillant", "chat", "nuee", "flottille"]

static var _tex139: Dictionary = {}

var _bande: Array = []                    # rats, pigeons, canetons : [nœud, phase, place]
var _trace: Array = []                    # la cane : ses dernières positions (les canetons les suivent)
var _croise_cd: float = 15.0
var _croise_to: Vector3 = Vector3.ZERO
var _robe_chat: String = ""
var _au_sol: bool = false                 # les pigeons : posés sur le vrai sol (pavés, toits plats…)
# tests
var calins: int = 0
var croisements: int = 0
var envolees: int = 0
var approches: int = 0


static func spec_of(k: String) -> Dictionary:
	if SPECS139.has(k):
		return SPECS139[k]
	if SPECS138.has(k):
		return SPECS138[k]
	if SPECS137.has(k):
		return SPECS137[k]
	if SPECS136.has(k):
		return SPECS136[k]
	if SPECS135.has(k):
		return SPECS135[k]
	if SPECS133.has(k):
		return SPECS133[k]
	return SPECS132.get(k, {})


static func has_kind(k: String) -> bool:
	return SPECS139.has(k) or SPECS138.has(k) or SPECS137.has(k) or SPECS136.has(k) or SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS139.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS139[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = true
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	# (on passe au travers : un chat qui se frotte aux jambes ne doit pas bloquer le héros)
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var col: Array = spec["col"]
	if str(col[0]) == "boule":
		var s := SphereShape3D.new()
		s.radius = float(col[1])
		cs.shape = s
		cs.position.y = float(col[2])
	else:
		var b := BoxShape3D.new()
		b.size = col[1]
		cs.shape = b
		cs.position.y = (col[1] as Vector3).y * 0.5 + 0.02
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"rat":
			_build_rats()
		"chat_errant", "chat_noir":
			_build_chat(k == "chat_noir")
		"pigeon":
			_build_pigeons()
		"canard":
			_build_canards()
	add_to_group("cibles_v28")
	add_to_group("faune_v132")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if facing.length() < 0.5:
		facing = Vector3.FORWARD
	_flank = randf_range(-1.0, 1.0)
	_wander_t = randf_range(0.5, 3.0)
	_orbit_c = Vector3(at.x, 0.0, at.z)
	_orbit_a = randf() * TAU
	_cd136 = randf_range(3.0, 7.0)
	match k:
		"rat":
			state = "fouille"
		"pigeon":
			state = "picore"
		"canard":
			state = "nage"
		_:
			state = "assis"
			timer = randf_range(4.0, 9.0)
	_base_scale = _visual.scale
	if k == "canard":
		_trace_derriere()


## Les canetons, au départ : en file derrière leur mère.
func _trace_derriere() -> void:
	_trace.clear()
	for j in range(80):
		_trace.append(global_position - facing * 0.05 * j)


# =================================================================== textures

## La robe d'un chat tigré : des rayures sombres en travers du corps, sur un fond brun ou roux.
func _tigre_tex(roux: bool) -> Texture2D:
	var key: String = "roux" if roux else "tigre"
	if _tex139.has(key):
		return _tex139[key]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1391 if roux else 1392
	var fond: Color = Color(0.78, 0.45, 0.2) if roux else Color(0.5, 0.43, 0.33)
	var raie: Color = Color(0.5, 0.25, 0.1) if roux else Color(0.13, 0.11, 0.09)
	for y in range(n):
		for x in range(n):
			var u: float = float(x) / n * TAU * 7.0 + sin(float(y) / n * TAU * 2.0) * 1.5 + sin(float(y) * 0.31) * 0.4
			var k: float = smoothstep(0.35, 0.8, sin(u))
			var v: float = 1.0 + rng.randf_range(-0.07, 0.07)
			var c: Color = fond.lerp(raie, k * 0.85)
			img.set_pixel(x, y, Color(c.r * v, c.g * v, c.b * v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex139[key] = t
	return t


# =================================================================== modèles

## Les rats : une bande de six rats bruns, le museau pointu, les petites oreilles roses, la longue
## queue nue.
func _build_rats() -> void:
	var poil := _vmat(Color(0.36, 0.3, 0.25), 0.95)
	var fl: StandardMaterial3D = _flat_of(poil, 0.92)
	var rose := _mat(Color(0.75, 0.55, 0.52), 0.6)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.1)
	var dos := func(s: float, ang: float) -> float:
		return 0.75 + 0.25 * (0.5 - 0.5 * sin(ang)) + 0.05 * sin(s * 37.0 + ang * 7.0)
	for i in range(6):
		var r := Node3D.new()
		_visual.add_child(r)
		_put(r, _tube_fn("rat:corps", [Vector3(0, 0.035, -0.08), Vector3(0, 0.045, -0.03), Vector3(0, 0.042, 0.03), Vector3(0, 0.035, 0.07)], [0.022, 0.035, 0.03, 0.018], 10, 1.0, dos), poil)
		_put(r, _tube_fn("rat:museau", [Vector3(0, 0.035, 0.065), Vector3(0, 0.03, 0.095), Vector3(0, 0.025, 0.115)], [0.02, 0.012, 0.005], 8, 1.0, Callable()), fl)
		_mesh(r, _unit_sphere(), rose, Vector3(0, 0.025, 0.117), Vector3.ONE * 0.004)
		for sx in [-1.0, 1.0]:
			_mesh(r, _unit_sphere(), rose, Vector3(sx * 0.014, 0.055, 0.06), Vector3(0.008, 0.009, 0.004))
			_mesh(r, _unit_sphere(), noir, Vector3(sx * 0.012, 0.042, 0.088), Vector3.ONE * 0.0035)
		_put(r, _tube_fn("rat:queue", [Vector3(0, 0.03, -0.08), Vector3(0, 0.015, -0.14), Vector3(0.01, 0.006, -0.2), Vector3(0.02, 0.004, -0.25)], [0.006, 0.004, 0.003, 0.0012], 5, 1.0, Callable()), rose)
		_bande.append([r, randf() * TAU, Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))])


## Le chat : de la taille d'un vrai chat, la queue dressée ; tigré brun, roux, noir et blanc… ou
## tout noir, les yeux jaunes (le chat noir de Sombreval).
func _build_chat(noir: bool) -> void:
	var robes: Array = ["tigre", "tigre", "roux", "noir_blanc"]
	_robe_chat = "noir" if noir else str(robes[randi() % robes.size()])
	var fur: StandardMaterial3D
	match _robe_chat:
		"tigre", "roux":
			fur = _mat(Color(1, 1, 1), 0.9)
			fur.vertex_color_use_as_albedo = true
			fur.albedo_texture = _tigre_tex(_robe_chat == "roux")
			fur.uv1_triplanar = true
			fur.uv1_scale = Vector3(3.0, 3.0, 3.0)
		"noir_blanc":
			fur = _vmat(Color(0.06, 0.055, 0.05), 0.85)
		_:
			fur = _vmat(Color(0.035, 0.032, 0.03), 0.55)
	var ventre := func(s: float, ang: float) -> float:
		return 0.88 + 0.12 * smoothstep(0.0, -0.8, sin(ang)) + 0.03 * sin(s * 31.0 + ang * 5.0)
	_build_mammal({"long": 0.42, "haut": 0.27, "rayon": 0.068, "mat": fur, "shade": ventre, "museau": 0.035, "bout": 0.5,
		"crane": 0.72, "oreille": 0.85, "forme_oreille": "pointe", "ecart": 0.28, "queue": 0.32, "style": "dressee", "touffe": 0.28,
		"patte": 0.2, "pied": 0.8, "cou": 0.6, "port": 0.6, "taille": 0.85, "segs": 14,
		"yeux": Color(0.85, 0.8, 0.2) if noir else Color(0.55, 0.8, 0.3), "oeil": 0.2, "sombre": Color(0.12, 0.08, 0.08),
		"dedans": Color(0.85, 0.6, 0.6), "teinte": 0.92})
	if _robe_chat == "noir_blanc":
		# le plastron, le museau et les « chaussettes » blancs
		var blanc := _mat(Color(0.93, 0.92, 0.9), 0.9)
		var body: Node3D = _pivots["corps"]
		_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.17, 0.17), Vector3(0.05, 0.07, 0.05))
		var head: Node3D = _pivots["tete"]
		_mesh(head, _unit_sphere(), blanc, Vector3(0, -0.02, 0.05), Vector3(0.035, 0.025, 0.035))
		for l in _legs:
			var kids: Array = (l[0] as Node3D).get_children()
			if kids.size() >= 2 and kids[1] is MeshInstance3D:
				(kids[1] as MeshInstance3D).material_override = blanc


## Les pigeons : huit pigeons des villes, gris bleuté, le cou irisé de vert et de violet, deux barres
## noires sur l'aile, la queue barrée de sombre, les pattes roses, l'œil orange.
func _build_pigeons() -> void:
	var gris := _vmat(Color(0.42, 0.44, 0.5), 0.75)
	var fl: StandardMaterial3D = _flat_of(gris, 0.85)
	var cou := _mat(Color(0.3, 0.45, 0.4), 0.3)
	cou.metallic = 0.6
	cou.metallic_specular = 0.9
	var noir := _mat(Color(0.12, 0.12, 0.14), 0.7)
	var rose := _mat(Color(0.8, 0.4, 0.45), 0.6)
	var oeil := _mat(Color(0.9, 0.45, 0.1), 0.2)
	for i in range(8):
		var b := Node3D.new()
		_visual.add_child(b)
		var corps := Node3D.new()
		b.add_child(corps)
		_put(corps, _tube_fn("pigeon:corps", [Vector3(0, 0.11, -0.09), Vector3(0, 0.12, -0.02), Vector3(0, 0.13, 0.05)], [0.03, 0.06, 0.05], 10, 1.0, Callable(self, "_shade_dos")), gris)
		_mesh(corps, _unit_sphere(), cou, Vector3(0, 0.155, 0.065), Vector3(0.035, 0.04, 0.035))
		var head := Node3D.new()
		head.position = Vector3(0, 0.18, 0.08)
		corps.add_child(head)
		_mesh(head, _unit_sphere(), _flat_of(gris, 0.7), Vector3.ZERO, Vector3(0.025, 0.025, 0.03))
		_mesh(head, _cyl(0.002, 0.005, 0.02), _mat(Color(0.3, 0.28, 0.27), 0.5), Vector3(0, -0.004, 0.035), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		for sx in [-1.0, 1.0]:
			_mesh(head, _unit_sphere(), oeil, Vector3(sx * 0.017, 0.006, 0.01), Vector3.ONE * 0.005)
		_mesh(corps, _unit_sphere(), noir, Vector3(0, 0.115, -0.15), Vector3(0.03, 0.006, 0.03))
		_mesh(corps, _unit_sphere(), fl, Vector3(0, 0.115, -0.12), Vector3(0.035, 0.007, 0.05))
		var ws: Array = []
		for sx in [-1.0, 1.0]:
			var w := Node3D.new()
			w.position = Vector3(sx * 0.035, 0.135, 0.02)
			corps.add_child(w)
			_mesh(w, _unit_sphere(), fl, Vector3(sx * 0.1, 0.0, -0.03), Vector3(0.11, 0.008, 0.055))
			_mesh(w, BoxMesh.new(), noir, Vector3(sx * 0.07, 0.006, -0.05), Vector3(0.05, 0.002, 0.006))
			_mesh(w, BoxMesh.new(), noir, Vector3(sx * 0.07, 0.006, -0.065), Vector3(0.05, 0.002, 0.006))
			_mesh(w, _unit_sphere(), noir, Vector3(sx * 0.19, 0.0, -0.05), Vector3(0.05, 0.006, 0.04))
			ws.append([w, sx])
		for sx in [-1.0, 1.0]:
			_mesh(corps, _cyl(0.004, 0.004, 0.08), rose, Vector3(sx * 0.015, 0.04, 0.0))
		_bande.append([b, randf() * TAU, Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2)), corps, head, ws])


## La cane et ses canetons : la cane brune, mouchetée de beige, le miroir bleu violacé sur l'aile, le
## bec orange taché de sombre ; quatre canetons duveteux, jaunes au dos brun.
func _build_canards() -> void:
	# la cane : brune, chaque plume bordée de beige (la texture du plumage, mouchetée de sombre)
	var brun := _mat(Color(1, 1, 1), 0.9)
	brun.vertex_color_use_as_albedo = true
	brun.albedo_texture = _plumage_tex()
	brun.uv1_triplanar = true
	brun.uv1_scale = Vector3(5.0, 5.0, 5.0)
	var fl: StandardMaterial3D = brun.duplicate()
	fl.vertex_color_use_as_albedo = false
	fl.albedo_color = Color(0.88, 0.85, 0.8)
	_flash_mats.append(fl)
	var aile := brun.duplicate()
	aile.vertex_color_use_as_albedo = false
	aile.albedo_color = Color(0.62, 0.58, 0.55)
	_flash_mats.append(aile)
	var blanc := _mat(Color(0.92, 0.9, 0.86), 0.8)
	var bleu := _mat(Color(0.25, 0.2, 0.75), 0.3)
	bleu.metallic = 0.5
	var bec := _mat(Color(0.9, 0.5, 0.15), 0.5)
	var noir := _mat(Color(0.03, 0.03, 0.03), 0.1)
	var plumes := func(s: float, ang: float) -> float:
		return 0.8 + 0.2 * sin(s * 50.0 + ang * 9.0) * sin(ang * 4.0 - s * 21.0)
	var mere := Node3D.new()
	_visual.add_child(mere)
	_put(mere, _tube_fn("cane:corps", [Vector3(0, 0.1, -0.25), Vector3(0, 0.07, -0.18), Vector3(0, 0.07, -0.08), Vector3(0, 0.07, 0.06), Vector3(0, 0.07, 0.14)], [0.012, 0.06, 0.12, 0.11, 0.07], 12, 0.82, plumes), brun)
	var head := Node3D.new()
	head.position = Vector3(0, 0.2, 0.17)
	mere.add_child(head)
	_put(mere, _tube_fn("cane:cou", [Vector3(0, 0.1, 0.13), Vector3(0, 0.16, 0.16), Vector3(0, 0.2, 0.17)], [0.045, 0.035, 0.03], 8, 1.0, plumes), brun)
	_mesh(head, _unit_sphere(), fl, Vector3.ZERO, Vector3(0.04, 0.04, 0.05))
	_mesh(head, _unit_sphere(), _mat(Color(0.25, 0.18, 0.11), 0.9), Vector3(0, 0.018, -0.002), Vector3(0.034, 0.024, 0.046))
	_put(head, _tube_fn("cane:bec", [Vector3(0, -0.005, 0.035), Vector3(0, -0.01, 0.07), Vector3(0, -0.012, 0.09)], [0.016, 0.017, 0.012], 8, 0.5, Callable()), bec)
	_mesh(head, _unit_sphere(), noir, Vector3(0, -0.004, 0.06), Vector3(0.012, 0.004, 0.012))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.03, 0.01, 0.02), Vector3.ONE * 0.006)
		_mesh(head, _unit_sphere(), _mat(Color(0.3, 0.22, 0.14), 0.9), Vector3(sx * 0.031, 0.006, 0.015), Vector3(0.004, 0.003, 0.03))
		# l'aile repliée, et son miroir bleu violacé bordé de blanc
		_mesh(mere, _unit_sphere(), aile, Vector3(sx * 0.085, 0.115, -0.06), Vector3(0.035, 0.045, 0.14), Vector3(0.1, sx * 0.08, 0))
		_mesh(mere, _unit_sphere(), bleu, Vector3(sx * 0.111, 0.11, -0.1), Vector3(0.008, 0.017, 0.04))
		_mesh(mere, _unit_sphere(), blanc, Vector3(sx * 0.11, 0.128, -0.1), Vector3(0.008, 0.004, 0.04))
		_mesh(mere, _unit_sphere(), blanc, Vector3(sx * 0.11, 0.092, -0.1), Vector3(0.008, 0.004, 0.04))
	_pivots["tete"] = head
	_bande.append([mere, 0.0, Vector3.ZERO])
	var jaune := _vmat(Color(0.92, 0.8, 0.35), 0.98)
	var dos := _mat(Color(0.38, 0.3, 0.18), 0.98)
	for i in range(4):
		var c := Node3D.new()
		_visual.add_child(c)
		_mesh(c, _unit_sphere(), _flat_of(jaune, 1.0), Vector3(0, 0.035, 0.0), Vector3(0.04, 0.035, 0.055))
		_mesh(c, _unit_sphere(), dos, Vector3(0, 0.05, -0.01), Vector3(0.035, 0.022, 0.045))
		_mesh(c, _unit_sphere(), _flat_of(jaune, 1.0), Vector3(0, 0.075, 0.04), Vector3.ONE * 0.026)
		_mesh(c, _unit_sphere(), dos, Vector3(0, 0.088, 0.035), Vector3(0.02, 0.012, 0.02))
		_mesh(c, _unit_sphere(), _mat(Color(0.3, 0.25, 0.2), 0.5), Vector3(0, 0.07, 0.068), Vector3(0.01, 0.006, 0.012))
		for sx in [-1.0, 1.0]:
			_mesh(c, _unit_sphere(), noir, Vector3(sx * 0.018, 0.08, 0.055), Vector3.ONE * 0.004)
		_bande.append([c, randf() * TAU, Vector3.ZERO])


# =================================================================== sons, coups

func _sound(what: String) -> void:
	if not SPECS139.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS139.get(kind, ["", ""])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * 0.3)


func alert_text() -> String:
	if SPECS139.has(kind):
		return ""
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS139.has(kind):
		return super.loot(rng)
	if kind == "rat" and rng.randf() < 0.5:
		return [["piece", 1]]
	return []


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS139.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	match kind:
		"chat_errant", "chat_noir":
			# on ne fait pas de mal à un chat : il crache, le dos rond, et s'enfuit
			_flash = 0.12
			state = "crache"
			timer = 0.8
			_sound("mort")
			return
		"pigeon":
			_envol_pigeons(from_pos)
			return
		"canard":
			_eloigne_canards(from_pos)
			return
	super.take_hit(damage, from_pos)
	if state != "mort" and kind == "rat":
		state = "fuite"
		timer = 1.5


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES139):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	if state == "mort":
		_death_tick(delta)
		return
	if not bool(manager.active):
		_animate132(delta, 0.0)
		return
	var p: Vector3 = _player()
	var hero_dir := Vector3.ZERO
	if _last_p != Vector3.INF:
		var dv := Vector3(p.x - _last_p.x, 0, p.z - _last_p.z)
		_hero_v = lerpf(_hero_v, dv.length() / maxf(delta, 0.001), clampf(delta * 6.0, 0.0, 1.0))
		if dv.length() > 0.0001:
			hero_dir = dv.normalized()
	_last_p = p
	var to_p: Vector3 = p - global_position
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var vue: float = float(spec["vue"])
	match genre:
		"nuee":
			_pigeons(delta, p, dist)
			_animate132(delta, 0.0)
			return
		"flottille":
			_canards(delta, p, dist)
			_animate132(delta, 0.0)
			return
	var move := Vector3.ZERO
	match genre:
		"grouillant":
			move = _rats(delta, dist, dir_p, sp, vue)
		"chat":
			move = _chat(delta, dist, dir_p, p, hero_dir, sp, vue)
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 0.8
		if _au_vide(ahead) or (_ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead)):
			move = -move * 0.3
			_wander_to = Vector3.INF
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


# ------------------------------------------------------------------- les rats

func _rats(delta: float, dist: float, dir_p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"fouille":
			move = _wander(delta, sp) * 1.2
			if dist < vue:
				state = "fuite"
				timer = 1.5
				_sound("menace")
		"fuite":
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			move = facing * sp * 2.0
			if timer <= 0.0:
				state = "tapis"
				timer = randf_range(3.0, 5.0)
				fuites += 1
		"tapis":
			if timer <= 0.0:
				if dist > vue:
					state = "fouille"
					home = global_position
				elif dist < vue * 0.6:
					state = "fuite"
					timer = 1.2
		_:
			state = "fouille"
	return move


# ------------------------------------------------------------------- les chats

func _chat(delta: float, dist: float, dir_p: Vector3, p: Vector3, hero_dir: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	_croise_cd -= delta
	# le héros court droit sur lui : il file
	if state in ["assis", "erre", "approche", "suit"] and _hero_v > 3.5 and dist < 4.0 and hero_dir.dot(-dir_p) > 0.5:
		state = "fuit"
		timer = 1.5
	match state:
		"assis", "erre":
			if state == "erre":
				move = _wander(delta, sp) * 0.5
			if timer <= 0.0:
				state = "erre" if state == "assis" else "assis"
				timer = randf_range(4.0, 9.0)
			# on reste tranquille près de lui : il vient se frotter
			if dist < vue and _hero_v < 0.3:
				_calm_t += delta
				if _calm_t > 1.5:
					state = "approche"
					_calm_t = 0.0
					_sound("menace")
			else:
				_calm_t = 0.0
			# le chat noir coupe la route au héros qui marche
			if kind == "chat_noir" and _croise_cd <= 0.0 and _hero_v > 1.0 and dist > 5.0 and dist < 14.0 and hero_dir != Vector3.ZERO:
				var devant: Vector3 = p + hero_dir * 4.0
				var cote := Vector3(-hero_dir.z, 0, hero_dir.x)
				var s: float = signf((global_position - devant).dot(cote))
				if s == 0.0:
					s = 1.0
				_croise_to = devant - cote * s * 4.0
				state = "croise"
				timer = 4.0
				_croise_cd = 40.0
		"approche":
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			move = facing * sp * 0.6
			if dist < 0.9:
				state = "caline"
				timer = randf_range(4.5, 6.0)
				calins += 1
				if manager.main != null and manager.main.has_method("sfx"):
					manager.main.sfx("ronron", global_position)
			elif _hero_v > 1.5 or dist > vue * 1.5:
				state = "assis"
				timer = 3.0
		"caline":
			# il tourne autour des jambes du héros, la queue en l'air
			_orbit_a += delta * 1.6
			var cible: Vector3 = p + Vector3(cos(_orbit_a), 0, sin(_orbit_a)) * 0.55
			var to: Vector3 = cible - global_position
			to.y = 0.0
			if to.length() > 0.05:
				facing = facing.lerp(to.normalized(), clampf(delta * 8.0, 0.0, 1.0)).normalized()
				move = to.limit_length(1.0) * sp * 0.4
			if _hero_v > 1.0 or timer <= 0.0:
				state = "suit"
				timer = 20.0
		"suit":
			if dist > 2.2:
				facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
				move = facing * sp * minf(1.0, (dist - 1.8) * 0.7 + 0.4) * (1.6 if dist > 5.0 else 1.0)
			if timer <= 0.0 or dist > vue * 3.0:
				state = "assis"
				timer = randf_range(4.0, 8.0)
				home = global_position
		"croise":
			var to2: Vector3 = _croise_to - global_position
			to2.y = 0.0
			if to2.length() > 0.4:
				facing = facing.lerp(to2.normalized(), clampf(delta * 10.0, 0.0, 1.0)).normalized()
				move = facing * sp * 2.2
			if to2.length() <= 0.4 or timer <= 0.0:
				croisements += 1
				_texte("Un chat noir te coupe la route…", Color(0.85, 0.8, 1.0))
				_sound("menace")
				state = "assis"
				timer = randf_range(3.0, 6.0)
				home = global_position
		"crache":
			facing = facing.lerp(dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "fuit"
				timer = 1.6
		"fuit":
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			move = facing * sp * 2.4
			if timer <= 0.0:
				state = "assis"
				timer = randf_range(4.0, 8.0)
				home = global_position
				fuites += 1
		_:
			state = "assis"
	return move


# ------------------------------------------------------------------- les pigeons

func _pigeons(delta: float, p: Vector3, dist: float) -> void:
	match state:
		"picore":
			# au sol : la bande picore sur place (posée sur les pavés, s'il y en a)
			if not _au_sol:
				global_position.y = _sol139(global_position)
				_au_sol = true
			if dist < float(spec["vue"]) or (_hero_v > 3.0 and dist < 7.0):
				_envol_pigeons(p)
		"vol":
			_orbit_a += delta * 0.9
			var target: Vector3 = _orbit_c + Vector3(cos(_orbit_a) * 8.0, 0, sin(_orbit_a) * 8.0)
			target.y = _plancher(target) + 7.0 + sin(_clock * 0.8) * 0.8
			_voler137(delta, target, float(spec["vitesse"]), 2.0)
			if timer <= 0.0:
				# ils vont se reposer plus loin, loin du héros
				var best := Vector3.INF
				for k in range(16):
					var a: float = randf() * TAU
					var q: Vector3 = _orbit_c + Vector3(cos(a), 0, sin(a)) * randf_range(10.0, 16.0)
					if _au_vide(q) or _ground_at(q) < 0.3 or Vector2(q.x - p.x, q.z - p.z).length() < 9.0 or _sous_toit139(q):
						continue
					best = Vector3(q.x, _sol139(q), q.z)
					break
				if best == Vector3.INF:
					best = Vector3(_orbit_c.x, _ground_at(_orbit_c), _orbit_c.z)
				_cible = best
				state = "pose"
		"pose":
			_voler137(delta, _cible + Vector3.UP * 0.1, float(spec["vitesse"]) * 0.7, 2.0)
			if global_position.distance_to(_cible) < 0.6:
				global_position = _cible
				_visual.rotation = Vector3.ZERO
				state = "picore"
				home = _cible
				_au_sol = true
		_:
			state = "picore"


## Un toit, un mur, une arche au-dessus de ce point ?
func _sous_toit139(q: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var h: float = _ground_at(q)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(q.x, h + 30.0, q.z), Vector3(q.x, h - 1.0, q.z), 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and float(hit.position.y) > h + 0.9


## Le vrai sol sous ce point : le relief, ou les pavés, un muret, une marche posés dessus.
func _sol139(q: Vector3) -> float:
	var h: float = _ground_at(q)
	if not is_inside_tree():
		return h
	var ray := PhysicsRayQueryParameters3D.create(Vector3(q.x, h + 0.9, q.z), Vector3(q.x, h - 1.0, q.z), 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	return maxf(h, float(hit.position.y)) if not hit.is_empty() else h


func _envol_pigeons(from: Vector3) -> void:
	if state in ["vol", "pose"]:
		return
	state = "vol"
	timer = randf_range(4.0, 6.0)
	envolees += 1
	_au_sol = false
	var away: Vector3 = global_position - from
	away.y = 0.0
	_orbit_c = global_position + (away.normalized() if away.length() > 0.1 else Vector3.FORWARD) * 6.0
	_orbit_c.y = 0.0
	if manager != null and manager.main != null and manager.main.has_method("sfx"):
		manager.main.sfx("ailes", global_position)


# ------------------------------------------------------------------- la cane et ses canetons

## V140 : la distance du centre de l'étang à l'endroit où l'on nage, dans la direction dir (un lac
## peut être une ellipse).
func _r_canard(et: Array, dir: Vector3) -> float:
	if et.is_empty():
		return 4.0
	var rr: float = float(manager.rayon_etang(et, dir)) if manager.has_method("rayon_etang") else float(et[1])
	return rr - 2.5


func _canards(delta: float, p: Vector3, dist: float) -> void:
	var et: Array = manager.etang_de(ile_sol) if manager.has_method("etang_de") else []
	var c: Vector3 = et[0] if not et.is_empty() else home
	var r: float = _r_canard(et, Vector3.RIGHT)
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	# le héros est au bord, tout près ?
	var hc: float = Vector2(p.x - c.x, p.z - c.z).length()
	var vers_h: Vector3 = Vector3(p.x - c.x, 0, p.z - c.z)
	vers_h = vers_h.normalized() if vers_h.length() > 0.1 else Vector3.FORWARD
	var au_bord: bool = hc < _r_canard(et, vers_h) + 10.0
	# les canetons piaillent de temps en temps
	if dist < 18.0 and fmod(_clock + _flank * 2.0, 5.0) < delta and manager.main != null and manager.main.has_method("sfx"):
		manager.main.sfx("caneton_piaille", global_position)
	match state:
		"nage":
			_orbit_a += delta * speed / maxf(r, 1.0)
			var d_o := Vector3(cos(_orbit_a), 0, sin(_orbit_a))
			target = c + d_o * _r_canard(et, d_o) * (0.8 + 0.2 * sin(_clock * 0.3))
			if au_bord and _hero_v < 0.3:
				_calm_t += delta
				if _calm_t > 2.0:
					state = "approche"
					timer = 10.0
					approches += 1
					_calm_t = 0.0
					_sound("menace")
			else:
				_calm_t = 0.0
			if au_bord and _hero_v > 2.5 and hc < _r_canard(et, vers_h) + 4.0:
				_eloigne_canards(p)
		"approche":
			# elle vient vers le héros, jusqu'au bord de l'eau, en cancanant
			target = c + vers_h * _r_canard(et, vers_h)
			speed *= 1.3
			if fmod(_clock, 2.5) < delta:
				_sound("menace")
			if not au_bord or timer <= 0.0:
				state = "nage"
				_orbit_a = atan2(global_position.z - c.z, global_position.x - c.x)
			elif _hero_v > 2.5:
				_eloigne_canards(p)
		"eloigne":
			target = _cible
			speed *= 2.5
			if Vector2(global_position.x - _cible.x, global_position.z - _cible.z).length() < 0.6 or timer <= 0.0:
				state = "nage"
				_orbit_a = atan2(global_position.z - c.z, global_position.x - c.x)
		_:
			state = "nage"
			target = global_position
	var to: Vector3 = target - global_position
	to.y = 0.0
	var step: Vector3 = to.limit_length(speed * delta)
	global_position += step
	global_position.y = c.y if not et.is_empty() else _ground_at(global_position)
	if step.length() > 0.0005:
		facing = facing.lerp(step.normalized(), clampf(delta * 3.0, 0.0, 1.0)).normalized()
	rotation.y = atan2(facing.x, facing.z)
	# la trace de la mère : les canetons la suivent à la file
	if _trace.is_empty() or (_trace[0] as Vector3).distance_to(global_position) > 0.05:
		_trace.push_front(global_position)
		if _trace.size() > 80:
			_trace.pop_back()


func _eloigne_canards(from: Vector3) -> void:
	var et: Array = manager.etang_de(ile_sol) if manager != null and manager.has_method("etang_de") else []
	var c: Vector3 = et[0] if not et.is_empty() else home
	var loin: Vector3 = Vector3(c.x - from.x, 0, c.z - from.z)
	loin = loin.normalized() if loin.length() > 0.1 else Vector3.FORWARD
	_cible = c + loin * _r_canard(et, loin)
	state = "eloigne"
	timer = 12.0
	fuites += 1


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS139.has(kind):
		super._animate132(delta, speed)
		return
	var night: bool = manager != null and manager.has_method("night") and bool(manager.night())
	for m in _eye_glow:
		(m as StandardMaterial3D).emission_energy_multiplier = 2.5 if night else 0.3
	match kind:
		"rat":
			_anim_rats()
		"chat_errant", "chat_noir":
			_anim_chat(delta, speed)
		"pigeon":
			_anim_pigeons()
		"canard":
			_anim_canards()


func _anim_rats() -> void:
	var t: float = _clock
	var fuite: bool = state == "fuite"
	var tapis: bool = state == "tapis"
	for e in _bande:
		var r: Node3D = e[0]
		var ph: float = e[1]
		var place: Vector3 = e[2]
		var spread: float = 2.2 if fuite else (0.35 if tapis else 1.0)
		var pos: Vector3 = place * spread + (Vector3(sin(t * 0.9 + ph) * 0.25, 0, cos(t * 0.7 + ph * 1.3) * 0.25) if not tapis else Vector3.ZERO)
		var old: Vector3 = r.position
		r.position = old.lerp(pos, 0.15)
		var mv: Vector3 = r.position - old
		if mv.length() > 0.0005:
			r.rotation.y = lerp_angle(r.rotation.y, atan2(mv.x, mv.z), 0.3)
		r.position.y = absf(sin(t * (22.0 if fuite else 9.0) + ph)) * (0.015 if not tapis else 0.0)


func _anim_chat(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var sit: float = 1.0 if state == "assis" else 0.0
	_stand = lerpf(_stand, sit, clampf(delta * 5.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		if state == "crache":
			# le dos rond
			body.position.y = 0.05
			body.rotation.x = 0.0
		else:
			var bas := Basis(Vector3.RIGHT, -0.4 * _stand)
			var pv := Vector3(0, 0.05, -0.17)
			body.transform = Transform3D(bas, pv - bas * pv + Vector3(0, -0.06 * _stand, 0))
	# assis : les postérieurs repliés sous lui, les antérieurs bien droits
	for l in _legs:
		var leg: Node3D = l[0]
		if _stand > 0.05:
			if int(l[2]) >= 2:
				leg.rotation.x = -1.0 * _stand
			else:
				leg.rotation.x = 0.4 * _stand
		leg.scale.y = 1.0 + (0.3 * _stand if int(l[2]) < 2 else 0.0)
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		if state == "caline":
			tail.rotation.x = -0.5 + sin(_clock * 3.0) * 0.1
		elif state == "crache":
			tail.rotation.x = -0.8
		else:
			tail.rotation.y = sin(_clock * 1.3) * 0.25
	var head: Node3D = _pivots.get("tete")
	if head != null and state == "assis" and fmod(_clock + _flank * 5.0, 9.0) < 1.5:
		# il fait sa toilette
		head.rotation.x = 0.7 + sin(_clock * 8.0) * 0.1


func _anim_pigeons() -> void:
	var t: float = _clock
	var au_sol: bool = state == "picore"
	for e in _bande:
		var b: Node3D = e[0]
		var ph: float = e[1]
		var place: Vector3 = e[2]
		var corps: Node3D = e[3]
		var head: Node3D = e[4]
		var pos: Vector3
		if au_sol:
			pos = place + Vector3(sin(t * 0.3 + ph) * 0.4, 0, cos(t * 0.25 + ph) * 0.4)
			b.position = b.position.lerp(pos, 0.05)
			b.rotation.y = t * 0.3 + ph
			head.rotation.x = maxf(0.0, sin(t * 4.0 + ph)) * 0.9
			head.position.z = 0.08 + sin(t * 8.0 + ph) * 0.012
			corps.rotation.x = 0.0
		else:
			pos = place * 1.4 + Vector3(sin(t * 1.3 + ph) * 0.5, 0.6 + sin(t * 1.7 + ph) * 0.4, cos(t * 1.1 + ph) * 0.5)
			b.position = b.position.lerp(pos, 0.1)
			b.rotation.y = 0.0
			head.rotation.x = 0.0
			corps.rotation.x = 0.15
		for w in e[5]:
			var wn: Node3D = w[0]
			var sx: float = w[1]
			wn.rotation.z = (sx * sin(t * 18.0 + ph) * 0.9) if not au_sol else -sx * 0.1
			wn.rotation.y = 0.0 if not au_sol else sx * 1.3


func _anim_canards() -> void:
	var t: float = _clock
	for i in range(_bande.size()):
		var nd: Node3D = _bande[i][0]
		if i == 0:
			nd.position = Vector3(0, -0.04 + sin(t * 1.4) * 0.008, 0)
			nd.rotation = Vector3.ZERO
			continue
		# chaque caneton suit la trace de sa mère, à la file
		var k: int = mini(i * 4 + 1, _trace.size() - 1)
		if k < 0:
			continue
		var w: Vector3 = _trace[k]
		var lp: Vector3 = to_local(w)
		nd.position = nd.position.lerp(Vector3(lp.x, -0.02 + sin(t * 2.0 + float(i)) * 0.006, lp.z), 0.25)
		var k2: int = maxi(k - 3, 0)
		var dir: Vector3 = (_trace[k2] as Vector3) - w
		if dir.length() > 0.001:
			nd.rotation.y = atan2(dir.x, dir.z) - rotation.y
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = (0.6 if fmod(t + _flank * 3.0, 7.0) < 0.8 else 0.0) if state == "nage" else 0.0

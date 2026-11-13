extends "res://scripts/monstre_v137.gd"
## V138 : la faune d'Arcanelle, de l'Île de Braise et de Hautefond. (Les bêtes d'avant passent
## toujours par leurs fichiers : on ne fait ici que les nouvelles.)
## Des caractères nouveaux :
##  - voleur (grand corbeau d'Arcanelle) : la bande tourne au-dessus de la lande ; l'un d'eux se
##    pose près du héros, sautille jusqu'à lui et lui vole des pièces. Un coup, il les lâche ;
##  - curieuse (hermine) : elle suit le héros à distance, se dresse pour le regarder, et file
##    s'il s'approche trop ;
##  - prélasse (iguanes marins de Braise) : ils se chauffent sur la côte ; dérangés, ils hochent
##    la tête, éternuent leur sel, puis s'écartent sans se presser ;
##  - charognard (vautours fauves) : ils planent très haut… et descendent tourner au-dessus du
##    héros quand il est mal en point ; l'un d'eux se pose, et attend ;
##  - phalènes (phalènes de braise, la nuit) : attirées par la lumière, elles tournent autour du
##    héros ;
##  - harceleur (molosses des cendres, la nuit) : ils aboient à distance, l'un fonce mordre et
##    repart aussitôt ; puis c'est l'autre ;
##  - falaise (macareux de Hautefond) : sur la côte ; dérangés, ils s'envolent au-dessus de la mer
##    et reviennent se poser quand on est parti ;
##  - chasse basse (chouette effraie, la nuit) : elle survole les prés au ras de l'herbe, fait du
##    sur-place, puis plonge.
## Et le mouton, en troupeau comme les chevaux des Moaïs (mais il ne rue pas : il s'enfuit).

const SPECS138 := {
	"corbeau": {"pv": 6, "vitesse": 6.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 14.0, "laisse": 80.0,
		"rayon": 0.4, "haut": 0.0, "nom": "Grand corbeau", "genre": "voleur", "vol": true, "col": ["boule", 0.3, 0.0]},
	"hermine": {"pv": 3, "vitesse": 4.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 9.0, "laisse": 40.0,
		"rayon": 0.25, "haut": 0.1, "nom": "Hermine", "genre": "curieuse", "col": ["boite", Vector3(0.15, 0.15, 0.35)]},
	"iguane_marin": {"pv": 10, "vitesse": 0.9, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 3.0, "laisse": 30.0,
		"rayon": 0.45, "haut": 0.15, "nom": "Iguane marin", "genre": "prelasse", "col": ["boite", Vector3(0.3, 0.25, 0.9)]},
	"vautour_fauve": {"pv": 14, "vitesse": 6.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 60.0, "laisse": 120.0,
		"rayon": 0.7, "haut": 0.0, "nom": "Vautour fauve", "genre": "charognard", "vol": true, "col": ["boule", 0.5, 0.0]},
	"phalene_braise": {"pv": 99, "vitesse": 1.4, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 7.0, "laisse": 30.0,
		"rayon": 0.6, "haut": 0.0, "nom": "Phalènes de braise", "genre": "phalenes", "vol": true, "col": ["boule", 0.4, 0.0]},
	"molosse_cendre": {"pv": 14, "vitesse": 4.8, "degats": 1, "portee": 1.6, "armer": 0.3, "repos": 1.0, "vue": 16.0, "laisse": 40.0,
		"rayon": 0.5, "haut": 0.55, "nom": "Molosse des cendres", "genre": "harceleur", "col": ["boite", Vector3(0.45, 0.7, 1.1)]},
	"macareux": {"pv": 3, "vitesse": 5.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 6.0, "laisse": 60.0,
		"rayon": 0.25, "haut": 0.15, "nom": "Macareux moine", "genre": "falaise", "col": ["boite", Vector3(0.2, 0.3, 0.2)]},
	"mouton": {"pv": 12, "vitesse": 1.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 7.0, "laisse": 80.0,
		"rayon": 0.55, "haut": 0.6, "nom": "Mouton", "genre": "troupeau", "col": ["boite", Vector3(0.5, 0.8, 1.1)]},
	"effraie": {"pv": 5, "vitesse": 4.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 5.0, "laisse": 80.0,
		"rayon": 0.4, "haut": 0.0, "nom": "Chouette effraie", "genre": "chasse_basse", "vol": true, "col": ["boule", 0.3, 0.0]},
}
const SOUNDS138 := {
	"corbeau": ["corbeau_croasse", "corbeau_croasse"], "hermine": ["", ""], "iguane_marin": ["eternuement", ""],
	"vautour_fauve": ["", ""], "phalene_braise": ["", ""], "molosse_cendre": ["molosse_jappe", "molosse_jappe"],
	"macareux": ["macareux_grogne", "macareux_grogne"], "mouton": ["mouton_bele", "mouton_bele"], "effraie": ["effraie_cri", "effraie_cri"],
}
const ALERTES138 := {
	"corbeau": "Des corbeaux ! Ils aiment ce qui brille : si l'un d'eux se pose près de toi, méfie-toi de ta bourse… et frappe-le s'il s'envole avec tes pièces.",
	"molosse_cendre": "Des molosses des cendres ! Ils aboient de loin, puis l'un fonce mordre et repart aussitôt : garde-les devant toi et frappe celui qui charge.",
}
const GENRES138 := ["voleur", "curieuse", "prelasse", "charognard", "phalenes", "harceleur", "falaise", "chasse_basse"]

static var _tex138: Dictionary = {}

var butin_n: int = 0                      # corbeau : les pièces volées
var _piece: Node3D                        # la pièce dans son bec
var _vole: bool = false                   # macareux : en vol
var _fleece_face: Color = Color(0.85, 0.8, 0.72)
# tests
var eternuements: int = 0
var fuites: int = 0
var plongeons: int = 0
var charges: int = 0


static func spec_of(k: String) -> Dictionary:
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
	return SPECS138.has(k) or SPECS137.has(k) or SPECS136.has(k) or SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS138.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS138[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = int(spec["degats"]) == 0 or bool(spec.get("paisible", false))
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	collision_layer = 0 if (vol or k == "macareux") else 1
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
		"corbeau":
			_build_corbeau()
		"hermine":
			_build_hermine()
		"iguane_marin":
			_build_iguane()
		"vautour_fauve":
			_build_vautour()
		"phalene_braise":
			_build_phalenes()
		"molosse_cendre":
			_build_molosse()
		"macareux":
			_build_macareux()
		"mouton":
			_build_mouton()
		"effraie":
			_build_effraie()
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
	_cd136 = randf_range(2.0, 6.0)
	match k:
		"corbeau":
			_alt = randf_range(5.0, 7.0)
			state = "vol"
		"vautour_fauve":
			_alt = randf_range(24.0, 30.0)
			state = "vol"
		"phalene_braise":
			_alt = randf_range(1.0, 1.6)
			state = "vol"
		"effraie":
			_alt = randf_range(2.6, 3.4)
			state = "quete"
			_cd136 = randf_range(5.0, 9.0)
		"iguane_marin":
			state = "bain"
		"macareux":
			state = "pose"
		_:
			state = "erre"
	_base_scale = _visual.scale


# =================================================================== textures

## La robe du molosse des cendres : gris charbon ; et, pour la lueur, des fêlures de braise.
func _molosse_tex(braise: bool) -> Texture2D:
	var key: String = "molosse_braise" if braise else "molosse"
	if _tex138.has(key):
		return _tex138[key]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1381
	for y in range(n):
		for x in range(n):
			if braise:
				img.set_pixel(x, y, Color(0, 0, 0))
			else:
				var v: float = 1.0 + rng.randf_range(-0.15, 0.15) + 0.08 * sin(float(x) * 0.8) * sin(float(y) * 0.6)
				img.set_pixel(x, y, Color(0.1 * v, 0.09 * v, 0.085 * v))
	if braise:
		# des fêlures : de petits chemins brisés
		for i in range(20):
			var px: float = rng.randf() * n
			var py: float = rng.randf() * n
			var a: float = rng.randf() * TAU
			for k in range(rng.randi_range(14, 30)):
				a += rng.randf_range(-0.6, 0.6)
				px += cos(a) * 1.2
				py += sin(a) * 1.2
				_disque(img, px, py, 0.9, Color(1.0, 0.45, 0.08).darkened(rng.randf_range(0.0, 0.3)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex138[key] = t
	return t


# =================================================================== modèles : Arcanelle

## Le grand corbeau : tout noir, lustré de bleu, le gros bec épais, la gorge hérissée, la queue
## en coin ; les grandes rémiges écartées comme des doigts.
func _build_corbeau() -> void:
	var noir := _vmat(Color(0.05, 0.05, 0.065), 0.36)
	noir.metallic_specular = 0.8
	var fl: StandardMaterial3D = _flat_of(noir, 1.0)
	var bec := _mat(Color(0.03, 0.03, 0.035), 0.3)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("corbeau:corps", [Vector3(0, 0, -0.2), Vector3(0, 0, -0.05), Vector3(0, 0.01, 0.08), Vector3(0, 0.03, 0.15)], [0.035, 0.075, 0.075, 0.05], 12, 1.0, Callable(self, "_shade_dos")), noir)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.05, 0.2)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), fl, Vector3.ZERO, Vector3(0.05, 0.048, 0.06))
	_mesh(head, _unit_sphere(), fl, Vector3(0, -0.03, 0.0), Vector3(0.04, 0.035, 0.045))
	_put(head, _tube_fn("corbeau:bec", [Vector3(0, 0.008, 0.045), Vector3(0, 0.007, 0.09), Vector3(0, -0.003, 0.12), Vector3(0, -0.016, 0.126)], [0.021, 0.015, 0.008, 0.003], 8, 1.0, Callable()), bec)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), _mat(Color(0.12, 0.07, 0.04), 0.1), Vector3(sx * 0.036, 0.014, 0.03), Vector3.ONE * 0.007)
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.05, 0.03, 0.06)
		body.add_child(wing)
		_mesh(wing, _unit_sphere(), fl, Vector3(sx * 0.14, 0.0, -0.04), Vector3(0.15, 0.012, 0.09))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.27, 0.0, 0.0)
		wing.add_child(hand)
		_mesh(hand, _unit_sphere(), fl, Vector3(sx * 0.08, 0.0, -0.05), Vector3(0.1, 0.01, 0.075))
		for k2 in range(5):
			var b0 := Vector3(sx * 0.1, 0.0, -0.01 - float(k2) * 0.025)
			var b1 := Vector3(sx * (0.27 - float(k2) * 0.02), -0.003, -0.04 - float(k2) * 0.04)
			_put(hand, _tube_fn("corbeau:remige%d%s" % [k2, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.022, 0.018, 0.005], 6, 0.2, Callable()), noir)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.0, -0.2)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("corbeau:queue", [Vector3.ZERO, Vector3(0, -0.005, -0.1), Vector3(0, -0.008, -0.19)], [0.03, 0.055, 0.02], 8, 0.12, Callable()), noir)
	var legs := Node3D.new()
	legs.position = Vector3(0, -0.06, 0.02)
	body.add_child(legs)
	_pivots["pattes"] = legs
	for sx in [-1.0, 1.0]:
		_mesh(legs, _cyl(0.006, 0.006, 0.09), bec, Vector3(sx * 0.025, -0.045, 0))
		for k3 in range(3):
			var a: float = (float(k3) - 1.0) * 0.45
			_mesh(legs, _cyl(0.003, 0.004, 0.04), bec, Vector3(sx * 0.025 + sin(a) * 0.015, -0.09, cos(a) * 0.018), Vector3.ONE, Vector3(PI * 0.5, a, 0))
	_piece = Node3D.new()
	_piece.position = Vector3(0, -0.012, 0.12)
	head.add_child(_piece)
	var orm := _mat(Color(1.0, 0.8, 0.25), 0.25)
	orm.metallic = 0.9
	_mesh(_piece, _cyl(0.022, 0.022, 0.004), orm, Vector3.ZERO, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	_piece.visible = false


## L'hermine en robe d'hiver : toute blanche, longue et fine, les yeux noirs brillants, le bout de
## la queue noir.
func _build_hermine() -> void:
	var blanc := _vmat(Color(0.95, 0.94, 0.9), 0.95)
	var ombre := func(s: float, ang: float) -> float:
		return 0.9 + 0.1 * (0.5 - 0.5 * sin(ang)) + 0.02 * sin(s * 31.0 + ang * 5.0)
	var bout := func(s: float, ang: float) -> float:
		return 0.06 if s > 0.62 else float(ombre.call(s, ang))
	_build_mammal({"long": 0.3, "haut": 0.1, "rayon": 0.036, "mat": blanc, "shade": ombre, "shade_queue": bout,
		"museau": 0.03, "bout": 0.32, "crane": 0.66, "oreille": 0.36, "forme_oreille": "rond", "ecart": 0.5, "queue": 0.17,
		"style": "pend", "touffe": 0.45, "patte": 0.32, "pied": 1.0, "cou": 1.1, "port": 0.55, "taille": 1.0, "oeil": 0.2,
		"sombre": Color(0.02, 0.02, 0.02), "teinte": 0.97, "segs": 12})


# =================================================================== modèles : l'Île de Braise

## L'iguane marin : trapu, gris-noir et rugueux, une crête de piques le long du dos, la tête
## camuse encroûtée du sel qu'il éternue, la longue queue aplatie, les griffes crochues.
func _build_iguane() -> void:
	var peau := _vmat(Color(0.17, 0.155, 0.14), 0.88)
	var rugueux := func(s: float, ang: float) -> float:
		return 0.75 + 0.25 * absf(sin(s * 53.0 + ang * 7.0) * sin(s * 17.0 - ang * 3.0)) + 0.1 * smoothstep(0.0, -0.8, sin(ang))
	var fl: StandardMaterial3D = _flat_of(peau, 0.9)
	var sel := _mat(Color(0.88, 0.86, 0.8), 0.95)
	var pique := _mat(Color(0.35, 0.33, 0.3), 0.8)
	var griffe := _mat(Color(0.05, 0.05, 0.05), 0.4)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(10):
		var u: float = float(i) / 9.0
		sp.append(Vector3(0, 0.13, lerpf(-0.3, 0.25, u)))
		rr.append(lerpf(0.06, 0.11, sin(u * PI * 0.9 + 0.2)))
	_put(body, _tube_fn("iguane:corps", sp, rr, 12, 0.78, rugueux), peau)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.15, 0.3)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_fn("iguane:tete", [Vector3(0, 0, -0.04), Vector3(0, 0.006, 0.04), Vector3(0, -0.004, 0.1)], [0.055, 0.05, 0.034], 12, 0.85, rugueux), peau)
	_mesh(head, _unit_sphere(), sel, Vector3(0, 0.035, 0.05), Vector3(0.035, 0.012, 0.04))
	_mesh(head, _unit_sphere(), sel, Vector3(0, 0.02, 0.09), Vector3(0.022, 0.012, 0.018))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), _mat(Color(0.3, 0.12, 0.06), 0.1), Vector3(sx * 0.04, 0.018, 0.035), Vector3.ONE * 0.009)
		_mesh(head, _unit_sphere(), fl, Vector3(sx * 0.045, -0.015, 0.0), Vector3(0.02, 0.025, 0.03))
	for i in range(18):
		var u2: float = float(i) / 17.0
		var z: float = lerpf(0.33, -0.3, u2)
		var hh: float = 0.035 + 0.015 * sin(u2 * PI)
		var top: float = 0.13 + 0.1 * 0.78 * sin(clampf(u2, 0.05, 0.95) * PI * 0.9 + 0.2) + (0.03 if z > 0.25 else 0.0)
		_mesh(body, _cyl(0.0, 0.009, hh), pique, Vector3(0, top + hh * 0.4, z), Vector3(0.6, 1.0, 1.0))
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.12, -0.3)
	body.add_child(tail)
	_pivots["queue"] = tail
	var tp: Array = []
	var tr: Array = []
	for i in range(9):
		var u3: float = float(i) / 8.0
		tp.append(Vector3(0, -0.04 * u3, -u3 * 0.65))
		tr.append(lerpf(0.06, 0.008, u3))
	_put(tail, _tube_fn("iguane:queue", tp, tr, 10, 1.4, rugueux), peau)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.08, 0.12, 0.18 if front else -0.22)
		body.add_child(leg)
		var lp: Array = [Vector3.ZERO, Vector3(sx2 * 0.09, 0.0, 0.0), Vector3(sx2 * 0.13, -0.07, 0.04), Vector3(sx2 * 0.14, -0.115, 0.06)]
		_put(leg, _tube_fn("iguane:patte%s" % ("g" if sx2 < 0.0 else "d"), lp, [0.035, 0.028, 0.022, 0.018], 8, 1.0, rugueux), peau)
		for f in range(5):
			var a: float = (float(f) - 2.0) * 0.3 + sx2 * 0.2
			_mesh(leg, _cyl(0.001, 0.004, 0.04), griffe, (lp[3] as Vector3) + Vector3(sin(a) * 0.025, -0.006, 0.02 + cos(a) * 0.015), Vector3.ONE, Vector3(PI * 0.5 + 0.15, a, 0))
		_legs135.append([leg, sx2, i, 0.0])


## Le vautour fauve : immense, le corps et les couvertures couleur sable, les rémiges et la queue
## brun-noir, la collerette blanche duveteuse, la tête et le long cou nus et pâles, le bec crochu.
func _build_vautour() -> void:
	var sable := _vmat(Color(0.62, 0.47, 0.31), 0.9)
	var sable_f: StandardMaterial3D = _flat_of(sable, 0.95)
	var sombre := _vmat(Color(0.14, 0.11, 0.09), 0.8)
	var blanc := _mat(Color(0.93, 0.91, 0.86), 0.95)
	var tete := _mat(Color(0.86, 0.82, 0.74), 0.85)
	var bec := _mat(Color(0.75, 0.7, 0.5), 0.4)
	var rachis := func(s: float, ang: float) -> float:
		return 0.8 + 0.2 * smoothstep(0.7, 1.0, sin(s * 50.0)) + 0.05 * sin(ang * 3.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		sp.append(Vector3(0, -0.02 * sin(u * PI), lerpf(-0.36, 0.26, u)))
		rr.append(lerpf(0.06, 0.15, smoothstep(0.0, 0.55, u)) * (1.0 - 0.3 * smoothstep(0.8, 1.0, u)))
	_put(body, _tube_fn("vautour:corps", sp, rr, 14, 0.95, Callable(self, "_shade_dos")), sable)
	_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.03, 0.26), Vector3(0.09, 0.07, 0.07))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.06, 0.3)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_fn("vautour:cou", [Vector3(0, -0.02, -0.02), Vector3(0, 0.0, 0.06), Vector3(0, 0.01, 0.12)], [0.035, 0.03, 0.03], 10, 1.0, Callable()), tete)
	_mesh(head, _unit_sphere(), tete, Vector3(0, 0.015, 0.15), Vector3(0.045, 0.042, 0.055))
	_put(head, _tube_fn("vautour:bec", [Vector3(0, 0.015, 0.19), Vector3(0, 0.012, 0.23), Vector3(0, -0.005, 0.25), Vector3(0, -0.025, 0.252)], [0.018, 0.013, 0.008, 0.003], 8, 0.9, Callable()), bec)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), _mat(Color(0.25, 0.15, 0.08), 0.1), Vector3(sx * 0.032, 0.025, 0.18), Vector3.ONE * 0.008)
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.08, 0.03, 0.06)
		body.add_child(wing)
		var ap: Array = [Vector3(0, 0, -0.08), Vector3(sx * 0.3, 0.02, -0.1), Vector3(sx * 0.6, 0.03, -0.09)]
		_put(wing, _tube_fn("vautour:bras%s" % ("g" if sx < 0.0 else "d"), ap, [0.2, 0.2, 0.17], 10, 0.08, rachis), sombre)
		_mesh(wing, _unit_sphere(), sable_f, Vector3(sx * 0.3, 0.012, -0.02), Vector3(0.28, 0.012, 0.1))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.6, 0.03, 0.0)
		wing.add_child(hand)
		_mesh(hand, _unit_sphere(), _flat_of(sombre, 1.0), Vector3(sx * 0.1, 0.0, -0.09), Vector3(0.12, 0.012, 0.14))
		for k2 in range(7):
			var b0 := Vector3(sx * 0.12, 0.0, 0.03 - float(k2) * 0.035)
			var b1 := Vector3(sx * (0.42 - float(k2) * 0.025), -0.004, -0.0 - float(k2) * 0.045)
			_put(hand, _tube_fn("vautour:remige%d%s" % [k2, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.03, 0.026, 0.008], 6, 0.18, rachis), sombre)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.0, -0.34)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("vautour:queue", [Vector3.ZERO, Vector3(0, -0.005, -0.12), Vector3(0, -0.01, -0.2)], [0.06, 0.09, 0.07], 8, 0.1, rachis), sombre)
	var legs := Node3D.new()
	legs.position = Vector3(0, -0.1, 0.03)
	body.add_child(legs)
	_pivots["pattes"] = legs
	for sx in [-1.0, 1.0]:
		_mesh(legs, _cyl(0.014, 0.014, 0.14), _mat(Color(0.55, 0.52, 0.48), 0.6), Vector3(sx * 0.06, -0.07, 0.0))


## Les phalènes de braise : de petits papillons de nuit au corps velu sombre, les ailes rouge
## orangé qui rougeoient comme des braises.
func _build_phalenes() -> void:
	var braise := _mat(Color(0.9, 0.32, 0.06), 0.6, 1.2)
	braise.emission = Color(1.0, 0.38, 0.05)
	_eye_glow.append(braise)
	var corps := _mat(Color(0.12, 0.08, 0.06), 0.9)
	for i in range(7):
		var b := Node3D.new()
		_visual.add_child(b)
		_put(b, _tube_fn("phalene:corps", [Vector3(0, 0, -0.018), Vector3(0, 0.001, 0.0), Vector3(0, 0.002, 0.014)], [0.004, 0.006, 0.005], 6, 1.0, Callable()), corps)
		var ailes: Array = []
		for sx in [-1.0, 1.0]:
			for avant in [true, false]:
				var w := Node3D.new()
				w.position = Vector3(sx * 0.003, 0.002, 0.004 if avant else -0.004)
				b.add_child(w)
				var c: Vector3 = Vector3(sx * 0.022, 0.0, -0.002) if avant else Vector3(sx * 0.016, 0.0, -0.012)
				var sc: Vector3 = Vector3(0.024, 0.001, 0.014) if avant else Vector3(0.016, 0.001, 0.012)
				_mesh(w, _unit_sphere(), braise, c, sc)
				ailes.append([w, sx, avant])
		_papillons.append([b, ailes, randf() * TAU, i])


## Le molosse des cendres : un grand chien maigre, gris charbon, la poitrine profonde et la taille
## creuse ; dans son poil, des fêlures qui rougeoient comme des braises ; les yeux orange.
func _build_molosse() -> void:
	var fur := _mat(Color(1, 1, 1), 0.9)
	fur.vertex_color_use_as_albedo = true
	fur.albedo_texture = _molosse_tex(false)
	fur.uv1_triplanar = true
	fur.uv1_scale = Vector3(2.4, 2.4, 2.4)
	fur.emission_enabled = true
	fur.emission = Color(1.0, 0.42, 0.08)
	fur.emission_texture = _molosse_tex(true)
	fur.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	fur.emission_energy_multiplier = 1.0
	_eye_glow.append(fur)
	_build_mammal({"long": 0.75, "haut": 0.66, "rayon": 0.165, "mat": fur, "shade": _selle(0.1), "museau": 0.2, "bout": 0.24,
		"crane": 0.62, "oreille": 0.6, "forme_oreille": "pointe", "ecart": 0.25, "queue": 0.42, "style": "pend", "touffe": 0.28,
		"patte": 0.17, "pied": 0.9, "cou": 0.85, "port": 0.7, "taille": 0.6, "yeux": Color(1.0, 0.45, 0.1), "oeil": 0.13,
		"sombre": Color(0.03, 0.02, 0.02), "teinte": 0.85, "dedans": Color(0.3, 0.12, 0.06)})


# =================================================================== modèles : Hautefond

## Le macareux moine : petit, dressé, le dos noir et le ventre blanc, les joues blanc-gris, le
## grand bec en triangle rayé de bleu-gris, de jaune et d'orange, les pattes orange.
func _build_macareux() -> void:
	var noir := _vmat(Color(0.05, 0.05, 0.06), 0.5)
	var blanc := _mat(Color(0.95, 0.95, 0.93), 0.8)
	var joue := _mat(Color(0.86, 0.86, 0.84), 0.85)
	var orange := _mat(Color(0.95, 0.42, 0.1), 0.5)
	var gris_bleu := _mat(Color(0.36, 0.42, 0.5), 0.5)
	var jaune := _mat(Color(0.95, 0.8, 0.2), 0.5)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("macareux:corps", [Vector3(0, 0.05, -0.015), Vector3(0, 0.13, 0.0), Vector3(0, 0.22, 0.0)], [0.068, 0.085, 0.062], 12, 0.95, Callable()), noir)
	_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.13, 0.03), Vector3(0.068, 0.085, 0.06))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.27, 0.0)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), _flat_of(noir, 1.0), Vector3.ZERO, Vector3(0.055, 0.052, 0.055))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), joue, Vector3(sx * 0.028, -0.006, 0.02), Vector3(0.03, 0.04, 0.035))
		_mesh(head, _unit_sphere(), _mat(Color(0.05, 0.05, 0.05), 0.1), Vector3(sx * 0.04, 0.008, 0.035), Vector3.ONE * 0.007)
		_mesh(head, _unit_sphere(), _mat(Color(0.85, 0.3, 0.15), 0.4), Vector3(sx * 0.039, 0.008, 0.033), Vector3.ONE * 0.009)
	_mesh(head, _unit_sphere(), jaune, Vector3(0, -0.004, 0.047), Vector3(0.013, 0.036, 0.006))
	_mesh(head, _unit_sphere(), gris_bleu, Vector3(0, -0.006, 0.058), Vector3(0.012, 0.034, 0.016))
	_mesh(head, _unit_sphere(), orange, Vector3(0, -0.01, 0.078), Vector3(0.011, 0.028, 0.022))
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.065, 0.2, -0.01)
		body.add_child(wing)
		_mesh(wing, _unit_sphere(), _flat_of(noir, 1.0), Vector3(0, -0.06, -0.02), Vector3(0.014, 0.08, 0.04))
		_wings.append([wing, wing, sx])
		_pivots["aile%d" % int(sx)] = wing
		_mesh(body, _unit_sphere(), orange, Vector3(sx * 0.03, 0.01, 0.025), Vector3(0.02, 0.008, 0.035))


## Le mouton : une épaisse toison crème toute bouclée, la tête et les pattes fines (blanches, ou
## noires pour un mouton sur trois), les oreilles à l'horizontale.
func _build_mouton() -> void:
	var noire: bool = randi() % 3 == 0
	_fleece_face = Color(0.1, 0.085, 0.08) if noire else Color(0.86, 0.81, 0.72)
	var face := _mat(_fleece_face, 0.85)
	var peau := _vmat(_fleece_face, 0.9)
	_build_mammal({"long": 0.85, "haut": 0.72, "rayon": 0.17, "mat": peau, "museau": 0.12, "bout": 0.38, "crane": 0.62,
		"oreille": 0.5, "forme_oreille": "pointe", "ecart": 1.35, "queue": 0.12, "style": "pend", "touffe": 0.4, "patte": 0.13,
		"pied": 0.6, "cou": 0.8, "port": 0.6, "taille": 0.9, "oeil": 0.13, "sombre": Color(0.05, 0.04, 0.04), "teinte": 0.95,
		"dedans": _fleece_face.lightened(0.15)})
	var laine := _vmat(Color(0.88, 0.85, 0.78), 0.98)
	var boucles := func(d: Vector3) -> Vector3:
		var b: float = 1.0 + 0.07 * sin(d.x * 17.0) * sin(d.y * 15.0) * sin(d.z * 13.0) + 0.03 * sin(d.x * 41.0 + d.z * 37.0)
		return Vector3(d.x * 0.3, d.y * 0.27, d.z * 0.52) * b
	var ombre := func(d: Vector3, _p: Vector3) -> Color:
		var v: float = 0.82 + 0.18 * (0.5 + 0.5 * d.y) + 0.06 * sin(d.x * 30.0) * sin(d.z * 28.0)
		return Color(v, v, v)
	var body: Node3D = _pivots["corps"]
	var fleece := MeshInstance3D.new()
	fleece.mesh = _blob_mesh("mouton:toison", boucles, ombre, 18, 28)
	fleece.material_override = laine
	fleece.position = Vector3(0, 0.6, -0.02)
	body.add_child(fleece)
	var head: Node3D = _pivots["tete"]
	var kids: Array = head.get_children()
	for i in [0, 1, 3]:
		if i < kids.size() and kids[i] is MeshInstance3D:
			(kids[i] as MeshInstance3D).material_override = face
	_mesh(head, _unit_sphere(), laine, Vector3(0, 0.07, -0.02), Vector3(0.07, 0.04, 0.07))


## La chouette effraie : le dessus doré moucheté de gris, le dessous tout blanc, le grand disque
## facial en cœur, les yeux noirs ; de longues pattes qui pendent quand elle plonge.
func _build_effraie() -> void:
	var dos := _vmat(Color(0.82, 0.66, 0.42), 0.9)
	var dos_f: StandardMaterial3D = _flat_of(dos, 0.95)
	var blanc := _mat(Color(0.97, 0.96, 0.93), 0.9)
	var bord := _mat(Color(0.62, 0.46, 0.3), 0.9)
	var mouchete := func(s: float, ang: float) -> float:
		return 0.85 + 0.15 * sin(s * 47.0 + ang * 9.0) * sin(ang * 5.0 - s * 13.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("effraie:corps", [Vector3(0, 0, -0.16), Vector3(0, 0.01, 0.0), Vector3(0, 0.02, 0.12)], [0.05, 0.09, 0.07], 12, 0.95, mouchete), dos)
	_mesh(body, _unit_sphere(), blanc, Vector3(0, -0.03, 0.0), Vector3(0.075, 0.06, 0.13))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.04, 0.17)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), dos_f, Vector3.ZERO, Vector3(0.07, 0.066, 0.065))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), bord, Vector3(sx * 0.028, -0.006, 0.045), Vector3(0.044, 0.064, 0.02), Vector3(0, 0, sx * 0.25))
		_mesh(head, _unit_sphere(), blanc, Vector3(sx * 0.027, -0.006, 0.05), Vector3(0.039, 0.058, 0.02), Vector3(0, 0, sx * 0.25))
		_mesh(head, _unit_sphere(), _mat(Color(0.02, 0.02, 0.02), 0.1), Vector3(sx * 0.022, 0.004, 0.064), Vector3.ONE * 0.009)
	_mesh(head, _unit_sphere(), _mat(Color(0.85, 0.78, 0.7), 0.5), Vector3(0, -0.018, 0.066), Vector3(0.008, 0.014, 0.01))
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.06, 0.03, 0.04)
		body.add_child(wing)
		_mesh(wing, _unit_sphere(), dos_f, Vector3(sx * 0.2, 0.0, -0.04), Vector3(0.21, 0.016, 0.11))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.38, 0.0, 0.0)
		wing.add_child(hand)
		_mesh(hand, _unit_sphere(), dos_f, Vector3(sx * 0.1, 0.0, -0.05), Vector3(0.13, 0.013, 0.09))
		for k2 in range(5):
			var b0 := Vector3(sx * 0.12, 0.0, 0.0 - float(k2) * 0.028)
			var b1 := Vector3(sx * (0.27 - float(k2) * 0.02), -0.003, -0.04 - float(k2) * 0.038)
			_put(hand, _tube_fn("effraie:remige%d%s" % [k2, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.026, 0.023, 0.01], 6, 0.18, mouchete), dos)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	_mesh(body, _unit_sphere(), dos_f, Vector3(0, 0.0, -0.2), Vector3(0.05, 0.01, 0.07))
	var legs := Node3D.new()
	legs.position = Vector3(0, -0.04, 0.02)
	body.add_child(legs)
	_pivots["pattes"] = legs
	for sx in [-1.0, 1.0]:
		_mesh(legs, _cyl(0.009, 0.007, 0.11), blanc, Vector3(sx * 0.03, -0.055, 0.0))
		_mesh(legs, _cyl(0.002, 0.005, 0.03), _mat(Color(0.05, 0.05, 0.05), 0.4), Vector3(sx * 0.03, -0.115, 0.015), Vector3.ONE, Vector3(PI * 0.5, 0, 0))


# =================================================================== sons, alertes, butin, coups

func _sound(what: String) -> void:
	if not SPECS138.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS138.get(kind, ["", ""])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * maxf(hit_height, 0.3))


func alert_text() -> String:
	if SPECS138.has(kind):
		return str(ALERTES138.get(kind, ""))
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS138.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"corbeau":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.3:
				g.append(["plume_corbeau", 1])
		"hermine", "macareux":
			if rng.randf() < 0.5:
				g.append(["piece", 1])
		"iguane_marin":
			g.append(["piece", rng.randi_range(1, 3)])
		"vautour_fauve":
			g.append(["piece", rng.randi_range(2, 4)])
		"molosse_cendre":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.15:
				g.append(["obsidienne", 1])
		"mouton":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.4:
				g.append(["pelote_laine", 1])
		"effraie":
			g.append(["piece", rng.randi_range(1, 2)])
	return g


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS138.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	if kind == "phalene_braise":
		_envol_papillons(from_pos)
		return
	if kind == "corbeau" and butin != "" and manager.has_method("corbeau_lache"):
		manager.corbeau_lache(self)
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	match kind:
		"corbeau":
			_piece.visible = false
			state = "fuite_air"
			timer = 3.0
		"hermine":
			state = "fuite"
			timer = 1.2
			fuites += 1
		"iguane_marin":
			state = "s_en_va"
			timer = 4.0
		"vautour_fauve", "effraie":
			state = "fuite_air"
			timer = 3.0
		"macareux":
			_envol_macareux()
		"mouton":
			_panique(from_pos)
		"molosse_cendre":
			manager.release_token(self)
			state = "repli"
			timer = 1.0


func _die() -> void:
	if kind == "corbeau" and butin != "" and manager != null and manager.has_method("corbeau_lache"):
		manager.corbeau_lache(self)
	if kind == "molosse_cendre" and manager != null:
		manager.release_token(self)
	if _piece != null:
		_piece.visible = false
	super._die()


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES138):
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
	_hit_cd -= delta
	var p: Vector3 = _player()
	if _last_p != Vector3.INF:
		_hero_v = lerpf(_hero_v, Vector2(p.x - _last_p.x, p.z - _last_p.z).length() / maxf(delta, 0.001), clampf(delta * 6.0, 0.0, 1.0))
	_last_p = p
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var vue: float = float(spec["vue"])
	match genre:
		"voleur":
			_corbeau(delta, p, dist, dir_p)
			_animate132(delta, 1.0)
			return
		"charognard":
			_vautour(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"phalenes":
			_fly_phalenes(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"chasse_basse":
			_fly_effraie(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"falaise":
			if _vole:
				_fly_macareux(delta, p, dist)
				_animate132(delta, 1.0)
				return
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	match genre:
		"curieuse":
			move = _hermine(delta, dist, dir_p, sp, vue)
		"prelasse":
			move = _iguane(delta, dist, dir_p, p, sp, vue)
		"harceleur":
			move = _molosse(delta, dist, dir_p, dy, p, sp, vue, from_home)
		"falaise":
			move = _macareux_sol(delta, dist, dir_p, sp, vue)
	# ni dans la mer (sauf l'iguane), ni dans le vide, ni sur la lave
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		var mer: bool = genre != "prelasse" and _ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead)
		var lave: bool = manager.has_method("lave") and bool(manager.lave(ahead, ile_sol if ile_sol != "" else "-"))
		if mer or lave or _au_vide(ahead):
			move = -move * 0.3
			_wander_to = Vector3.INF
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


# ------------------------------------------------------------------- le corbeau voleur

func _peut_voler() -> bool:
	if manager == null or manager.main == null:
		return false
	var inv: Node = manager.main.get("inventory_v28")
	return inv != null and int(inv.count("piece")) > 0 and float(manager.get("_corbeau_cd")) <= 0.0


func _corbeau(delta: float, p: Vector3, dist: float, dir_p: Vector3) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	var sol: bool = false
	match state:
		"vol":
			_orbit_a += delta * 0.6
			var rr: float = 7.0 + _flank * 2.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _plancher(target) + _alt + sin(_clock * 1.1 + _flank) * 0.6
			speed *= 0.6
			_cd136 -= delta
			if dist < float(spec["vue"]) and _cd136 <= 0.0 and _peut_voler() and manager.take_token(self):
				# il se pose à côté du héros
				var c: Vector3 = p - dir_p * 1.8
				_cible = Vector3(c.x, _ground_at(c), c.z)
				state = "descend"
				timer = 7.0
				_sound("menace")
				manager.alert(self)
		"descend":
			target = _cible + Vector3.UP * 0.12
			if global_position.distance_to(target) < 0.5:
				state = "sautille"
				timer = 2.0
			elif timer <= 0.0:
				state = "envol"
				timer = 2.5
		"sautille":
			sol = true
			# de petits sauts vers le héros, les ailes repliées
			var ph: float = fmod(_clock * 3.0, 1.0)
			if dist > 0.85:
				global_position += dir_p * delta * 1.1 * (1.0 if ph < 0.5 else 0.2)
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			global_position.y = _ground_at(global_position) + 0.12 + absf(sin(ph * PI)) * 0.06
			if dist <= 0.95 or timer <= 0.0:
				manager.release_token(self)
				if manager.corbeau_vole(self):
					_piece.visible = true
					state = "emporte"
					timer = 6.0
				else:
					state = "envol"
					timer = 2.5
		"emporte", "envol", "fuite_air":
			var out: Vector3 = global_position - p
			out.y = 0.0
			out = out.normalized() if out.length() > 0.1 else Vector3.FORWARD
			target = global_position + out * 6.0 + Vector3.UP * 3.0
			speed *= 0.9
			if timer <= 0.0:
				if state == "emporte" and butin != "":
					manager.corbeau_garde(self)
				_piece.visible = false
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0.0, global_position.z)
				_cd136 = randf_range(20.0, 30.0)
		_:
			state = "vol"
			target = global_position
	if sol:
		velocity = Vector3.ZERO
		rotation.y = atan2(facing.x, facing.z)
		_visual.rotation = Vector3.ZERO
	else:
		_voler137(delta, target, speed, 2.5)


# ------------------------------------------------------------------- l'hermine

func _hermine(delta: float, dist: float, dir_p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp) * 0.5
			if dist < vue:
				state = "suit"
		"suit":
			if dist < 2.8:
				state = "fuite"
				timer = 1.2
				fuites += 1
			elif dist > 6.0:
				# elle s'approche en zigzaguant un peu
				var zig: Vector3 = dir_p + Vector3(-dir_p.z, 0, dir_p.x) * sin(_clock * 3.0 + _flank) * 0.5
				facing = facing.lerp(zig.normalized(), clampf(delta * 8.0, 0.0, 1.0)).normalized()
				move = facing * sp * 0.8
			else:
				state = "guette"
				timer = randf_range(1.2, 2.2)
			if dist > vue * 1.8:
				state = "erre"
				home = global_position
		"guette":
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if dist < 2.8:
				state = "fuite"
				timer = 1.2
				fuites += 1
			elif timer <= 0.0:
				state = "suit"
				_flank = -_flank
		"fuite", "recul":
			if state == "recul":
				state = "fuite"
				timer = 1.0
			facing = facing.lerp(-dir_p, clampf(delta * 12.0, 0.0, 1.0)).normalized()
			move = facing * sp * 1.6
			if timer <= 0.0:
				state = "suit"
		_:
			state = "erre"
	return move


# ------------------------------------------------------------------- l'iguane marin

func _iguane(delta: float, dist: float, dir_p: Vector3, p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"bain":
			_cd136 -= delta
			if _cd136 <= 0.0:
				_cd136 = randf_range(6.0, 12.0)
				_eternue()
			if dist < vue:
				state = "menace"
				timer = 2.0
				_eternue()
		"menace":
			# il hoche la tête et éternue son sel vers le héros
			facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if dist < 1.8 or timer <= 0.0:
				if dist < vue:
					state = "s_en_va"
					timer = 4.0
					_fuite_dir = _loin_de(p)
				else:
					state = "bain"
			elif dist > vue + 1.0:
				state = "bain"
		"s_en_va", "recul":
			if state == "recul":
				state = "s_en_va"
				timer = 3.0
				_fuite_dir = _loin_de(p)
			facing = facing.lerp(_fuite_dir, clampf(delta * 3.0, 0.0, 1.0)).normalized()
			move = facing * sp
			if timer <= 0.0:
				state = "bain"
				home = global_position
		_:
			state = "bain"
	return move


func _eternue() -> void:
	eternuements += 1
	_sound("menace")
	var head: Node3D = _pivots.get("tete")
	if head != null:
		_puff(head.global_position + facing * 0.12 + Vector3.UP * 0.02, 6, Color(0.95, 0.95, 0.92, 0.8), 0.02, 0.07, 0.5, 0.6, 1.4)


## Une direction pour s'éloigner du héros (vers la mer de préférence, l'iguane y nage).
func _loin_de(p: Vector3) -> Vector3:
	var away: Vector3 = global_position - p
	away.y = 0.0
	away = away.normalized() if away.length() > 0.05 else -facing
	var down: Vector3 = _pente(false)
	return (away + down * 0.6).normalized()


# ------------------------------------------------------------------- le vautour fauve

func _hero_mal_en_point() -> float:
	var h: Node = manager.main.get("hero_v28") if manager != null and manager.main != null else null
	if h == null:
		return 1.0
	return float(h.hp) / maxf(float(h.HP_MAX), 1.0)


func _vautour(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	var ratio: float = _hero_mal_en_point()
	var sol: bool = false
	match state:
		"vol":
			_orbit_a += delta * 0.1
			var rr: float = 30.0 + _flank * 6.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _plancher(target) + _alt
			speed *= 0.7
			if ratio <= 0.4 and dist < float(spec["vue"]):
				state = "tourne_bas"
				_calm_t = 0.0
		"tourne_bas":
			# ils descendent tourner au-dessus du héros, en silence
			_orbit_a += delta * 0.45
			target = p + Vector3(cos(_orbit_a + _flank) * (7.0 + _flank * 2.0), 0, sin(_orbit_a + _flank) * (7.0 + _flank * 2.0))
			target.y = _plancher(target) + 7.0 + _flank
			speed *= 0.8
			_calm_t += delta
			if ratio > 0.6:
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0, global_position.z)
			elif _calm_t > 8.0 and _flank > -0.2:
				var a: float = randf() * TAU
				var c: Vector3 = p + Vector3(cos(a), 0, sin(a)) * 5.0
				_cible = Vector3(c.x, _ground_at(c), c.z)
				state = "atterrit"
				timer = 6.0
		"atterrit":
			target = _cible + Vector3.UP * 0.2
			speed *= 0.6
			if global_position.distance_to(target) < 0.6 or timer <= 0.0:
				state = "pose"
		"pose":
			sol = true
			var to: Vector3 = p - global_position
			to.y = 0.0
			if to.length() > 0.1:
				facing = facing.lerp(to.normalized(), clampf(delta * 2.0, 0.0, 1.0)).normalized()
			global_position.y = _ground_at(global_position) + 0.2
			if ratio > 0.6 or dist < 2.5:
				state = "fuite_air"
				timer = 3.0
		"fuite_air":
			target = global_position + Vector3(facing.x, 0, facing.z) * 8.0 + Vector3.UP * 6.0
			if timer <= 0.0:
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0, global_position.z)
		_:
			state = "vol"
			target = global_position
	if sol:
		velocity = Vector3.ZERO
		rotation.y = atan2(facing.x, facing.z)
		_visual.rotation = Vector3.ZERO
	else:
		_voler137(delta, target, speed, 1.0)


# ------------------------------------------------------------------- les phalènes

func _fly_phalenes(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"vol":
			target = home + Vector3(cos(_clock * 0.5 + _flank * 3.0) * 1.2, 0, sin(_clock * 0.61) * 1.2)
			target.y = _ground_at(target) + _alt + sin(_clock * 1.9) * 0.25
			speed *= 0.6
			if dist < float(spec["vue"]):
				state = "lumiere"
				poses += 1
		"lumiere":
			# attirées par la lanterne du héros, elles tournent autour de lui
			target = p + Vector3(0, 1.6, 0)
			speed *= 1.5
			if dist > float(spec["vue"]) * 1.8:
				state = "vol"
				home = Vector3(global_position.x, _ground_at(global_position), global_position.z)
		"envol":
			target = _cible
			speed *= 2.0
			if timer <= 0.0:
				state = "vol"
				home = Vector3(global_position.x, _ground_at(global_position), global_position.z)
		_:
			state = "vol"
			target = global_position
	var v: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * 3.0, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _plancher(global_position)
	if global_position.y < g + 0.3:
		global_position.y = g + 0.3


# ------------------------------------------------------------------- le molosse des cendres

func _molosse(delta: float, dist: float, dir_p: Vector3, dy: float, p: Vector3, sp: float, vue: float, from_home: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp)
			if dist < vue and dy < 3.0:
				state = "garde"
				timer = randf_range(1.0, 2.5)
				_sound("menace")
				manager.alert(self)
		"garde":
			# il tourne autour du héros à distance, en aboyant
			if from_home > float(spec["laisse"]) or dist > vue * 1.8:
				state = "retour"
			else:
				var side := Vector3(-dir_p.z, 0, dir_p.x) * signf(_flank + 0.01)
				var want: float = 7.0 + _flank
				var radial: Vector3 = dir_p * clampf(dist - want, -1.0, 1.0)
				move = (radial + side * 0.6).normalized() * sp * 0.6
				facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
				_cd136 -= delta
				if _cd136 <= 0.0:
					_cd136 = randf_range(1.5, 3.0)
					_sound("menace")
				if timer <= 0.0 and manager.take_token(self):
					state = "fonce"
					timer = 2.0
					charges += 1
		"fonce":
			facing = facing.lerp(dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			move = facing * sp * 1.9
			if dist < float(spec["portee"]) + 0.4 and dy < 2.0:
				manager.hurt_player(int(spec["degats"]), global_position)
				landed_hits += 1
				state = "repli"
				timer = 1.2
			elif timer <= 0.0:
				state = "repli"
				timer = 1.0
		"repli", "recul":
			if state == "recul":
				state = "repli"
				timer = 1.0
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			move = facing * sp * 1.6
			if timer <= 0.0:
				manager.release_token(self)
				state = "garde"
				timer = randf_range(1.5, 3.0)
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 2.0:
				state = "erre"
			else:
				move = back.normalized() * sp * 0.7
				facing = facing.lerp(back.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
		_:
			state = "erre"
	return move


# ------------------------------------------------------------------- le macareux

func _macareux_sol(delta: float, dist: float, _dir_p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"pose", "erre":
			state = "pose"
			move = _wander(delta, sp) * 0.08
			if dist < vue:
				_envol_macareux()
		"recul":
			_envol_macareux()
		_:
			state = "pose"
	return move


func _envol_macareux() -> void:
	var w: Vector3 = _mer_pres(global_position, 40.0)
	_cible = (w if w != Vector3.INF else global_position + facing * 20.0) + Vector3.UP * 4.0
	_vole = true
	state = "mer"
	timer = randf_range(6.0, 10.0)
	fuites += 1
	_sound("menace")


func _fly_macareux(delta: float, p: Vector3, _dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"mer":
			# au-dessus de la mer, en rond, les ailes qui vrombissent
			_orbit_a += delta * 0.9
			target = _cible + Vector3(cos(_orbit_a) * 5.0, sin(_clock * 1.3) * 0.5, sin(_orbit_a) * 5.0)
			var hd: float = Vector2(p.x - home.x, p.z - home.z).length()
			if timer <= 0.0 and hd > float(spec["vue"]) * 1.5:
				state = "retour"
		"retour":
			target = home + Vector3.UP * 0.05
			if global_position.distance_to(target) < 0.4:
				_vole = false
				state = "pose"
				global_position = home
				velocity = Vector3.ZERO
				_visual.rotation = Vector3.ZERO
				return
		_:
			state = "mer"
			target = _cible
	_voler137(delta, target, speed, 2.5)


# ------------------------------------------------------------------- la chouette effraie

func _fly_effraie(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"quete":
			# elle balaie le pré au ras de l'herbe, en longs allers-retours
			_orbit_a += delta * 0.32
			target = _orbit_c + Vector3(sin(_orbit_a) * 14.0, 0, sin(_orbit_a * 2.0) * 6.0)
			target.y = _plancher(target) + _alt
			speed *= 0.6
			if dist < float(spec["vue"]):
				# le héros est là : elle s'écarte
				var away: Vector3 = global_position - p
				away.y = 0.0
				_orbit_c += (away.normalized() if away.length() > 0.1 else Vector3.FORWARD) * 12.0
				_orbit_c.y = 0.0
			_cd136 -= delta
			if _cd136 <= 0.0:
				_cd136 = randf_range(6.0, 10.0)
				state = "sur_place"
				timer = 1.3
				_cible = Vector3(global_position.x, _ground_at(global_position), global_position.z)
				if randf() < 0.35:
					_sound("menace")
		"sur_place":
			target = _cible + Vector3.UP * (_alt - 0.4)
			speed *= 0.3
			if timer <= 0.0:
				state = "plonge"
				timer = 1.0
		"plonge":
			target = _cible + Vector3.UP * 0.25
			speed *= 1.4
			if global_position.distance_to(target) < 0.5 or timer <= 0.0:
				plongeons += 1
				_puff(_cible + Vector3.UP * 0.15, 6, Color(0.5, 0.6, 0.35, 0.8), 0.05, 0.18, 0.5, 0.5, 1.4)
				state = "remonte"
				timer = 1.5
		"remonte", "fuite_air":
			target = global_position + Vector3(facing.x, 0, facing.z) * 5.0 + Vector3.UP * 2.0
			if timer <= 0.0:
				state = "quete"
		_:
			state = "quete"
			target = global_position
	_voler137(delta, target, speed, 2.0)


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS138.has(kind):
		super._animate132(delta, speed)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	var night: bool = manager != null and manager.has_method("night") and bool(manager.night())
	for m in _eye_glow:
		(m as StandardMaterial3D).emission_energy_multiplier = 2.2 if night else 0.35
	match kind:
		"corbeau":
			_anim_oiseau_sol(state == "sautille", 6.0, 0.6)
		"vautour_fauve":
			_anim_oiseau_sol(state == "pose", 1.6, 0.05)
		"effraie":
			_anim_effraie()
		"phalene_braise":
			_anim_papillons()
		"hermine":
			super._animate132(delta, speed)
			_stand = lerpf(_stand, 1.0 if state == "guette" else 0.0, clampf(delta * 8.0, 0.0, 1.0))
			if _stand > 0.02:
				_pose_corps(_stand * 1.2, Vector3(0, 0.02, -0.12))
			else:
				_pose_corps(0.0, Vector3.ZERO)
			var tail: Node3D = _pivots.get("queue")
			if tail != null:
				tail.rotation.x = -0.4 * _stand
		"iguane_marin":
			_anim_iguane(delta, walk)
		"molosse_cendre":
			super._animate132(delta, speed)
			var head: Node3D = _pivots.get("tete")
			if head != null:
				head.rotation.x = 0.3 if state == "fonce" else (-0.1 if state == "garde" and fmod(_clock, 2.0) < 0.3 else head.rotation.x)
		"macareux":
			_anim_macareux(delta, walk)
		"mouton":
			super._animate132(delta, speed)
			var neck: Node3D = _pivots.get("tete")
			if neck != null:
				var low: float = 0.6 if (state == "erre" and _graze > 0.0) else (-0.15 if state == "alerte" else 0.0)
				neck.rotation.x = lerpf(neck.rotation.x, low, clampf(delta * 4.0, 0.0, 1.0))
			var body: Node3D = _pivots.get("corps")
			if body != null and state == "galop":
				body.position.y = absf(sin(_clock * 9.0)) * 0.05


## Un oiseau qui vole (battements « flap » par seconde, amplitude « amp ») ou qui est posé (les
## ailes repliées le long du corps, les pattes sorties).
func _anim_oiseau_sol(pose: bool, freq: float, amp: float) -> void:
	var t: float = _clock
	var flap: float = sin(t * freq) * amp
	if kind == "vautour_fauve" and state == "tourne_bas":
		flap = sin(t * 1.2) * 0.03
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		if pose:
			wing.rotation = Vector3(0.0, sx * 1.35, -sx * 0.25)
			hand.rotation = Vector3(0.0, sx * 1.4, 0.0)
		else:
			wing.rotation = Vector3(0.0, 0.0, sx * (flap + 0.08))
			hand.rotation = Vector3(0.0, 0.0, sx * flap * 0.6)
	var legs: Node3D = _pivots.get("pattes")
	if legs != null:
		legs.rotation.x = 0.0 if pose else 1.2
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.rotation.x = -0.45 if pose else 0.0
	if _piece != null and kind == "corbeau":
		_piece.visible = state == "emporte"


func _anim_effraie() -> void:
	var t: float = _clock
	var flap: float = sin(t * 4.0) * 0.4
	if state == "sur_place":
		flap = sin(t * 9.0) * 0.6
	elif state == "plonge":
		flap = 0.6
	elif state == "quete" and fmod(t + _flank * 3.0, 4.0) < 1.6:
		flap = sin(t * 1.5) * 0.06
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * (flap + 0.05)
		hand.rotation.z = sx * flap * 0.5
	var legs: Node3D = _pivots.get("pattes")
	if legs != null:
		legs.rotation.x = -0.3 if state in ["plonge", "sur_place"] else 1.3
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 0.5 if state in ["sur_place", "plonge"] else 0.15


func _anim_iguane(delta: float, walk: float) -> void:
	var t: float = _clock
	var w: float = minf(walk, 1.2)
	for e in _legs135:
		var leg: Node3D = e[0]
		var sx: float = e[1]
		var i: int = e[2]
		var ph: float = t * 4.5 + (0.0 if i in [0, 3] else PI)
		leg.rotation.y = sin(ph) * 0.45 * w * (1.0 if i < 2 else -1.0)
		leg.rotation.z = sx * maxf(0.0, cos(ph)) * 0.22 * w
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.rotation.y = sin(t * 4.5) * 0.1 * w
		# au soleil, il se soulève sur ses pattes de devant, la tête haute
		var up: float = 0.06 if state == "menace" else 0.0
		body.rotation.x = lerpf(body.rotation.x, -up, clampf(delta * 4.0, 0.0, 1.0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		var bob: float = 0.0
		if state == "menace":
			bob = absf(sin(t * 7.0)) * 0.35
		head.rotation.x = -bob
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(t * 4.5 + 1.0) * 0.3 * w + 0.05 * sin(t * 0.7)
	# dans l'eau, il nage, le corps à fleur d'eau
	var under: float = clampf((EAU + 0.05) - (global_position.y + 0.12), 0.0, 0.3)
	_visual.position.y = under * 0.5


func _anim_macareux(delta: float, walk: float) -> void:
	var t: float = _clock
	_unfold = lerpf(_unfold, 1.0 if _vole else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		var bas := Basis(Vector3.RIGHT, 1.3 * _unfold)
		var pv := Vector3(0, 0.15, 0)
		body.transform = Transform3D(bas, pv - bas * pv)
		if walk > 0.02 and _unfold < 0.1:
			body.rotation.z = sin(t * 10.0) * 0.12
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = -1.2 * _unfold
		head.rotation.y = sin(t * 0.9 + _flank) * 0.6 * (1.0 - _unfold)
	for e in _wings:
		var wing: Node3D = e[0]
		var sx: float = e[2]
		# repliées contre le flanc ; en vol, des battements très vifs
		wing.rotation.z = lerpf(0.0, sx * (1.5 + sin(t * 26.0) * 0.6), _unfold)

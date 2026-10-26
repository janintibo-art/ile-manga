extends "res://scripts/monstre_v71.gd"
## V75 : les monstres de l'Île du Boucan (Port-Boucan, le Bois des Spores, l'Usine Grise).
## Même règle que les autres (groupe « cibles_v28 », take_hit, butin, conseil à la première
## rencontre). Tout public : les robots ne saignent pas, ils se démontent (boulons, ressorts,
## un petit nuage de fumée) ; les champignards font « pouf » et s'enfuient en riant.
##  - le robot déménageur (Lisse & Fils) : trapu, sur chenilles, deux bras à pinces rembourrées,
##    un écran-visage aux yeux de pixels ; il bouscule poliment (un demi-cœur, on recule) et dit
##    des phrases d'entreprise. Mode « porter » pour la Descente des Déménageurs :
##      m.porter(cible: Vector3, objet := "")  → il emporte une caisse (ou un fauteuil, un
##      carton) vers « cible » ; m.arrive devient vrai à 2 m ; touché, il lâche tout et se bat ;
##      détruit, la charge tombe. m.lacher() la lui fait poser.
##  - le drone-huissier : un petit quadricoptère, un avis d'expulsion qui flotte dessous ; il tourne
##    autour du joueur à 2-3 m, lit ses avis… et pique pour une petite décharge (on le frappe quand
##    il remonte, essoufflé) ;
##  - le robot soudeur : un bras de soudage sur une base mobile, un arc bleu-blanc très court ;
##  - la mini-pelleteuse : godet qui s'abat (cercle rouge au sol, puis onde de choc), balayages ;
##  - LA GRANDE PELLETEUSE (le boss de l'Usine Grise, ordinateur « OPTIMUS-LISSE ») : un godet qui
##    se lève (cercle rouge au sol) puis s'abat ; il reste planté trois secondes, les DURITES à nu :
##    c'est le moment de frapper (points faibles). Sinon : « Clang ! Ça ne lui fait rien. »
##    Trois phases : une durite éclate à chaque fois, elle va plus vite et appelle deux déménageurs.
##    Comme le Roi Gélatineux : on surveille hp / spec["pv"] / state == "mort" (ou le signal died).
##  - le champignard : une petite créature champignon farceuse ; son nuage de spores ne fait aucun
##    mal… il fait ÉTERNUER (« Atchoum ! », on titube un instant) ; touché, il détale ; deux coups
##    et « pouf » ;
##  - le Roi Champignard (le Bois des Spores) : de grands nuages, il appelle trois champignards.

const A75 = preload("res://scripts/animaux_v75.gd")
const TEXTES75_PATH := "res://scripts/pnj/boucan_textes_v75.gd"

const SPECS75 := {
	"robot_demenageur": {"pv": 16, "vitesse": 2.1, "degats": 1, "portee": 1.6, "armer": 0.65, "repos": 1.4, "vue": 12.0, "laisse": 40.0,
		"rayon": 0.55, "haut": 0.8, "nom": "Robot déménageur"},
	"drone_huissier": {"pv": 6, "vitesse": 3.4, "degats": 1, "portee": 5.0, "armer": 0.75, "repos": 1.6, "vue": 15.0, "laisse": 40.0,
		"rayon": 0.42, "haut": 0.12, "nom": "Drone-huissier", "vol": 2.6},
	"robot_soudeur": {"pv": 22, "vitesse": 1.5, "degats": 1, "portee": 2.2, "armer": 0.8, "repos": 1.6, "vue": 11.0, "laisse": 20.0,
		"rayon": 0.6, "haut": 0.75, "nom": "Robot soudeur"},
	"pelleteuse_mini": {"pv": 70, "vitesse": 1.6, "degats": 2, "portee": 4.4, "armer": 1.1, "repos": 1.6, "vue": 18.0, "laisse": 30.0,
		"rayon": 1.35, "haut": 0.9, "nom": "la Mini-Pelleteuse", "chef": true},
	"grande_pelleteuse": {"pv": 220, "vitesse": 1.3, "degats": 2, "portee": 10.0, "armer": 1.5, "repos": 1.4, "vue": 45.0, "laisse": 80.0,
		"rayon": 2.8, "haut": 1.6, "nom": "la Grande Pelleteuse", "boss": true},
	"champignard": {"pv": 2, "vitesse": 2.6, "degats": 0, "portee": 1.7, "armer": 0.55, "repos": 1.0, "vue": 9.0, "laisse": 18.0,
		"rayon": 0.3, "haut": 0.3, "nom": "Champignard"},
	"champignard_roi": {"pv": 60, "vitesse": 1.5, "degats": 0, "portee": 3.4, "armer": 0.95, "repos": 1.6, "vue": 16.0, "laisse": 26.0,
		"rayon": 1.0, "haut": 1.1, "nom": "le Roi Champignard", "chef": true},
}
const SOUNDS75 := {"robot_demenageur": ["robot_voix", "robot_mort"], "drone_huissier": ["robot_bip", "robot_mort"],
	"robot_soudeur": ["soudure", "robot_mort"], "pelleteuse_mini": ["pelleteuse_cri", "robot_mort"],
	"grande_pelleteuse": ["pelleteuse_cri", "pelleteuse_cri"], "champignard": ["champignard_rire", "champignard_pouf"],
	"champignard_roi": ["champignard_rire", "champignard_pouf"]}
const ROBOTS75 := ["robot_demenageur", "drone_huissier", "robot_soudeur", "pelleteuse_mini", "grande_pelleteuse"]
const CHAMPIS75 := ["champignard", "champignard_roi"]
const DIGGERS75 := ["pelleteuse_mini", "grande_pelleteuse"]
const CAPS75 := {"bleu": Color(0.22, 0.5, 1.0), "violet": Color(0.62, 0.3, 1.0), "orange": Color(1.0, 0.5, 0.12)}
const FALLBACK75 := {
	"robots": ["Veuillez libérer les lieux. Merci de votre compréhension.", "Ceci est une expulsion amicale.",
		"Votre canapé a été optimisé.", "Merci de patienter : votre déménagement est en cours.",
		"Lisse & Fils vous remercie de votre coopération.", "Bip. Ce meuble ne vous appartient plus. Bip.",
		"Pardon. Excusez-moi. Je vous pousse.", "Souriez : vous êtes relogé… ailleurs."],
	"drones": ["AVIS N° 4012 : vous êtes prié d'être ailleurs.", "Article 3 : la bonne humeur est interdite après 18 h.",
		"Notification : votre coiffure n'est pas conforme au règlement.", "Ceci est un avis d'expulsion. Bonne journée !",
		"Lecture de l'avis… page 1 sur 347.", "Signez ici. Et ici. Et là. Merci."],
	"pelleteuse": ["OPTIMISATION EN COURS.", "ZONE À RASER. ZONE À RASER.", "VOTRE QUARTIER EST UN PARKING EN DEVENIR.",
		"BIENTÔT ICI : LE LISSE-CENTER."],
}

## Le point faible de la Grande Pelleteuse (les durites, près du godet planté) : une cible à part.
class PointFaible extends Node3D:
	var boss: Node3D
	var kind: String = "durite"
	var hit_radius: float = 1.6
	var hit_height: float = 1.0

	func is_hittable() -> bool:
		return boss != null and is_instance_valid(boss) and bool(boss.call("weak_open"))

	func take_hit(damage: int, from_pos: Vector3) -> void:
		if boss != null and is_instance_valid(boss):
			boss.call("hit_weak", damage, from_pos)


static var _m75: Dictionary = {}           # maillages partagés
static var _t75: Dictionary = {}           # textures partagées (écrans, chenilles, avis…)
static var _txt75: Dictionary = {}
static var _txt75_loaded: bool = false
static var _say75_t: float = -10.0         # un seul robot parle à la fois (ou presque)
static var _sneeze_until: float = -10.0
static var _tint_layer: CanvasLayer
static var _tint_rect: ColorRect
static var _calib75: Dictionary = {}       # pelleteuses : où tombe le godet selon la pose du bras

## --- mode « porter » (Descente des Déménageurs)
var arrive: bool = false
var porteur: bool = false
var cible: Vector3 = Vector3.ZERO
var objet: String = ""
var _load: Node3D
var _detour: Vector3 = Vector3.ZERO
var _detour_t: float = 0.0
## --- commun
var couleur: String = ""                  # champignards : bleu, violet, orange
var _bubble75: Label3D
var _bubble75_t: float = 0.0
var _say_next: float = 6.0
var _face_mat: StandardMaterial3D
var _face_expr: String = ""
var _expr_t: float = 0.0
var _tread_mats: Array = []
var _beacon: StandardMaterial3D
var _arms75: Array = []                   # [épaule, coude, côté]
var _head75: Node3D
var _body75: Node3D
var _push_t: float = 0.0
var _push_dir: Vector3 = Vector3.ZERO
var _snd_t: float = 0.0
var _hits75: int = 0
var _tread_v: float = 0.0
## --- drone
var _rotors: Array = []
var _paper: Node3D
var _alt: float = 2.6
var _orbit_a: float = 0.0
var _dive_from: Vector3
var _dive_to: Vector3
var _vy: float = 0.0
var _bounces: int = 0
var _zapped: bool = false
## --- soudeur
var _turret: Node3D
var _torch: Node3D
var _sparks: CPUParticles3D
var _arc_mat: StandardMaterial3D
var _arc_mesh: MeshInstance3D
var _arc_light: OmniLight3D
var _arc_fx: CPUParticles3D
## --- pelleteuses
var _house: Node3D
var _boom: Node3D
var _dstick: Node3D
var _bucket: Node3D
var _pistons: Array = []                  # [ancre A, ancre B, fût, tige, longueur du fût]
var _hoses: Array = []                    # [[matériau, vapeur]] : les trois durites (boss)
var _hose_mats: Array = []
var _circle: MeshInstance3D
var _circle_mat: StandardMaterial3D
var _slam_at: Vector3 = Vector3.ZERO
var _sweep_from: float = 0.0
var _sweep_hit: bool = false
var _house_yaw: float = 0.0
var _arm_goal := Vector3(-0.5, 1.0, 0.6)  # [flèche, bras, godet] (radians)
var _phase75: int = 0
var _speed_k: float = 1.0
var _close_t: float = 0.0
var _close_t2: float = 0.0
var _weak: Node3D
var _exhaust: CPUParticles3D
var _steam75: CPUParticles3D
var _said: Dictionary = {}
var _atk_i: int = 0
## --- champignards
var _cap: Node3D
var _cap_mat: StandardMaterial3D
var _stem: Node3D
var _feet75: Array = []
var _mouth75: Node3D
var _spore_idle: CPUParticles3D
var _hop_t75: float = 0.0
var _wander_to: Vector3 = Vector3.ZERO
var _summon_t: float = 8.0
var _flee_t: float = 0.0
var _puffed: bool = false


# =================================================================== aiguillage

func _v63() -> bool:
	return SPECS75.has(kind) or super._v63()


func _leaper() -> bool:
	return false if SPECS75.has(kind) else super._leaper()


func _sound_pair() -> Array:
	return SOUNDS75.get(kind, super._sound_pair())


func is_boss() -> bool:
	if SPECS75.has(kind):
		return bool(spec.get("boss", false))
	return super.is_boss()


func is_chef() -> bool:
	if SPECS75.has(kind):
		return bool(spec.get("chef", false))
	return super.is_chef()


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS75.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = (SPECS75[k] as Dictionary).duplicate()
	_base_speed = float(spec["vitesse"])
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Monstre_%s_%d" % [k, get_instance_id()]
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	match k:
		"robot_demenageur":
			var b := BoxShape3D.new()
			b.size = Vector3(0.95, 1.5, 0.95)
			cs.shape = b
			cs.position.y = 0.78
		"drone_huissier":
			var sp := SphereShape3D.new()
			sp.radius = 0.28
			cs.shape = sp
			cs.position.y = 0.0
		"robot_soudeur":
			var b2 := BoxShape3D.new()
			b2.size = Vector3(0.8, 1.3, 0.9)
			cs.shape = b2
			cs.position.y = 0.66
		"pelleteuse_mini":
			var b3 := BoxShape3D.new()
			b3.size = Vector3(1.9, 1.5, 2.3)
			cs.shape = b3
			cs.position.y = 0.76
		"grande_pelleteuse":
			var b4 := BoxShape3D.new()
			b4.size = Vector3(5.0, 3.6, 6.2)
			cs.shape = b4
			cs.position.y = 1.82
		"champignard":
			var sp2 := SphereShape3D.new()
			sp2.radius = 0.24
			cs.shape = sp2
			cs.position.y = 0.3
		"champignard_roi":
			var cap := CapsuleShape3D.new()
			cap.radius = 0.85
			cap.height = 2.5
			cs.shape = cap
			cs.position.y = 1.25
	add_child(cs)
	_cs71 = cs
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"robot_demenageur":
			_build_demenageur()
		"drone_huissier":
			_build_drone()
		"robot_soudeur":
			_build_soudeur()
		"pelleteuse_mini":
			_build_digger(1.0, false)
		"grande_pelleteuse":
			_build_digger(3.0, true)
		"champignard":
			couleur = ["bleu", "violet", "orange"][randi() % 3]
			_build_champignard(1.0, false)
		"champignard_roi":
			couleur = "violet"
			_build_champignard(3.4, true)
	add_to_group("cibles_v28")
	add_to_group("monstres_v36")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	_say_next = randf_range(3.0, 9.0)
	_hop_t75 = randf() * 2.0
	if k == "drone_huissier":
		_alt = float(spec["vol"]) + randf_range(-0.3, 0.4)
		_orbit_a = randf() * TAU
		global_position = at + Vector3.UP * _alt


# =================================================================== outils

func _m75mesh(key: String, maker: Callable) -> Mesh:
	if not _m75.has(key):
		_m75[key] = maker.call()
	return _m75[key]


func _box75(size: Vector3) -> Mesh:
	var key: String = "box_%s" % str(size)
	if not _m75.has(key):
		var b := BoxMesh.new()
		b.size = size
		_m75[key] = b
	return _m75[key]


func _rbox75(size: Vector3, r: float) -> Mesh:
	return A75.rbox(size, r)


func _cyl75(a: float, b: float, h: float, seg: int = 12) -> Mesh:
	var key: String = "cyl_%.4f_%.4f_%.4f_%d" % [a, b, h, seg]
	if not _m75.has(key):
		var c := CylinderMesh.new()
		c.top_radius = a
		c.bottom_radius = b
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		_m75[key] = c
	return _m75[key]


func _sph75(r: float, seg: int = 14) -> Mesh:
	var key: String = "sph_%.4f_%d" % [r, seg]
	if not _m75.has(key):
		var sp := SphereMesh.new()
		sp.radius = r
		sp.height = r * 2.0
		sp.radial_segments = seg
		sp.rings = maxi(seg / 2, 4)
		_m75[key] = sp
	return _m75[key]


## Peinture d'usine : une couleur, des rayures et de la crasse légères (texture de bruit partagée).
func _paint(c: Color, rough: float = 0.45, metal: float = 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = _noise_tex("peinture75", 7501, 0.05, [[0.0, Color(0.78, 0.77, 0.75)], [0.35, Color(0.94, 0.94, 0.93)], [1.0, Color(1, 1, 1)]])
	m.normal_enabled = true
	m.normal_texture = _noise_tex("peinture75", 7502, 0.12, [], true, 2.0)
	m.normal_scale = 0.25
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * 1.6
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.6
	_flash_mats.append(m)
	return m


func _steel(c: Color = Color(0.42, 0.43, 0.45), rough: float = 0.35) -> StandardMaterial3D:
	var m := _paint(c, rough, 0.85)
	m.uv1_scale = Vector3.ONE * 3.0
	return m


func _rubber(c: Color = Color(0.07, 0.07, 0.075)) -> StandardMaterial3D:
	var m := _mat(c, 0.92)
	m.metallic_specular = 0.3
	return m


func _chrome() -> StandardMaterial3D:
	var m := _mat(Color(0.86, 0.87, 0.9), 0.12)
	m.metallic = 1.0
	return m


func _glass(c: Color = Color(0.08, 0.1, 0.12)) -> StandardMaterial3D:
	var m := _mat(c, 0.05)
	m.metallic = 0.6
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	return m


func _hazard_tex() -> Texture2D:
	if _t75.has("hazard"):
		return _t75["hazard"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var band: int = int(floor(float(x + y) / 16.0)) % 2
			var c: Color = Color(0.95, 0.72, 0.08) if band == 0 else Color(0.06, 0.06, 0.06)
			var g: float = randf_range(-0.03, 0.03)
			img.set_pixel(x, y, Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g, 0, 1)))
	var t := ImageTexture.create_from_image(img)
	_t75["hazard"] = t
	return t


func _hazard_mat() -> StandardMaterial3D:
	var m := _mat(Color(1, 1, 1), 0.5)
	m.albedo_texture = _hazard_tex()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * 2.5
	m.metallic = 0.25
	return m


## Les crampons d'une chenille : bandes claires/sombres (u = le long de la chenille) et leur relief.
func _tread_tex(normal: bool) -> Texture2D:
	var key: String = "chenille_n" if normal else "chenille"
	if _t75.has(key):
		return _t75[key]
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(64):
			var cx: int = x % 16
			var cleat: bool = cx >= 2 and cx <= 7 and not (y >= 14 and y <= 17 and cx > 5)
			var h: float = 0.85 if cleat else 0.25
			if normal:
				img.set_pixel(x, y, Color(h, h, h))
			else:
				var v: float = 0.13 if cleat else 0.06
				v += randf_range(-0.015, 0.015)
				img.set_pixel(x, y, Color(v, v, v * 1.05))
	if normal:
		img.bump_map_to_normal_map(6.0)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_t75[key] = t
	return t


## L'écran-visage : des yeux de pixels (expressions : poli, parle, fache, mort, rouge…).
func _face_tex(expr: String, col: Color) -> Texture2D:
	var key: String = "face_%s_%s" % [expr, col.to_html(false)]
	if _t75.has(key):
		return _t75[key]
	var W: int = 32
	var H: int = 24
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0))
	for y in range(H):
		if y % 2 == 0:
			for x in range(W):
				img.set_pixel(x, y, col * 0.06)
	var px := func(x: int, y: int) -> void:
		if x >= 0 and x < W and y >= 0 and y < H:
			img.set_pixel(x, y, col)
	for side in [0, 1]:
		var ex: int = 8 if side == 0 else 20
		var ey: int = 8
		match expr:
			"parle", "content":
				# yeux fermés de plaisir : ^ ^
				for k in range(5):
					px.call(ex - 2 + k, ey + 2 - (2 - absi(k - 2)))
					px.call(ex - 2 + k, ey + 3 - (2 - absi(k - 2)))
			"fache":
				for yy in range(4):
					for xx in range(4):
						if not (yy == 0 and ((side == 0 and xx < 2) or (side == 1 and xx > 1))):
							px.call(ex - 2 + xx, ey + yy)
				for k2 in range(5):
					px.call(ex - 2 + k2, ey - 2 + (k2 / 2 if side == 0 else (4 - k2) / 2))
			"mort":
				for k3 in range(5):
					px.call(ex - 2 + k3, ey - 1 + k3)
					px.call(ex + 2 - k3, ey - 1 + k3)
			"rouge":
				for yy2 in range(3):
					for xx2 in range(6):
						px.call(ex - 3 + xx2, ey + yy2 + (1 if (side == 0 and xx2 > 3) or (side == 1 and xx2 < 2) else 0))
			_:
				# poli : deux yeux ronds (4 × 5 pixels aux coins arrondis)
				for yy3 in range(5):
					for xx3 in range(4):
						if (yy3 == 0 or yy3 == 4) and (xx3 == 0 or xx3 == 3):
							continue
						px.call(ex - 2 + xx3, ey + yy3)
	# la bouche
	match expr:
		"parle":
			for x2 in range(13, 19):
				px.call(x2, 17)
				px.call(x2, 18)
			px.call(12, 17)
			px.call(19, 17)
		"poli", "content":
			for x3 in range(12, 20):
				px.call(x3, 18 - (1 if x3 == 12 or x3 == 19 else 0))
		"fache":
			for x4 in range(12, 20):
				px.call(x4, 18)
		"mort":
			for x5 in range(12, 20):
				px.call(x5, 18 + (x5 % 2))
		"rouge":
			for x6 in range(10, 22):
				px.call(x6, 18)
			for x7 in range(10, 22, 3):
				px.call(x7, 17)
	var t := ImageTexture.create_from_image(img)
	_t75[key] = t
	return t


func _screen_mat(expr: String, col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.015, 0.018, 0.022)
	m.roughness = 0.4
	m.metallic_specular = 0.25
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_texture = _face_tex(expr, col)
	m.emission_energy_multiplier = 1.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.set_meta("col", col)
	_flash_mats.append(m)
	return m


func _set_face(expr: String, hold: float = 0.0) -> void:
	if _face_mat == null or not _face_mat.has_meta("col"):
		return
	if _face_expr == expr:
		_expr_t = maxf(_expr_t, hold)
		return
	_face_expr = expr
	_expr_t = hold
	var col: Color = _face_mat.get_meta("col", Color(0.5, 0.95, 1.0))
	_face_mat.emission_texture = _face_tex(expr, col)


## L'avis d'expulsion (papier crème, bandeau rouge, lignes).
func _paper_tex() -> Texture2D:
	if _t75.has("avis"):
		return _t75["avis"]
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.93, 0.86))
	for y in range(64):
		for x in range(48):
			var c: Color = img.get_pixel(x, y)
			if y >= 4 and y <= 10 and x >= 4 and x <= 43:
				c = Color(0.75, 0.1, 0.08)
			elif y >= 15 and y <= 56 and (y - 15) % 5 == 0 and x >= 5 and x <= (42 if (y / 5) % 3 != 0 else 30):
				c = Color(0.25, 0.25, 0.27)
			elif y >= 58 and y <= 60 and x >= 26 and x <= 42:
				c = Color(0.1, 0.15, 0.45)
			c = c.darkened(randf_range(0.0, 0.04))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_t75["avis"] = t
	return t


## Une chenille : une bande crantée en stade (u le long de la bande), roues à l'intérieur.
func _track_band(L: float, R: float, W: float) -> ArrayMesh:
	var key: String = "bande_%.2f_%.2f_%.2f" % [L, R, W]
	if _m75.has(key):
		return _m75[key]
	var P: float = 2.0 * L + TAU * R
	var N: int = 56
	var pts: Array = []
	var nrs: Array = []
	var us: Array = []
	for i in range(N + 1):
		var s: float = P * float(i) / float(N)
		var p := Vector3.ZERO
		var nn := Vector3.UP
		if s < L:
			p = Vector3(0, R, -L * 0.5 + s)
			nn = Vector3.UP
		elif s < L + PI * R:
			var a: float = (s - L) / R
			p = Vector3(0, cos(a) * R, L * 0.5 + sin(a) * R)
			nn = Vector3(0, cos(a), sin(a))
		elif s < 2.0 * L + PI * R:
			p = Vector3(0, -R, L * 0.5 - (s - L - PI * R))
			nn = Vector3.DOWN
		else:
			var a2: float = (s - 2.0 * L - PI * R) / R
			p = Vector3(0, -cos(a2) * R, -L * 0.5 - sin(a2) * R)
			nn = Vector3(0, -cos(a2), -sin(a2))
		pts.append(p)
		nrs.append(nn)
		us.append(s / 0.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(N):
		var a0: Vector3 = pts[i]
		var a1: Vector3 = pts[i + 1]
		var n0: Vector3 = nrs[i]
		var n1: Vector3 = nrs[i + 1]
		var u0: float = float(us[i])
		var u1: float = float(us[i + 1])
		var q: Array = [[a0 + Vector3(-W * 0.5, 0, 0), n0, Vector2(u0, 0)], [a1 + Vector3(-W * 0.5, 0, 0), n1, Vector2(u1, 0)],
			[a1 + Vector3(W * 0.5, 0, 0), n1, Vector2(u1, 1)], [a0 + Vector3(W * 0.5, 0, 0), n0, Vector2(u0, 1)]]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var va: Array = q[tri[0]]
			var vb: Array = q[tri[1]]
			var vc: Array = q[tri[2]]
			var g: Vector3 = ((vb[0] as Vector3) - (va[0] as Vector3)).cross((vc[0] as Vector3) - (va[0] as Vector3))
			var order: Array = [va, vb, vc] if g.dot(n0) < 0.0 else [va, vc, vb]
			for v in order:
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	_m75[key] = mesh
	return mesh


## Une chenille complète posée en « at » (repère du parent) : bande, barbotin, galets, flasque.
func _build_track(parent: Node3D, at: Vector3, L: float, R: float, W: float, frame_mat: Material) -> void:
	var tm := StandardMaterial3D.new()
	tm.albedo_texture = _tread_tex(false)
	tm.normal_enabled = true
	tm.normal_texture = _tread_tex(true)
	tm.normal_scale = 1.0
	tm.roughness = 0.9
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.uv1_scale = Vector3(1.0, 1.0, 1.0)
	_flash_mats.append(tm)
	_tread_mats.append(tm)
	var tr := Node3D.new()
	tr.position = at
	parent.add_child(tr)
	_mesh(tr, _track_band(L, R, W), tm, Vector3.ZERO)
	var hub := _steel(Color(0.3, 0.3, 0.32), 0.4)
	for z in [-L * 0.5, L * 0.5]:
		_mesh(tr, _cyl75(R * 0.86, R * 0.86, W * 0.84, 16), hub, Vector3(0, 0, z), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	var nw: int = maxi(int(L / (R * 1.1)), 1)
	for k in range(nw):
		var zz: float = -L * 0.5 + L * float(k + 1) / float(nw + 1)
		_mesh(tr, _cyl75(R * 0.5, R * 0.5, W * 0.8, 12), hub, Vector3(0, -R * 0.45, zz), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	# la flasque : la plaque du châssis entre les roues (des deux côtés)
	for sx in [-1.0, 1.0]:
		_mesh(tr, _rbox75(Vector3(W * 0.08, R * 0.9, L * 0.92), minf(R * 0.2, W * 0.035)), frame_mat, Vector3(sx * W * 0.36, 0.0, 0))
		for z2 in [-L * 0.5, L * 0.5]:
			_mesh(tr, _cyl75(R * 0.3, R * 0.3, 0.02 * maxf(R / 0.18, 1.0), 10), frame_mat, Vector3(sx * W * 0.44, 0, z2), Vector3.ONE, Vector3(0, 0, PI * 0.5))


## Une bulle de paroles au-dessus du robot.
func _say75(text: String, secs: float = -1.0) -> void:
	if text == "":
		return
	if _bubble75 == null:
		_bubble75 = Label3D.new()
		_bubble75.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble75.font_size = 34
		_bubble75.pixel_size = 0.0026 * (1.0 if kind != "grande_pelleteuse" else 2.2)
		_bubble75.outline_size = 10
		_bubble75.width = 560
		_bubble75.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bubble75.no_depth_test = true
		_bubble75.modulate = Color(0.85, 0.95, 1.0) if kind in ROBOTS75 else Color(1.0, 0.92, 0.7)
		_bubble75.outline_modulate = Color(0.05, 0.08, 0.12)
		var hh: float = {"robot_demenageur": 2.0, "drone_huissier": 0.55, "robot_soudeur": 1.9, "pelleteuse_mini": 3.4, "grande_pelleteuse": 10.0}.get(kind, 1.4)
		_bubble75.position = Vector3(0, hh, 0)
		add_child(_bubble75)
	_bubble75.text = text
	_bubble75.visible = true
	_bubble75.modulate.a = 1.0
	_bubble75_t = secs if secs > 0.0 else clampf(1.6 + text.length() * 0.055, 2.8, 7.0)
	_say75_t = _clock_static()
	if kind == "robot_demenageur" or kind == "drone_huissier":
		_set_face("parle", 0.9)
		_sfx71("robot_voix", global_position + Vector3.UP * 1.3, -4.0)


static func _clock_static() -> float:
	return Time.get_ticks_msec() / 1000.0


func _bubble75_tick(delta: float) -> void:
	if _bubble75 != null and _bubble75_t > 0.0:
		_bubble75_t -= delta
		_bubble75.modulate.a = clampf(_bubble75_t, 0.0, 1.0)
		if _bubble75_t <= 0.0:
			_bubble75.visible = false


static func _all_texts75() -> Dictionary:
	if _txt75_loaded:
		return _txt75
	_txt75_loaded = true
	if ResourceLoader.exists(TEXTES75_PATH):
		var scr: Script = load(TEXTES75_PATH)
		if scr != null:
			var cm: Dictionary = scr.get_script_constant_map()
			_txt75 = cm
	return _txt75


## Une réplique au hasard : textes de Port-Boucan (boucan_textes_v75.gd : DESCENTE[clé]) ou secours.
func _line75(key: String) -> String:
	var all: Dictionary = _all_texts75()
	var arr: Array = []
	var d: Variant = all.get("DESCENTE", {})
	if d is Dictionary and (d as Dictionary).has(key):
		var v: Variant = (d as Dictionary)[key]
		if v is Array:
			arr = v
		elif v is String:
			arr = [v]
	if arr.is_empty():
		arr = FALLBACK75.get(key, [])
	if arr.is_empty():
		return ""
	var e: Variant = arr[randi() % arr.size()]
	if e is Dictionary:
		return str((e as Dictionary).get("texte", (e as Dictionary).get("text", "")))
	if e is Array and not (e as Array).is_empty():
		return str((e as Array)[(e as Array).size() - 1])
	return str(e)


func _maybe_talk(delta: float, key: String, dist: float) -> void:
	_say_next -= delta
	if _say_next > 0.0 or dist > 14.0:
		return
	_say_next = randf_range(7.0, 14.0)
	if _clock_static() - _say75_t < 2.5:
		return
	_say75(_line75(key))


func _player_feet75() -> Vector3:
	var p: Vector3 = _player()
	if manager.main.xr_active:
		p.y -= 1.5
	return p


## Les monstres du Boucan sont actifs dès qu'on est près d'eux (ils viennent d'un événement, d'un
## repaire ou du donjon), même hors des zones hostiles déclarées par les autres îles.
func _active75() -> bool:
	if manager.active:
		return true
	var mn: Node = manager.main
	if mn == null or not bool(mn.game_started):
		return false
	if mn.get("game_menu") != null and mn.game_menu != null and bool(mn.game_menu.opened):
		return false
	if mn.get("dialogue_v31") != null and mn.dialogue_v31 != null and bool(mn.dialogue_v31.opened):
		return false
	return global_position.distance_to(_player_feet75()) < 70.0


## Pousse le joueur (une bousculade, une onde de choc) : quelques images de glissade.
func _push_player(dir: Vector3, strength: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_push_dir = dir.normalized() * strength
	_push_t = 0.3


func _push_tick(delta: float) -> void:
	if _push_t <= 0.0:
		return
	_push_t -= delta
	var mn: Node = manager.main
	var body: CharacterBody3D = mn.get("vr_body") if mn.xr_active else mn.get("pc_body")
	if body == null or not is_instance_valid(body):
		return
	var k: float = clampf(_push_t / 0.3, 0.0, 1.0) * (0.5 if mn.xr_active else 1.0)
	body.move_and_collide(_push_dir * k * delta * 1.8)


# =================================================================== le robot déménageur

func _build_demenageur() -> void:
	var grey := _paint(Color(0.6, 0.62, 0.64), 0.42, 0.35)
	var dark := _steel(Color(0.22, 0.23, 0.25), 0.45)
	var yellow := _paint(Color(0.96, 0.74, 0.08), 0.4, 0.2)
	var pad := _rubber(Color(0.85, 0.36, 0.12))
	var joint := _steel(Color(0.32, 0.33, 0.35), 0.3)
	_body75 = Node3D.new()
	_body75.name = "Corps"
	_visual.add_child(_body75)
	for sx in [-1.0, 1.0]:
		_build_track(_visual, Vector3(sx * 0.37, 0.2, 0.0), 0.56, 0.17, 0.22, dark)
	_mesh(_visual, _rbox75(Vector3(0.56, 0.16, 0.66), 0.03), dark, Vector3(0, 0.42, 0))
	# le corps : une grosse caisse peinte, la bande jaune « LISSE & FILS »
	_mesh(_body75, _rbox75(Vector3(0.8, 0.72, 0.62), 0.09), grey, Vector3(0, 0.86, 0))
	_mesh(_body75, _rbox75(Vector3(0.82, 0.1, 0.64), 0.05), yellow, Vector3(0, 0.99, 0))
	for sx2 in [-1.0, 1.0]:
		var lb := Label3D.new()
		lb.text = "LISSE & FILS"
		lb.font_size = 40
		lb.pixel_size = 0.0016
		lb.outline_size = 0
		lb.modulate = Color(0.08, 0.08, 0.1)
		lb.position = Vector3(sx2 * 0.412, 0.99, 0.0)
		lb.rotation.y = sx2 * PI * 0.5
		lb.double_sided = false
		lb.shaded = true
		_body75.add_child(lb)
	var num := Label3D.new()
	num.text = "N° %03d" % (randi() % 900 + 100)
	num.font_size = 28
	num.pixel_size = 0.0016
	num.modulate = Color(0.12, 0.12, 0.14)
	num.position = Vector3(0.22, 0.66, 0.313)
	num.shaded = true
	_body75.add_child(num)
	# la grille d'aération, deux phares
	for k in range(5):
		_mesh(_body75, _box75(Vector3(0.26, 0.012, 0.02)), dark, Vector3(-0.12, 0.6 + k * 0.035, 0.31))
	var lamp := _mat(Color(1.0, 0.95, 0.8), 0.1, 1.5)
	for sx3 in [-1.0, 1.0]:
		_mesh(_body75, _cyl75(0.035, 0.035, 0.03, 12), lamp, Vector3(sx3 * 0.3, 1.14, 0.315), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	# la tête : un boîtier arrondi, l'écran-visage, une balise orange
	_head75 = Node3D.new()
	_head75.name = "Tete"
	_head75.position = Vector3(0, 1.25, 0.02)
	_body75.add_child(_head75)
	_mesh(_head75, _cyl75(0.08, 0.1, 0.08, 12), joint, Vector3(0, 0.0, 0))
	_mesh(_head75, _rbox75(Vector3(0.48, 0.34, 0.32), 0.11), grey, Vector3(0, 0.2, 0))
	_mesh(_head75, _rbox75(Vector3(0.4, 0.27, 0.04), 0.06), dark, Vector3(0, 0.2, 0.155))
	_face_mat = _screen_mat("poli", Color(0.55, 0.95, 1.0))
	var q := QuadMesh.new()
	q.size = Vector2(0.34, 0.24)
	_mesh(_head75, q, _face_mat, Vector3(0, 0.2, 0.177))
	_face_expr = "poli"
	for sx4 in [-1.0, 1.0]:
		_mesh(_head75, _cyl75(0.05, 0.05, 0.04, 12), dark, Vector3(sx4 * 0.25, 0.2, 0), Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_mesh(_head75, _cyl75(0.012, 0.012, 0.12, 6), dark, Vector3(0.12, 0.42, -0.05))
	_beacon = _mat(Color(1.0, 0.55, 0.05), 0.2, 2.5)
	_mesh(_head75, _sph75(0.03, 10), _beacon, Vector3(0.12, 0.49, -0.05))
	# les bras : épaule, bras, coude, avant-bras, pince aux mâchoires rembourrées
	for sx5 in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(sx5 * 0.47, 1.08, 0.04)
		_body75.add_child(sh)
		_mesh(sh, _sph75(0.085, 12), joint, Vector3.ZERO)
		_mesh(sh, _cyl75(0.05, 0.055, 0.3, 10), grey, Vector3(0, -0.15, 0))
		var el := Node3D.new()
		el.position = Vector3(0, -0.3, 0)
		sh.add_child(el)
		_mesh(el, _sph75(0.06, 10), joint, Vector3.ZERO)
		_mesh(el, _cyl75(0.045, 0.05, 0.3, 10), grey, Vector3(0, 0, 0.15), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		_mesh(el, _rbox75(Vector3(0.2, 0.08, 0.06), 0.02), dark, Vector3(0, 0, 0.31))
		for jy in [-1.0, 1.0]:
			_mesh(el, _rbox75(Vector3(0.03, 0.12, 0.12), 0.012), dark, Vector3(-sx5 * 0.0 + jy * 0.085, 0, 0.37))
			_mesh(el, _rbox75(Vector3(0.035, 0.13, 0.11), 0.015), pad, Vector3(jy * 0.06, 0, 0.375))
		_arms75.append([sh, el, sx5])
	# un peu de fumée quand il force
	_steam75 = _smoke_emitter(_visual, Vector3(-0.28, 1.22, -0.28), 0.6, Color(0.6, 0.6, 0.62, 0.5))
	_mesh(_body75, _cyl75(0.035, 0.035, 0.12, 8), dark, Vector3(-0.28, 1.25, -0.28))


## Un petit panache (fumée, vapeur) : ne s'allume que quand on le demande.
func _smoke_emitter(parent: Node3D, at: Vector3, s: float, c: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 12
	p.lifetime = 1.4
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 18.0
	p.initial_velocity_min = 0.5 * s
	p.initial_velocity_max = 1.0 * s
	p.gravity = Vector3(0, 0.4, 0)
	p.scale_amount_min = 0.6 * s
	p.scale_amount_max = 1.2 * s
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 2.2))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, c)
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	p.color_ramp = grad
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.35)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _dot_tex()
	qm.material = m
	p.mesh = qm
	p.position = at
	parent.add_child(p)
	return p


## La charge du déménageur : une caisse, un fauteuil, un carton (tenue entre les pinces).
func _build_load(what: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Charge"
	match what:
		"fauteuil":
			var fab := _skin71("velours75", 7531, 0.09, [[0.0, Color(0.45, 0.08, 0.1)], [1.0, Color(0.68, 0.16, 0.16)]], 0.9, 6.0, 3.0)
			var wood := _wood71()
			_mesh(n, _rbox75(Vector3(0.62, 0.16, 0.56), 0.06), fab, Vector3(0, 0.0, 0))
			_mesh(n, _rbox75(Vector3(0.62, 0.5, 0.14), 0.07), fab, Vector3(0, 0.28, -0.22), Vector3.ONE, Vector3(-0.15, 0, 0))
			for sx in [-1.0, 1.0]:
				_mesh(n, _rbox75(Vector3(0.12, 0.24, 0.52), 0.05), fab, Vector3(sx * 0.3, 0.13, 0.0))
				for sz in [-1.0, 1.0]:
					_mesh(n, _cyl75(0.022, 0.016, 0.14, 8), wood, Vector3(sx * 0.26, -0.13, sz * 0.22))
			n.rotation.y = PI
		"carton":
			var card := _skin71("carton75", 7532, 0.2, [[0.0, Color(0.55, 0.4, 0.24)], [1.0, Color(0.68, 0.52, 0.32)]], 0.95, 4.0, 1.5)
			var tape := _mat(Color(0.75, 0.65, 0.45), 0.3)
			_mesh(n, _box75(Vector3(0.55, 0.42, 0.42)), card, Vector3.ZERO)
			_mesh(n, _box75(Vector3(0.08, 0.425, 0.425)), tape, Vector3.ZERO)
			var lb := Label3D.new()
			lb.text = ["VAISSELLE", "DISQUES", "FRAGILE", "PATCHS", "BRIC-À-BRAC"][randi() % 5]
			lb.font_size = 36
			lb.pixel_size = 0.0018
			lb.modulate = Color(0.1, 0.1, 0.12)
			lb.position = Vector3(0, 0.05, 0.212)
			lb.shaded = true
			n.add_child(lb)
		_:
			var w := _wood71()
			var dk := _skin71("bois_fonce75", 7533, 0.04, [[0.0, Color(0.18, 0.11, 0.06)], [1.0, Color(0.3, 0.2, 0.1)]], 0.8, 2.0, 5.0)
			_mesh(n, _box75(Vector3(0.6, 0.46, 0.46)), dk, Vector3.ZERO)
			for y in [-0.17, 0.0, 0.17]:
				_mesh(n, _box75(Vector3(0.62, 0.1, 0.48)), w, Vector3(0, y, 0))
			for sx2 in [-1.0, 1.0]:
				_mesh(n, _box75(Vector3(0.06, 0.48, 0.5)), w, Vector3(sx2 * 0.29, 0, 0))
	return n


## Mode « porter » : emporter une charge vers « cible_pos » (le quai) ; m.arrive à 2 m.
func porter(cible_pos: Vector3, quoi: String = "") -> void:
	if kind != "robot_demenageur" or state == "mort":
		return
	cible = cible_pos
	objet = quoi if quoi != "" else ["caisse", "fauteuil", "carton", "caisse"][randi() % 4]
	arrive = false
	porteur = true
	if _load != null and is_instance_valid(_load):
		_load.queue_free()
	_load = _build_load(objet)
	_load.position = Vector3(0, 1.0, 0.62)
	_visual.add_child(_load)
	state = "porte"
	timer = 0.0


## Pose (ou lâche) la charge : elle tombe là où elle est et reste un moment par terre.
func lacher() -> void:
	porteur = false
	if _load == null or not is_instance_valid(_load):
		_load = null
		return
	var l: Node3D = _load
	_load = null
	var gt: Transform3D = l.global_transform
	l.get_parent().remove_child(l)
	manager.add_child(l)
	l.global_transform = gt
	var gy: float = _ground_y71(gt.origin, gt.origin.y) if is_inside_tree() else gt.origin.y - 1.0
	if gy < -1e8:
		gy = global_position.y
	var tw := l.create_tween()
	tw.tween_property(l, "global_position:y", gy + 0.24, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(l, "rotation:z", randf_range(-0.12, 0.12), 0.35)
	tw.tween_interval(25.0)
	tw.tween_property(l, "scale", Vector3.ONE * 0.01, 0.6)
	tw.tween_callback(l.queue_free)
	_sfx71("caisse_casse" if objet == "caisse" else "jeter", gt.origin, -6.0)


func _carry_tick(delta: float) -> void:
	var to: Vector3 = cible - global_position
	to.y = 0.0
	var d: float = to.length()
	var move := Vector3.ZERO
	if d < 2.0:
		if not arrive:
			arrive = true
			_set_face("content", 2.0)
			if randf() < 0.5:
				_say75(_line75("robots"))
		state = "arrive"
	else:
		var dir: Vector3 = to / d
		if _detour_t > 0.0:
			_detour_t -= delta
			dir = _detour
		elif is_on_wall():
			_detour = dir.rotated(Vector3.UP, (1.2 if randf() < 0.5 else -1.2))
			_detour_t = 0.9
		facing = facing.lerp(dir, clampf(delta * 3.0, 0.0, 1.0)).normalized()
		move = facing * float(spec["vitesse"]) * 0.8
	var dist: float = global_position.distance_to(_player_feet75())
	_maybe_talk(delta, "robots", dist)
	_move75(move, delta)


# =================================================================== le drone-huissier

func _build_drone() -> void:
	var shell := _paint(Color(0.86, 0.87, 0.86), 0.32, 0.05)
	var dark := _steel(Color(0.18, 0.18, 0.2), 0.4)
	var blade := _rubber(Color(0.06, 0.06, 0.07))
	_body75 = Node3D.new()
	_body75.name = "Drone"
	_visual.add_child(_body75)
	_mesh(_body75, _rbox75(Vector3(0.2, 0.08, 0.28), 0.035), shell, Vector3.ZERO)
	_mesh(_body75, _rbox75(Vector3(0.14, 0.04, 0.18), 0.02), dark, Vector3(0, 0.05, -0.02))
	var stripe := _paint(Color(0.96, 0.74, 0.08), 0.4, 0.1)
	_mesh(_body75, _rbox75(Vector3(0.205, 0.02, 0.285), 0.01), stripe, Vector3(0, -0.012, 0))
	# l'œil-caméra et le feu rouge
	_mesh(_body75, _sph75(0.035, 12), _glass(Color(0.03, 0.03, 0.04)), Vector3(0, -0.04, 0.12))
	_face_mat = _mat(Color(1.0, 0.1, 0.06), 0.2, 4.0)
	_mesh(_body75, _sph75(0.016, 8), _face_mat, Vector3(0, 0.035, 0.13))
	for k in range(4):
		var a: float = PI * 0.25 + PI * 0.5 * k
		var dir := Vector3(sin(a), 0, cos(a))
		var arm_end: Vector3 = dir * 0.24
		_stick(_body75, dir * 0.06, arm_end, 0.014, dark)
		_mesh(_body75, _cyl75(0.025, 0.028, 0.05, 10), dark, arm_end + Vector3.UP * 0.02)
		var rot := Node3D.new()
		rot.position = arm_end + Vector3.UP * 0.05
		_body75.add_child(rot)
		for b in range(2):
			_mesh(rot, _box75(Vector3(0.21, 0.004, 0.022)), blade, Vector3.ZERO, Vector3.ONE, Vector3(0.08 * (1 if b == 0 else -1), PI * 0.5 * b, 0))
		var disc := StandardMaterial3D.new()
		disc.albedo_color = Color(0.2, 0.2, 0.22, 0.12)
		disc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disc.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh(rot, _cyl75(0.11, 0.11, 0.002, 20), disc, Vector3.ZERO)
		_rotors.append(rot)
	# l'avis d'expulsion, pendu à deux fils
	_paper = Node3D.new()
	_paper.position = Vector3(0, -0.06, 0.0)
	_body75.add_child(_paper)
	var thread := _mat(Color(0.8, 0.8, 0.78), 0.8)
	for sx in [-0.05, 0.05]:
		_mesh(_paper, _cyl75(0.0025, 0.0025, 0.12, 4), thread, Vector3(sx, -0.06, 0))
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = _paper_tex()
	pm.roughness = 0.95
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flash_mats.append(pm)
	var pq := QuadMesh.new()
	pq.size = Vector2(0.14, 0.19)
	_mesh(_paper, pq, pm, Vector3(0, -0.215, 0))
	var lb := Label3D.new()
	lb.text = "AVIS\nD'EXPULSION"
	lb.font_size = 22
	lb.pixel_size = 0.001
	lb.modulate = Color(1, 1, 1)
	lb.outline_size = 0
	lb.position = Vector3(0, -0.14, 0.002)
	lb.shaded = true
	_paper.add_child(lb)


func _drone_tick(delta: float) -> void:
	var p: Vector3 = _player_feet75()
	var to_p: Vector3 = p - global_position
	var flat: Vector3 = Vector3(to_p.x, 0, to_p.z)
	var dist: float = flat.length()
	var dir_p: Vector3 = flat / dist if dist > 0.01 else facing
	var ground: float = _ground_y71(global_position, global_position.y - 1.0)
	if ground < -1e8:
		ground = home.y
	var goal := global_position
	timer -= delta
	var sp: float = float(spec["vitesse"])
	match state:
		"veille":
			goal = home + Vector3(sin(_clock * 0.4) * 1.5, _alt, cos(_clock * 0.31) * 1.5)
			goal.y = ground + _alt
			if dist < float(spec["vue"]) and absf(to_p.y) < 6.0:
				state = "chasse"
				manager.alert(self)
				_sfx71("robot_bip", global_position)
		"chasse", "souffle", "recul":
			# il tourne autour du joueur en lisant ses avis
			_orbit_a += delta * 0.55
			var r: float = 4.2 + sin(_clock * 0.7) * 0.6
			goal = p + Vector3(cos(_orbit_a), 0, sin(_orbit_a)) * r
			goal.y = maxf(ground, p.y) + _alt + sin(_clock * 1.3) * 0.2
			if state == "chasse" and dist > float(spec["vue"]) * 1.8:
				state = "veille"
			_maybe_talk(delta, "drones", dist)
			if timer <= 0.0 and state != "chasse":
				state = "chasse"
				timer = randf_range(2.5, 4.5)
			elif timer <= 0.0 and state == "chasse" and dist < 7.0:
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("robot_bip", global_position, 2.0)
				_say75("Décharge réglementaire !", 1.4)
		"armer":
			goal = global_position
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.9
				_dive_from = global_position
				_dive_to = p + Vector3.UP * 1.1
				_zapped = false
		"frappe":
			var k: float = clampf(1.0 - timer / 0.9, 0.0, 1.0)
			var pc: Vector3 = p + Vector3.UP * 1.0
			if k < 0.65 and not _zapped:
				# il fond sur le joueur (il le suit un peu)
				_dive_to = _dive_to.lerp(pc, clampf(delta * 3.0, 0.0, 1.0))
				goal = _dive_to
			else:
				goal = _dive_to + (_dive_to - _dive_from).normalized() * 1.5
			sp = 8.0
			if not _zapped and global_position.distance_to(pc) < 1.25:
				_zapped = true
				manager.hurt_player(int(spec["degats"]), global_position)
				_sfx71("drone_zap", global_position)
				_zap_fx(global_position)
			if timer <= 0.0:
				# essoufflé : il reste bas un instant (c'est le moment de le frapper)
				state = "souffle"
				timer = 1.6
				_alt = 1.25
		"etourdi":
			goal = global_position
			if timer <= 0.0:
				state = "chasse"
	if state == "souffle" and timer > 0.0:
		goal.y = ground + 1.25
	elif state in ["chasse", "veille"]:
		_alt = lerpf(_alt, float(spec["vol"]), delta * 0.8)
	var v: Vector3 = goal - global_position
	var vmax: float = sp if state == "frappe" else sp * 0.8
	if v.length() > vmax:
		v = v.normalized() * vmax
	else:
		v *= 2.0 if state != "frappe" else 4.0
		if v.length() > vmax:
			v = v.normalized() * vmax
	if _knock.length() > 0.05:
		v += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 10.0)
	velocity = v
	move_and_slide()
	if state != "frappe" and dist > 0.3:
		facing = facing.lerp(dir_p, clampf(delta * 3.0, 0.0, 1.0)).normalized()
	rotation.y = atan2(facing.x, facing.z)
	_snd_t -= delta
	if _snd_t <= 0.0 and dist < 16.0:
		_snd_t = 2.4
		_sfx71("drone_vol", global_position, -6.0)
	_animate75(delta, v.length())


func _zap_fx(at: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 22
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.local_coords = false
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.6, 0.85, 1.0)
	m.albedo_texture = _dot_tex()
	q.material = m
	p.mesh = q
	manager.add_child(p)
	p.global_position = at
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


# =================================================================== le robot soudeur

func _build_soudeur() -> void:
	var grey := _paint(Color(0.58, 0.6, 0.62), 0.42, 0.35)
	var dark := _steel(Color(0.22, 0.23, 0.25), 0.45)
	var yellow := _paint(Color(0.96, 0.74, 0.08), 0.4, 0.2)
	var hz := _hazard_mat()
	var joint := _steel(Color(0.3, 0.31, 0.33), 0.3)
	_body75 = Node3D.new()
	_visual.add_child(_body75)
	for sx in [-1.0, 1.0]:
		_build_track(_visual, Vector3(sx * 0.33, 0.15, 0.0), 0.5, 0.13, 0.16, dark)
	_mesh(_body75, _rbox75(Vector3(0.62, 0.34, 0.74), 0.06), grey, Vector3(0, 0.42, 0))
	_mesh(_body75, _rbox75(Vector3(0.64, 0.08, 0.76), 0.03), hz, Vector3(0, 0.3, 0))
	# les bouteilles de gaz à l'arrière
	var bottle := _paint(Color(0.15, 0.32, 0.6), 0.35, 0.3)
	var bottle2 := _paint(Color(0.65, 0.12, 0.1), 0.35, 0.3)
	for k in range(2):
		_mesh(_body75, _cyl75(0.07, 0.07, 0.42, 14), bottle if k == 0 else bottle2, Vector3(-0.1 + k * 0.2, 0.78, -0.27))
		_mesh(_body75, _sph75(0.07, 12), bottle if k == 0 else bottle2, Vector3(-0.1 + k * 0.2, 0.99, -0.27))
		_mesh(_body75, _cyl75(0.02, 0.02, 0.05, 8), _chrome(), Vector3(-0.1 + k * 0.2, 1.07, -0.27))
	# la tourelle et son écran
	_turret = Node3D.new()
	_turret.position = Vector3(0, 0.6, 0.08)
	_body75.add_child(_turret)
	_mesh(_turret, _cyl75(0.24, 0.26, 0.12, 20), dark, Vector3(0, 0.0, 0))
	_mesh(_turret, _rbox75(Vector3(0.36, 0.26, 0.3), 0.06), grey, Vector3(0, 0.18, 0.0))
	_face_mat = _screen_mat("fache", Color(0.55, 0.95, 1.0))
	var q := QuadMesh.new()
	q.size = Vector2(0.26, 0.17)
	_mesh(_turret, q, _face_mat, Vector3(0, 0.19, 0.152))
	_face_expr = "fache"
	# le bras de soudage : épaule, coude, poignet, chalumeau
	var sh := Node3D.new()
	sh.position = Vector3(0.0, 0.3, 0.05)
	_turret.add_child(sh)
	_mesh(sh, _cyl75(0.09, 0.09, 0.26, 16), yellow, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_mesh(sh, _rbox75(Vector3(0.14, 0.5, 0.14), 0.05), grey, Vector3(0, 0.25, 0))
	var el := Node3D.new()
	el.position = Vector3(0, 0.5, 0)
	sh.add_child(el)
	_mesh(el, _cyl75(0.075, 0.075, 0.2, 16), yellow, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_mesh(el, _rbox75(Vector3(0.11, 0.11, 0.48), 0.04), grey, Vector3(0, 0, 0.24))
	var wr := Node3D.new()
	wr.position = Vector3(0, 0, 0.48)
	el.add_child(wr)
	_mesh(wr, _sph75(0.06, 12), joint, Vector3.ZERO)
	_mesh(wr, _cyl75(0.03, 0.045, 0.22, 12), dark, Vector3(0, -0.04, 0.1), Vector3.ONE, Vector3(PI * 0.62, 0, 0))
	_mesh(wr, _cyl75(0.012, 0.022, 0.08, 10), _chrome(), Vector3(0, -0.12, 0.19), Vector3.ONE, Vector3(PI * 0.62, 0, 0))
	_torch = Node3D.new()
	_torch.position = Vector3(0, -0.15, 0.22)
	wr.add_child(_torch)
	# le tuyau du gaz (des bouteilles au bras)
	_tube(_body75, [Vector3(0.0, 1.05, -0.27), Vector3(0.05, 1.2, -0.15), Vector3(0.08, 1.3, 0.1), Vector3(0.06, 1.25, 0.3)], 0.018, 0.018, _rubber(Color(0.1, 0.1, 0.1)), 6)
	_arms75.append([sh, el, 1.0])
	_arms75.append([wr, null, 0.0])
	# l'arc : une boule bleu-blanc qui crépite, une petite lumière, des étincelles
	_arc_mat = _mat(Color(0.7, 0.85, 1.0), 0.0, 9.0)
	_arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arc_mesh = _mesh(_torch, _sph75(0.03, 8), _arc_mat, Vector3.ZERO)
	_arc_mesh.visible = false
	_arc_light = OmniLight3D.new()
	_arc_light.light_color = Color(0.65, 0.8, 1.0)
	_arc_light.omni_range = 3.0
	_arc_light.light_energy = 0.0
	_arc_light.shadow_enabled = false
	_torch.add_child(_arc_light)
	_sparks = CPUParticles3D.new()
	_sparks.emitting = false
	_sparks.amount = 40
	_sparks.lifetime = 0.6
	_sparks.local_coords = false
	_sparks.direction = Vector3(0, 0.5, 1)
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 1.5
	_sparks.initial_velocity_max = 3.5
	_sparks.gravity = Vector3(0, -9.8, 0)
	_sparks.scale_amount_min = 0.4
	_sparks.scale_amount_max = 1.0
	var sq := QuadMesh.new()
	sq.size = Vector2(0.025, 0.025)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	smat.vertex_color_use_as_albedo = true
	smat.albedo_texture = _dot_tex()
	sq.material = smat
	_sparks.mesh = sq
	var sg := Gradient.new()
	sg.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	sg.set_color(1, Color(1.0, 0.45, 0.1, 0.0))
	_sparks.color_ramp = sg
	_torch.add_child(_sparks)
	_arc_fx = _breath(_torch, Vector3.ZERO, 0.45, true)
	var ag := Gradient.new()
	ag.set_color(0, Color(0.95, 0.98, 1.0, 1.0))
	ag.set_color(1, Color(0.3, 0.5, 1.0, 0.0))
	_arc_fx.color_ramp = ag
	_arc_fx.gravity = Vector3.ZERO
	_arc_fx.lifetime = 0.3
	_breaths.erase(_arc_fx)


# =================================================================== les pelleteuses

## La pelleteuse (s = 1 : la mini, ~3 m bras levé ; s = 3 : la Grande, ~9 m), châssis à chenilles,
## tourelle (cabine, contrepoids rayé, moteur), flèche, bras, godet, vérins, durites.
func _build_digger(s: float, boss: bool) -> void:
	var grey := _paint(Color(0.6, 0.61, 0.63) if not boss else Color(0.5, 0.52, 0.55), 0.45, 0.35)
	var dark := _steel(Color(0.2, 0.21, 0.22), 0.45)
	var yellow := _paint(Color(0.95, 0.72, 0.08), 0.42, 0.2)
	var hz := _hazard_mat()
	var bucket_m := _steel(Color(0.28, 0.27, 0.26), 0.55)
	var rust := _skin71("rouille75", 7541, 0.08, [[0.0, Color(0.25, 0.14, 0.08)], [0.5, Color(0.42, 0.24, 0.12)], [1.0, Color(0.3, 0.27, 0.25)]], 0.8, 2.0, 4.0)
	rust.metallic = 0.4
	var chrome := _chrome()
	_body75 = Node3D.new()
	_body75.scale = Vector3.ONE * s
	_visual.add_child(_body75)
	for sx in [-1.0, 1.0]:
		_build_track(_body75, Vector3(sx * 0.62, 0.24, 0.0), 1.5, 0.23, 0.36, dark)
	_mesh(_body75, _rbox75(Vector3(0.95, 0.3, 1.5), 0.06), dark, Vector3(0, 0.38, 0))
	_mesh(_body75, _cyl75(0.42, 0.45, 0.12, 24), dark, Vector3(0, 0.58, 0))
	# la tourelle
	_house = Node3D.new()
	_house.name = "Tourelle"
	_house.position = Vector3(0, 0.64, 0)
	_body75.add_child(_house)
	_mesh(_house, _rbox75(Vector3(1.5, 0.5, 1.8), 0.08), grey, Vector3(0, 0.26, -0.1))
	_mesh(_house, _rbox75(Vector3(1.52, 0.42, 0.5), 0.1), hz, Vector3(0, 0.3, -0.85))
	# la cabine (à gauche) : vitres teintées, l'écran-visage
	_mesh(_house, _rbox75(Vector3(0.66, 0.78, 0.82), 0.08), grey, Vector3(-0.38, 0.9, 0.38))
	_mesh(_house, _rbox75(Vector3(0.6, 0.5, 0.06), 0.03), _glass(), Vector3(-0.38, 0.98, 0.79))
	for sx2 in [-1.0, 1.0]:
		_mesh(_house, _rbox75(Vector3(0.06, 0.42, 0.62), 0.02), _glass(), Vector3(-0.38 + sx2 * 0.32, 0.98, 0.38))
	_face_mat = _screen_mat("rouge" if boss else "fache", Color(1.0, 0.18, 0.1) if boss else Color(0.55, 0.95, 1.0))
	_face_expr = "rouge" if boss else "fache"
	var q := QuadMesh.new()
	q.size = Vector2(0.48, 0.34)
	_mesh(_house, q, _face_mat, Vector3(-0.38, 0.98, 0.825))
	if boss:
		var lb := Label3D.new()
		lb.text = "OPTIMUS-LISSE"
		lb.font_size = 48
		lb.pixel_size = 0.0018
		lb.modulate = Color(1.0, 0.25, 0.15)
		lb.outline_size = 0
		lb.position = Vector3(-0.38, 1.25, 0.8)
		_house.add_child(lb)
		var face_l := OmniLight3D.new()
		face_l.light_color = Color(1.0, 0.2, 0.1)
		face_l.light_energy = 0.8
		face_l.omni_range = 2.5
		face_l.position = Vector3(-0.38, 1.0, 1.0)
		_house.add_child(face_l)
	# le moteur (à droite), la cheminée d'échappement
	_mesh(_house, _rbox75(Vector3(0.62, 0.32, 0.9), 0.06), grey, Vector3(0.42, 0.66, -0.4))
	for k in range(5):
		_mesh(_house, _box75(Vector3(0.5, 0.012, 0.03)), dark, Vector3(0.42, 0.83, -0.7 + k * 0.08))
	_mesh(_house, _cyl75(0.05, 0.05, 0.5, 10), dark, Vector3(0.6, 1.0, -0.6))
	_exhaust = _smoke_emitter(_house, Vector3(0.6, 1.28, -0.6), 0.7 * s, Color(0.35, 0.35, 0.37, 0.45))
	_exhaust.emitting = true
	var lb2 := Label3D.new()
	lb2.text = "LISSE & FILS"
	lb2.font_size = 64
	lb2.pixel_size = 0.0022
	lb2.modulate = Color(0.08, 0.08, 0.1)
	lb2.position = Vector3(0.755, 0.3, -0.1)
	lb2.rotation.y = PI * 0.5
	lb2.shaded = true
	_house.add_child(lb2)
	var lb3 := lb2.duplicate() as Label3D
	lb3.position = Vector3(-0.755, 0.3, -0.1)
	lb3.rotation.y = -PI * 0.5
	_house.add_child(lb3)
	# la flèche (coudée), le bras, le godet
	_boom = Node3D.new()
	_boom.name = "Fleche"
	_boom.position = Vector3(0.2, 0.62, 0.72)
	_house.add_child(_boom)
	_mesh(_boom, _cyl75(0.09, 0.09, 0.3, 14), dark, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	# deux tronçons : vers le haut-avant, puis vers l'avant
	var b1 := Node3D.new()
	_boom.add_child(b1)
	_mesh(b1, _rbox75(Vector3(0.22, 0.26, 1.2), 0.05), yellow, Vector3(0, 0, 0.6))
	b1.rotation.x = -0.75
	var knee := Node3D.new()
	knee.position = Vector3(0, 0.82, 0.82)
	_boom.add_child(knee)
	_mesh(knee, _rbox75(Vector3(0.2, 0.24, 1.0), 0.05), yellow, Vector3(0, 0, 0.45))
	_mesh(knee, _box75(Vector3(0.23, 0.05, 0.6)), hz, Vector3(0, 0.12, 0.45))
	knee.rotation.x = 0.35
	_dstick = Node3D.new()
	_dstick.name = "Bras"
	_dstick.position = Vector3(0, 0.82 - 0.31, 0.82 + 0.85)
	_boom.add_child(_dstick)
	_mesh(_dstick, _cyl75(0.08, 0.08, 0.26, 14), dark, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_mesh(_dstick, _rbox75(Vector3(0.17, 0.2, 1.05), 0.04), yellow, Vector3(0, -0.05, 0.42), Vector3.ONE, Vector3(0, 0, 0))
	_mesh(_dstick, _rbox75(Vector3(0.15, 0.18, 0.3), 0.04), yellow, Vector3(0, 0.1, -0.15))
	_bucket = Node3D.new()
	_bucket.name = "Godet"
	_bucket.position = Vector3(0, -0.05, 0.95)
	_dstick.add_child(_bucket)
	_mesh(_bucket, _cyl75(0.065, 0.065, 0.36, 12), dark, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	# le godet : un fond courbe (des plaques le long d'un arc), un plancher, deux joues, des dents
	var bc := Vector3(0, -0.2, 0.1)
	var br: float = 0.25
	for k2 in range(9):
		var ph: float = 0.08 + k2 * 0.4
		var pos := bc + Vector3(0, cos(ph) * br, -sin(ph) * br)
		_mesh(_bucket, _box75(Vector3(0.5, 0.025, 0.105)), bucket_m if k2 % 3 != 1 else rust, pos, Vector3.ONE, Vector3(-ph, 0, 0))
	_mesh(_bucket, _box75(Vector3(0.5, 0.025, 0.17)), bucket_m, Vector3(0, -0.442, 0.27))
	_mesh(_bucket, _box75(Vector3(0.52, 0.03, 0.05)), dark, Vector3(0, -0.438, 0.355))
	var cheek: Mesh = _cheek_mesh(bc, br)
	for sx3 in [-1.0, 1.0]:
		_mesh(_bucket, cheek, bucket_m, Vector3(sx3 * 0.255, 0, 0))
	for t in range(5):
		_mesh(_bucket, _cyl75(0.0, 0.026, 0.1, 6), chrome, Vector3(-0.2 + t * 0.1, -0.44, 0.42), Vector3(1, 1, 0.55), Vector3(PI * 0.5, 0, 0))
	# les vérins (fût peint, tige chromée) : ancrés aux deux bouts, recalculés à chaque image
	_piston(_house, Vector3(0.2, 0.42, 0.62), _boom, Vector3(0, 0.55, 0.55), 0.07, grey, chrome)
	_piston(_boom, Vector3(0, 1.0, 0.9), _dstick, Vector3(0, 0.25, -0.25), 0.055, grey, chrome)
	_piston(_dstick, Vector3(0, 0.12, 0.05), _bucket, Vector3(0, 0.1, -0.05), 0.045, grey, chrome)
	# les durites hydrauliques : orangées, elles luisent (la Grande Pelleteuse : ses points faibles)
	var hose_c: Color = Color(1.0, 0.45, 0.08) if boss else Color(0.12, 0.12, 0.12)
	for h in range(3):
		var hm := _mat(hose_c, 0.5, 0.9 if boss else 0.0)
		_hose_mats.append(hm)
		var off: float = -0.07 + h * 0.07
		var hp: Array
		match h:
			0:
				hp = [Vector3(off, 0.15, 0.4), Vector3(off, 0.3, 0.1), Vector3(off, 0.6, 0.15)]
			1:
				hp = [Vector3(off, 0.1, 0.45), Vector3(off * 2.0, 0.55, 0.55), Vector3(off, 0.95, 0.85)]
			_:
				hp = [Vector3(off, 0.9, 0.8), Vector3(off, 1.02, 1.2), Vector3(off, 0.72, 1.62)]
		_tube(_boom, hp, 0.022, 0.022, hm, 6)
		var hp2: Array = [Vector3(off, 0.08, -0.15), Vector3(off, 0.14, 0.3), Vector3(off, 0.05, 0.8)]
		_tube(_dstick, hp2, 0.02, 0.02, hm, 6)
		var vap := _smoke_emitter(_dstick if h == 2 else _boom, (hp2[1] if h == 2 else hp[1]) as Vector3, 0.8 * s, Color(0.95, 0.95, 0.98, 0.55))
		_hoses.append([hm, vap])
	if boss:
		_steam75 = _smoke_emitter(_body75, Vector3(0, 0.3, 0), 2.0, Color(0.95, 0.95, 1.0, 0.6))
		_steam75.amount = 40
		_steam75.spread = 80.0
		_steam75.direction = Vector3.UP
		_steam75.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		_steam75.emission_ring_axis = Vector3.UP
		_steam75.emission_ring_radius = 1.4
		_steam75.emission_ring_inner_radius = 1.0
		_steam75.emission_ring_height = 0.1
		# le cercle rouge (télégraphe du coup de godet) et le point faible
		_weak = PointFaible.new()
		(_weak as PointFaible).boss = self
		_weak.name = "Durites"
		add_child(_weak)
		_weak.top_level = true
		_weak.add_to_group("cibles_v28")
	_circle = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 6
	_circle.mesh = tm
	_circle_mat = StandardMaterial3D.new()
	_circle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_circle_mat.albedo_color = Color(1.0, 0.1, 0.05, 0.8)
	_circle_mat.emission_enabled = true
	_circle_mat.emission = Color(1.0, 0.1, 0.05)
	_circle_mat.no_depth_test = false
	_circle.material_override = _circle_mat
	_circle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_circle.top_level = true
	_circle.visible = false
	add_child(_circle)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.92
	dm.bottom_radius = 0.92
	dm.height = 0.01
	dm.radial_segments = 32
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.albedo_color = Color(1.0, 0.1, 0.05, 0.18)
	disc.material_override = dmat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_circle.add_child(disc)
	_arm_goal = Vector3(-0.15, 0.9, 0.5)
	_apply_arm(1.0)


## La joue du godet : un secteur de disque (le fond courbe) prolongé par le plancher, en plaque.
func _cheek_mesh(c: Vector3, r: float) -> Mesh:
	if _m75.has("joue_godet"):
		return _m75["joue_godet"]
	var outline: Array = []
	for i in range(15):
		var ph: float = deg_to_rad(200.0) * float(i) / 14.0
		outline.append(c + Vector3(0, cos(ph) * r, -sin(ph) * r))
	outline.append(Vector3(0, -0.455, 0.36))
	outline.append(Vector3(0, -0.02, 0.3))
	var ctr := Vector3.ZERO
	for p in outline:
		ctr += p
	ctr /= float(outline.size())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		var off := Vector3(side * 0.012, 0, 0)
		var nrm := Vector3(side, 0, 0)
		for i in range(outline.size()):
			var a: Vector3 = (outline[i] as Vector3) + off
			var b: Vector3 = (outline[(i + 1) % outline.size()] as Vector3) + off
			var cc: Vector3 = ctr + off
			var g: Vector3 = (a - cc).cross(b - cc)
			var tri: Array = [cc, a, b] if g.dot(nrm) < 0.0 else [cc, b, a]
			for v in tri:
				st.set_normal(nrm)
				st.set_uv(Vector2((v as Vector3).z, (v as Vector3).y))
				st.add_vertex(v)
	# la tranche
	for i2 in range(outline.size()):
		var a2: Vector3 = outline[i2]
		var b2: Vector3 = outline[(i2 + 1) % outline.size()]
		var n2: Vector3 = ((a2 + b2) * 0.5 - ctr).normalized()
		var q: Array = [a2 + Vector3(-0.012, 0, 0), b2 + Vector3(-0.012, 0, 0), b2 + Vector3(0.012, 0, 0), a2 + Vector3(0.012, 0, 0)]
		for tri2 in [[0, 1, 2], [0, 2, 3]]:
			var pa: Vector3 = q[tri2[0]]
			var pb: Vector3 = q[tri2[1]]
			var pc: Vector3 = q[tri2[2]]
			var g2: Vector3 = (pb - pa).cross(pc - pa)
			var ord: Array = [pa, pb, pc] if g2.dot(n2) < 0.0 else [pa, pc, pb]
			for v2 in ord:
				st.set_normal(n2)
				st.set_uv(Vector2((v2 as Vector3).z, (v2 as Vector3).x))
				st.add_vertex(v2)
	var m: ArrayMesh = st.commit()
	_m75["joue_godet"] = m
	return m


func _piston(pa: Node3D, a: Vector3, pb: Node3D, b: Vector3, r: float, barrel_m: Material, rod_m: Material) -> void:
	var an := Node3D.new()
	an.position = a
	pa.add_child(an)
	var bn := Node3D.new()
	bn.position = b
	pb.add_child(bn)
	var L: float = 0.62
	var barrel := MeshInstance3D.new()
	barrel.mesh = _cyl75(r, r, 1.0, 12)
	barrel.material_override = barrel_m
	_body75.add_child(barrel)
	var rod := MeshInstance3D.new()
	rod.mesh = _cyl75(r * 0.55, r * 0.55, 1.0, 10)
	rod.material_override = rod_m
	_body75.add_child(rod)
	_pistons.append([an, bn, barrel, rod, L])


## Recalcule les vérins entre leurs ancres (dans le repère du corps).
func _update_pistons() -> void:
	if _pistons.is_empty():
		return
	var inv: Transform3D = _body75.global_transform.affine_inverse()
	for p in _pistons:
		var a: Vector3 = inv * (p[0] as Node3D).global_position
		var b: Vector3 = inv * (p[1] as Node3D).global_position
		var d: Vector3 = b - a
		var L: float = d.length()
		if L < 0.01:
			continue
		var dir: Vector3 = d / L
		var bl: float = minf(float(p[4]), L * 0.8)
		var barrel: MeshInstance3D = p[2]
		var rod: MeshInstance3D = p[3]
		var bas: Basis = PB._basis_y(dir)
		barrel.transform = Transform3D(bas * Basis.from_scale(Vector3(1, bl, 1)), a + dir * bl * 0.5)
		var rl: float = maxf(L - bl * 0.6, 0.05)
		rod.transform = Transform3D(bas * Basis.from_scale(Vector3(1, rl, 1)), b - dir * rl * 0.5)


## Pose du bras : flèche (x), bras (y), godet (z) ; k = rapidité.
func _apply_arm(k: float) -> void:
	if _boom == null:
		return
	_boom.rotation.x = lerpf(_boom.rotation.x, _arm_goal.x, k)
	_dstick.rotation.x = lerpf(_dstick.rotation.x, _arm_goal.y, k)
	_bucket.rotation.x = lerpf(_bucket.rotation.x, _arm_goal.z, k)


## Où est le godet (dents) en ce moment, au monde.
func _bucket_tip() -> Vector3:
	if _bucket == null:
		return global_position
	return _bucket.to_global(Vector3(0, -0.44, 0.44))


func _digger_reach() -> float:
	return float(_calib()[1]) * (1.0 if kind == "pelleteuse_mini" else 3.0)


## Calibrage (une fois par espèce) : la position des dents du godet pour une grille de poses
## (flèche, bras), dans le repère du corps. Renvoie [poses, portée maxi, portée mini] (échelle 1).
func _calib() -> Array:
	if _calib75.has(kind):
		return _calib75[kind]
	if _boom == null or not is_inside_tree():
		return [[], 4.0, 2.0]
	var saved := [_boom.rotation.x, _dstick.rotation.x, _bucket.rotation.x, _house.rotation.y]
	_house.rotation.y = 0.0
	var poses: Array = []
	var zmin: float = INF
	var zmax: float = 0.0
	for bi in range(12):
		var b: float = lerpf(-0.6, 0.75, float(bi) / 11.0)
		for ti in range(12):
			var t: float = lerpf(0.15, 2.1, float(ti) / 11.0)
			_boom.rotation.x = b
			_dstick.rotation.x = t
			_bucket.rotation.x = 0.9
			var lp: Vector3 = _body75.to_local(_bucket.to_global(Vector3(0, -0.44, 0.44)))
			poses.append([lp.z, lp.y, b, t])
			if absf(lp.y - 0.08) < 0.12 and absf(lp.x) < 0.5:
				zmin = minf(zmin, lp.z)
				zmax = maxf(zmax, lp.z)
	_boom.rotation.x = saved[0]
	_dstick.rotation.x = saved[1]
	_bucket.rotation.x = saved[2]
	_house.rotation.y = saved[3]
	if zmin == INF:
		zmin = 2.0
		zmax = 4.0
	var out: Array = [poses, zmax, maxf(zmin, 1.35)]
	_calib75[kind] = out
	return out


## La pose (flèche, bras, godet) qui pose les dents du godet au sol à « d » mètres du centre.
func _slam_pose(d: float) -> Vector3:
	var s: float = 1.0 if kind == "pelleteuse_mini" else 3.0
	var dl: float = d / s
	var best := Vector3(0.2, 0.9, 0.9)
	var best_e: float = INF
	for e in _calib()[0]:
		var err: float = absf(float(e[0]) - dl) + 1.5 * absf(float(e[1]) - 0.08)
		if err < best_e:
			best_e = err
			best = Vector3(float(e[2]), float(e[3]), 0.9)
	return best


func _slam_min() -> float:
	return float(_calib()[2]) * (1.0 if kind == "pelleteuse_mini" else 3.0)


func _digger_tick(delta: float) -> void:
	var boss: bool = kind == "grande_pelleteuse"
	var s: float = 1.0 if not boss else 3.0
	var p: Vector3 = _player_feet75()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var move := Vector3.ZERO
	timer -= delta
	vulnerable_t = maxf(vulnerable_t - delta, 0.0) if state != "coince" else vulnerable_t
	var turn: float = (1.6 if not boss else 0.75) * _speed_k
	var reach: float = _digger_reach()
	match state:
		"veille":
			_arm_goal = Vector3(-0.15, 0.9, 0.5)
			if dist < float(spec["vue"]) and dy < 6.0:
				state = "chasse"
				timer = 1.5
				manager.alert(self)
				_sfx71("pelleteuse_cri", global_position + Vector3.UP * 2.0 * s)
				if boss:
					_say75(_line75("pelleteuse"), 3.0)
		"chasse":
			_arm_goal = Vector3(-0.15, 0.9, 0.5)
			facing = facing.lerp(dir_p, clampf(delta * turn, 0.0, 1.0)).normalized()
			if dist > reach * 0.75:
				move = facing * float(spec["vitesse"]) * _speed_k * clampf(facing.dot(dir_p) * 1.5 - 0.3, 0.0, 1.0)
			elif dist < _slam_min() * 0.8 and not boss:
				move = -facing * float(spec["vitesse"]) * 0.5 * _speed_k
			if not boss and not is_boss() and (dist > float(spec["vue"]) * 1.6 or Vector2(global_position.x - home.x, global_position.z - home.z).length() > float(spec["laisse"])):
				state = "veille"
			if boss:
				_maybe_talk(delta, "pelleteuse", dist)
				# trop près : un jet de vapeur tout autour
				if dist < 4.6:
					_close_t += delta
				else:
					_close_t = maxf(_close_t - delta, 0.0)
				if _close_t > 1.4:
					_close_t = 0.0
					state = "vapeur"
					timer = 0.75
					_steam75.amount = 16
					_steam75.emitting = true
					_sfx71("vapeur", global_position + Vector3.UP * 1.5, 2.0)
					_hint_once("vapeur", "La Grande Pelleteuse siffle… un jet de vapeur ! Écarte-toi de ses chenilles !")
			# bloquée (une pente, un obstacle) : elle attaque quand même, au plus loin de son bras
			if move.length() > 0.1 and get_real_velocity().length() < 0.15:
				_close_t2 += delta
			else:
				_close_t2 = 0.0
			if timer <= 0.0 and (dist < reach * 1.25 or _close_t2 > 2.0) and dist < reach * 2.6 and facing.dot(dir_p) > 0.8 and state == "chasse":
				_close_t2 = 0.0
				_atk_i += 1
				if dist > _slam_min() * 1.05 and (_atk_i % 3 != 0 or not boss) and (_atk_i % 2 == 1 or boss):
					# le godet se lève : cercle rouge au sol
					state = "leve"
					timer = (1.6 if boss else 1.1) / _speed_k
					_slam_at = p
					_circle.visible = true
					_sfx71("robot_servo", global_position + Vector3.UP * 2.0 * s)
					if boss:
						_hint_once("leve", "Le godet se lève… Un cercle rouge au sol : sors-en !")
				else:
					state = "balaie_armer"
					timer = 0.9 / _speed_k
					var side: float = 1.0 if randf() < 0.5 else -1.0
					_sweep_from = side * 1.05
					_sweep_hit = false
					_sfx71("robot_servo", global_position + Vector3.UP * 2.0 * s)
					if boss:
						_hint_once("balaie", "Il balaie ! Colle-toi à ses chenilles, ou recule hors de portée.")
		"leve":
			var T: float = (1.6 if boss else 1.1) / _speed_k
			var k: float = clampf(1.0 - timer / T, 0.0, 1.0)
			# le cercle suit le joueur, puis se fige (on a le temps d'en sortir)
			if k < 0.6:
				var lim: float = reach * 0.95
				var tgt: Vector3 = p
				var rel: Vector3 = tgt - global_position
				rel.y = 0.0
				if rel.length() > lim:
					tgt = global_position + rel.normalized() * lim
				if rel.length() < _slam_min():
					tgt = global_position + rel.normalized() * _slam_min()
				_slam_at = _slam_at.lerp(tgt, clampf(delta * 5.0, 0.0, 1.0))
			var to_s: Vector3 = _slam_at - global_position
			to_s.y = 0.0
			facing = facing.lerp(to_s.normalized(), clampf(delta * 3.0, 0.0, 1.0)).normalized()
			_arm_goal = Vector3(-1.05, 0.25, -0.3)
			_show_circle(_slam_at, (3.4 if boss else 2.0), k)
			if timer <= 0.0:
				state = "frappe"
				timer = 0.32
		"frappe":
			var to_s2: Vector3 = _slam_at - global_position
			to_s2.y = 0.0
			_arm_goal = _slam_pose(to_s2.length())
			if timer <= 0.0:
				_slam()
				if boss:
					state = "coince"
					timer = 3.0 / maxf(_speed_k * 0.9, 1.0)
					vulnerable_t = timer
					_hint_once("coince", "Le godet est planté dans le sol ! Les durites sont à nu : FRAPPE-LES !")
					_sfx71("vapeur", _bucket_tip(), -2.0)
				else:
					state = "souffle"
					timer = float(spec["repos"])
		"coince":
			vulnerable_t = maxf(timer, 0.0)
			# le godet tremble, coincé ; les durites palpitent
			_arm_goal.y += sin(_clock * 30.0) * 0.004
			if _weak != null:
				var tip: Vector3 = _bucket_tip()
				var back: Vector3 = (global_position - tip)
				back.y = 0.0
				_weak.global_position = Vector3(tip.x, global_position.y, tip.z) + back.normalized() * 1.6
				(_weak as PointFaible).hit_radius = 2.0
			if timer <= 0.0:
				state = "degage"
				timer = 0.9
				vulnerable_t = 0.0
				_sfx71("robot_servo", global_position + Vector3.UP * 4.0)
		"degage":
			_arm_goal = Vector3(-0.4, 0.9, 0.5)
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"]) / _speed_k
		"balaie_armer":
			_house_yaw = lerpf(_house_yaw, _sweep_from, clampf(delta * 5.0, 0.0, 1.0))
			_arm_goal = Vector3(-0.1, 1.45, 0.9)
			if timer <= 0.0:
				state = "balaie"
				timer = 1.15 / _speed_k
				_sfx71("pelleteuse_frappe", global_position + Vector3.UP * 1.5 * s, -3.0)
		"balaie":
			var T2: float = 1.15 / _speed_k
			var k2: float = clampf(1.0 - timer / T2, 0.0, 1.0)
			_house_yaw = lerpf(_sweep_from, -_sweep_from, smoothstep(0.0, 1.0, k2))
			_arm_goal = Vector3(-0.1, 1.45, 0.9)
			if not _sweep_hit:
				var tip2: Vector3 = _bucket_tip()
				var hero: Node = manager.main.get("hero_v28")
				var airborne: bool = hero != null and str(hero.state) == "air" and p.y > global_position.y + 0.5 and not boss
				if Vector2(tip2.x - p.x, tip2.z - p.z).length() < (1.0 * s if boss else 1.1) and not airborne:
					_sweep_hit = true
					manager.hurt_player(int(spec["degats"]), tip2)
					var side_dir: Vector3 = (p - global_position).cross(Vector3.UP).normalized() * signf(_sweep_from)
					_push_player(side_dir + (p - global_position).normalized() * 0.5, 3.0)
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"]) / _speed_k
		"vapeur":
			if timer <= 0.0:
				_steam75.amount = 40
				_steam75.restart()
				_steam75.emitting = true
				var st_off := func() -> void:
					if is_instance_valid(_steam75):
						_steam75.emitting = false
				get_tree().create_timer(0.8).timeout.connect(st_off)
				if dist < 5.0:
					manager.hurt_player(1, global_position)
					_push_player(dir_p, 4.0)
				state = "souffle"
				timer = 1.2
		"rugit":
			_arm_goal = Vector3(-1.2, 0.2, -0.4)
			_house_yaw = sin(_clock * 6.0) * 0.08
			if timer <= 0.0:
				state = "souffle"
				timer = 0.8
		"souffle", "recul":
			_house_yaw = lerpf(_house_yaw, 0.0, clampf(delta * 2.0, 0.0, 1.0))
			_arm_goal = Vector3(-0.15, 0.9, 0.5)
			facing = facing.lerp(dir_p, clampf(delta * turn * 0.5, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "chasse"
				timer = randf_range(0.4, 1.2) / _speed_k
	if not (state in ["leve", "frappe"]):
		_circle.visible = false
	if state != "coince" and _weak != null:
		_weak.global_position = global_position + Vector3.DOWN * 50.0
	if not (state in ["balaie_armer", "balaie", "rugit"]):
		_house_yaw = lerpf(_house_yaw, 0.0, clampf(delta * 3.0, 0.0, 1.0))
	var arm_k: float = clampf(delta * (14.0 if state == "frappe" else (3.5 if state == "leve" else 4.0)) * _speed_k, 0.0, 1.0)
	_apply_arm(arm_k)
	_tread_v = move.dot(facing)
	_move75(move, delta)


func _show_circle(at: Vector3, r: float, k: float) -> void:
	var gy: float = _ground_y71(at, global_position.y + 0.5)
	if gy < -1e8:
		gy = global_position.y
	_circle.global_position = Vector3(at.x, gy + 0.06, at.z)
	_circle.scale = Vector3(r, 1.0, r)
	_circle.visible = true
	_circle_mat.albedo_color.a = 0.45 + 0.45 * absf(sin(_clock * (6.0 + 10.0 * k)))


func _slam() -> void:
	var boss: bool = kind == "grande_pelleteuse"
	var at: Vector3 = _slam_at
	var r: float = 3.4 if boss else 2.0
	var p: Vector3 = _player_feet75()
	if Vector2(p.x - at.x, p.z - at.z).length() < r and absf(p.y - at.y) < 2.5:
		manager.hurt_player(int(spec["degats"]), at)
		_push_player(p - at, 3.5)
	elif boss and Vector2(p.x - at.x, p.z - at.z).length() < r + 2.0:
		# l'onde de choc fait trébucher
		_push_player(p - at, 2.0)
	var cb: Node = _m71().get("combat_v28")
	if cb != null:
		for k in range(10 if boss else 7):
			var a: float = TAU * k / (10.0 if boss else 7.0)
			cb.puff(at + Vector3(cos(a) * r * 0.8, 0.3, sin(a) * r * 0.8), Color(0.62, 0.6, 0.56))
	_sfx71("pelleteuse_frappe", at, 2.0 if boss else 0.0)
	_sfx71("onde_choc", at)
	_circle.visible = false


func _hint_once(key: String, t: String) -> void:
	if _said.has(key):
		return
	_said[key] = true
	_hint70(t)


## La Grande Pelleteuse : le point faible est ouvert (godet planté).
func weak_open() -> bool:
	return kind == "grande_pelleteuse" and state == "coince" and vulnerable_t > 0.0


## Un coup sur les durites : plein pot.
func hit_weak(damage: int, from_pos: Vector3) -> void:
	if not weak_open():
		return
	var cb: Node = _m71().get("combat_v28")
	if cb != null and _weak != null:
		cb.float_text(_weak.global_position + Vector3.UP * 2.0, "Dans les durites !", Color(1.0, 0.65, 0.25))
	_take75(int(round(damage * 2.0)), from_pos, true)


func _phase_check() -> void:
	if kind != "grande_pelleteuse" or hp <= 0:
		return
	var pv: int = int(spec["pv"])
	var want: int = 0
	if hp <= pv * 2 / 3:
		want = 1
	if hp <= pv / 3:
		want = 2
	while _phase75 < want:
		_phase75 += 1
		_burst_hose(_phase75 - 1)
		_speed_k = 1.0 + 0.22 * _phase75
		state = "rugit"
		timer = 2.0
		vulnerable_t = 0.0
		_circle.visible = false
		_sfx71("pelleteuse_cri", global_position + Vector3.UP * 6.0, 2.0)
		for k in range(2):
			var side: Vector3 = facing.cross(Vector3.UP).normalized() * (1.0 if k == 0 else -1.0)
			var at: Vector3 = global_position + side * 6.5 + facing * 2.0
			var gy: float = _ground_y71(at, global_position.y + 1.0)
			at.y = (gy if gy > -1e8 else global_position.y) + 0.2
			var m: Node3D = manager.spawn_extra("robot_demenageur", at)
			m.home = at
		if _phase75 == 1:
			_hint70("PSCHHHT ! Une durite éclate ! La Grande Pelleteuse rugit, plus rapide… et appelle deux déménageurs !")
		else:
			_hint70("Une deuxième durite lâche ! OPTIMUS-LISSE s'affole : elle frappe plus vite que jamais !")
		_say75("ALERTE. DURITE %d HORS SERVICE. OPTIMISATION DE LA COLÈRE." % _phase75, 3.5)


func _burst_hose(i: int) -> void:
	if i < 0 or i >= _hoses.size():
		return
	var hm: StandardMaterial3D = _hoses[i][0]
	_flash_mats.erase(hm)
	_hose_mats.erase(hm)
	if hm.has_meta("e0"):
		hm.remove_meta("e0")
	hm.albedo_color = Color(0.12, 0.08, 0.06)
	hm.emission_enabled = false
	var vap: CPUParticles3D = _hoses[i][1]
	vap.amount = 16
	vap.emitting = true
	_sfx71("durite", vap.global_position, 2.0)
	var cb: Node = _m71().get("combat_v28")
	if cb != null:
		for k in range(4):
			cb.puff(vap.global_position + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)), Color(0.35, 0.33, 0.32))


# =================================================================== les champignards

func _build_champignard(s: float, roi: bool) -> void:
	var cc: Color = CAPS75.get(couleur, CAPS75["bleu"])
	var stem_m := _skin71("pied75", 7551, 0.12, [[0.0, Color(0.82, 0.78, 0.68)], [0.6, Color(0.93, 0.9, 0.82)], [1.0, Color(0.98, 0.96, 0.9)]], 0.75, 5.0, 2.0)
	stem_m.subsurf_scatter_enabled = false
	stem_m.rim_enabled = true
	stem_m.rim = 0.3
	_cap_mat = StandardMaterial3D.new()
	_cap_mat.albedo_color = cc * 0.85
	_cap_mat.albedo_texture = _noise_tex("chapeau75", 7552, 0.07, [[0.0, Color(0.75, 0.75, 0.75)], [0.5, Color(0.95, 0.95, 0.95)], [1.0, Color(1, 1, 1)]])
	_cap_mat.uv1_triplanar = true
	_cap_mat.uv1_scale = Vector3.ONE * 3.0
	_cap_mat.roughness = 0.35
	_cap_mat.clearcoat_enabled = true
	_cap_mat.clearcoat = 0.5
	_cap_mat.emission_enabled = true
	_cap_mat.emission = cc
	_cap_mat.emission_energy_multiplier = 0.45
	_cap_mat.rim_enabled = true
	_cap_mat.rim = 0.4
	_flash_mats.append(_cap_mat)
	var gill_m := _mat(cc.lerp(Color(0.95, 0.9, 0.85), 0.55), 0.8, 0.35)
	var spot_m := _mat(Color(0.98, 0.97, 0.92), 0.5, 0.5)
	var eye_m := _wet_mat(Color(0.03, 0.03, 0.04), 0.1)
	var shine := _mat(Color(1, 1, 1), 0.1, 2.0)
	_body75 = Node3D.new()
	_body75.scale = Vector3.ONE * s
	_visual.add_child(_body75)
	_stem = Node3D.new()
	_stem.name = "Pied"
	_body75.add_child(_stem)
	var stem_mesh: Mesh = _m75mesh("champi_pied", func() -> Mesh: return _lathe71([Vector2(0.0, 0.06), Vector2(0.1, 0.07), Vector2(0.13, 0.13), Vector2(0.135, 0.22), Vector2(0.12, 0.32), Vector2(0.1, 0.4), Vector2(0.0, 0.42)], 18, 0.03))
	_mesh(_stem, stem_mesh, stem_m, Vector3.ZERO)
	# les yeux (deux points noirs brillants), la bouche ronde
	for sx in [-1.0, 1.0]:
		_mesh(_stem, _sph75(0.028, 10), eye_m, Vector3(sx * 0.05, 0.27, 0.11), Vector3(1, 1.25, 0.7))
		_mesh(_stem, _sph75(0.008, 6), shine, Vector3(sx * 0.05 + 0.008, 0.285, 0.13))
		if roi:
			_mesh(_stem, _box75(Vector3(0.06, 0.012, 0.02)), _mat(Color(0.35, 0.25, 0.2), 0.8), Vector3(sx * 0.052, 0.315, 0.115), Vector3.ONE, Vector3(0, 0, sx * 0.3))
	_mouth75 = _mesh(_stem, _sph75(0.018, 8), _mat(Color(0.25, 0.08, 0.1), 0.6), Vector3(0, 0.205, 0.122), Vector3(1.3, 0.35, 0.5))
	# des petits bras
	for sx2 in [-1.0, 1.0]:
		_mesh(_stem, _sph75(0.035, 8), stem_m, Vector3(sx2 * 0.13, 0.2, 0.02), Vector3(0.8, 1.3, 0.8), Vector3(0, 0, sx2 * 0.5))
	# le chapeau (dôme lumineux, lamelles dessous, taches blanches)
	_cap = Node3D.new()
	_cap.name = "Chapeau"
	_cap.position = Vector3(0, 0.38, 0)
	_stem.add_child(_cap)
	var cap_mesh: Mesh = _m75mesh("champi_chapeau", func() -> Mesh: return _lathe71([Vector2(0.17, -0.02), Vector2(0.25, -0.01), Vector2(0.28, 0.02), Vector2(0.27, 0.07), Vector2(0.22, 0.13), Vector2(0.14, 0.18), Vector2(0.05, 0.2), Vector2(0.0, 0.205)], 24, 0.02))
	_mesh(_cap, cap_mesh, _cap_mat, Vector3.ZERO)
	var gill_mesh: Mesh = _m75mesh("champi_lamelles", func() -> Mesh: return _lathe71([Vector2(0.06, 0.03), Vector2(0.18, -0.0), Vector2(0.255, -0.012), Vector2(0.17, -0.02)], 30, 0.07))
	_mesh(_cap, gill_mesh, gill_m, Vector3.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = 75 + (0 if not roi else 1)
	for k in range(9):
		var a: float = rng.randf() * TAU
		var rr: float = rng.randf_range(0.04, 0.24)
		var hy: float = _cap_y(rr) - 0.004
		var nrm := Vector3(sin(a) * rr, 0.25, cos(a) * rr).normalized()
		var sp := _mesh(_cap, _sph75(rng.randf_range(0.022, 0.038), 8), spot_m, Vector3(sin(a) * rr, hy, cos(a) * rr), Vector3(1, 0.3, 1))
		sp.basis = PB._basis_y(nrm) * Basis.from_scale(Vector3(1, 0.3, 1))
	# les petites pattes
	for sx3 in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx3 * 0.06, 0.08, 0)
		_body75.add_child(leg)
		_mesh(leg, _cyl75(0.022, 0.026, 0.07, 8), stem_m, Vector3(0, -0.035, 0))
		_mesh(leg, _sph75(0.035, 8), stem_m, Vector3(0, -0.07, 0.015), Vector3(1.0, 0.55, 1.4))
		_feet75.append([leg, sx3])
	if roi:
		# une couronne de petits champignons, une barbe de mousse
		var crown_c: Array = [CAPS75["orange"], CAPS75["bleu"], CAPS75["orange"], CAPS75["bleu"], CAPS75["orange"]]
		for k2 in range(5):
			var a2: float = TAU * k2 / 5.0
			var mini := Node3D.new()
			mini.position = Vector3(sin(a2) * 0.09, 0.19, cos(a2) * 0.09)
			mini.rotation = Vector3(cos(a2) * 0.35, 0, -sin(a2) * 0.35)
			mini.scale = Vector3.ONE * 0.24
			_cap.add_child(mini)
			_mesh(mini, stem_mesh, stem_m, Vector3(0, -0.06, 0))
			var cm := _mat(crown_c[k2], 0.35, 1.2)
			_mesh(mini, cap_mesh, cm, Vector3(0, 0.33, 0))
		var moss := _skin71("mousse75", 7553, 0.2, [[0.0, Color(0.18, 0.32, 0.12)], [1.0, Color(0.38, 0.55, 0.2)]], 0.95, 8.0, 3.0)
		for sxm in [-1.0, 1.0]:
			_mesh(_stem, _sph75(0.03, 8), moss, Vector3(sxm * 0.03, 0.235, 0.125), Vector3(1.6, 0.6, 0.6), Vector3(0, 0, sxm * -0.35))
		var l := OmniLight3D.new()
		l.light_color = cc
		l.light_energy = 1.2
		l.omni_range = 7.0
		l.position = Vector3(0, 0.55, 0)
		l.shadow_enabled = false
		_body75.add_child(l)
	# quelques spores qui flottent en permanence
	_spore_idle = _spore_emitter(_body75, Vector3(0, 0.45, 0), cc, 0.35 * s, false)
	_spore_idle.amount = 5 if not roi else 14
	_spore_idle.lifetime = 2.5
	_spore_idle.emitting = true


## La hauteur du dessus du chapeau à une distance « r » de l'axe (le profil du tour).
func _cap_y(r: float) -> float:
	var prof: Array = [Vector2(0.0, 0.205), Vector2(0.05, 0.2), Vector2(0.14, 0.18), Vector2(0.22, 0.13), Vector2(0.27, 0.07), Vector2(0.28, 0.02)]
	for i in range(prof.size() - 1):
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		if r >= a.x and r <= b.x:
			return lerpf(a.y, b.y, (r - a.x) / maxf(b.x - a.x, 1e-4))
	return 0.02


func _spore_emitter(parent: Node3D, at: Vector3, c: Color, s: float, burst: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = burst
	p.emitting = burst
	p.amount = 40 if burst else 6
	p.lifetime = 1.6 if burst else 2.5
	p.explosiveness = 0.85 if burst else 0.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.15 * s if burst else 0.3 * s
	p.direction = Vector3(0, 0.3, 1) if burst else Vector3.UP
	p.spread = 60.0 if burst else 30.0
	p.initial_velocity_min = 1.0 * s if burst else 0.05
	p.initial_velocity_max = 2.5 * s if burst else 0.2
	p.damping_min = 1.5
	p.damping_max = 2.5
	p.gravity = Vector3(0, 0.15, 0)
	p.scale_amount_min = 0.6 * maxf(s, 0.4)
	p.scale_amount_max = 1.6 * maxf(s, 0.4)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(1, 2.0 if burst else 1.0))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(c.r, c.g, c.b, 0.75 if burst else 0.9))
	grad.set_color(1, Color(c.lightened(0.3).r, c.lightened(0.3).g, c.lightened(0.3).b, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4) if burst else Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if not burst else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _dot_tex()
	q.material = m
	p.mesh = q
	p.position = at
	parent.add_child(p)
	return p


## Un nuage de spores (au monde) : le joueur dedans éternue.
func _spore_cloud(at: Vector3, radius: float, strength: float) -> void:
	var cc: Color = CAPS75.get(couleur, CAPS75["bleu"])
	var holder := Node3D.new()
	manager.add_child(holder)
	holder.global_position = at
	holder.rotation.y = rotation.y
	var p: CPUParticles3D = _spore_emitter(holder, Vector3.ZERO, cc, radius / 1.6, true)
	p.restart()
	get_tree().create_timer(2.5).timeout.connect(holder.queue_free)
	_sfx71("champignard_pouf", at, -3.0)
	var pp: Vector3 = _player_feet75()
	if Vector2(pp.x - at.x, pp.z - at.z).length() < radius and absf(pp.y - at.y) < 2.2:
		sneeze(manager.main, strength, cc)


## « Atchoum ! » : le joueur éternue (un petit vacillement, il ralentit, l'écran se teinte).
## Aucun dégât. Utilisable par d'autres scripts : Monster75.sneeze(main, 1.0, couleur).
static func sneeze(mn: Node, strength: float, c: Color) -> void:
	if mn == null:
		return
	var now: float = _clock_static()
	if now < _sneeze_until:
		return
	_sneeze_until = now + 1.2 + 0.6 * strength
	var hero: Node = mn.get("hero_v28")
	var pos: Vector3 = mn._player_pos_v27()
	if hero != null:
		if str(hero.state) in ["sol", "attaque", "charge"]:
			hero.state = "action"
			hero.action_time = 0.0
			hero.action_length = 0.6 * strength
			if hero.has_method("_play"):
				hero._play("v28/hurt", 0.05, 0.8, 0.0)
		if float(hero.sol_mult) >= 1.0:
			hero.sol_mult = 0.5
			var tree: SceneTree = mn.get_tree()
			var restore := func() -> void:
				if is_instance_valid(hero) and absf(float(hero.sol_mult) - 0.5) < 0.001:
					hero.sol_mult = 1.0
			tree.create_timer(1.1 * strength).timeout.connect(restore)
	var cb: Node = mn.get("combat_v28")
	if cb != null:
		cb.float_text(pos + Vector3.UP * (0.8 if mn.xr_active else 2.1), "Atchoum !", c.lightened(0.4))
	if mn.has_method("sfx"):
		mn.sfx("eternuement", pos + Vector3.UP * (0.0 if mn.xr_active else 1.5))
	# un voile coloré (PC)
	if not mn.xr_active:
		if _tint_layer == null or not is_instance_valid(_tint_layer):
			_tint_layer = CanvasLayer.new()
			_tint_layer.layer = 24
			mn.add_child(_tint_layer)
			_tint_rect = ColorRect.new()
			_tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_tint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_tint_layer.add_child(_tint_rect)
		_tint_rect.color = Color(c.r, c.g, c.b, 0.3 * clampf(strength, 0.5, 1.5))
		var tw := _tint_rect.create_tween()
		tw.tween_property(_tint_rect, "color:a", 0.0, 1.0 * strength)


func _champi_tick(delta: float) -> void:
	var roi: bool = kind == "champignard_roi"
	var p: Vector3 = _player_feet75()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var from_home := Vector3(home.x - global_position.x, 0, home.z - global_position.z)
	var move := Vector3.ZERO
	var sp: float = float(spec["vitesse"])
	timer -= delta
	_flee_t = maxf(_flee_t - delta, 0.0)
	match state:
		"veille":
			# il gambade autour de chez lui
			if _wander_to == Vector3.ZERO or Vector2(_wander_to.x - global_position.x, _wander_to.z - global_position.z).length() < 0.4 or timer <= -6.0:
				var a: float = randf() * TAU
				_wander_to = home + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, 3.0)
				timer = 0.0
			var tw: Vector3 = _wander_to - global_position
			tw.y = 0.0
			if tw.length() > 0.3:
				move = tw.normalized() * sp * 0.35
				facing = facing.lerp(tw.normalized(), clampf(delta * 4.0, 0.0, 1.0)).normalized()
			if dist < float(spec["vue"]) and dy < 3.0 and _flee_t <= 0.0:
				state = "chasse"
				manager.alert(self)
				_sfx71("champignard_rire", global_position + Vector3.UP * 0.5, -4.0)
		"chasse":
			if dist > float(spec["vue"]) * 1.6 or from_home.length() > float(spec["laisse"]):
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_puffed = false
				_sfx71("champignard_rire", global_position + Vector3.UP * 0.5, -2.0)
			else:
				move = dir_p * sp
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if roi:
				_summon_t -= delta
				if _summon_t <= 0.0:
					_summon_t = 14.0
					var n_near: int = 0
					for m in manager.monsters:
						if is_instance_valid(m) and m.kind == "champignard" and m.state != "mort" and (m as Node3D).global_position.distance_to(global_position) < 14.0:
							n_near += 1
					if n_near < 5:
						for k in range(3):
							var a3: float = TAU * k / 3.0 + randf()
							var at: Vector3 = global_position + Vector3(cos(a3), 0, sin(a3)) * 2.6
							var gy: float = _ground_y71(at, global_position.y + 1.0)
							at.y = (gy if gy > -1e8 else global_position.y) + 0.15
							var m2: Node3D = manager.spawn_extra("champignard", at)
							m2.home = at
						_sfx71("champignard_rire", global_position + Vector3.UP * 2.0, 2.0)
						_hint_once("appel", "Le Roi Champignard tape du pied : « Mes petits ! » Trois champignards sortent de la mousse !")
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.35
				var at2: Vector3 = global_position + facing * (0.5 if not roi else 1.4) + Vector3.UP * (0.4 if not roi else 1.4)
				_spore_cloud(at2, 2.3 if not roi else 4.6, 1.0 if not roi else 2.0)
		"frappe":
			if timer <= 0.0:
				# ravi de sa farce, il détale en riant
				if not roi:
					_start_flee75(randf_range(2.0, 3.5))
				else:
					state = "souffle"
					timer = float(spec["repos"])
		"fuite":
			var away: Vector3 = -dir_p
			if from_home.length() > float(spec["laisse"]) * 0.8:
				away = (away + from_home.normalized()).normalized()
			if is_on_wall():
				away = away.rotated(Vector3.UP, 1.3)
			facing = facing.lerp(away, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			move = facing * sp * 1.25
			if timer <= 0.0:
				state = "veille"
				_flee_t = 2.0
				timer = 0.0
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
	# les champignards avancent par petits bonds
	_hop_t75 += delta * (5.5 if move.length() > 0.1 else 2.0) * (0.7 if roi else 1.0)
	_move75(move, delta)


func _start_flee75(t: float) -> void:
	state = "fuite"
	timer = t
	_sfx71("champignard_rire", global_position + Vector3.UP * 0.5, -2.0)


# =================================================================== chaque image

func is_hittable() -> bool:
	if SPECS75.has(kind):
		return state != "mort"
	return super.is_hittable()


func _physics_process(delta: float) -> void:
	if not SPECS75.has(kind):
		super._physics_process(delta)
		return
	if manager == null:
		return
	_clock += delta
	if _flash > 0.0:
		_flash -= delta
	_apply_flash()
	_bubble75_tick(delta)
	_push_tick(delta)
	if state == "mort":
		_death_tick(delta)
		return
	if not _active75():
		_animate75(delta, 0.0)
		return
	if not _started:
		_started = true
		if state == "chasse":
			manager.alert(self)
	if state == "etourdi":
		timer -= delta
		if timer <= 0.0:
			state = "chasse"
			if _stars != null:
				_stars.visible = false
		elif _stars != null:
			_stars.rotation.y += delta * 4.0
		if kind == "drone_huissier":
			velocity = Vector3.ZERO
			_animate75(delta, 0.0)
		else:
			_move75(Vector3.ZERO, delta)
		return
	if _expr_t > 0.0:
		_expr_t -= delta
		if _expr_t <= 0.0 and _face_mat != null and kind != "drone_huissier":
			_set_face(_rest_face())
	match kind:
		"drone_huissier":
			_drone_tick(delta)
		"pelleteuse_mini", "grande_pelleteuse":
			_digger_tick(delta)
		"champignard", "champignard_roi":
			_champi_tick(delta)
		_:
			if state in ["porte", "arrive"]:
				if state == "porte":
					_carry_tick(delta)
				else:
					_maybe_talk(delta, "robots", global_position.distance_to(_player_feet75()))
					_move75(Vector3.ZERO, delta)
			else:
				_robot_tick(delta)


func _rest_face() -> String:
	match kind:
		"robot_demenageur":
			return "fache" if state in ["armer", "frappe"] else "poli"
		"grande_pelleteuse":
			return "rouge"
	return "fache"


## Les robots au sol (déménageur, soudeur) : veille, chasse, armer, frappe, souffle, recul.
func _robot_tick(delta: float) -> void:
	var p: Vector3 = _player_feet75()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	timer -= delta
	match state:
		"veille":
			if dist < float(spec["vue"]) and dy < 3.0:
				state = "chasse"
				manager.alert(self)
				_sfx71("robot_bip", global_position + Vector3.UP)
			elif from_home > 1.0:
				var back: Vector3 = home - global_position
				back.y = 0.0
				move = back.normalized() * float(spec["vitesse"]) * 0.5
				facing = facing.lerp(back.normalized(), clampf(delta * 4.0, 0.0, 1.0)).normalized()
		"chasse":
			if dist > float(spec["vue"]) * 1.6 or from_home > float(spec["laisse"]) or dy > 3.0:
				state = "veille"
			elif dist <= float(spec["portee"]):
				state = "armer"
				timer = float(spec["armer"])
				_sfx71("robot_servo", global_position + Vector3.UP)
				if kind == "robot_soudeur":
					_sfx71("soudure", global_position + Vector3.UP)
					_sparks.emitting = true
				else:
					_set_face("fache", 1.5)
			else:
				move = dir_p * float(spec["vitesse"])
			facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if kind == "robot_demenageur":
				_maybe_talk(delta, "robots", dist)
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.3
				if kind == "robot_soudeur":
					_fire_arc()
				else:
					_shove(dist, dir_p)
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
				if kind == "robot_soudeur":
					_sparks.emitting = false
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
	_move75(move, delta)


## Le déménageur bouscule (poliment) : un demi-cœur, et on recule.
func _shove(dist: float, dir_p: Vector3) -> void:
	_sfx71("robot_servo", global_position + Vector3.UP, -2.0)
	if dist <= float(spec["portee"]) + 0.4 and facing.dot(dir_p) > 0.4:
		manager.hurt_player(int(spec["degats"]), global_position)
		_push_player(dir_p, 4.5)
		if randf() < 0.5:
			_say75(["Pardon.", "Excusez-moi.", "Veuillez circuler.", "Merci de dégager le passage."][randi() % 4], 1.8)


## Le soudeur : un arc bleu-blanc très court devant lui.
func _fire_arc() -> void:
	if _arc_fx != null:
		_arc_fx.restart()
		_arc_fx.emitting = true
	_sfx71("soudure", global_position + Vector3.UP, 2.0)
	var p: Vector3 = _player_feet75()
	var to: Vector3 = p - global_position
	to.y = 0.0
	if to.length() < float(spec["portee"]) + 0.5 and to.normalized().dot(facing) > 0.6:
		manager.hurt_player(int(spec["degats"]), global_position)


func _move75(move: Vector3, delta: float) -> void:
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	if _tread_v == 0.0:
		_tread_v = Vector2(move.x, move.z).length()
	_animate75(delta, Vector2(move.x, move.z).length())
	_tread_v = 0.0


# =================================================================== coups reçus

func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS75.has(kind):
		super.take_hit(damage, from_pos)
		return
	_take75(damage, from_pos, false)


func _take75(damage: int, from_pos: Vector3, weak: bool) -> void:
	if state == "mort":
		return
	var cb: Node = _m71().get("combat_v28") if _m71() != null else null
	# la Grande Pelleteuse : le blindage arrête tout, sauf godet planté (durites à nu)
	if kind == "grande_pelleteuse" and not weak:
		if vulnerable_t <= 0.0 or state != "coince":
			if cb != null and _clock - _through_t > 1.0:
				_through_t = _clock
				cb.float_text(global_position + Vector3.UP * 4.0, "Clang ! Ça ne lui fait rien", Color(0.85, 0.85, 0.9))
			_sfx71("touche_carapace", global_position + Vector3.UP * 2.0)
			_flash = 0.05
			if _clock - _last_hint > 6.0:
				_hint70("Son blindage arrête tout ! Attends qu'elle plante son godet dans le sol : ses durites seront à nu.")
			return
		damage = int(round(damage * 1.5))
	if kind in CHAMPIS75 and kind == "champignard":
		damage = 1
	hp -= damage
	_flash = 0.18
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	var kb: float = 0.0
	match kind:
		"champignard", "drone_huissier":
			kb = 3.4
		"robot_demenageur", "robot_soudeur":
			kb = 1.2
		"champignard_roi", "pelleteuse_mini":
			kb = 0.3
	if state != "coince":
		_knock = away * kb
	if cb != null:
		var at: Vector3 = global_position + Vector3.UP * (hit_height * 2.0 + 0.3)
		if kind == "grande_pelleteuse":
			at = (_weak.global_position if weak and _weak != null else global_position) + Vector3.UP * 3.0
		if kind == "champignard":
			cb.float_text(at, ["Pouic !", "Hé !", "Aïe-aïe !", "Hihi !"][randi() % 4], CAPS75.get(couleur, Color.WHITE).lightened(0.5))
		elif cb.get("critical") == true:
			cb.damage_number_color(at, damage, Color(1.0, 0.55, 0.2), " !")
		else:
			cb.damage_number(at, damage)
		cb.puff(global_position + Vector3.UP * hit_height, _puff_color())
	if kind in ROBOTS75:
		_sfx71("touche_carapace", global_position + Vector3.UP * hit_height, -4.0)
	_phase_check()
	if hp <= 0:
		_die63()
		return
	match kind:
		"robot_demenageur":
			if state in ["porte", "arrive"]:
				# touché pendant le déménagement : il lâche tout et se défend
				lacher()
				state = "chasse"
				arrive = false
				_set_face("fache", 2.0)
				_say75(["Ceci est une agression de mobilier !", "Vous froissez le carton !", "Je vais devoir vous signaler."][randi() % 3], 2.2)
				manager.alert(self)
				return
			state = "recul"
			timer = 0.25
		"robot_soudeur":
			if state != "frappe":
				state = "recul"
				timer = 0.25
				if _sparks != null:
					_sparks.emitting = false
		"drone_huissier":
			state = "etourdi"
			timer = 0.5
		"champignard":
			_start_flee75(randf_range(2.5, 4.0))
		"champignard_roi":
			_sfx71("champignard_rire", global_position + Vector3.UP * 2.0, -2.0)
		"pelleteuse_mini":
			pass


func _die63() -> void:
	if not SPECS75.has(kind):
		super._die63()
		return
	if porteur or _load != null:
		lacher()
	_circle_off()
	if _weak != null and is_instance_valid(_weak):
		_weak.remove_from_group("cibles_v28")
	super._die63()
	_tread_v = 0.0
	if _face_mat != null and kind != "drone_huissier":
		_face_expr = ""
		_set_face("mort", 99.0)
	if kind in ROBOTS75:
		_fall_apart()
	else:
		_pouf()
	if _bubble75 != null:
		_bubble75.visible = false
	if kind == "grande_pelleteuse":
		for i in range(_hoses.size()):
			_burst_hose(i)
		_say75("ERREUR… ERREUR… OPTIMISATION… IMPOSSIBLE…", 4.0)
	if kind == "drone_huissier":
		_vy = 0.0
		_bounces = 0


func _circle_off() -> void:
	if _circle != null:
		_circle.visible = false


## Un robot se démonte : boulons et ressorts qui volent, un petit nuage de fumée.
func _fall_apart() -> void:
	var s: float = {"robot_demenageur": 1.0, "drone_huissier": 0.5, "robot_soudeur": 1.0, "pelleteuse_mini": 2.0, "grande_pelleteuse": 5.0}.get(kind, 1.0)
	var at: Vector3 = global_position + Vector3.UP * hit_height
	var bolt_mesh: Mesh = _cyl75(0.018, 0.018, 0.06, 6)
	if not _m75.has("ressort"):
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		for i in range(64):
			var a: float = TAU * 5.0 * float(i) / 63.0
			pts.append(Vector3(cos(a) * 0.035, -0.06 + 0.12 * float(i) / 63.0, sin(a) * 0.035))
			radii.append(0.006)
		_m75["ressort"] = PB.tube_mesh(pts, radii, 5, 0.0, 0.0, Color(1, 1, 1), Color(1, 1, 1))
	var spring_mesh: Mesh = _m75["ressort"]
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.7, 0.7, 0.72)
	metal.metallic = 1.0
	metal.roughness = 0.3
	for what in [[bolt_mesh, int(8 * minf(s, 3.0))], [spring_mesh, int(4 * minf(s, 3.0))]]:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = true
		p.amount = maxi(int(what[1]), 2)
		p.lifetime = 1.6
		p.explosiveness = 0.95
		p.local_coords = false
		p.direction = Vector3.UP
		p.spread = 75.0
		p.initial_velocity_min = 2.0 * sqrt(s)
		p.initial_velocity_max = 4.5 * sqrt(s)
		p.gravity = Vector3(0, -12.0, 0)
		p.angular_velocity_min = -600.0
		p.angular_velocity_max = 600.0
		p.particle_flag_rotate_y = true
		p.scale_amount_min = 0.8 * minf(s, 2.5)
		p.scale_amount_max = 1.4 * minf(s, 2.5)
		p.mesh = what[0]
		p.material_override = metal
		manager.add_child(p)
		p.global_position = at
		get_tree().create_timer(2.2).timeout.connect(p.queue_free)
	var smoke := _smoke_emitter(manager, Vector3.ZERO, 1.2 * sqrt(s), Color(0.42, 0.42, 0.44, 0.6))
	smoke.global_position = at
	smoke.one_shot = true
	smoke.amount = 14
	smoke.explosiveness = 0.7
	smoke.emitting = true
	get_tree().create_timer(2.5).timeout.connect(smoke.queue_free)
	if _sparks != null:
		_sparks.emitting = false
	if _arc_light != null:
		_arc_light.light_energy = 0.0
	if _exhaust != null:
		_exhaust.emitting = false


## Un champignard fait « pouf » : un nuage de spores, et il n'y a plus personne.
func _pouf() -> void:
	var cc: Color = CAPS75.get(couleur, CAPS75["bleu"])
	var s: float = 1.0 if kind == "champignard" else 3.0
	var holder := Node3D.new()
	manager.add_child(holder)
	holder.global_position = global_position + Vector3.UP * 0.4 * s
	var p: CPUParticles3D = _spore_emitter(holder, Vector3.ZERO, cc, 0.8 * s, true)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.restart()
	get_tree().create_timer(2.5).timeout.connect(holder.queue_free)
	if _spore_idle != null:
		_spore_idle.emitting = false


func _death_tick(delta: float) -> void:
	if not SPECS75.has(kind):
		super._death_tick(delta)
		return
	timer += delta
	var end_t: float = 2.6
	match kind:
		"robot_demenageur":
			# la tête saute sur son ressort, les bras tombent, il s'affaisse
			if _head75 != null:
				var k: float = clampf(timer / 0.25, 0.0, 1.0)
				_head75.position.y = 1.25 + sin(minf(timer * 9.0, PI)) * 0.45 * (1.0 if timer < 0.35 else 0.0) + (0.0 if timer < 0.35 else maxf(0.3 - (timer - 0.35) * 0.6, 0.0)) * k
				_head75.rotation.z = minf(timer * 1.4, 0.6)
			for a in _arms75:
				(a[0] as Node3D).rotation.x = lerpf((a[0] as Node3D).rotation.x, 0.25, clampf(delta * 6.0, 0.0, 1.0))
				(a[0] as Node3D).rotation.z = lerpf((a[0] as Node3D).rotation.z, float(a[2]) * 0.6, clampf(delta * 6.0, 0.0, 1.0))
			if _body75 != null:
				_body75.rotation.x = minf(timer * 0.6, 0.22)
				_body75.position.y = -minf(timer * 0.2, 0.12)
		"drone_huissier":
			# il tombe, rebondit deux fois
			_vy -= 14.0 * delta
			var gy: float = _ground_y71(global_position, global_position.y)
			if gy < -1e8:
				gy = home.y
			var ny: float = global_position.y + _vy * delta
			if ny < gy + 0.1:
				ny = gy + 0.1
				if _bounces < 2 and absf(_vy) > 1.5:
					_vy = -_vy * 0.35
					_bounces += 1
					_sfx71("touche_carapace", global_position, -6.0)
				else:
					_vy = 0.0
			global_position.y = ny
			_visual.rotation.z = minf(timer * 3.0, 2.6)
		"robot_soudeur":
			if _arms75.size() > 0:
				(_arms75[0][0] as Node3D).rotation.x = lerpf((_arms75[0][0] as Node3D).rotation.x, 1.4, clampf(delta * 2.0, 0.0, 1.0))
		"pelleteuse_mini", "grande_pelleteuse":
			_arm_goal = Vector3(0.45, 1.6, 1.4)
			_apply_arm(clampf(delta * 1.5, 0.0, 1.0))
			_house_yaw = lerpf(_house_yaw, 0.25, clampf(delta, 0.0, 1.0))
			if _house != null:
				_house.rotation.y = _house_yaw
			_update_pistons()
			end_t = 4.0 if kind == "pelleteuse_mini" else 7.0
		"champignard", "champignard_roi":
			var k2: float = clampf(timer / 0.3, 0.0, 1.0)
			_visual.scale = Vector3.ONE * (1.0 + sin(k2 * PI) * 0.4) * (1.0 - k2 * 0.99)
			_visual.rotation.y += delta * 12.0
			end_t = 0.35
	if timer > end_t - 0.7 and not (kind in CHAMPIS75):
		_visual.scale = Vector3.ONE * clampf(1.0 - (timer - (end_t - 0.7)) / 0.7, 0.01, 1.0)
	if timer > end_t:
		visible = false
		set_physics_process(false)


# =================================================================== animation

func _animate63(delta: float, speed: float) -> void:
	if not SPECS75.has(kind):
		super._animate63(delta, speed)
		return
	_animate75(delta, speed)


func _animate75(delta: float, speed: float) -> void:
	# les chenilles défilent
	if not _tread_mats.is_empty():
		var v: float = _tread_v if absf(_tread_v) > 0.01 else speed
		var s: float = 3.0 if kind == "grande_pelleteuse" else 1.0
		for tm in _tread_mats:
			(tm as StandardMaterial3D).uv1_offset.x -= v * delta / (0.5 * s)
		if speed > 0.2:
			_snd_t -= delta
			if _snd_t <= 0.0 and kind != "drone_huissier":
				_snd_t = 1.6 if kind != "grande_pelleteuse" else 1.1
				_sfx71("robot_pas", global_position + Vector3.UP * 0.4, -6.0 if kind != "grande_pelleteuse" else 0.0)
	if _beacon != null:
		_beacon.emission_energy_multiplier = 0.4 + 3.0 * maxf(0.0, sin(_clock * 5.0))
	match kind:
		"robot_demenageur":
			_anim_demenageur(delta, speed)
		"drone_huissier":
			for i in range(_rotors.size()):
				(_rotors[i] as Node3D).rotation.y += delta * (55.0 if state != "mort" else maxf(0.0, 55.0 - timer * 40.0)) * (1.0 if i % 2 == 0 else -1.0)
			if _body75 != null and state != "mort":
				_body75.rotation.x = lerpf(_body75.rotation.x, (0.35 if state == "frappe" else clampf(speed * 0.05, 0.0, 0.2)), clampf(delta * 6.0, 0.0, 1.0))
				_body75.position.y = sin(_clock * 3.1) * 0.03
			if _paper != null:
				_paper.rotation.x = sin(_clock * 7.0) * 0.18 + clampf(speed * 0.06, 0.0, 0.5)
				_paper.rotation.z = sin(_clock * 5.3) * 0.12
			if _face_mat != null:
				var fast: bool = state == "armer" or state == "frappe"
				_face_mat.emission_energy_multiplier = 0.3 + 5.0 * (1.0 if fmod(_clock * (8.0 if fast else 1.5), 1.0) < 0.3 else 0.0)
		"robot_soudeur":
			_anim_soudeur(delta, speed)
		"pelleteuse_mini", "grande_pelleteuse":
			if _house != null:
				_house.rotation.y = _house_yaw
			_update_pistons()
			if kind == "grande_pelleteuse":
				for h in _hose_mats:
					var hm: StandardMaterial3D = h
					if hm.emission_enabled and _flash <= 0.0:
						hm.emission_energy_multiplier = (4.0 + 3.0 * sin(_clock * 14.0)) if state == "coince" else (0.8 + 0.25 * sin(_clock * 2.0))
		"champignard", "champignard_roi":
			_anim_champi(delta, speed)


func _anim_demenageur(delta: float, speed: float) -> void:
	var k: float = clampf(delta * 8.0, 0.0, 1.0)
	var carry: bool = _load != null
	var shove: float = 0.0
	if state == "armer":
		shove = -0.6 * (1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0))
	elif state == "frappe":
		shove = 0.9
	for a in _arms75:
		var sh: Node3D = a[0]
		var el: Node3D = a[1]
		var side: float = float(a[2])
		var gx: float = -0.15 + sin(_clock * 2.0 + side) * 0.05
		var gel: float = 0.25
		var gz: float = side * 0.08
		if carry:
			gx = -0.55
			gel = 0.55
			gz = side * 0.05
		elif state == "armer" or state == "frappe":
			gx = -0.9 - shove * 0.4
			gel = -0.1 + shove * 0.2
			gz = side * 0.05
		elif _bubble75 != null and _bubble75.visible:
			# il « parle avec les mains »
			gx = -0.35 + sin(_clock * 4.0 + side * 1.7) * 0.2
			gel = 0.6 + sin(_clock * 5.0) * 0.2
		sh.rotation.x = lerpf(sh.rotation.x, gx, k)
		sh.rotation.z = lerpf(sh.rotation.z, gz, k)
		if el != null:
			el.rotation.x = lerpf(el.rotation.x, gel, k)
	if _body75 != null:
		var lean: float = shove * 0.12 + clampf(speed * 0.02, 0.0, 0.06)
		_body75.rotation.x = lerpf(_body75.rotation.x, lean, k)
		_body75.position.y = sin(_clock * 17.0) * 0.006 * clampf(speed, 0.0, 1.0)
	if _head75 != null:
		var tilt: float = 0.0
		if _bubble75 != null and _bubble75.visible:
			tilt = sin(_clock * 2.5) * 0.12
		_head75.rotation.z = lerpf(_head75.rotation.z, tilt, k)
		_head75.rotation.x = lerpf(_head75.rotation.x, (-0.1 if carry else 0.0), k)
	if _steam75 != null:
		_steam75.emitting = carry or state == "armer"


func _anim_soudeur(delta: float, speed: float) -> void:
	var k: float = clampf(delta * 6.0, 0.0, 1.0)
	var weld: bool = state == "armer" or state == "frappe"
	if _turret != null:
		_turret.rotation.y = lerpf(_turret.rotation.y, sin(_clock * 0.6) * 0.3 if not weld and state == "veille" else 0.0, k)
	if _arms75.size() >= 2:
		var sh: Node3D = _arms75[0][0]
		var el: Node3D = _arms75[0][1]
		var wr: Node3D = _arms75[1][0]
		var gs: float = -0.2 + sin(_clock * 1.1) * 0.08
		var ge: float = 0.6
		var gw: float = 0.2
		if weld:
			gs = -0.45 + sin(_clock * 13.0) * 0.03
			ge = 1.05
			gw = 0.05 + sin(_clock * 9.0) * 0.06
		sh.rotation.x = lerpf(sh.rotation.x, gs, k)
		el.rotation.x = lerpf(el.rotation.x, ge, k)
		wr.rotation.x = lerpf(wr.rotation.x, gw, k)
	var on: bool = weld
	if _arc_mesh != null:
		_arc_mesh.visible = on
		_arc_mesh.scale = Vector3.ONE * (0.7 + randf() * 0.8)
	if _arc_light != null:
		_arc_light.light_energy = (1.5 + randf() * 1.5) if on else 0.0
	if _sparks != null:
		_sparks.emitting = on


func _anim_champi(delta: float, speed: float) -> void:
	var roi: bool = kind == "champignard_roi"
	var moving: bool = speed > 0.1
	var hop: float = absf(sin(_hop_t75 * PI)) if moving else 0.0
	var crouch: float = 0.0
	if state == "armer":
		crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	elif state == "frappe":
		crouch = -0.6
	if _body75 != null:
		var s: float = 1.0 if not roi else 3.4
		_body75.position.y = hop * 0.12 * s
		var sq: float = 1.0 - (1.0 - hop) * 0.08 * (1.0 if moving else 0.0) - crouch * 0.12
		_body75.scale = Vector3(s * (2.0 - sq), s * sq, s * (2.0 - sq))
		_body75.rotation.z = sin(_clock * 2.3) * 0.05 + (sin(_hop_t75 * PI) * 0.12 if moving else 0.0)
	if _cap != null:
		# le chapeau se gonfle avant le « pfff » des spores
		var inflate: float = 1.0 + maxf(crouch, 0.0) * 0.28 + (sin(_clock * 3.0) * 0.02)
		_cap.scale = Vector3(inflate, 1.0 + maxf(crouch, 0.0) * 0.15, inflate)
		_cap.rotation.x = lerpf(_cap.rotation.x, (-0.25 * maxf(crouch, 0.0)) + (0.25 if state == "fuite" else 0.0), clampf(delta * 8.0, 0.0, 1.0))
	if _cap_mat != null and _flash <= 0.0:
		_cap_mat.emission_energy_multiplier = 0.45 + 0.15 * sin(_clock * 2.0) + maxf(crouch, 0.0) * 1.5
	if _mouth75 != null:
		var open: float = 0.35
		if state == "armer":
			open = 0.35 + crouch * 0.5
		elif state == "frappe":
			open = 1.1
		elif state == "fuite":
			open = 0.8 + sin(_clock * 18.0) * 0.3
		_mouth75.scale = Vector3(1.3, open, 0.5)
	for f in _feet75:
		var leg: Node3D = f[0]
		var side: float = float(f[1])
		leg.rotation.x = sin(_hop_t75 * PI * 2.0 + (0.0 if side > 0 else PI)) * (0.7 if moving else 0.0)


# =================================================================== butin, conseils

func _puff_color() -> Color:
	match kind:
		"champignard", "champignard_roi":
			return CAPS75.get(couleur, CAPS75["bleu"])
		"robot_demenageur", "robot_soudeur", "drone_huissier", "pelleteuse_mini", "grande_pelleteuse":
			return Color(0.75, 0.75, 0.78)
	return super._puff_color()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS75.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"robot_demenageur":
			g.append(["piece", rng.randi_range(1, 4)])
			if rng.randf() < 0.75:
				g.append(["boulon", rng.randi_range(1, 2)])
			if rng.randf() < 0.4:
				g.append(["ressort", 1])
		"drone_huissier":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.5:
				g.append(["boulon", 1])
			if rng.randf() < 0.25:
				g.append(["ressort", 1])
		"robot_soudeur":
			g.append(["piece", rng.randi_range(2, 5)])
			g.append(["boulon", rng.randi_range(1, 2)])
			if rng.randf() < 0.5:
				g.append(["ressort", 1])
		"pelleteuse_mini":
			g.append(["piece", rng.randi_range(15, 25)])
			g.append(["boulon", 3])
			g.append(["ressort", 2])
			if rng.randf() < 0.35:
				g.append(["piece_or", 1])
		"grande_pelleteuse":
			g.append(["piece", rng.randi_range(70, 100)])
			g.append(["piece_or", 3])
			g.append(["boulon", 5])
			g.append(["ressort", 3])
		"champignard":
			if rng.randf() < 0.2:
				g.append(["piece", rng.randi_range(1, 2)])
			if rng.randf() < 0.08:
				g.append([["champi_ressort", "champi_babil", "champi_arcenciel"][rng.randi() % 3], 1])
		"champignard_roi":
			g.append(["champi_geant", 1])
			g.append(["piece", rng.randi_range(15, 25)])
			if rng.randf() < 0.5:
				g.append([["champi_ressort", "champi_babil", "champi_arcenciel"][rng.randi() % 3], 1])
	for e in get_meta("butin_extra", []):
		g.append(e)
	return g


func alert_text() -> String:
	match kind:
		"robot_demenageur":
			return "Un robot déménageur de Lisse & Fils ! Très poli… et très lourd. Quand il lève ses pinces, il va te bousculer : écarte-toi, puis frappe. Il se démonte en boulons et en ressorts."
		"drone_huissier":
			return "Un drone-huissier ! Il tourne au-dessus de toi en lisant ses avis… puis il pique pour une décharge. Esquive son plongeon : il reste bas, essoufflé, un instant. C'est le moment de le frapper !"
		"robot_soudeur":
			return "Un robot soudeur ! Son arc bleu ne porte pas loin : reste hors de portée quand les étincelles jaillissent, puis frappe-le pendant qu'il refroidit."
		"pelleteuse_mini":
			return "UNE MINI-PELLETEUSE ! Quand son godet se lève, un cercle rouge marque l'endroit où il va s'abattre : sors du cercle ! Et attention à ses balayages."
		"grande_pelleteuse":
			return "LA GRANDE PELLETEUSE ! Neuf mètres d'acier, pilotés par OPTIMUS-LISSE. Ton épée rebondit sur son blindage… Évite le godet (le cercle rouge), puis frappe les DURITES qui luisent quand il reste planté dans le sol !"
		"champignard":
			return "Un champignard ! Une petite créature champignon farceuse. Son nuage de spores ne fait pas mal… mais il fait éternuer. Une petite tape, il détale ; deux, et pouf !"
		"champignard_roi":
			return "LE ROI CHAMPIGNARD ! Une couronne de champignons, et un nuage de spores grand comme une maison. Il n'est pas méchant… mais tu vas éternuer ! Garde tes distances quand son chapeau gonfle."
	return super.alert_text()


func _exit_tree() -> void:
	if SPECS75.has(kind):
		if _circle != null and is_instance_valid(_circle):
			_circle.visible = false
	super._exit_tree()

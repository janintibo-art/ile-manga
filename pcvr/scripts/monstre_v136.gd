extends "res://scripts/monstre_v135.gd"
## V136 : la faune sauvage de trois îles du nord : l'Île aux Moaïs, l'Île de la Balafre et l'Île de
## Larsen. (Les bêtes des V132 à V135 passent toujours par leurs fichiers : on ne fait ici que les
## nouvelles.) Des caractères nouveaux :
##  - troupeau (chevaux sauvages des Moaïs) : ils broutent ensemble ; quand on approche, ils lèvent
##    la tête… et tout le troupeau part au galop. Celui qu'on frappe par derrière rue des deux
##    postérieurs ; frappé de face, il se cabre, puis s'enfuit ;
##  - pêcheur (frégate) : elle plane très haut au-dessus des Moaïs, puis plonge raser la mer et
##    remonte un poisson au bec ;
##  - carapace (tortue verte, la nuit) : elle monte sur la plage, creuse son nid, puis redescend à la
##    mer. Dérangée, elle se fige et retourne à l'eau ; un coup ne lui fait rien (toc !) ;
##  - bavard (ara rouge de la Balafre) : la petite bande tourne autour du héros en criant des mots
##    de pirate, puis file plus loin ;
##  - fouetteur (varan) : il mord devant, et fouette de la queue si l'on passe sur son flanc ou
##    derrière lui ; il tourne lentement ;
##  - terrier (lapin de garenne) : il se dresse, détale en zigzag… et plonge dans son terrier ; il
##    ressort plus loin quand on est parti ;
##  - frelons (essaim) : ils poursuivent le héros et piquent ; on les sème en courant loin de leur
##    coin, ou en plongeant dans l'eau ;
##  - boule (hérisson, la nuit) : il se roule en boule quand on approche ; le frapper en boule,
##    ça pique !
##  - veilleur (hibou grand-duc, la nuit) : posé au sol, il suit le héros des yeux en tournant la
##    tête ; si l'on approche, il s'envole sans un bruit et se pose plus loin.
## Et des cousins : le crabe de cocotier (il pince ; sa carapace est très dure devant : il faut le
## frapper par derrière) et le renard roux (un chapardeur, comme le coati).

const SPECS136 := {
	"cheval_sauvage": {"pv": 26, "vitesse": 2.0, "degats": 2, "portee": 2.3, "armer": 0.35, "repos": 1.0, "vue": 6.5, "laisse": 80.0,
		"rayon": 0.75, "haut": 1.2, "nom": "Cheval sauvage", "genre": "troupeau", "paisible": true, "col": ["boite", Vector3(0.6, 1.45, 1.8)]},
	"fregate": {"pv": 6, "vitesse": 8.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 0.0, "laisse": 200.0,
		"rayon": 0.6, "haut": 0.0, "nom": "Frégate", "genre": "pecheur", "vol": true, "col": ["boule", 0.5, 0.0]},
	"tortue_verte": {"pv": 99, "vitesse": 0.9, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 3.2, "laisse": 60.0,
		"rayon": 0.65, "haut": 0.35, "nom": "Tortue verte", "genre": "carapace", "col": ["boite", Vector3(0.85, 0.4, 1.05)]},
	"perroquet": {"pv": 99, "vitesse": 6.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 9.0, "laisse": 80.0,
		"rayon": 0.4, "haut": 0.0, "nom": "Ara rouge", "genre": "bavard", "vol": true, "col": ["boule", 0.3, 0.0]},
	"varan": {"pv": 24, "vitesse": 2.6, "degats": 2, "portee": 1.7, "armer": 0.5, "repos": 1.3, "vue": 9.0, "laisse": 26.0,
		"rayon": 0.6, "haut": 0.3, "nom": "Varan", "genre": "fouetteur", "col": ["boite", Vector3(0.55, 0.4, 1.3)]},
	"crabe_cocotier": {"pv": 18, "vitesse": 1.7, "degats": 2, "portee": 1.4, "armer": 0.6, "repos": 1.5, "vue": 8.0, "laisse": 20.0,
		"rayon": 0.6, "haut": 0.3, "nom": "Crabe de cocotier", "genre": "pinceur", "blinde": true, "col": ["boite", Vector3(0.8, 0.45, 0.8)]},
	"lapin_garenne": {"pv": 3, "vitesse": 4.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 7.0, "laisse": 40.0,
		"rayon": 0.3, "haut": 0.18, "nom": "Lapin de garenne", "genre": "terrier", "col": ["boite", Vector3(0.24, 0.28, 0.4)]},
	"frelon": {"pv": 6, "vitesse": 4.0, "degats": 1, "portee": 1.8, "armer": 1.2, "repos": 1.0, "vue": 6.5, "laisse": 30.0,
		"rayon": 0.8, "haut": 0.0, "nom": "Frelons", "genre": "frelons", "vol": true, "col": ["boule", 0.6, 0.0]},
	"herisson": {"pv": 99, "vitesse": 0.8, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 2.6, "laisse": 30.0,
		"rayon": 0.3, "haut": 0.12, "nom": "Hérisson", "genre": "boule", "col": ["boule", 0.14, 0.14]},
	"hibou_grand_duc": {"pv": 6, "vitesse": 6.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 5.5, "laisse": 80.0,
		"rayon": 0.4, "haut": 0.35, "nom": "Hibou grand-duc", "genre": "veilleur", "col": ["boule", 0.22, 0.3]},
	"renard_roux": {"pv": 99, "vitesse": 4.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 13.0, "laisse": 40.0,
		"rayon": 0.4, "haut": 0.35, "nom": "Renard roux", "genre": "chapardeur", "col": ["boite", Vector3(0.35, 0.5, 0.9)]},
}
const SOUNDS136 := {
	"cheval_sauvage": ["cheval_hennit", "cheval_hennit"], "fregate": ["fregate_claque", "fregate_claque"],
	"tortue_verte": ["tortue_souffle", "tortue_souffle"], "perroquet": ["perroquet", "perroquet"],
	"varan": ["varan_siffle", "varan_siffle"], "crabe_cocotier": ["crabe_menace", "crabe_mort"],
	"lapin_garenne": ["lapin_tape", "lapin_tape"], "frelon": ["frelon_bourdonne", "insecte_mort"],
	"herisson": ["herisson_renifle", "herisson_renifle"], "hibou_grand_duc": ["hibou_hulule", "hibou_hulule"],
	"renard_roux": ["renard_glapit", "renard_glapit"],
}
const ALERTES136 := {
	"cheval_sauvage": "Un cheval sauvage ! Il ne t'attaque pas… mais ne passe jamais derrière lui : s'il prend peur, il rue des deux pattes arrière.",
	"varan": "Un varan ! Il mord devant et fouette de la queue sur les côtés et derrière : reste face à lui, recule quand il ouvre la gueule, puis frappe.",
	"crabe_cocotier": "Un crabe de cocotier ! Sa carapace est très dure devant : tourne autour de lui et frappe-le par derrière.",
	"frelon": "Des frelons ! Ils te poursuivent et piquent : cours loin de leur coin, ou plonge dans l'eau pour les semer. Chaque coup en chasse quelques-uns.",
}
const GENRES136 := ["troupeau", "pecheur", "carapace", "bavard", "fouetteur", "terrier", "frelons", "boule", "veilleur"]
## Ce que crient les aras de la Balafre (ils ont grandi chez les pirates).
const PAROLES := ["Coco veut un biscuit !", "À l'abordage !", "Mille sabords !", "Pièces d'or ! Pièces d'or !",
	"Hissez les voiles !", "Coco a faim !", "Terre en vue !"]

static var _tex136: Dictionary = {}
static var _parole_ms: int = -100000

var robe: String = ""                    # cheval : bai, alezan, gris, noir
var _cible: Vector3 = Vector3.INF         # là où l'on vole (frégate, ara, hibou)
var _fuite_dir: Vector3 = Vector3.ZERO    # cheval au galop, tortue qui redescend
var _cd136: float = 0.0
var _poisson: Node3D                      # frégate : le poisson au bec
var _sting_t: float = 0.0
var _frelons: Array = []                  # [nœud, phase, rayon, hauteur, vitesse, ailes]
var _ball: float = 0.0                    # hérisson : 0 déroulé, 1 en boule
var _calme: float = 0.0
var _head_yaw: float = 0.0
var _fl_from: Vector3 = Vector3.ZERO
var _fl_u: float = 0.0
var _fl_dur: float = 1.0
var _hoot_t: float = 4.0
var _kick: float = 0.0
var _dig_t: float = 0.0
var _down: float = 0.0                    # lapin dans son terrier, tortue sous l'eau
var _fige_fait: bool = false
var _tongue_t: float = 1.0
var _tongue_u: float = 0.0
var _herd_t: float = 0.0
var _whip_side: float = 1.0
var _unfold: float = 0.0
# tests
var kicks: int = 0
var peches: int = 0
var tocs: int = 0
var paroles: int = 0
var whips: int = 0
var terriers: int = 0
var stings: int = 0
var piques: int = 0
var envols: int = 0
var sorties: int = 0


static func spec_of(k: String) -> Dictionary:
	if SPECS136.has(k):
		return SPECS136[k]
	if SPECS135.has(k):
		return SPECS135[k]
	if SPECS133.has(k):
		return SPECS133[k]
	return SPECS132.get(k, {})


static func has_kind(k: String) -> bool:
	return SPECS136.has(k) or SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS136.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS136[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = int(spec["degats"]) == 0 or bool(spec.get("paisible", false))
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	collision_layer = 0 if (vol or k == "hibou_grand_duc") else 1
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
		"cheval_sauvage":
			_build_cheval()
		"fregate":
			_build_fregate()
		"tortue_verte":
			_build_tortue()
		"perroquet":
			_build_perroquet()
		"varan":
			_build_varan()
		"crabe_cocotier":
			_build_crabe_cocotier()
		"lapin_garenne":
			_build_lapin()
		"frelon":
			_build_frelons()
		"herisson":
			_build_herisson()
		"hibou_grand_duc":
			_build_hibou()
		"renard_roux":
			_build_renard()
	add_to_group("cibles_v28")
	add_to_group("faune_v132")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if facing.length() < 0.5:
		facing = Vector3.FORWARD
	_flank = randf_range(-1.0, 1.0)
	_wander_t = randf_range(0.5, 3.0)
	if vol:
		_orbit_c = Vector3(at.x, 0.0, at.z)
		_orbit_a = randf() * TAU
		state = "vol"
		match k:
			"fregate":
				_alt = randf_range(16.0, 22.0)
				_cd136 = randf_range(3.0, 7.0)
			"perroquet":
				_alt = randf_range(3.0, 4.5)
				_cd136 = randf_range(0.0, 1.5)
			_:
				_alt = randf_range(1.1, 1.5)
	elif k == "hibou_grand_duc":
		state = "perche"
		_hoot_t = randf_range(1.5, 5.0)
	elif k == "tortue_verte":
		state = "monte"
		timer = randf_range(5.0, 9.0)
	else:
		state = "erre"
	_base_scale = _visual.scale


# =================================================================== textures

## La carapace de la tortue verte, vue de dessus (x de -0,42 à 0,42, z de -0,52 à 0,52) : les
## écailles du dos (vertébrales, costales, marginales), brun olive, rayées de fauve depuis leur
## centre, les sutures sombres entre elles.
func _carapace_tex() -> Texture2D:
	if _tex136.has("carapace"):
		return _tex136["carapace"]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1361
	var centres: Array = []
	for z in [0.36, 0.17, -0.02, -0.21, -0.38]:
		centres.append(Vector2(0.0, z))
	for sx in [-1.0, 1.0]:
		for z in [0.27, 0.08, -0.12, -0.3]:
			centres.append(Vector2(sx * 0.24, z))
	var fonce := Color(0.2, 0.15, 0.08)
	var fauve := Color(0.52, 0.43, 0.2)
	var olive := Color(0.27, 0.26, 0.12)
	for py in range(n):
		for px in range(n):
			# la texture est posée en triplan : u = x * 0,9 + 0,5, v = z * 0,9 + 0,5
			var x: float = (float(px) / n - 0.5) / 0.9
			var z: float = (float(py) / n - 0.5) / 0.9
			var rho: float = sqrt(pow(x / 0.42, 2.0) + pow(z / 0.52, 2.0))
			var c: Color
			if rho > 0.86:
				# les marginales : une bordure plus claire, coupée de sutures
				var a: float = atan2(z / 0.52, x / 0.42)
				var seg: float = fmod(a / TAU * 24.0 + 24.0, 1.0)
				c = olive.lerp(fauve, 0.45 + 0.2 * sin(a * 7.0))
				if seg < 0.07 or absf(rho - 0.86) < 0.025:
					c = fonce
			else:
				var d1: float = 9.0
				var d2: float = 9.0
				var best: Vector2 = Vector2.ZERO
				for ce in centres:
					var cv: Vector2 = ce
					var dd: float = Vector2((x - cv.x) * 0.9, z - cv.y).length()
					if dd < d1:
						d2 = d1
						d1 = dd
						best = cv
					elif dd < d2:
						d2 = dd
				var ang: float = atan2(z - best.y, x - best.x)
				var ray: float = 0.5 + 0.5 * sin(ang * 9.0 + sin(ang * 3.0 + best.x * 20.0) * 1.5)
				c = olive.lerp(fauve, ray * smoothstep(0.01, 0.1, d1) * 0.85)
				c = c.lerp(fonce, (1.0 - ray) * 0.35)
				if d2 - d1 < 0.016:
					c = fonce
			var v: float = 1.0 + rng.randf_range(-0.06, 0.06)
			img.set_pixel(px, py, Color(c.r * v, c.g * v, c.b * v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex136["carapace"] = t
	return t


## Des écailles (la peau des tortues de mer) : de petites plaques brunes aux bords pâles, en mosaïque
## (cellules de Voronoï sur une grille, la texture se répète sans couture).
func _ecailles_tex() -> Texture2D:
	if _tex136.has("ecailles"):
		return _tex136["ecailles"]
	var n: int = 128
	var g: int = 9
	var rng := RandomNumberGenerator.new()
	rng.seed = 1362
	var pts: Array = []
	for j in range(g):
		var row: Array = []
		for i in range(g):
			row.append(Vector2((float(i) + rng.randf_range(0.15, 0.85)) * n / g, (float(j) + rng.randf_range(0.15, 0.85)) * n / g))
		pts.append(row)
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var cell: float = float(n) / g
	for py in range(n):
		for px in range(n):
			var gi: int = int(px / cell)
			var gj: int = int(py / cell)
			var d1: float = 1e9
			var d2: float = 1e9
			var tint: float = 0.0
			for oj in range(-1, 2):
				for oi in range(-1, 2):
					var ii: int = posmod(gi + oi, g)
					var jj: int = posmod(gj + oj, g)
					var q: Vector2 = pts[jj][ii]
					q += Vector2(float(gi + oi - ii) * cell, float(gj + oj - jj) * cell)
					var dd: float = q.distance_to(Vector2(px, py))
					if dd < d1:
						d2 = d1
						d1 = dd
						tint = fmod(float(ii * 7 + jj * 13), 5.0) / 5.0
					elif dd < d2:
						d2 = dd
			var c := Color(0.27, 0.22, 0.13).lerp(Color(0.36, 0.29, 0.15), tint)
			if d2 - d1 < 1.6:
				c = Color(0.74, 0.68, 0.48)
			elif d2 - d1 < 2.8:
				c = c.lerp(Color(0.6, 0.54, 0.36), 0.5)
			img.set_pixel(px, py, c)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex136["ecailles"] = t
	return t


## La peau du varan : gris-noir, semée de rangées de taches jaune pâle (des ocelles) et de
## petits points.
func _varan_tex() -> Texture2D:
	if _tex136.has("varan"):
		return _tex136["varan"]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1363
	for y in range(n):
		for x in range(n):
			var v: float = 1.0 + 0.08 * sin(float(x) * 1.7) * sin(float(y) * 1.3) + rng.randf_range(-0.12, 0.12)
			img.set_pixel(x, y, Color(0.13 * v, 0.13 * v, 0.1 * v))
	var jaune := Color(0.78, 0.7, 0.4)
	for row in range(6):
		var y0: float = (float(row) + 0.5) * n / 6.0
		var k: int = 0
		while k < 9:
			var cx: float = (float(k) + rng.randf_range(0.2, 0.8)) * n / 9.0
			var cy: float = y0 + rng.randf_range(-4.0, 4.0)
			var r: float = rng.randf_range(2.6, 4.2)
			_disque(img, cx, cy, r, jaune)
			if rng.randf() < 0.6:
				_disque(img, cx, cy, r * 0.45, Color(0.16, 0.15, 0.1))
			k += 1
	for i in range(160):
		_disque(img, rng.randf() * n, rng.randf() * n, rng.randf_range(0.5, 1.1), jaune.darkened(rng.randf_range(0.0, 0.35)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex136["varan"] = t
	return t


func _flat_of(m: StandardMaterial3D, k: float = 0.9) -> StandardMaterial3D:
	var f: StandardMaterial3D = m.duplicate()
	f.vertex_color_use_as_albedo = false
	f.albedo_color = m.albedo_color * k
	f.albedo_color.a = 1.0
	_flash_mats.append(f)
	return f


# =================================================================== modèles : l'Île aux Moaïs

## Le cheval sauvage : petit et robuste, la crinière courte et dressée (comme les chevaux de
## Przewalski), la queue longue ; robe baie (crins et bas des jambes noirs), alezane, grise ou
## noire ; certains ont une liste blanche sur le chanfrein.
func _build_cheval() -> void:
	var robes := {
		"bai": [Color(0.4, 0.22, 0.11), Color(0.055, 0.045, 0.04), true],
		"alezan": [Color(0.56, 0.29, 0.13), Color(0.6, 0.38, 0.2), false],
		"gris": [Color(0.64, 0.62, 0.58), Color(0.27, 0.26, 0.25), true],
		"noir": [Color(0.11, 0.09, 0.08), Color(0.045, 0.04, 0.035), false],
	}
	var noms: Array = ["bai", "bai", "alezan", "gris", "noir"]
	robe = str(noms[randi() % noms.size()])
	var e: Array = robes[robe]
	var poil: StandardMaterial3D = _vmat(e[0], 0.55)
	var crin: StandardMaterial3D = _vmat(e[1], 0.85)
	var bas: bool = e[2]
	var flat: StandardMaterial3D = _flat_of(poil, 0.95)
	var bout: StandardMaterial3D = _flat_of(poil, 0.62)
	var corne := _mat(Color(0.15, 0.13, 0.11), 0.6)
	var noir := _mat(Color(0.025, 0.02, 0.018), 0.25)
	var robe_fn := func(s: float, ang: float) -> float:
		return 0.9 + 0.07 * (0.5 - 0.5 * sin(ang)) + 0.03 * sin(s * 23.0 + ang * 3.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var pr: Array = [Vector2(0.0, 0.1), Vector2(0.07, 0.22), Vector2(0.2, 0.28), Vector2(0.5, 0.285), Vector2(0.78, 0.275), Vector2(0.93, 0.23), Vector2(1.0, 0.1)]
	var py: Array = [Vector2(0.0, 1.1), Vector2(0.2, 1.11), Vector2(0.5, 1.07), Vector2(0.78, 1.1), Vector2(1.0, 1.05)]
	var sp: Array = []
	var rr: Array = []
	for i in range(18):
		var u: float = float(i) / 17.0
		sp.append(Vector3(0, _profil(u, py), lerpf(-0.78, 0.74, u)))
		rr.append(_profil(u, pr))
	_put(body, _tube_fn("cheval:tronc", sp, rr, 18, 1.15, robe_fn), poil)
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), flat, Vector3(sx * 0.1, 1.13, -0.5), Vector3(0.17, 0.24, 0.25))
		_mesh(body, _unit_sphere(), flat, Vector3(sx * 0.115, 1.06, 0.5), Vector3(0.12, 0.22, 0.17))
	# l'encolure (elle porte la tête : c'est elle qui se baisse pour brouter)
	var neck := Node3D.new()
	neck.name = "Cou"
	neck.position = Vector3(0, 1.2, 0.6)
	body.add_child(neck)
	_pivots["tete"] = neck
	var np: Array = [Vector3(0, -0.04, -0.06), Vector3(0, 0.2, 0.14), Vector3(0, 0.42, 0.34), Vector3(0, 0.6, 0.5)]
	var nr: Array = [0.26, 0.19, 0.135, 0.11]
	_put(neck, _tube_fn("cheval:cou", np, nr, 16, 0.62, robe_fn), poil)
	# la crinière : une brosse dressée sur le bord de l'encolure, du garrot à la nuque
	var mp: Array = [Vector3(0, 0.25, -0.26)]
	var mr: Array = [0.035]
	for i in range(1, np.size()):
		var d: Vector3 = ((np[mini(i + 1, np.size() - 1)] as Vector3) - (np[i - 1] as Vector3)).normalized()
		var nn := Vector3(0, d.z, -d.y)
		mp.append((np[i] as Vector3) + nn * (float(nr[i]) * 0.92 + 0.035))
		mr.append([0.0, 0.085, 0.085, 0.07][i])
	var meche := func(s: float, _ang: float) -> float:
		return 0.72 + 0.28 * sin(s * 140.0)
	_put(neck, _tube_fn("cheval:criniere", mp, mr, 8, 0.22, meche), crin)
	_put(neck, _tube_fn("cheval:toupet", [Vector3(0, 0.66, 0.46), Vector3(0, 0.63, 0.55), Vector3(0, 0.55, 0.6)], [0.035, 0.04, 0.015], 8, 0.8, meche), crin)
	# la tête : longue, le chanfrein droit, les ganaches rondes, le bout du nez plus sombre
	var head := Node3D.new()
	head.name = "Crane"
	head.position = Vector3(0, 0.6, 0.5)
	neck.add_child(head)
	_pivots["crane"] = head
	var hp2: Array = [Vector3(0, 0.03, -0.05), Vector3(0, -0.06, 0.06), Vector3(0, -0.24, 0.2), Vector3(0, -0.42, 0.31), Vector3(0, -0.5, 0.35)]
	var hr: Array = [0.1, 0.115, 0.085, 0.07, 0.06]
	_put(head, _tube_fn("cheval:tete", hp2, hr, 16, 0.7, robe_fn), poil)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), flat, Vector3(sx * 0.055, -0.1, 0.0), Vector3(0.05, 0.1, 0.11))
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.034, -0.49, 0.385), Vector3(0.012, 0.02, 0.012))
		# l'œil, sur le côté, et son arcade
		var ep := Vector3(sx * 0.072, -0.07, 0.06)
		_mesh(head, _unit_sphere(), _mat(Color(0.07, 0.04, 0.025), 0.08), ep, Vector3(0.016, 0.024, 0.022))
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.2), ep + Vector3(sx * 0.012, 0.008, 0.008), Vector3.ONE * 0.004)
		_mesh(head, _unit_sphere(), flat, ep + Vector3(-sx * 0.004, 0.018, -0.004), Vector3(0.02, 0.012, 0.026))
		# les oreilles, pointues, tournées vers l'avant
		var ear := Node3D.new()
		ear.position = Vector3(sx * 0.045, 0.1, -0.035)
		ear.rotation = Vector3(0.3, 0, sx * -0.2)
		head.add_child(ear)
		_mesh(ear, _cyl(0.0, 0.032, 0.13), flat, Vector3(0, 0.065, 0), Vector3(1.0, 1.0, 0.55))
		_mesh(ear, _cyl(0.0, 0.022, 0.1), noir, Vector3(0, 0.055, 0.01), Vector3(1.0, 1.0, 0.3))
	_mesh(head, _unit_sphere(), bout, Vector3(0, -0.47, 0.32), Vector3(0.06, 0.062, 0.075))
	_mesh(head, _unit_sphere(), bout, Vector3(0, -0.535, 0.295), Vector3(0.045, 0.024, 0.05))
	if randi() % 3 == 0 and robe != "gris":
		# une liste blanche sur le chanfrein
		var lp: Array = []
		for i in range(1, 5):
			var a0: Vector3 = hp2[maxi(i - 1, 0)]
			var a1: Vector3 = hp2[mini(i + 1, 4)]
			var d2: Vector3 = (a1 - a0).normalized()
			lp.append((hp2[i] as Vector3) + Vector3(0, d2.z, -d2.y) * float(hr[i]) * 0.97)
		_put(head, _tube_fn("cheval:liste", lp, [0.012, 0.012, 0.011, 0.01], 8, 2.8, Callable()), _mat(Color(0.94, 0.93, 0.9), 0.8))
	# les jambes : l'avant-bras et le genou, le canon, le boulet, le sabot ; derrière, la cuisse, le
	# grasset, le jarret coudé
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * (0.15 if front else 0.14), 0.98 if front else 1.0, 0.5 if front else -0.52)
		body.add_child(leg)
		var path: Array
		var radii: Array
		if front:
			path = [Vector3(0, 0.05, 0), Vector3(0, -0.24, -0.04), Vector3(0, -0.5, 0.0), Vector3(0, -0.57, 0.0), Vector3(0, -0.85, 0.01), Vector3(0, -0.9, 0.035)]
			radii = [0.1, 0.07, 0.048, 0.046, 0.038, 0.044]
		else:
			path = [Vector3(0, 0.05, 0), Vector3(0, -0.28, 0.1), Vector3(0, -0.52, -0.1), Vector3(0, -0.6, -0.1), Vector3(0, -0.87, -0.02), Vector3(0, -0.92, 0.015)]
			radii = [0.13, 0.085, 0.05, 0.044, 0.038, 0.044]
		var pfn := func(s: float, _a: float) -> float:
			return lerpf(0.93, 0.18, smoothstep(0.52, 0.64, s)) if bas else 0.93
		_put(leg, _tube_fn("cheval:%s:%s" % ["av" if front else "ar", "bas" if bas else "uni"], path, radii, 12, 1.0, pfn), poil)
		var last: Vector3 = path[5]
		_mesh(leg, _cyl(0.042, 0.052, 0.07), corne, Vector3(0, last.y - 0.045, last.z + 0.01))
		_legs.append([leg, sx2, i])
	# la queue : le tronçon, puis les crins jusqu'aux jarrets
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 1.3, -0.76)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("cheval:tronçon", [Vector3(0, 0.02, 0.04), Vector3(0, -0.05, -0.07), Vector3(0, -0.16, -0.12)], [0.06, 0.05, 0.04], 10, 1.0, robe_fn), poil)
	var crins := func(s: float, ang: float) -> float:
		return 0.72 + 0.28 * sin(ang * 5.0 + s * 9.0) * sin(s * 31.0)
	for j in range(3):
		var ox: float = (float(j) - 1.0) * 0.022
		var l2: float = [0.82, 0.9, 0.78][j]
		var tp: Array = [Vector3(ox * 0.5, -0.03, -0.07), Vector3(ox, -0.2, -0.16), Vector3(ox * 1.4, -l2 * 0.6, -0.21), Vector3(ox * 1.2, -l2, -0.17)]
		_put(tail, _tube_fn("cheval:crins%d" % j, tp, [0.045, 0.06, 0.055, 0.012], 10, 0.75, crins), crin)


## La frégate : tout noire, lustrée, la poche rouge sous la gorge ; de très longues ailes étroites,
## coudées au poignet ; la queue fourchue comme des ciseaux ; le long bec gris crochu.
func _build_fregate() -> void:
	var noir := _vmat(Color(0.075, 0.07, 0.085), 0.42)
	noir.metallic_specular = 0.7
	var bec := _mat(Color(0.55, 0.57, 0.6), 0.4)
	var gorge := _mat(Color(0.85, 0.08, 0.06), 0.35)
	var oeil := _mat(Color(0.02, 0.02, 0.02), 0.1)
	var plumes := func(s: float, ang: float) -> float:
		return 0.82 + 0.18 * sin(s * 40.0 + ang * 2.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		sp.append(Vector3(0, -0.015 * sin(u * PI), lerpf(-0.3, 0.24, u)))
		rr.append(lerpf(0.028, 0.075, smoothstep(0.0, 0.55, u)) * (1.0 - 0.35 * smoothstep(0.8, 1.0, u)))
	_put(body, _tube_fn("fregate:corps", sp, rr, 12, 0.9, plumes), noir)
	var fl: StandardMaterial3D = _flat_of(noir, 1.0)
	_mesh(body, _unit_sphere(), fl, Vector3(0, 0.01, 0.27), Vector3(0.042, 0.042, 0.055))
	_put(body, _tube_fn("fregate:bec", [Vector3(0, 0.012, 0.31), Vector3(0, 0.01, 0.4), Vector3(0, 0.004, 0.45), Vector3(0, -0.02, 0.465)], [0.013, 0.009, 0.007, 0.003], 8, 1.0, Callable()), bec)
	_mesh(body, _unit_sphere(), gorge, Vector3(0, -0.035, 0.23), Vector3(0.028, 0.032, 0.05))
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), oeil, Vector3(sx * 0.03, 0.02, 0.3), Vector3.ONE * 0.008)
	# les ailes : le bras, droit, puis la main qui file vers l'arrière, très pointue
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.05, 0.02, 0.08)
		body.add_child(wing)
		var ap: Array = [Vector3(0, 0, -0.05), Vector3(sx * 0.22, 0.02, -0.07), Vector3(sx * 0.44, 0.03, -0.05)]
		_put(wing, _tube_fn("fregate:bras%s" % ("g" if sx < 0.0 else "d"), ap, [0.12, 0.11, 0.08], 10, 0.09, plumes), noir)
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.44, 0.03, 0.0)
		wing.add_child(hand)
		var hpth: Array = [Vector3(0, 0, -0.04), Vector3(sx * 0.25, -0.005, -0.13), Vector3(sx * 0.48, -0.02, -0.3), Vector3(sx * 0.6, -0.03, -0.42)]
		_put(hand, _tube_fn("fregate:main%s" % ("g" if sx < 0.0 else "d"), hpth, [0.085, 0.065, 0.035, 0.006], 10, 0.09, plumes), noir)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	for sx in [-1.0, 1.0]:
		var tl := Node3D.new()
		tl.position = Vector3(0, 0, -0.27)
		body.add_child(tl)
		_pivots["queue%d" % int(sx)] = tl
		_put(tl, _tube_fn("fregate:queue%s" % ("g" if sx < 0.0 else "d"), [Vector3(sx * 0.01, 0, 0), Vector3(sx * 0.03, -0.005, -0.2), Vector3(sx * 0.06, -0.01, -0.42)], [0.04, 0.025, 0.006], 8, 0.12, plumes), noir)
	# le poisson qu'elle remonte de la mer
	_poisson = Node3D.new()
	_poisson.position = Vector3(0, -0.01, 0.46)
	body.add_child(_poisson)
	var argent := _mat(Color(0.75, 0.8, 0.85), 0.25)
	argent.metallic = 0.6
	_mesh(_poisson, _unit_sphere(), argent, Vector3(0.0, 0.0, 0.0), Vector3(0.05, 0.016, 0.018), Vector3(0, 0, 0))
	_mesh(_poisson, _unit_sphere(), argent, Vector3(0.055, 0.0, 0.0), Vector3(0.012, 0.016, 0.004))
	_poisson.visible = false


## La tortue verte : une grande carapace en dôme (les écailles brun olive rayées de fauve), le
## plastron crème, une petite tête ronde au bec court, de longues nageoires avant en ailes, deux
## courtes palettes derrière ; la peau couverte de petites écailles aux bords pâles.
func _build_tortue() -> void:
	var shell := _mat(Color(0.78, 0.8, 0.7), 0.38)
	shell.vertex_color_use_as_albedo = true
	shell.albedo_texture = _carapace_tex()
	shell.uv1_triplanar = true
	shell.uv1_scale = Vector3(0.9, 0.9, 0.9)
	shell.uv1_offset = Vector3(0.5, 0.5, 0.5)
	var peau := _mat(Color(0.72, 0.72, 0.68), 0.7)
	peau.albedo_texture = _ecailles_tex()
	peau.uv1_triplanar = true
	peau.uv1_scale = Vector3(5.0, 5.0, 5.0)
	var creme := _mat(Color(0.86, 0.79, 0.56), 0.7)
	var bec := _mat(Color(0.55, 0.5, 0.36), 0.45)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var dome := func(d: Vector3) -> Vector3:
		var x: float = d.x * 0.42 * (1.0 - 0.2 * smoothstep(0.1, 1.0, -d.z))
		var y: float = d.y * (0.2 if d.y > 0.0 else 0.06)
		return Vector3(x, 0.17 + y, d.z * 0.52 + 0.02 * d.y)
	var ombre := func(d: Vector3, _p: Vector3) -> Color:
		var v: float = 1.0 if d.y > -0.05 else 0.75
		return Color(v, v, v)
	_put(body, _blob_mesh("tortue:carapace", dome, ombre, 20, 32), shell)
	var plastron := func(d: Vector3) -> Vector3:
		return Vector3(d.x * 0.36 * (1.0 - 0.2 * smoothstep(0.1, 1.0, -d.z)), 0.1 + d.y * 0.055, d.z * 0.45)
	var blanc := func(_d: Vector3, _p: Vector3) -> Color:
		return Color(1, 1, 1)
	_put(body, _blob_mesh("tortue:plastron", plastron, blanc, 10, 20), creme)
	# la tête et le cou
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.16, 0.47)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_fn("tortue:cou", [Vector3(0, -0.01, -0.08), Vector3(0, 0.0, 0.0), Vector3(0, 0.02, 0.07)], [0.075, 0.07, 0.062], 12, 0.8, Callable()), peau)
	_mesh(head, _unit_sphere(), peau, Vector3(0, 0.035, 0.12), Vector3(0.072, 0.064, 0.098))
	_mesh(head, _unit_sphere(), bec, Vector3(0, 0.012, 0.205), Vector3(0.038, 0.034, 0.03))
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * 0.052, 0.048, 0.15)
		_mesh(head, _unit_sphere(), _mat(Color(0.06, 0.04, 0.03), 0.06), ep, Vector3(0.016, 0.016, 0.018))
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.0), ep + Vector3(sx * 0.006, 0.006, 0.012), Vector3.ONE * 0.004)
	# les nageoires
	for sx in [-1.0, 1.0]:
		var fp := Node3D.new()
		fp.position = Vector3(sx * 0.3, 0.13, 0.28)
		body.add_child(fp)
		var path: Array = [Vector3.ZERO, Vector3(sx * 0.18, -0.03, 0.06), Vector3(sx * 0.38, -0.07, -0.04), Vector3(sx * 0.52, -0.09, -0.2)]
		_put(fp, _tube_fn("tortue:avant%s" % ("g" if sx < 0.0 else "d"), path, [0.06, 0.075, 0.06, 0.012], 10, 0.2, Callable()), peau)
		_legs135.append([fp, sx, 0, 0.0])
		var bp := Node3D.new()
		bp.position = Vector3(sx * 0.22, 0.11, -0.4)
		body.add_child(bp)
		var path2: Array = [Vector3.ZERO, Vector3(sx * 0.08, -0.03, -0.08), Vector3(sx * 0.12, -0.05, -0.18)]
		_put(bp, _tube_fn("tortue:arriere%s" % ("g" if sx < 0.0 else "d"), path2, [0.05, 0.06, 0.025], 10, 0.22, Callable()), peau)
		_legs135.append([bp, sx, 1, 0.0])
	_mesh(body, _cyl(0.0, 0.03, 0.09), peau, Vector3(0, 0.12, -0.52), Vector3.ONE, Vector3(-PI * 0.5, 0, 0))


# =================================================================== modèles : l'Île de la Balafre

## L'ara rouge : rouge vif, les ailes rouges, puis une bande jaune, puis des rémiges bleues ; la
## longue queue rouge aux pointes bleues ; la face nue toute blanche ; le gros bec crochu ivoire
## (la mandibule du bas est noire).
func _build_perroquet() -> void:
	var rouge := _vmat(Color(0.8, 0.07, 0.05), 0.55)
	var rouge_f: StandardMaterial3D = _flat_of(rouge, 0.95)
	var jaune := _mat(Color(0.98, 0.78, 0.1), 0.55)
	var bleu := _mat(Color(0.08, 0.26, 0.72), 0.5)
	var blanc := _mat(Color(0.95, 0.93, 0.9), 0.6)
	var ivoire := _mat(Color(0.92, 0.88, 0.8), 0.4)
	var noir := _mat(Color(0.04, 0.04, 0.04), 0.3)
	var plumes := func(s: float, ang: float) -> float:
		return 0.85 + 0.15 * sin(s * 30.0 + ang * 3.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("ara:corps", [Vector3(0, -0.01, -0.13), Vector3(0, 0.0, -0.05), Vector3(0, 0.01, 0.04), Vector3(0, 0.025, 0.11)], [0.03, 0.06, 0.068, 0.05], 12, 1.0, plumes), rouge)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.04, 0.14)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), rouge_f, Vector3.ZERO, Vector3(0.05, 0.053, 0.056))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), blanc, Vector3(sx * 0.033, -0.008, 0.026), Vector3(0.02, 0.028, 0.03))
		_mesh(head, _unit_sphere(), _mat(Color(0.95, 0.9, 0.55), 0.2), Vector3(sx * 0.043, 0.008, 0.03), Vector3.ONE * 0.009)
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.049, 0.008, 0.033), Vector3.ONE * 0.005)
	_put(head, _tube_fn("ara:bec", [Vector3(0, 0.015, 0.04), Vector3(0, 0.012, 0.075), Vector3(0, -0.012, 0.1), Vector3(0, -0.055, 0.095)], [0.028, 0.025, 0.015, 0.004], 10, 0.85, Callable()), ivoire)
	_mesh(head, _unit_sphere(), noir, Vector3(0, -0.05, 0.093), Vector3.ONE * 0.006)
	_mesh(head, _unit_sphere(), noir, Vector3(0, -0.035, 0.055), Vector3(0.022, 0.018, 0.026))
	# les ailes
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.045, 0.03, 0.03)
		body.add_child(wing)
		_mesh(wing, _unit_sphere(), rouge_f, Vector3(sx * 0.11, 0.0, -0.01), Vector3(0.12, 0.015, 0.075))
		_mesh(wing, _unit_sphere(), jaune, Vector3(sx * 0.15, -0.003, -0.06), Vector3(0.1, 0.011, 0.05))
		_mesh(wing, _unit_sphere(), bleu, Vector3(sx * 0.12, -0.006, -0.11), Vector3(0.11, 0.009, 0.055))
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.21, 0.0, 0.0)
		wing.add_child(hand)
		_mesh(hand, _unit_sphere(), bleu, Vector3(sx * 0.07, 0.0, -0.04), Vector3(0.09, 0.01, 0.07))
		for k in range(5):
			var b0 := Vector3(sx * 0.12, 0.0, -0.01 - float(k) * 0.025)
			var b1 := Vector3(sx * (0.3 - float(k) * 0.025), -0.004, -0.05 - float(k) * 0.045)
			_put(hand, _tube_fn("ara:remige%d%s" % [k, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.022, 0.018, 0.005], 6, 0.2, Callable()), bleu)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, -0.005, -0.12)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("ara:queue", [Vector3.ZERO, Vector3(0, -0.015, -0.22), Vector3(0, -0.035, -0.44)], [0.026, 0.022, 0.006], 8, 0.15, plumes), rouge)
	_put(tail, _tube_fn("ara:queue_bout", [Vector3(0, -0.022, -0.27), Vector3(0, -0.036, -0.45)], [0.024, 0.007], 8, 0.17, Callable()), bleu)
	for sx in [-1.0, 1.0]:
		_put(tail, _tube_fn("ara:queue_cote%s" % ("g" if sx < 0.0 else "d"), [Vector3(sx * 0.01, -0.005, 0.0), Vector3(sx * 0.03, -0.015, -0.16), Vector3(sx * 0.04, -0.025, -0.3)], [0.02, 0.018, 0.005], 8, 0.15, Callable()), bleu)
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), _mat(Color(0.3, 0.3, 0.32), 0.7), Vector3(sx * 0.025, -0.055, 0.0), Vector3(0.012, 0.012, 0.025))


## Le varan : long et bas, la tête étroite, le long cou, la queue aplatie sur les côtés ; la peau
## gris-noir semée de rangées d'ocelles jaunes ; la langue fourchue qui file et revient.
func _build_varan() -> void:
	var peau := _mat(Color(1, 1, 1), 0.66)
	peau.vertex_color_use_as_albedo = true
	peau.albedo_texture = _varan_tex()
	peau.uv1_triplanar = true
	peau.uv1_scale = Vector3(2.6, 2.6, 2.6)
	var peau_f := _mat(Color(0.95, 0.95, 0.95), 0.66)
	peau_f.albedo_texture = peau.albedo_texture
	peau_f.uv1_triplanar = true
	peau_f.uv1_scale = peau.uv1_scale
	var ventre := func(s: float, ang: float) -> float:
		return 0.82 + 0.18 * smoothstep(0.0, -0.8, sin(ang)) + 0.04 * sin(s * 31.0 + ang * 4.0)
	var langue := _mat(Color(0.62, 0.3, 0.45), 0.35)
	var griffe := _mat(Color(0.06, 0.05, 0.04), 0.35)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(12):
		var u: float = float(i) / 11.0
		sp.append(Vector3(0, 0.2 + 0.015 * sin(u * PI), lerpf(-0.36, 0.32, u)))
		rr.append(lerpf(0.08, 0.13, sin(u * PI * 0.9 + 0.2)) * (1.0 - 0.3 * smoothstep(0.85, 1.0, u)))
	_put(body, _tube_fn("varan:corps", sp, rr, 14, 0.72, ventre), peau)
	_put(body, _tube_fn("varan:cou", [Vector3(0, 0.205, 0.28), Vector3(0, 0.212, 0.42), Vector3(0, 0.218, 0.5)], [0.088, 0.066, 0.056], 12, 0.85, ventre), peau)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.218, 0.5)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_fn("varan:tete", [Vector3(0, 0.0, -0.01), Vector3(0, 0.006, 0.06), Vector3(0, -0.004, 0.12), Vector3(0, -0.012, 0.17)], [0.055, 0.047, 0.031, 0.016], 12, 0.68, ventre), peau)
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * 0.033, 0.02, 0.055)
		_mesh(head, _unit_sphere(), _mat(Color(0.75, 0.48, 0.12), 0.15), ep, Vector3.ONE * 0.011)
		_mesh(head, _unit_sphere(), _mat(Color(0.02, 0.02, 0.02), 0.1), ep + Vector3(sx * 0.004, 0, 0.003), Vector3(0.006, 0.009, 0.006))
		_mesh(head, _unit_sphere(), peau_f, ep + Vector3(-sx * 0.003, 0.011, -0.002), Vector3(0.014, 0.006, 0.016))
		_mesh(head, _unit_sphere(), griffe, Vector3(sx * 0.011, 0.002, 0.155), Vector3.ONE * 0.004)
	var jaw := Node3D.new()
	jaw.position = Vector3(0, -0.02, 0.02)
	head.add_child(jaw)
	_pivots["machoire"] = jaw
	_put(jaw, _tube_fn("varan:machoire", [Vector3(0, 0, -0.01), Vector3(0, -0.006, 0.08), Vector3(0, -0.004, 0.142)], [0.036, 0.026, 0.012], 10, 0.55, ventre), peau)
	var tongue := Node3D.new()
	tongue.position = Vector3(0, -0.012, 0.15)
	head.add_child(tongue)
	_pivots["langue"] = tongue
	_put(tongue, _tube_fn("varan:langue", [Vector3.ZERO, Vector3(0, -0.004, 0.06), Vector3(0, -0.006, 0.09)], [0.006, 0.0045, 0.003], 6, 0.6, Callable()), langue)
	for sx in [-1.0, 1.0]:
		_put(tongue, _tube_fn("varan:fourche%s" % ("g" if sx < 0.0 else "d"), [Vector3(0, -0.006, 0.088), Vector3(sx * 0.008, -0.006, 0.11), Vector3(sx * 0.014, -0.005, 0.125)], [0.003, 0.002, 0.0008], 5, 1.0, Callable()), langue)
	tongue.scale = Vector3(1, 1, 0.01)
	tongue.visible = false
	# la queue en deux morceaux (le bout fouette avec un temps de retard)
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.19, -0.35)
	body.add_child(tail)
	_pivots["queue"] = tail
	var tp: Array = []
	var tr: Array = []
	for i in range(8):
		var u: float = float(i) / 7.0
		tp.append(Vector3(0, -0.03 * u, -u * 0.5))
		tr.append(lerpf(0.078, 0.042, u))
	_put(tail, _tube_fn("varan:queue1", tp, tr, 12, 1.25, ventre), peau)
	var tail2 := Node3D.new()
	tail2.position = Vector3(0, -0.03, -0.5)
	tail.add_child(tail2)
	_pivots["queue2"] = tail2
	var tp2: Array = []
	var tr2: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		tp2.append(Vector3(0, -0.04 * u, -u * 0.58))
		tr2.append(lerpf(0.042, 0.005, u))
	_put(tail2, _tube_fn("varan:queue2", tp2, tr2, 10, 1.35, ventre), peau)
	# les pattes, écartées sur les côtés, et leurs cinq longues griffes
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.09, 0.19, 0.22 if front else -0.26)
		body.add_child(leg)
		var lp: Array
		var lr: Array
		if front:
			lp = [Vector3.ZERO, Vector3(sx2 * 0.1, 0.0, 0.02), Vector3(sx2 * 0.15, -0.08, 0.06), Vector3(sx2 * 0.16, -0.165, 0.08)]
			lr = [0.042, 0.032, 0.026, 0.022]
		else:
			lp = [Vector3.ZERO, Vector3(sx2 * 0.11, 0.0, -0.04), Vector3(sx2 * 0.17, -0.08, -0.02), Vector3(sx2 * 0.18, -0.165, 0.0)]
			lr = [0.052, 0.038, 0.03, 0.024]
		_put(leg, _tube_fn("varan:patte%s%s" % ["av" if front else "ar", "g" if sx2 < 0.0 else "d"], lp, lr, 10, 1.0, ventre), peau)
		var foot: Vector3 = lp[3]
		_mesh(leg, _unit_sphere(), peau_f, foot + Vector3(0, -0.005, 0.02), Vector3(0.03, 0.012, 0.035))
		for f in range(5):
			var a: float = (float(f) - 2.0) * 0.32 + sx2 * 0.15
			var c0: Vector3 = foot + Vector3(sin(a) * 0.03, -0.008, 0.03 + cos(a) * 0.02)
			_mesh(leg, _cyl(0.001, 0.005, 0.045), griffe, c0 + Vector3(sin(a) * 0.02, -0.004, cos(a) * 0.02), Vector3.ONE, Vector3(PI * 0.5 + 0.2, a, 0))
		_legs135.append([leg, sx2, i, 0.0])


## Le crabe de cocotier : énorme, rouge orangé (parfois bleu violet), la carapace bombée, l'abdomen
## replié sous lui, deux pinces inégales (la gauche plus grosse), trois paires de longues pattes
## annelées, les yeux sur des pédoncules et de longues antennes.
func _build_crabe_cocotier() -> void:
	var bleu: bool = randi() % 3 == 0
	var c0: Color = Color(0.3, 0.26, 0.55) if bleu else Color(0.72, 0.25, 0.1)
	var cara := _vmat(c0, 0.42)
	var cara_f: StandardMaterial3D = _flat_of(cara, 0.92)
	var fonce := _mat(c0.darkened(0.55), 0.45)
	var mou := _mat(Color(0.45, 0.28, 0.3) if not bleu else Color(0.35, 0.3, 0.42), 0.6)
	var doigt_m := _mat(Color(0.12, 0.08, 0.07), 0.35)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.1)
	var body := Node3D.new()
	body.name = "Corps"
	body.position = Vector3(0, 0.3, 0)
	_visual.add_child(body)
	_pivots["corps"] = body
	var thorax := func(d: Vector3) -> Vector3:
		var x: float = d.x * 0.17 * (1.0 - 0.25 * smoothstep(0.3, 1.0, d.z))
		return Vector3(x, d.y * (0.1 if d.y > 0.0 else 0.07), d.z * 0.2)
	var sillons := func(d: Vector3, _p: Vector3) -> Color:
		var v: float = 0.95 - 0.25 * smoothstep(0.85, 1.0, absf(sin(d.z * 7.0 + 0.6))) * smoothstep(0.0, 0.6, d.y) + 0.05 * sin(d.x * 30.0)
		v = minf(v, 1.0) * (1.0 if d.y > -0.2 else 0.75)
		return Color(v, v, v)
	_put(body, _blob_mesh("crabe_coco:thorax", thorax, sillons, 14, 22), cara)
	_mesh(body, _unit_sphere(), mou, Vector3(0, -0.06, -0.2), Vector3(0.15, 0.11, 0.15))
	for sx in [-1.0, 1.0]:
		_mesh(body, _cyl(0.008, 0.012, 0.07), cara_f, Vector3(sx * 0.035, 0.07, 0.19), Vector3.ONE, Vector3(0.4, 0, sx * -0.2))
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.044, 0.105, 0.205), Vector3.ONE * 0.014)
		_put(body, _tube_fn("crabe_coco:antenne%s" % ("g" if sx < 0.0 else "d"), [Vector3(sx * 0.02, 0.02, 0.2), Vector3(sx * 0.06, 0.1, 0.33), Vector3(sx * 0.18, 0.14, 0.42), Vector3(sx * 0.32, 0.12, 0.4)], [0.006, 0.004, 0.003, 0.001], 5, 1.0, Callable()), fonce)
		_mesh(body, _unit_sphere(), fonce, Vector3(sx * 0.03, -0.03, 0.2), Vector3(0.025, 0.02, 0.025))
	# les pinces
	for sx in [-1.0, 1.0]:
		var f: float = 1.3 if sx < 0.0 else 1.0
		var pv := Node3D.new()
		pv.position = Vector3(sx * 0.11, -0.02, 0.16)
		body.add_child(pv)
		_pivots["pince%d" % int(sx)] = pv
		var ap: Array = [Vector3.ZERO, Vector3(sx * 0.08 * f, 0.05, 0.08 * f), Vector3(sx * 0.1 * f, 0.06, 0.2 * f)]
		_put(pv, _tube_fn("crabe_coco:bras%s" % ("g" if sx < 0.0 else "d"), ap, [0.035 * f, 0.04 * f, 0.045 * f], 10, 0.85, Callable()), cara_f)
		var palm := Vector3(sx * 0.1 * f, 0.06, 0.28 * f)
		_mesh(pv, _unit_sphere(), cara_f, palm, Vector3(0.062, 0.05, 0.09) * f)
		_put(pv, _tube_fn("crabe_coco:fixe%s" % ("g" if sx < 0.0 else "d"), [palm + Vector3(0, -0.02 * f, 0.06 * f), palm + Vector3(-sx * 0.01, -0.025 * f, 0.15 * f)], [0.028 * f, 0.007 * f], 8, 0.8, Callable()), doigt_m)
		var dg := Node3D.new()
		dg.position = palm + Vector3(0, 0.022 * f, 0.06 * f)
		pv.add_child(dg)
		_put(dg, _tube_fn("crabe_coco:doigt%s" % ("g" if sx < 0.0 else "d"), [Vector3.ZERO, Vector3(-sx * 0.006, 0.004, 0.085 * f)], [0.024 * f, 0.006 * f], 8, 0.8, Callable()), doigt_m)
		_pinces.append([dg, sx])
	# les pattes : longues, annelées de sombre aux articulations
	var anneaux := func(s: float, ang: float) -> float:
		return (0.95 - 0.45 * smoothstep(0.8, 1.0, absf(sin(s * PI * 3.0 + 0.3)))) * (0.85 + 0.15 * sin(ang))
	for sx in [-1.0, 1.0]:
		for j in range(3):
			var z: float = [0.08, -0.02, -0.12][j]
			var leg := Node3D.new()
			leg.position = Vector3(sx * 0.14, 0.0, z)
			body.add_child(leg)
			var lp: Array = [Vector3.ZERO, Vector3(sx * 0.16, 0.12, z * 0.4), Vector3(sx * 0.32, 0.06, z * 0.9), Vector3(sx * 0.42, -0.27, z * 1.3)]
			_put(leg, _tube_fn("crabe_coco:patte%d%s" % [j, "g" if sx < 0.0 else "d"], lp, [0.032, 0.03, 0.02, 0.006], 8, 0.9, anneaux), cara)
			_legs135.append([leg, sx, j, 0.0])


# =================================================================== modèles : l'Île de Larsen

## Le lapin de garenne : gris-brun, la nuque rousse, le ventre et le dessous de la queue blancs ;
## de grands yeux sur les côtés, les oreilles bordées de noir au bout ; les pattes arrière longues.
func _build_lapin() -> void:
	var poil := _vmat(Color(0.52, 0.42, 0.3), 0.95)
	var flat: StandardMaterial3D = _flat_of(poil, 0.88)
	var blanc := _mat(Color(0.93, 0.91, 0.88), 0.9)
	var rose := _mat(Color(0.78, 0.55, 0.5), 0.8)
	var dos := func(s: float, ang: float) -> float:
		return 0.72 + 0.28 * (0.5 - 0.5 * sin(ang)) + 0.05 * sin(s * 41.0 + ang * 7.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("lapin:corps", [Vector3(0, 0.13, -0.16), Vector3(0, 0.15, -0.09), Vector3(0, 0.15, 0.0), Vector3(0, 0.145, 0.08), Vector3(0, 0.15, 0.12)], [0.055, 0.105, 0.1, 0.08, 0.05], 14, 1.0, dos), poil)
	_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.085, -0.01), Vector3(0.065, 0.045, 0.1))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.2, 0.13)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), flat, Vector3(0, 0.01, 0.015), Vector3(0.052, 0.054, 0.065))
	_mesh(head, _unit_sphere(), flat, Vector3(0, -0.012, 0.065), Vector3(0.037, 0.034, 0.036))
	_mesh(head, _unit_sphere(), _flat_of(poil, 1.05), Vector3(0, -0.035, 0.075), Vector3(0.025, 0.014, 0.022))
	_mesh(head, _unit_sphere(), rose, Vector3(0, 0.0, 0.098), Vector3(0.01, 0.007, 0.006))
	_mesh(head, _unit_sphere(), _mat(Color(0.62, 0.38, 0.2), 0.95), Vector3(0, 0.02, -0.045), Vector3(0.04, 0.03, 0.03))
	for sx in [-1.0, 1.0]:
		var ep := Vector3(sx * 0.04, 0.022, 0.035)
		_mesh(head, _unit_sphere(), _mat(Color(0.86, 0.8, 0.7), 0.8), ep, Vector3(0.018, 0.019, 0.017))
		_mesh(head, _unit_sphere(), _mat(Color(0.08, 0.05, 0.03), 0.06), ep + Vector3(sx * 0.004, 0, 0.002), Vector3(0.015, 0.016, 0.015))
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.2), ep + Vector3(sx * 0.012, 0.007, 0.008), Vector3.ONE * 0.003)
	var ears := Node3D.new()
	ears.position = Vector3(0, 0.05, -0.012)
	head.add_child(ears)
	_pivots["oreilles"] = ears
	var bout := func(s: float, _a: float) -> float:
		return lerpf(1.0, 0.25, smoothstep(0.78, 0.95, s))
	for sx in [-1.0, 1.0]:
		var ep2: Array = [Vector3(sx * 0.015, 0, 0), Vector3(sx * 0.024, 0.07, -0.015), Vector3(sx * 0.028, 0.13, -0.03), Vector3(sx * 0.025, 0.155, -0.035)]
		_put(ears, _tube_fn("lapin:oreille%s" % ("g" if sx < 0.0 else "d"), ep2, [0.008, 0.011, 0.009, 0.002], 10, 2.4, bout), poil)
		var ip: Array = [Vector3(sx * 0.015, 0.02, 0.006), Vector3(sx * 0.024, 0.07, -0.006), Vector3(sx * 0.027, 0.12, -0.02)]
		_put(ears, _tube_fn("lapin:dedans%s" % ("g" if sx < 0.0 else "d"), ip, [0.004, 0.006, 0.002], 8, 2.2, Callable()), rose)
	# les pattes : avant fines, arrière repliées (les cuisses rondes, les longs pieds à plat)
	for sx in [-1.0, 1.0]:
		var fl := Node3D.new()
		fl.position = Vector3(sx * 0.035, 0.1, 0.1)
		body.add_child(fl)
		_put(fl, _tube_fn("lapin:avant", [Vector3.ZERO, Vector3(0, -0.06, 0.01), Vector3(0, -0.095, 0.025)], [0.018, 0.013, 0.012], 8, 1.0, Callable()), flat)
		_legs.append([fl, sx, 0 if sx < 0.0 else 1])
		var hl := Node3D.new()
		hl.position = Vector3(sx * 0.06, 0.12, -0.07)
		body.add_child(hl)
		_mesh(hl, _unit_sphere(), flat, Vector3.ZERO, Vector3(0.045, 0.075, 0.08))
		_mesh(hl, _unit_sphere(), flat, Vector3(0, -0.105, 0.03), Vector3(0.024, 0.016, 0.075))
		_legs.append([hl, sx, 2 if sx < 0.0 else 3])
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.16, -0.17)
	body.add_child(tail)
	_pivots["queue"] = tail
	_mesh(tail, _unit_sphere(), blanc, Vector3(0, -0.005, -0.01), Vector3(0.028, 0.03, 0.026))
	_mesh(tail, _unit_sphere(), flat, Vector3(0, 0.012, -0.004), Vector3(0.022, 0.014, 0.022))


## Les frelons : une dizaine de gros frelons roux et jaunes qui tournent ensemble ; la tête jaune,
## le thorax brun-roux, l'abdomen jaune barré de brun, les ailes transparentes.
func _build_frelons() -> void:
	var jaune := _mat(Color(0.95, 0.72, 0.12), 0.4)
	var brun := _mat(Color(0.36, 0.13, 0.05), 0.45)
	var noir := _mat(Color(0.05, 0.03, 0.02), 0.3)
	var aile := _mat(Color(0.9, 0.85, 0.65, 0.35), 0.15)
	aile.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aile.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wm := BoxMesh.new()
	wm.size = Vector3(0.024, 0.0006, 0.009)
	for i in range(10):
		var b := Node3D.new()
		_visual.add_child(b)
		_mesh(b, _unit_sphere(), brun, Vector3(0, 0, 0.008), Vector3(0.0095, 0.0095, 0.012))
		_mesh(b, _unit_sphere(), jaune, Vector3(0, 0.0, 0.023), Vector3(0.0085, 0.008, 0.007))
		for sx in [-1.0, 1.0]:
			_mesh(b, _unit_sphere(), brun, Vector3(sx * 0.005, 0.002, 0.025), Vector3(0.003, 0.005, 0.004))
		_mesh(b, _unit_sphere(), jaune, Vector3(0, -0.002, -0.017), Vector3(0.0105, 0.0095, 0.019))
		for zz in [-0.008, -0.019]:
			_mesh(b, _unit_sphere(), brun, Vector3(0, -0.0015, zz), Vector3(0.011, 0.0098, 0.0035))
		_mesh(b, _unit_sphere(), noir, Vector3(0, -0.004, -0.036), Vector3(0.0025, 0.0025, 0.004))
		var ws: Array = []
		for sx in [-1.0, 1.0]:
			var w := _mesh(b, wm, aile, Vector3(sx * 0.013, 0.008, 0.004), Vector3.ONE, Vector3(0, sx * 0.35, 0))
			ws.append([w, sx])
		_frelons.append([b, randf() * TAU, randf_range(0.25, 0.7), randf_range(-0.3, 0.3), randf_range(2.5, 4.5), ws])


## Le hérisson : un dôme de piquants bruns aux pointes crème, le museau pointu au bout noir, les
## petits yeux noirs ; quand il se roule en boule, on ne voit plus que les piquants.
func _build_herisson() -> void:
	var fourrure := _vmat(Color(0.5, 0.42, 0.33), 0.95)
	var fl: StandardMaterial3D = _flat_of(fourrure, 0.9)
	var peau := _mat(Color(0.2, 0.16, 0.12), 0.9)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.2)
	var piq := _vmat(Color(0.9, 0.82, 0.66), 0.7)
	var bandes := func(s: float, _a: float) -> float:
		if s < 0.3:
			return 0.8
		if s < 0.62:
			return 0.16
		if s < 0.86:
			return 0.95
		return 0.22
	var spine: ArrayMesh = _tube_fn("herisson:piquant", [Vector3.ZERO, Vector3(0, 0.02, 0), Vector3(0, 0.038, 0)], [0.0042, 0.003, 0.0004], 5, 1.0, bandes)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_mesh(body, _unit_sphere(), peau, Vector3(0, 0.07, -0.01), Vector3(0.09, 0.07, 0.12))
	_mesh(body, _unit_sphere(), fl, Vector3(0, 0.045, 0.0), Vector3(0.075, 0.035, 0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1364
	var xf: Array = []
	while xf.size() < 420:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.25, 1), rng.randf_range(-1, 1))
		if d.length() > 1.0 or d.length() < 0.3:
			continue
		d = d.normalized()
		if d.z > 0.55 and d.y < 0.55:
			continue
		var at := Vector3(d.x * 0.088, 0.07 + d.y * 0.068, -0.01 + d.z * 0.118)
		var up: Vector3 = (d + Vector3(0, 0.15, -0.9)).normalized()
		xf.append(Transform3D(_base_vers(up, rng.randf() * TAU), at))
	_multi(body, spine, piq, xf)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.05, 0.1)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), fl, Vector3.ZERO, Vector3(0.045, 0.04, 0.05))
	_put(head, _tube_fn("herisson:museau", [Vector3(0, -0.004, 0.03), Vector3(0, -0.012, 0.062), Vector3(0, -0.016, 0.082)], [0.024, 0.013, 0.007], 8, 0.9, Callable()), fl)
	_mesh(head, _unit_sphere(), noir, Vector3(0, -0.015, 0.086), Vector3.ONE * 0.008)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.022, 0.012, 0.034), Vector3.ONE * 0.0065)
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.0), Vector3(sx * 0.024, 0.015, 0.039), Vector3.ONE * 0.0018)
		_mesh(head, _unit_sphere(), fl, Vector3(sx * 0.03, 0.03, 0.0), Vector3(0.012, 0.012, 0.005))
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.05, 0.035, 0.06 if i < 2 else -0.06)
		body.add_child(leg)
		_mesh(leg, _cyl(0.008, 0.01, 0.035), peau, Vector3(0, -0.016, 0))
		_legs.append([leg, sx2, i])
	# la boule (cachée tant qu'il est déroulé)
	var ball := Node3D.new()
	ball.name = "Boule"
	ball.position = Vector3(0, 0.1, 0)
	_visual.add_child(ball)
	_pivots["boule"] = ball
	_mesh(ball, _unit_sphere(), peau, Vector3.ZERO, Vector3.ONE * 0.085)
	var xf2: Array = []
	while xf2.size() < 460:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if d.length() > 1.0 or d.length() < 0.3:
			continue
		d = d.normalized()
		xf2.append(Transform3D(_base_vers(d, rng.randf() * TAU), d * 0.082))
	_multi(ball, spine, piq, xf2)
	ball.visible = false
	ball.scale = Vector3.ONE * 0.01


## Une base qui tourne l'axe +y vers « up » (puis tourne d'un angle autour de lui).
func _base_vers(up: Vector3, spin: float) -> Basis:
	var u: Vector3 = up.normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(u.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = ref.cross(u).normalized()
	var z: Vector3 = x.cross(u).normalized()
	return Basis(x, u, z) * Basis(Vector3.UP, spin)


func _multi(parent: Node3D, mesh: Mesh, mat: Material, xfs: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)
	return mmi


## Le hibou grand-duc : grand, fauve, rayé de brun sur la poitrine, le disque facial cerclé de
## sombre, les grands yeux orange, les aigrettes dressées, la gorge blanche, le bec noir crochu ;
## les pattes emplumées. Posé, ses ailes sont repliées le long du corps.
func _build_hibou() -> void:
	var plume := _mat(Color(1, 1, 1), 0.95)
	plume.vertex_color_use_as_albedo = true
	plume.albedo_texture = _plumage_tex()
	plume.uv1_triplanar = true
	plume.uv1_scale = Vector3(3.2, 3.2, 3.2)
	var fl := _mat(Color(0.95, 0.95, 0.95), 0.95)
	fl.albedo_texture = plume.albedo_texture
	fl.uv1_triplanar = true
	fl.uv1_scale = Vector3(4.0, 4.0, 4.0)
	var aile_m := _mat(Color(0.7, 0.66, 0.62), 0.95)
	aile_m.vertex_color_use_as_albedo = true
	aile_m.albedo_texture = plume.albedo_texture
	aile_m.uv1_triplanar = true
	aile_m.uv1_scale = Vector3(4.5, 4.5, 4.5)
	var sombre := _mat(Color(0.17, 0.11, 0.06), 0.95)
	var disque := _mat(Color(0.74, 0.57, 0.36), 0.95)
	var orange := _mat(Color(1.0, 0.5, 0.06), 0.12, 0.35)
	_eye_glow.append(orange)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.25)
	var blanc := _mat(Color(0.92, 0.9, 0.84), 0.9)
	var dos := func(_s: float, ang: float) -> float:
		return 0.95 - 0.2 * maxf(0.0, cos(ang))
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	# le corps : un œuf dressé, la poitrine large
	_put(body, _tube_fn("hibou:corps", [Vector3(0, 0.04, -0.03), Vector3(0, 0.12, 0.0), Vector3(0, 0.26, 0.025), Vector3(0, 0.4, 0.015), Vector3(0, 0.5, -0.01)], [0.08, 0.14, 0.165, 0.14, 0.11], 24, 0.92, dos), plume)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.56, 0.0)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), fl, Vector3(0, 0.02, -0.005), Vector3(0.125, 0.108, 0.11))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), sombre, Vector3(sx * 0.046, 0.012, 0.064), Vector3(0.068, 0.082, 0.034))
		_mesh(head, _unit_sphere(), disque, Vector3(sx * 0.045, 0.012, 0.072), Vector3(0.06, 0.074, 0.032))
		var ep := Vector3(sx * 0.043, 0.024, 0.097)
		_mesh(head, _unit_sphere(), orange, ep, Vector3(0.027, 0.027, 0.012))
		_mesh(head, _unit_sphere(), noir, ep + Vector3(0, 0, 0.008), Vector3(0.015, 0.016, 0.006))
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.2), ep + Vector3(sx * 0.006, 0.008, 0.012), Vector3.ONE * 0.0035)
		_mesh(head, _unit_sphere(), fl, ep + Vector3(0, 0.021, -0.004), Vector3(0.032, 0.011, 0.017))
		_put(head, _tube_fn("hibou:aigrette%s" % ("g" if sx < 0.0 else "d"), [Vector3(sx * 0.058, 0.072, 0.03), Vector3(sx * 0.078, 0.128, 0.012), Vector3(sx * 0.094, 0.17, -0.01)], [0.024, 0.016, 0.004], 8, 0.4, Callable()), sombre)
	_put(head, _tube_fn("hibou:bec", [Vector3(0, 0.0, 0.098), Vector3(0, -0.018, 0.125), Vector3(0, -0.042, 0.121)], [0.013, 0.009, 0.003], 8, 0.8, Callable()), noir)
	_mesh(head, _unit_sphere(), blanc, Vector3(0, -0.078, 0.074), Vector3(0.054, 0.028, 0.03))
	# les ailes repliées le long des flancs (on les voit posé)…
	var barres := func(s: float, _a: float) -> float:
		return 0.72 + 0.28 * smoothstep(-0.3, 0.7, sin(s * 16.0))
	var plie := Node3D.new()
	body.add_child(plie)
	_pivots["ailes_pliees"] = plie
	for sx in [-1.0, 1.0]:
		var wp: Array = [Vector3(sx * 0.12, 0.47, 0.0), Vector3(sx * 0.145, 0.34, -0.035), Vector3(sx * 0.13, 0.19, -0.07), Vector3(sx * 0.085, 0.06, -0.13), Vector3(sx * 0.045, 0.0, -0.18)]
		_put(plie, _tube_fn("hibou:pliee%s" % ("g" if sx < 0.0 else "d"), wp, [0.05, 0.095, 0.095, 0.06, 0.02], 16, 0.45, barres), aile_m)
	_mesh(body, _unit_sphere(), aile_m, Vector3(0, 0.08, -0.13), Vector3(0.07, 0.03, 0.1), Vector3(-0.7, 0, 0))
	# … et ouvertes, en vol : le bras, la main et ses rémiges barrées
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.1, 0.43, -0.02)
		body.add_child(wing)
		var ap: Array = [Vector3(0, 0, -0.03), Vector3(sx * 0.2, 0.01, -0.05), Vector3(sx * 0.42, 0.0, -0.05)]
		_put(wing, _tube_fn("hibou:bras%s" % ("g" if sx < 0.0 else "d"), ap, [0.13, 0.15, 0.13], 12, 0.12, barres), aile_m)
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.42, 0.0, 0.0)
		wing.add_child(hand)
		for k in range(6):
			var b0 := Vector3(sx * 0.02, 0.0, 0.02 - float(k) * 0.035)
			var b1 := Vector3(sx * (0.3 - float(k) * 0.02), -0.004, -0.02 - float(k) * 0.05)
			_put(hand, _tube_fn("hibou:remige%d%s" % [k, "g" if sx < 0.0 else "d"], [b0, (b0 + b1) * 0.5, b1], [0.034, 0.03, 0.014], 6, 0.15, barres), aile_m)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
		wing.visible = false
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx * 0.05, 0.05, 0.05)
		body.add_child(leg)
		_mesh(leg, _unit_sphere(), fl, Vector3.ZERO, Vector3(0.04, 0.05, 0.04))
		for k in range(3):
			var a: float = (float(k) - 1.0) * 0.4
			_mesh(leg, _cyl(0.002, 0.007, 0.04), noir, Vector3(sin(a) * 0.02, -0.045, 0.03 + cos(a) * 0.01), Vector3.ONE, Vector3(PI * 0.55, a, 0))
		_pivots["patte%d" % int(sx)] = leg


## Le plumage du grand-duc : fauve chaud, strié de mèches brun sombre, finement barré.
func _plumage_tex() -> Texture2D:
	if _tex136.has("plumage"):
		return _tex136["plumage"]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1365
	for y in range(n):
		for x in range(n):
			var v: float = 0.9 + 0.1 * sin(float(y) * 1.6 + sin(float(x) * 0.3) * 2.0) + rng.randf_range(-0.05, 0.05)
			img.set_pixel(x, y, Color(0.72 * v, 0.53 * v, 0.31 * v))
	var brun := Color(0.2, 0.12, 0.055)
	for i in range(90):
		var cx: float = rng.randf() * n
		var cy: float = rng.randf() * n
		var ln: int = rng.randi_range(5, 14)
		var w: float = rng.randf_range(0.8, 1.7)
		for k in range(ln):
			_disque(img, cx + sin(float(k) * 0.3) * 0.5, cy + float(k), w * (1.0 - float(k) / float(ln) * 0.5), brun)
	for i in range(140):
		_disque(img, rng.randf() * n, rng.randf() * n, rng.randf_range(0.6, 1.4), brun.lightened(rng.randf_range(0.1, 0.4)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex136["plumage"] = t
	return t


## Le renard roux : roux flamboyant, la gorge et le bout du museau blancs, les « chaussettes »
## noires, le dos des oreilles noir ; la grosse queue touffue au bout blanc.
func _build_renard() -> void:
	var sh: Callable = _selle(0.12)
	var R: float = 0.125
	var ql: float = 0.46
	var touffe: float = 0.9
	_build_mammal({"long": 0.6, "haut": 0.4, "rayon": R, "mat": _vmat(Color(0.8, 0.4, 0.13), 0.93), "shade": sh,
		"museau": 0.16, "bout": 0.17, "crane": 0.62, "oreille": 0.95, "forme_oreille": "pointe", "ecart": 0.28,
		"queue": ql, "style": "pend", "touffe": touffe, "patte": 0.15, "pied": 0.85, "cou": 0.75, "port": 0.75, "taille": 0.72,
		"yeux": Color(0.95, 0.65, 0.15), "oeil": 0.12, "dedans": Color(0.92, 0.88, 0.82), "sombre": Color(0.04, 0.03, 0.03), "teinte": 0.9})
	var blanc := _mat(Color(0.93, 0.91, 0.87), 0.9)
	var noir := _mat(Color(0.07, 0.05, 0.04), 0.9)
	var head: Node3D = _pivots["tete"]
	var sk: float = 0.62 * R
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), blanc, Vector3(sx * sk * 0.42, -sk * 0.38, sk * 0.72), Vector3(0.032, 0.026, 0.045))
	_mesh(head, _unit_sphere(), blanc, Vector3(0, -sk * 0.48, sk * 0.6 + 0.08), Vector3(0.026, 0.016, 0.05))
	for ear in head.get_children():
		if str(ear.name).contains("Oreille") and ear is Node3D:
			var oh: float = 0.95 * R
			_mesh(ear as Node3D, _cyl(0.0, oh * 0.18, oh * 0.35), noir, Vector3(0, oh * 0.82, -oh * 0.02), Vector3(1.0, 1.0, 0.45))
	var body: Node3D = _pivots["corps"]
	_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.27, 0.27), Vector3(0.06, 0.08, 0.05))
	# les chaussettes noires
	for l in _legs:
		var leg: Node3D = l[0]
		var front: bool = int(l[2]) < 2
		var lh: float = leg.position.y
		var lw: float = 0.15 * R
		var path: Array
		if front:
			path = [Vector3(0, -lh * 0.5, -lh * 0.05), Vector3(0, -lh * 0.86, -lh * 0.02), Vector3(0, -lh + 0.03, lh * 0.03)]
		else:
			path = [Vector3(0, -lh * 0.62, -lh * 0.04), Vector3(0, -lh * 0.72, -lh * 0.1), Vector3(0, -lh + 0.03, -lh * 0.04)]
		_put(leg, _tube_fn("renard:chaussette%s" % ("av" if front else "ar"), path, [lw * 1.45, lw * 1.05, lw * 0.95], 10, 1.0, Callable()), noir)
		var kids: Array = leg.get_children()
		if kids.size() >= 2 and kids[1] is MeshInstance3D:
			(kids[1] as MeshInstance3D).material_override = noir
	# le bout blanc de la queue (même courbe que _build_mammal, style « pend »)
	var tail: Node3D = _pivots["queue"]
	var u: float = 0.94
	var q := Vector3(0, -sin(u * PI * 0.5) * ql * 0.55 - u * ql * 0.1, -sin(u * PI * 0.5) * ql * 0.7)
	_mesh(tail, _unit_sphere(), blanc, q, Vector3(0.05, 0.05, 0.065))


# =================================================================== sons, alertes, butin

func _sound(what: String) -> void:
	if not SPECS136.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS136.get(kind, ["monstre_menace", "monstre_mort"])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * maxf(hit_height, 0.3))


func _bruit(s: String) -> void:
	if manager != null and manager.main != null and manager.main.has_method("sfx"):
		manager.main.sfx(s, global_position + Vector3.UP * 0.4)


func _texte(t: String, col: Color = Color(1.0, 0.95, 0.7)) -> void:
	if manager == null or manager.main == null:
		return
	var cb: Node = manager.main.get("combat_v28")
	if cb != null and cb.has_method("float_text"):
		cb.float_text(global_position + Vector3.UP * (hit_height + 0.7), t, col)


func alert_text() -> String:
	if SPECS136.has(kind):
		return str(ALERTES136.get(kind, ""))
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS136.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"cheval_sauvage":
			g.append(["piece", rng.randi_range(2, 5)])
		"fregate":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.2:
				g.append(["plume_vent", 1])
		"varan":
			g.append(["piece", rng.randi_range(3, 6)])
			if rng.randf() < 0.08:
				g.append(["piece_or", 1])
		"crabe_cocotier":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.45:
				g.append(["noix_coco", 1])
		"lapin_garenne":
			if rng.randf() < 0.5:
				g.append(["piece", 1])
		"frelon":
			g.append(["piece", rng.randi_range(1, 3)])
		"hibou_grand_duc":
			g.append(["piece", rng.randi_range(1, 2)])
			if rng.randf() < 0.4:
				g.append(["chouette_plume", 1])
	return g


# =================================================================== coups reçus, mort

func is_hittable() -> bool:
	if kind == "lapin_garenne" and state in ["plonge", "terre"]:
		return false
	return super.is_hittable()


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS136.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var to_hero: Vector3 = from_pos - global_position
	to_hero.y = 0.0
	var dir_h: Vector3 = to_hero.normalized() if to_hero.length() > 0.01 else facing
	match kind:
		"tortue_verte":
			# la carapace encaisse tout : toc ! et elle retourne à la mer
			_flash = 0.12
			tocs += 1
			_bruit("touche_carapace")
			_texte("Toc !")
			if state in ["monte", "ponte", "fige"]:
				state = "descend"
				timer = 40.0
				_fige_fait = true
			return
		"herisson":
			_flash = 0.12
			if _ball > 0.7:
				if to_hero.length() < 3.2:
					piques += 1
					manager.hurt_player(1, global_position)
					_texte("Aïe ! Ça pique !")
				_bruit("touche_carapace")
			else:
				state = "enroule"
				timer = 0.15
				_sound("menace")
			return
		"perroquet":
			_flash = 0.15
			_sound("menace")
			_partir(from_pos)
			return
		"renard_roux":
			_flash = 0.15
			_sound("menace")
			if butin != "" and manager.has_method("chapardeur_lache"):
				manager.chapardeur_lache(self)
			_knock = -dir_h * 4.0
			state = "fuite"
			timer = 3.0
			return
		"crabe_cocotier":
			# de face, les pinces et la carapace prennent le coup
			if facing.dot(dir_h) > 0.3:
				damage = maxi(1, int(float(damage) / 3.0))
				tocs += 1
				_bruit("touche_carapace")
				_puff(global_position + Vector3.UP * 0.35 + facing * 0.3, 6, Color(1.0, 0.85, 0.5, 0.9), 0.04, 0.12, 0.3, 1.0, 2.5)
	var behind: bool = facing.dot(dir_h) < -0.15
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	match kind:
		"cheval_sauvage":
			manager.alert(self)
			_knock = Vector3.ZERO
			if behind and to_hero.length() < 3.2:
				state = "ruade"
				timer = float(spec["armer"])
			else:
				state = "cabre"
				timer = 0.8
			_sound("menace")
		"frelon":
			_maj_frelons()
			state = "chasse"
		"hibou_grand_duc":
			_envol(from_pos)
		"lapin_garenne":
			state = "fuite"
			timer = 1.2
		"fregate":
			state = "fuite_air"
			timer = 3.0
		"varan":
			_whip_side = 1.0


func _maj_frelons() -> void:
	var n: int = clampi(int(ceil(float(_frelons.size()) * float(hp) / float(spec["pv"]))), 1, _frelons.size())
	for i in range(_frelons.size()):
		(_frelons[i][0] as Node3D).visible = i < n


func _death_tick(delta: float) -> void:
	if kind != "frelon":
		super._death_tick(delta)
		return
	timer += delta
	for e in _frelons:
		var nd: Node3D = e[0]
		nd.position += (nd.position + Vector3(0, 0.2, 0)).normalized() * delta * 3.0
		nd.scale = Vector3.ONE * maxf(0.01, 1.0 - timer / 0.9)
	if timer > 1.0:
		set_physics_process(false)
		queue_free()


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES136):
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
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var vue: float = float(spec["vue"])
	match genre:
		"pecheur":
			_fly_fregate(delta)
			_animate132(delta, 1.0)
			return
		"bavard":
			_fly_perroquet(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"frelons":
			_fly_frelons(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"veilleur":
			if state == "envol":
				_vol_hibou(delta)
				_animate132(delta, 1.0)
				return
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	match genre:
		"troupeau":
			move = _troupeau(delta, dist, dir_p, dy, p, sp, vue)
		"carapace":
			move = _carapace(delta, dist, sp, vue)
		"fouetteur":
			move = _fouetteur(delta, dist, dir_p, dy, sp, vue, from_home)
		"terrier":
			move = _terrier(delta, dist, dir_p, p, sp, vue)
		"boule":
			move = _boule(delta, dist, sp, vue)
		"veilleur":
			move = _veilleur(delta, dist, dir_p, p, vue)
	# on ne s'avance pas dans la mer (sauf la tortue qui y retourne)
	if move.length() > 0.01 and not (genre == "carapace" and state in ["descend", "plonge"]):
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		if _ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead):
			move = -move * 0.3
			_wander_to = Vector3.INF
			if state == "galop":
				_fuite_dir = Vector3(-_fuite_dir.z, 0, _fuite_dir.x)
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	if state == "terre":
		velocity = Vector3.ZERO
	else:
		move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


# ------------------------------------------------------------------- le troupeau de chevaux

func _troupeau(delta: float, dist: float, dir_p: Vector3, dy: float, p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	_herd_t -= delta
	match state:
		"erre":
			# on broute en restant près des autres
			if _herd_t <= 0.0:
				_herd_t = 3.0
				var c: Vector3 = _centre_troupeau()
				if c != Vector3.INF:
					home = c
			move = _wander(delta, sp)
			if dist < vue and dy < 3.0:
				state = "alerte"
				timer = randf_range(0.6, 1.0)
				if randf() < 0.5:
					_sound("menace")
		"alerte":
			facing = facing.lerp(dir_p, clampf(delta * 2.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				if dist < vue * 0.8:
					_panique(p)
				else:
					state = "erre"
		"galop":
			facing = facing.lerp(_fuite_dir, clampf(delta * 4.0, 0.0, 1.0)).normalized()
			move = facing * sp * 4.0
			if timer <= 0.0:
				state = "erre"
				home = global_position
				_wander_to = Vector3.INF
		"ruade":
			# frappé par derrière : il baisse la tête… et détend les deux postérieurs
			if timer <= 0.0:
				kicks += 1
				if dist < float(spec["portee"]) + 0.6 and (-facing).dot(dir_p) > 0.2 and dy < 2.0:
					manager.hurt_player(int(spec["degats"]), global_position - facing)
					manager.shove(dir_p * 8.0)
					landed_hits += 1
				_puff(global_position - facing * 1.0 + Vector3.UP * 0.25, 8, Color(0.6, 0.55, 0.45, 0.8), 0.15, 0.5, 0.7, 0.6, 1.8)
				state = "ruade_fin"
				timer = 0.45
		"ruade_fin", "cabre", "recul":
			if timer <= 0.0:
				_panique(p)
		_:
			state = "erre"
	return move


func _troupeau_proche(r: float) -> Array:
	var out: Array = [self]
	if manager == null or manager.get("betes") == null:
		return out
	for b in manager.betes:
		if b != self and is_instance_valid(b) and str(b.kind) == kind and b.state != "mort" and (b as Node3D).global_position.distance_to(global_position) < r:
			out.append(b)
	return out


func _centre_troupeau() -> Vector3:
	var hs: Array = _troupeau_proche(25.0)
	if hs.size() < 2:
		return Vector3.INF
	var c := Vector3.ZERO
	for b in hs:
		c += (b as Node3D).global_position
	return c / float(hs.size())


## Tout le troupeau part au galop, loin de « from ».
func _panique(from: Vector3) -> void:
	for b in _troupeau_proche(30.0):
		if b != self and str(b.state) in ["ruade", "ruade_fin", "cabre"]:
			continue
		var away: Vector3 = (b as Node3D).global_position - from
		away.y = 0.0
		b._fuite_dir = away.normalized() if away.length() > 0.1 else -(b.facing as Vector3)
		b.state = "galop"
		b.timer = randf_range(4.5, 6.5)
	_sound("menace")


# ------------------------------------------------------------------- la tortue verte

func _carapace(delta: float, dist: float, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	if dist < vue and state in ["monte", "ponte", "descend"] and not _fige_fait:
		_fige_fait = true
		state = "fige"
		timer = 2.0
		_sound("menace")
	match state:
		"monte":
			var d: Vector3 = _pente(true)
			facing = facing.lerp(d, clampf(delta * 1.5, 0.0, 1.0)).normalized()
			move = facing * sp * 0.4
			if timer <= 0.0 or _ground_at(global_position) > 1.7:
				state = "ponte"
				timer = randf_range(14.0, 20.0)
		"ponte":
			_dig_t -= delta
			if _dig_t <= 0.0:
				_dig_t = 0.7
				_puff(global_position - facing * 0.55 + Vector3.UP * 0.05, 4, Color(0.86, 0.8, 0.66, 0.8), 0.06, 0.25, 0.6, 0.6, 1.6)
			if timer <= 0.0:
				state = "descend"
				timer = 40.0
		"fige":
			if timer <= 0.0:
				state = "descend"
				timer = 40.0
				_fuite_dir = Vector3.ZERO
		"descend":
			if _fuite_dir == Vector3.ZERO or fmod(_clock, 2.0) < delta:
				_fuite_dir = _pente(false)
			facing = facing.lerp(_fuite_dir, clampf(delta * 1.5, 0.0, 1.0)).normalized()
			move = facing * sp * 0.45
			if _ground_at(global_position) < EAU - 0.25:
				state = "plonge"
				timer = 1.6
		"plonge":
			move = facing * sp * 0.3
			_down = minf(_down + delta / 1.6, 1.0)
			if timer <= 0.0:
				sorties += 1
				if manager.get("betes") != null:
					manager.betes.erase(self)
				set_physics_process(false)
				queue_free()
		_:
			state = "monte"
	return move


## Le sens de la pente : vers le haut (la plage) ou vers le bas (la mer).
func _pente(up: bool) -> Vector3:
	var best := facing
	var bh: float = -1e9 if up else 1e9
	for k in range(12):
		var a: float = TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var h: float = _ground_at(global_position + d * 4.0)
		if (up and h > bh) or (not up and h < bh):
			bh = h
			best = d
	return best


# ------------------------------------------------------------------- le varan

func _fouetteur(delta: float, dist: float, dir_p: Vector3, dy: float, sp: float, vue: float, from_home: float) -> Vector3:
	var move := Vector3.ZERO
	var front: float = facing.dot(dir_p)
	match state:
		"erre":
			move = _wander(delta, sp)
			if dist < vue and dy < 3.0:
				state = "chasse"
				_sound("menace")
				manager.alert(self)
		"chasse":
			if dist > vue * 1.8 or from_home > float(spec["laisse"]) or dy > 4.0:
				state = "retour"
			elif dist < 2.7 and front < 0.15:
				# le héros est sur son flanc ou derrière : la queue part
				state = "fouet_armer"
				timer = 0.35
				_whip_side = 1.0 if dir_p.dot(Vector3(facing.z, 0, -facing.x)) > 0.0 else -1.0
				_sound("menace")
			elif dist <= float(spec["portee"]) and front > 0.6:
				state = "armer"
				timer = float(spec["armer"])
			else:
				# il tourne lentement : on peut le prendre de flanc
				facing = facing.lerp(dir_p, clampf(delta * 2.2, 0.0, 1.0)).normalized()
				move = facing * sp * (1.0 if front > 0.5 else 0.3)
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.2
				if dist <= float(spec["portee"]) + 0.35 and facing.dot(dir_p) > 0.35 and dy < 1.8:
					manager.hurt_player(int(spec["degats"]), global_position)
					landed_hits += 1
				_knock = facing * 3.0
		"frappe":
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"fouet_armer":
			if timer <= 0.0:
				state = "fouet"
				timer = 0.45
				_blow = false
		"fouet":
			if not _blow and timer < 0.3:
				_blow = true
				whips += 1
				if dist < 3.0 and facing.dot(dir_p) < 0.4 and dy < 1.8:
					manager.hurt_player(int(spec["degats"]), global_position - facing * 1.2)
					manager.shove(dir_p * 6.0)
					landed_hits += 1
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"]) * 0.8
		"souffle", "recul":
			if timer <= 0.0:
				state = "chasse"
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 2.0:
				state = "erre"
			else:
				move = back.normalized() * sp * 0.6
				facing = facing.lerp(back.normalized(), clampf(delta * 3.0, 0.0, 1.0)).normalized()
			if dist < vue * 0.6:
				state = "chasse"
		_:
			state = "erre"
	return move


# ------------------------------------------------------------------- le lapin de garenne

func _terrier(delta: float, dist: float, dir_p: Vector3, p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp) * 0.45
			if dist < vue:
				state = "alerte"
				timer = 0.4
				_sound("menace")
		"alerte":
			facing = facing.lerp(-dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "fuite"
				timer = randf_range(1.3, 1.9)
		"fuite", "recul":
			if state == "recul":
				state = "fuite"
				timer = 1.4
			var away: Vector3 = (-dir_p).rotated(Vector3.UP, sin(_clock * 7.0 + _flank * 3.0) * 0.7)
			facing = facing.lerp(away, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			move = facing * sp * 1.3
			if timer <= 0.0:
				state = "plonge"
				timer = 0.35
				terriers += 1
				_puff(global_position + Vector3.UP * 0.05, 6, Color(0.5, 0.42, 0.3, 0.8), 0.06, 0.2, 0.5, 0.5, 1.2)
		"plonge":
			_down = minf(_down + delta / 0.35, 1.0)
			if timer <= 0.0:
				state = "terre"
				timer = randf_range(5.0, 8.0)
				collision_layer = 0
				visible = false
		"terre":
			if timer <= 0.0:
				var q: Vector3 = _sortie_terrier(p) if dist > 7.0 else Vector3.INF
				if q != Vector3.INF:
					global_position = q
					visible = true
					collision_layer = 1
					state = "sort"
					timer = 0.5
					home = q
					sorties += 1
				else:
					timer = 1.0
		"sort":
			_down = maxf(_down - delta / 0.5, 0.0)
			if timer <= 0.0:
				_down = 0.0
				state = "erre"
		_:
			state = "erre"
	return move


## Une autre sortie du terrier, à quelques mètres, du côté opposé au héros.
func _sortie_terrier(p: Vector3) -> Vector3:
	for i in range(12):
		var a: float = randf() * TAU
		var q: Vector3 = global_position + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 9.0)
		var h: float = _ground_at(q)
		if h < 0.4 or Vector2(q.x - p.x, q.z - p.z).length() < 7.0:
			continue
		if absf(_ground_at(q + Vector3(1, 0, 0)) - h) > 0.8 or absf(_ground_at(q + Vector3(0, 0, 1)) - h) > 0.8:
			continue
		return Vector3(q.x, h + 0.05, q.z)
	return Vector3.INF


# ------------------------------------------------------------------- le hérisson

func _boule(delta: float, dist: float, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp) * 0.6
			if dist < vue:
				state = "enroule"
				timer = 0.3
				_sound("menace")
		"enroule":
			if timer <= 0.0:
				state = "boule"
				_calme = 0.0
		"boule":
			if dist > 4.0:
				_calme += delta
				if _calme > 2.2:
					state = "deroule"
					timer = 0.7
			else:
				_calme = 0.0
		"deroule":
			if timer <= 0.0:
				state = "erre"
		_:
			state = "erre"
	_ball = move_toward(_ball, 1.0 if state in ["enroule", "boule"] else 0.0, delta / 0.3)
	return move


# ------------------------------------------------------------------- le hibou grand-duc

func _veilleur(delta: float, dist: float, dir_p: Vector3, p: Vector3, vue: float) -> Vector3:
	match state:
		"perche":
			# la tête suit le héros (jusqu'aux trois quarts d'un tour) ; le corps suit s'il le faut
			var rel: float = wrapf(atan2(dir_p.x, dir_p.z) - atan2(facing.x, facing.z), -PI, PI)
			if dist < 30.0:
				_head_yaw = lerp_angle(_head_yaw, clampf(rel, -2.3, 2.3), clampf(delta * 3.0, 0.0, 1.0))
				if absf(rel) > 2.0:
					facing = facing.lerp(dir_p, clampf(delta * 0.8, 0.0, 1.0)).normalized()
			else:
				_head_yaw = lerpf(_head_yaw, 0.0, clampf(delta, 0.0, 1.0))
			_hoot_t -= delta
			if _hoot_t <= 0.0:
				_hoot_t = randf_range(6.0, 11.0)
				_sound("menace")
			if dist < vue:
				_envol(p)
		"recul":
			_envol(p)
		_:
			state = "perche"
	return Vector3.ZERO


## Il s'envole sans un bruit, loin du héros, et va se poser plus loin.
func _envol(p: Vector3) -> void:
	var away: Vector3 = global_position - p
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else -facing
	var best := Vector3.INF
	for i in range(16):
		var q: Vector3 = global_position + away.rotated(Vector3.UP, randf_range(-1.3, 1.3)) * randf_range(18.0, 28.0)
		var h: float = _ground_at(q)
		if h >= 1.0:
			best = Vector3(q.x, h, q.z)
			break
	if best == Vector3.INF:
		for i in range(16):
			var q2: Vector3 = global_position + Vector3(cos(TAU * i / 16.0), 0, sin(TAU * i / 16.0)) * 16.0
			var h2: float = _ground_at(q2)
			if h2 >= 1.0:
				best = Vector3(q2.x, h2, q2.z)
				break
	if best == Vector3.INF:
		best = global_position
	_fl_from = global_position
	_cible = best
	_fl_u = 0.0
	_fl_dur = maxf(_fl_from.distance_to(best) / float(spec["vitesse"]), 1.5)
	var d: Vector3 = best - _fl_from
	d.y = 0.0
	if d.length() > 0.1:
		facing = d.normalized()
	state = "envol"
	envols += 1


func _vol_hibou(delta: float) -> void:
	_fl_u = minf(_fl_u + delta / _fl_dur, 1.0)
	var u: float = _fl_u
	var pos: Vector3 = _fl_from.lerp(_cible, u)
	pos.y = lerpf(_fl_from.y, _cible.y, u) + sin(u * PI) * 4.0
	pos.y = maxf(pos.y, _ground_at(pos) + 0.3 + 2.0 * sin(u * PI))
	global_position = pos
	rotation.y = atan2(facing.x, facing.z)
	if _fl_u >= 1.0:
		state = "perche"
		home = global_position
		velocity = Vector3.ZERO
		_head_yaw = 0.0


# ------------------------------------------------------------------- en vol : frégate, aras, frelons

func _voler_vers(delta: float, target: Vector3, speed: float, rate: float) -> void:
	var v: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * rate, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = maxf(_ground_at(global_position), EAU)
	if global_position.y < g + 0.4:
		global_position.y = g + 0.4
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.3:
		var nf: Vector3 = facing.lerp(hv.normalized(), clampf(delta * 3.0, 0.0, 1.0)).normalized()
		_visual.rotation.z = lerpf(_visual.rotation.z, clampf(facing.cross(nf).y * 25.0, -0.6, 0.6), clampf(delta * 3.0, 0.0, 1.0))
		facing = nf
	rotation.y = atan2(facing.x, facing.z)
	_visual.rotation.x = lerpf(_visual.rotation.x, clampf(-velocity.y * 0.07, -0.5, 0.9), clampf(delta * 3.0, 0.0, 1.0))


## Le point de mer (assez profonde) le plus proche, ou Vector3.INF.
func _mer_pres(c: Vector3, rmax: float) -> Vector3:
	var r: float = 8.0
	while r <= rmax:
		for k in range(16):
			var a: float = TAU * float(k) / 16.0 + r
			var q := Vector3(c.x + cos(a) * r, 0, c.z + sin(a) * r)
			if _ground_at(q) < EAU - 0.8:
				return Vector3(q.x, EAU, q.z)
		r += 6.0
	return Vector3.INF


func _fly_fregate(delta: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	var rate: float = 1.2
	match state:
		"vol":
			_orbit_a += delta * 0.16
			var rr: float = 24.0 + _flank * 5.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = maxf(_ground_at(target), EAU) + _alt
			_cd136 -= delta
			if _cd136 <= 0.0:
				_cd136 = randf_range(10.0, 18.0)
				var w: Vector3 = _mer_pres(global_position, 60.0)
				if w != Vector3.INF:
					_cible = w
					state = "pique"
					timer = 7.0
					_sound("menace")
		"pique":
			target = _cible + Vector3.UP * 0.3
			speed *= 1.5
			rate = 2.5
			if global_position.distance_to(target) < 1.8 or timer <= 0.0:
				peches += 1
				_puff(Vector3(_cible.x, EAU + 0.05, _cible.z), 12, Color(0.85, 0.92, 0.95, 0.85), 0.12, 0.5, 0.8, 1.0, 3.0)
				_bruit("plouf")
				if _poisson != null:
					_poisson.visible = true
				state = "remonte"
				timer = 5.0
		"remonte", "fuite_air":
			var out := Vector3(facing.x, 0, facing.z)
			out = out.normalized() if out.length() > 0.1 else Vector3.FORWARD
			target = global_position + out * 10.0 + Vector3.UP * 6.0
			if timer <= 0.0 or global_position.y > maxf(_ground_at(global_position), EAU) + _alt * 0.85:
				if _poisson != null:
					_poisson.visible = false
				state = "vol"
		_:
			state = "vol"
			target = global_position
	_voler_vers(delta, target, speed, rate)


func _fly_perroquet(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	_cd136 -= delta
	match state:
		"vol":
			_orbit_a += delta * (0.9 + _flank * 0.2)
			var rr: float = 4.0 + _flank
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _ground_at(target) + _alt + sin(_clock * 1.3 + _flank) * 0.4
			speed *= 0.55
			if dist < float(spec["vue"]) and _cd136 <= 0.0:
				state = "tourne"
				timer = randf_range(5.0, 7.0)
				_orbit_a = atan2(global_position.z - p.z, global_position.x - p.x)
				_parler()
		"tourne":
			_orbit_a += delta * (1.5 + _flank * 0.2)
			target = p + Vector3(cos(_orbit_a) * 2.8, 2.3 + sin(_clock * 2.0 + _flank) * 0.35, sin(_orbit_a) * 2.8)
			if timer <= 0.0:
				_partir(p)
		"file":
			target = _cible
			speed *= 1.1
			if global_position.distance_to(_cible) < 2.0 or timer <= 0.0:
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0, global_position.z)
		_:
			state = "vol"
			target = global_position
	_voler_vers(delta, target, speed, 2.5)


## L'ara crie un mot de pirate (un seul à la fois pour toute la bande).
func _parler() -> void:
	_sound("menace")
	var now: int = Time.get_ticks_msec()
	if now - _parole_ms < 2500:
		return
	_parole_ms = now
	paroles += 1
	_texte(str(PAROLES[randi() % PAROLES.size()]), Color(1.0, 0.92, 0.55))


func _partir(p: Vector3) -> void:
	var away: Vector3 = global_position - p
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	away = away.rotated(Vector3.UP, randf_range(-0.6, 0.6))
	var q: Vector3 = global_position + away * randf_range(22.0, 30.0)
	q.y = maxf(_ground_at(q), EAU) + _alt
	_cible = q
	state = "file"
	timer = 6.0
	_cd136 = randf_range(22.0, 30.0)


func _fly_frelons(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	_sting_t -= delta
	var dy: float = absf(p.y - global_position.y)
	var hero_eau: bool = _ground_at(p) < EAU - 0.4 and p.y < EAU + 0.6
	match state:
		"vol":
			target = home + Vector3(cos(_clock * 0.6 + _flank) * 0.8, 0, sin(_clock * 0.8) * 0.8)
			target.y = _ground_at(target) + _alt
			speed *= 0.3
			if dist < float(spec["vue"]) and dy < 4.0 and not hero_eau:
				state = "chasse"
				_sound("menace")
				manager.alert(self)
		"chasse", "recul":
			state = "chasse"
			target = p + Vector3(sin(_clock * 3.1) * 0.4, 1.3 + sin(_clock * 4.3) * 0.2, cos(_clock * 2.7) * 0.4)
			var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
			if global_position.distance_to(p + Vector3.UP * 1.2) < float(spec["portee"]) and _sting_t <= 0.0:
				_sting_t = float(spec["armer"])
				stings += 1
				manager.hurt_player(int(spec["degats"]), global_position)
				landed_hits += 1
			if dist > 16.0 or from_home > float(spec["laisse"]) or hero_eau:
				state = "retour"
		"retour":
			target = Vector3(home.x, _ground_at(home) + _alt, home.z)
			speed *= 0.7
			if Vector2(global_position.x - home.x, global_position.z - home.z).length() < 1.5:
				state = "vol"
		_:
			state = "vol"
			target = global_position
	var v: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * 3.0, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _ground_at(global_position)
	if global_position.y < g + 0.4:
		global_position.y = g + 0.4


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS136.has(kind):
		super._animate132(delta, speed)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	var night: bool = manager != null and manager.has_method("night") and bool(manager.night())
	for m in _eye_glow:
		(m as StandardMaterial3D).emission_energy_multiplier = 2.5 if night else 0.3
	match kind:
		"cheval_sauvage":
			_anim_cheval(delta, speed)
		"fregate":
			_anim_fregate()
		"tortue_verte":
			_anim_tortue(delta, walk)
		"perroquet":
			_anim_perroquet()
		"varan":
			_anim_varan(delta, walk)
		"crabe_cocotier":
			_anim_crabe(walk)
		"lapin_garenne":
			_anim_lapin(delta, walk)
		"frelon":
			_anim_frelons()
		"herisson":
			_anim_herisson(delta, walk)
		"hibou_grand_duc":
			_anim_hibou(delta)
		"renard_roux":
			super._animate132(delta, speed)
			_anim_renard(delta)


func _anim_cheval(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var t: float = _clock
	var neck: Node3D = _pivots.get("tete")
	var crane: Node3D = _pivots.get("crane")
	var body: Node3D = _pivots.get("corps")
	var low: float = 0.0
	var rel: float = 0.0
	match state:
		"erre":
			if _graze > 0.0:
				low = 1.3
				rel = -0.35
		"alerte":
			low = -0.3
			rel = 0.15
		"galop":
			low = 0.3 + sin(t * 13.6) * 0.06
		"ruade":
			low = 0.7
		"ruade_fin":
			low = 0.85
		"cabre":
			low = -0.45
	if neck != null:
		neck.rotation.x = lerpf(neck.rotation.x, low, clampf(delta * 4.0, 0.0, 1.0))
	if crane != null:
		crane.rotation.x = lerpf(crane.rotation.x, rel, clampf(delta * 4.0, 0.0, 1.0))
	# cabré (l'avant se lève) ou ruade (l'arrière se lève)
	_rear = lerpf(_rear, 0.6 if state == "cabre" else 0.0, clampf(delta * 7.0, 0.0, 1.0))
	_kick = lerpf(_kick, 1.0 if state in ["ruade", "ruade_fin"] else 0.0, clampf(delta * (16.0 if state == "ruade_fin" else 6.0), 0.0, 1.0))
	if body != null:
		if _rear > 0.02:
			_pose_corps(_rear, Vector3(0, 0, -0.52))
		elif _kick > 0.02:
			_pose_corps(-0.2 * _kick, Vector3(0, 0, 0.5))
		else:
			body.transform = Transform3D.IDENTITY
		if state == "galop":
			body.position.y += absf(sin(t * 6.8)) * 0.07
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		if _rear > 0.02 and i < 2:
			leg.rotation.x = lerpf(leg.rotation.x, -1.3 * _rear + sin(t * 9.0 + i) * 0.35 * _rear, clampf(delta * 10.0, 0.0, 1.0))
		elif _kick > 0.02 and i >= 2:
			leg.rotation.x = (1.4 if state == "ruade_fin" else 0.15) * _kick
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(t * 1.7) * 0.15
		tail.rotation.x = lerpf(tail.rotation.x, -0.7 if state == "galop" else 0.0, clampf(delta * 4.0, 0.0, 1.0))


func _anim_fregate() -> void:
	var t: float = _clock
	var flap: float = 0.0
	var fold: float = 0.0
	match state:
		"vol":
			flap = sin(t * 2.2) * 0.04
			if fmod(t + _flank * 7.0, 9.0) < 1.4:
				flap += sin(t * 4.0) * 0.32
		"pique":
			fold = 1.0
		_:
			flap = sin(t * 4.5) * 0.45
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * (flap + 0.06)
		wing.rotation.y = sx * fold * 0.7
		hand.rotation.z = sx * (flap * 0.6 - 0.12)
		hand.rotation.y = sx * fold * 0.5
	for sx in [-1, 1]:
		var tl: Node3D = _pivots.get("queue%d" % sx)
		if tl != null:
			tl.rotation.y = float(sx) * -(0.06 + 0.14 * (0.5 + 0.5 * sin(t * 0.7)))


func _anim_tortue(delta: float, walk: float) -> void:
	var t: float = _clock
	var crawl: float = minf(walk * 2.5, 1.0) if state in ["monte", "descend", "plonge"] else 0.0
	var stroke: float = sin(t * 2.4)
	for e in _legs135:
		var fp: Node3D = e[0]
		var sx: float = e[1]
		if int(e[2]) == 0:
			fp.rotation.y = sx * (0.15 + stroke * 0.5 * crawl)
			fp.rotation.z = sx * (-0.1 + 0.12 * maxf(0.0, -stroke) * crawl + (0.18 if state == "fige" else 0.0))
		else:
			var dig: float = 1.0 if state == "ponte" else 0.0
			fp.rotation.x = sin(t * 3.0 + (0.0 if sx > 0.0 else PI)) * 0.6 * dig + stroke * 0.2 * crawl
			fp.rotation.y = -sx * 0.3 * dig
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position = Vector3(0, 0.02 * maxf(0.0, stroke) * crawl, 0.025 * stroke * crawl)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		var tuck: float = 1.0 if state == "fige" else 0.0
		head.position.z = lerpf(head.position.z, 0.47 - 0.07 * tuck, clampf(delta * 6.0, 0.0, 1.0))
		head.rotation.x = lerpf(head.rotation.x, 0.3 * tuck + (sin(t * 0.5) * 0.08 if tuck == 0.0 else 0.0), clampf(delta * 6.0, 0.0, 1.0))
	_visual.position.y = -_down * 0.5


func _anim_perroquet() -> void:
	var t: float = _clock
	var flap: float = sin(t * 15.0) * 0.75
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * (flap + 0.1)
		hand.rotation.z = sx * flap * 0.5
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.x = sin(t * 2.0) * 0.08
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.y = sin(t * 1.1 + _flank) * 0.4 if state == "tourne" else 0.0


func _anim_varan(delta: float, walk: float) -> void:
	var t: float = _clock
	var w: float = minf(walk, 1.2)
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.rotation.y = sin(t * 5.5) * 0.1 * w
	for e in _legs135:
		var leg: Node3D = e[0]
		var sx: float = e[1]
		var i: int = e[2]
		var ph: float = t * 5.5 + (0.0 if i in [0, 3] else PI)
		leg.rotation.y = sin(ph) * 0.5 * w * (1.0 if i < 2 else -1.0)
		leg.rotation.z = sx * maxf(0.0, cos(ph)) * 0.25 * w
	# la langue fourchue
	var tg: Node3D = _pivots.get("langue")
	if tg != null:
		_tongue_t -= delta
		if _tongue_t <= 0.0:
			_tongue_t = randf_range(0.7, 1.3) if state == "chasse" else randf_range(1.5, 3.0)
			_tongue_u = 0.0
		_tongue_u += delta / 0.4
		var out: float = sin(clampf(_tongue_u, 0.0, 1.0) * PI)
		tg.visible = out > 0.02 and state not in ["armer", "frappe"]
		tg.scale = Vector3(1, 1, maxf(out, 0.01))
		tg.rotation.x = sin(t * 30.0) * 0.08
	var jaw: Node3D = _pivots.get("machoire")
	if jaw != null:
		var open: float = 0.55 if state == "armer" else 0.0
		jaw.rotation.x = lerpf(jaw.rotation.x, open, clampf(delta * (30.0 if state == "frappe" else 8.0), 0.0, 1.0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = lerpf(head.rotation.x, -0.25 if state == "armer" else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	# la queue : elle ondule ; avant le fouet, elle s'arme d'un côté, puis balaie l'autre
	var tail: Node3D = _pivots.get("queue")
	var tail2: Node3D = _pivots.get("queue2")
	if tail != null and tail2 != null:
		var base: float = sin(t * 5.5 + 1.0) * 0.25 * w + 0.06 * sin(t * 0.9)
		var tgt: float = base
		var rate: float = 6.0
		if state == "fouet_armer":
			tgt = 0.8 * _whip_side
			rate = 10.0
		elif state == "fouet":
			tgt = -1.3 * _whip_side
			rate = 22.0
		tail.rotation.y = lerpf(tail.rotation.y, tgt, clampf(delta * rate, 0.0, 1.0))
		tail2.rotation.y = lerpf(tail2.rotation.y, tgt * 0.8 + base * 0.5, clampf(delta * rate * 0.6, 0.0, 1.0))


func _anim_crabe(walk: float) -> void:
	var t: float = _clock
	var w: float = minf(walk, 1.3)
	for e in _legs135:
		var leg: Node3D = e[0]
		var sx: float = e[1]
		var j: int = e[2]
		var ph: float = t * 9.0 * (0.4 + w) + (0.0 if ((j % 2 == 0) == (sx > 0.0)) else PI)
		leg.rotation.y = sin(ph) * 0.3 * w
		leg.rotation.z = sx * maxf(0.0, cos(ph)) * 0.2 * w
	var up: float = 0.0
	var open: float = 0.25
	if state == "armer":
		up = -0.45
		open = 0.6
	elif state == "frappe":
		up = 0.15
		open = 0.0
	for sx in [-1, 1]:
		var pv: Node3D = _pivots.get("pince%d" % sx)
		if pv != null:
			pv.rotation.x = up + sin(t * 1.3 + float(sx)) * 0.05
	for e in _pinces:
		(e[0] as Node3D).rotation.x = -open
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = 0.3 + absf(sin(t * 9.0)) * 0.01 * w


func _anim_lapin(delta: float, walk: float) -> void:
	var t: float = _clock
	var body: Node3D = _pivots.get("corps")
	var ears: Node3D = _pivots.get("oreilles")
	var hop: float = 0.0
	var pitch: float = 0.0
	if walk > 0.05:
		var ph: float = fmod(t * (2.6 + walk * 2.4), 1.0)
		hop = sin(ph * PI) * (0.03 + 0.09 * minf(walk, 1.3))
		pitch = -cos(ph * PI) * 0.18 * minf(walk, 1.0)
	if state == "alerte":
		pitch = -0.55
	if body != null:
		body.position.y = lerpf(body.position.y, hop + (0.03 if state == "alerte" else 0.0), clampf(delta * 18.0, 0.0, 1.0))
		body.rotation.x = lerpf(body.rotation.x, pitch, clampf(delta * 12.0, 0.0, 1.0))
	if ears != null:
		var back: float = 0.75 if state == "fuite" else (-0.15 if state == "alerte" else 0.1 + sin(t * 0.8) * 0.06)
		ears.rotation.x = lerpf(ears.rotation.x, back, clampf(delta * 8.0, 0.0, 1.0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 0.35 if (state == "erre" and _graze > 0.0) else 0.0
	_visual.position.y = -_down * 0.35


func _anim_frelons() -> void:
	var t: float = _clock
	var tight: float = 0.55 if state == "chasse" else 1.0
	for e in _frelons:
		var nd: Node3D = e[0]
		var ph: float = e[1]
		var r: float = float(e[2]) * tight
		var h: float = e[3]
		var sp2: float = float(e[4]) * (1.4 if state == "chasse" else 1.0)
		nd.position = Vector3(cos(t * sp2 + ph) * r, h + sin(t * sp2 * 1.7 + ph) * 0.12, sin(t * sp2 * 1.3 + ph) * r * 0.8)
		nd.rotation.y = -(t * sp2 + ph)
		for w in e[5]:
			(w[0] as Node3D).rotation.z = float(w[1]) * sin(t * 90.0 + ph) * 0.6


func _anim_herisson(_delta: float, walk: float) -> void:
	var t: float = _clock
	var body: Node3D = _pivots.get("corps")
	var ball: Node3D = _pivots.get("boule")
	if body != null:
		var k: float = clampf(1.0 - _ball, 0.01, 1.0)
		body.scale = Vector3(1.0, k, 1.0) * lerpf(0.6, 1.0, k)
		body.visible = _ball < 0.98
	if ball != null:
		ball.visible = _ball > 0.02
		ball.scale = Vector3.ONE * maxf(_ball, 0.01) * (1.0 + sin(t * 3.0) * 0.02 * _ball)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 0.15 + sin(t * 9.0) * 0.08
		head.rotation.y = sin(t * 1.7) * 0.25
	for l in _legs:
		(l[0] as Node3D).rotation.x = sin(t * 16.0 + (0.0 if int(l[2]) in [0, 3] else PI)) * 0.5 * minf(walk * 2.0, 1.0)


func _anim_hibou(delta: float) -> void:
	var t: float = _clock
	var flying: bool = state == "envol"
	_unfold = lerpf(_unfold, 1.0 if flying else 0.0, clampf(delta * 6.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		var pitch: float = 1.25 * _unfold
		var bas := Basis(Vector3.RIGHT, pitch)
		var pv := Vector3(0, 0.3, 0)
		body.transform = Transform3D(bas, pv - bas * pv + Vector3(0, 0.25 * _unfold, 0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.y = _head_yaw * (1.0 - _unfold)
		head.rotation.x = -1.15 * _unfold
		head.rotation.z = sin(t * 0.9) * 0.08 * (1.0 - _unfold)
	# posé : les ailes repliées ; en vol : les grandes ailes ouvertes
	var plie: Node3D = _pivots.get("ailes_pliees")
	if plie != null:
		plie.visible = _unfold < 0.5
	var flap: float = sin(t * 5.0) * 0.55
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.visible = _unfold >= 0.5
		wing.rotation.z = sx * (flap + 0.05)
		hand.rotation.z = sx * flap * 0.5
	for sx in [-1, 1]:
		var lg: Node3D = _pivots.get("patte%d" % sx)
		if lg != null:
			lg.rotation.x = 0.9 * _unfold


func _anim_renard(_delta: float) -> void:
	# le « mulotage » : il guette, bondit très haut et retombe le nez le premier
	var ph: float = fmod(_clock + _flank * 7.0, 10.0)
	if state == "erre" and _graze > 0.0 and ph < 1.0:
		_visual.position.y = sin(ph * PI) * 0.45
		_visual.rotation.x = lerpf(-0.6, 0.9, ph)
	else:
		_visual.position.y = 0.0
		_visual.rotation.x = 0.0
	var tail: Node3D = _pivots.get("queue")
	if tail != null and state in ["emporte", "fuite", "approche"]:
		tail.rotation.x = -0.35

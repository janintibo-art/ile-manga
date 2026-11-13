extends "res://scripts/monstre_v139.gd"
## V140 : la faune de l'Île de Montjoie, de Port-Azur et de l'Île Pixelithique.
## (Les bêtes d'avant passent toujours par leurs fichiers : on ne fait ici que les nouvelles.)
##  - la basse-cour (Montjoie, la ferme) : quatre poules et un coq qui picorent ; on court vers
##    elles, elles s'égaillent en caquetant ; on s'attarde près d'elles (ou on en frappe une), le
##    coq fonce, les ailes ouvertes, et vous chasse d'un coup de bec ; à l'aube, il chante ;
##  - le héron cendré (Montjoie, le lac) : immobile dans l'eau peu profonde, il pêche d'un coup de
##    bec ; on approche, il s'envole en croassant, survole le lac et se repose sur l'autre rive ;
##  - l'écureuil roux (Montjoie, le Bois des Lutins) : il fouille au pied des arbres ; on approche,
##    il file au tronc le plus proche, grimpe, et vous gronde de là-haut ; il redescend quand on
##    est parti ;
##  - le lézard des murailles (Port-Azur, les rochers ; Montjoie, les Crocs) : il se chauffe au
##    soleil ; on approche, il file en zigzag et disparaît dans une fente, puis ressort plus loin ;
##  - la tortue d'Hermann (Port-Azur, le maquis) : elle broute à petits pas ; on s'approche, elle
##    rentre la tête et les pattes dans sa carapace, et ressort quand on est parti ;
##  - les guêpiers (Port-Azur) : une petite bande d'oiseaux de toutes les couleurs qui chasse les
##    insectes en vol ; quand le héros marche dans le maquis, ils le suivent pour attraper ceux
##    qu'il dérange ;
##  - en petits cubes, comme toute l'Île Pixelithique : les compsognathes (une petite bande
##    curieuse qui suit le héros… et lui chipe à manger ; la nuit, ils dorment serrés), les
##    archéoptéryx (perchés en haut des araucarias, ils planent d'un arbre à l'autre quand on passe
##    dessous) et la meganeura, la libellule géante du Lac des Long-Cous (elle vient voir le héros
##    de tout près, puis file).

const Vox90 = preload("res://scripts/vox_v90.gd")
const Corps64 = preload("res://scripts/pnj/corps_v64.gd")
const VOX140 := "res://assets/models/pixel90/faune_v140.bin"
const PARENTS140 := {"compsognathe": {"jambeG": "cuisseG", "jambeD": "cuisseD"}}

const SPECS140 := {
	"poule": {"pv": 99, "vitesse": 1.6, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 3.0, "laisse": 30.0,
		"rayon": 1.0, "haut": 0.2, "nom": "Poules", "genre": "basse_cour", "col": ["boule", 0.3, 0.2]},
	"heron": {"pv": 99, "vitesse": 6.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 14.0, "laisse": 80.0,
		"rayon": 0.35, "haut": 0.6, "nom": "Héron cendré", "genre": "echassier", "vol": true, "col": ["boule", 0.25, 0.6]},
	"ecureuil": {"pv": 99, "vitesse": 4.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 7.0, "laisse": 40.0,
		"rayon": 0.25, "haut": 0.1, "nom": "Écureuil roux", "genre": "grimpeur", "col": ["boule", 0.1, 0.1]},
	"lezard": {"pv": 99, "vitesse": 5.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 3.5, "laisse": 20.0,
		"rayon": 0.15, "haut": 0.03, "nom": "Lézard des murailles", "genre": "lezard", "vol": true, "col": ["boule", 0.05, 0.03]},
	"tortue_terre": {"pv": 99, "vitesse": 0.14, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 2.3, "laisse": 20.0,
		"rayon": 0.2, "haut": 0.08, "nom": "Tortue d'Hermann", "genre": "rentreuse", "vol": true, "col": ["boule", 0.1, 0.06]},
	"guepier": {"pv": 99, "vitesse": 6.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 25.0, "laisse": 80.0,
		"rayon": 1.0, "haut": 0.0, "nom": "Guêpiers", "genre": "voltigeur", "vol": true, "col": ["boule", 0.3, 0.0]},
	"compsognathe": {"pv": 99, "vitesse": 4.5, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 9.0, "laisse": 40.0,
		"rayon": 0.3, "haut": 0.2, "nom": "Compsognathe", "genre": "compso", "col": ["boule", 0.12, 0.15]},
	"archeopteryx": {"pv": 99, "vitesse": 5.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 9.0, "laisse": 80.0,
		"rayon": 0.35, "haut": 0.0, "nom": "Archéoptéryx", "genre": "perche", "vol": true, "col": ["boule", 0.15, 0.0]},
	"meganeura": {"pv": 99, "vitesse": 7.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 8.0, "laisse": 60.0,
		"rayon": 0.4, "haut": 0.0, "nom": "Meganeura", "genre": "libellule", "vol": true, "col": ["boule", 0.15, 0.0]},
}
const SOUNDS140 := {
	"poule": ["poule_caquette", "poule_caquette"], "heron": ["heron_croasse", ""], "ecureuil": ["ecureuil_crie", "ecureuil_crie"],
	"lezard": ["", ""], "tortue_terre": ["tortue_souffle", ""], "guepier": ["guepier_trille", ""],
	"compsognathe": ["compso_piaille", "compso_piaille"], "archeopteryx": ["archeo_cri", ""], "meganeura": ["meganeura_bourdon", ""],
}
const GENRES140 := ["basse_cour", "echassier", "grimpeur", "lezard", "rentreuse", "voltigeur", "compso", "perche", "libellule"]

static var _tex140: Dictionary = {}
static var _vox140: Dictionary = {}
static var _vox140_mesh: Dictionary = {}

var _vox: Dictionary = {}                 # les pièces en petits cubes (Pixelithique)
var _coq_cd: float = 8.0
var _chant_t: float = 5.0
var _coq_i: int = -1
var _tronc := Vector3.INF                 # l'écureuil : le pied de son arbre
var _tronc_r: float = 0.4
var _grimpe_h: float = 0.0
var _parti_t: float = 0.0
var _arbre := Vector3.INF                 # l'archéoptéryx : la cime où il se perche
var _fil: float = 0.0                     # la libellule : le temps de la prochaine envolée
var _vise := Vector3.INF
var _en_bas: float = 0.0
# tests
var chants: int = 0
var coups_de_bec: int = 0
var grimpes: int = 0
var caches: int = 0
var rentrees: int = 0
var captures: int = 0
var planes: int = 0
var inspections: int = 0


static func spec_of(k: String) -> Dictionary:
	if SPECS140.has(k):
		return SPECS140[k]
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
	return SPECS140.has(k) or SPECS139.has(k) or SPECS138.has(k) or SPECS137.has(k) or SPECS136.has(k) or SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS140.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS140[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = true
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	# (on passe au travers : ces petites bêtes ne bloquent pas le héros)
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var col: Array = spec["col"]
	var s := SphereShape3D.new()
	s.radius = float(col[1])
	cs.shape = s
	cs.position.y = float(col[2])
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	match k:
		"poule":
			_build_basse_cour()
		"heron":
			_build_heron()
		"ecureuil":
			_build_ecureuil()
		"lezard":
			_build_lezard()
		"tortue_terre":
			_build_tortue_terre()
		"guepier":
			_build_guepiers()
		"compsognathe", "archeopteryx", "meganeura":
			_build_vox140(k)
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
	_fil = randf_range(1.0, 3.0)
	match k:
		"poule":
			state = "picore"
		"heron":
			state = "guette"
			timer = randf_range(4.0, 9.0)
		"ecureuil":
			state = "fouille"
		"lezard":
			state = "soleil"
		"tortue_terre":
			state = "broute"
		"guepier":
			state = "chasse"
			_alt = randf_range(6.0, 8.0)
		"compsognathe":
			state = "rode"
		"archeopteryx":
			state = "perche"
			timer = randf_range(6.0, 12.0)
		"meganeura":
			state = "patrouille"
	_base_scale = _visual.scale
	rotation.y = atan2(facing.x, facing.z)


# =================================================================== petits cubes (Pixelithique)

static func _vox_data140() -> Dictionary:
	if _vox140.is_empty():
		_vox140 = Corps64.read_bin(VOX140)
	return _vox140


static func _vox_mesh140(nom: String) -> ArrayMesh:
	if _vox140_mesh.has(nom):
		return _vox140_mesh[nom]
	var m: Dictionary = _vox_data140().get("modeles", {}).get(nom, {})
	if m.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = m["v"]
	arr[Mesh.ARRAY_NORMAL] = m["n"]
	arr[Mesh.ARRAY_COLOR] = m["c"]
	arr[Mesh.ARRAY_INDEX] = m["i"]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_vox140_mesh[nom] = am
	return am


## Une bête en petits cubes, en pièces articulées (comme les dinosaures de l'île).
func _build_vox140(bete: String) -> void:
	var r: Dictionary = _vox_data140().get("rigs", {}).get(bete, {})
	var par: Dictionary = PARENTS140.get(bete, {})
	var mat: StandardMaterial3D = Vox90.make_material()
	_flash_mats.append(mat)
	var done: Dictionary = {}
	for guard in range(6):
		for k in r:
			var key: String = str(k)
			if done.has(key):
				continue
			var p: String = str(par.get(key, ""))
			if p != "" and not done.has(p):
				continue
			var j := Node3D.new()
			j.name = key
			var pos := Vector3(float(r[k][0]), float(r[k][1]), float(r[k][2]))
			if p != "":
				var pp: Array = r[p]
				pos -= Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
				(done[p] as Node3D).add_child(j)
			else:
				_visual.add_child(j)
			j.position = pos
			j.set_meta("repos", pos)
			var mi := MeshInstance3D.new()
			mi.mesh = _vox_mesh140(bete + "." + key)
			mi.material_override = mat
			# (les ailes de la libellule laissent passer le jour)
			if bete == "meganeura" and (key.begins_with("avant") or key.begins_with("arriere")):
				var verre: StandardMaterial3D = Vox90.make_material()
				verre.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				verre.albedo_color = Color(1, 1, 1, 0.32)
				verre.cull_mode = BaseMaterial3D.CULL_DISABLED
				verre.metallic_specular = 0.9
				verre.roughness = 0.2
				mi.material_override = verre
			j.add_child(mi)
			done[key] = j
	_vox = done
	# (pour le butin du compsognathe : il le tient dans la gueule)
	if done.has("cou"):
		_pivots["tete"] = done["cou"]
	elif done.has("tete"):
		_pivots["tete"] = done["tete"]


# =================================================================== textures

## La carapace de la tortue d'Hermann : des écailles jaunes, une tache noire au cœur de chacune,
## les sillons sombres entre elles.
func _hermann_tex() -> Texture2D:
	if _tex140.has("hermann"):
		return _tex140["hermann"]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1401
	var pts: Array = []
	for j in range(4):
		for i in range(4):
			pts.append(Vector2((float(i) + 0.5 + (0.5 if j % 2 == 1 else 0.0) + rng.randf_range(-0.12, 0.12)) * n / 4.0,
				(float(j) + 0.5 + rng.randf_range(-0.12, 0.12)) * n / 4.0))
	for y in range(n):
		for x in range(n):
			var p := Vector2(x, y)
			var d1: float = 1e9
			var d2: float = 1e9
			for q in pts:
				for ox in [-n, 0, n]:
					for oy in [-n, 0, n]:
						var d: float = p.distance_to((q as Vector2) + Vector2(ox, oy))
						if d < d1:
							d2 = d1
							d1 = d
						elif d < d2:
							d2 = d
			var bord: float = 1.0 - smoothstep(0.0, 3.0, d2 - d1)
			var coeur: float = 1.0 - smoothstep(6.0, 11.0, d1)
			var c := Color(0.82, 0.64, 0.26).lerp(Color(0.6, 0.42, 0.14), smoothstep(10.0, 18.0, d1))
			c = c.lerp(Color(0.08, 0.06, 0.04), coeur * 0.92)
			c = c.lerp(Color(0.12, 0.09, 0.05), bord * 0.85)
			var v: float = 1.0 + rng.randf_range(-0.05, 0.05)
			img.set_pixel(x, y, Color(c.r * v, c.g * v, c.b * v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex140["hermann"] = t
	return t


# =================================================================== modèles réalistes

## La basse-cour : quatre poules (rousses, blanche, coucou) et un coq doré à la queue vert sombre.
func _build_basse_cour() -> void:
	var robes: Array = ["rousse", "rousse", "blanche", "coucou"]
	for i in range(5):
		var coq: bool = i == 4
		var b := Node3D.new()
		_visual.add_child(b)
		var parts: Dictionary = _build_poule(b, coq, "coq" if coq else str(robes[i]))
		var a: float = TAU * float(i) / 5.0 + randf_range(-0.3, 0.3)
		var place := Vector3(cos(a), 0, sin(a)) * randf_range(0.6, 1.6)
		b.position = place
		_bande.append([b, randf() * TAU, place, parts, coq])
		if coq:
			_coq_i = i


func _build_poule(b: Node3D, coq: bool, robe: String) -> Dictionary:
	var k: float = 1.2 if coq else 1.0
	var plum: Color
	var dos: Color
	match robe:
		"blanche":
			plum = Color(0.93, 0.92, 0.88)
			dos = Color(0.9, 0.89, 0.85)
		"coucou":
			plum = Color(0.5, 0.5, 0.5)
			dos = Color(0.36, 0.36, 0.36)
		"coq":
			plum = Color(0.42, 0.14, 0.07)
			dos = Color(0.86, 0.52, 0.16)
		_:
			plum = Color(0.58, 0.31, 0.13)
			dos = Color(0.45, 0.22, 0.09)
	var plume := func(s: float, ang: float) -> float:
		return 0.82 + 0.18 * (0.5 + 0.5 * sin(s * 47.0 + ang * 9.0)) * (0.6 + 0.4 * sin(ang * 3.0 - s * 13.0))
	var m := _vmat(plum, 0.92)
	var md := _vmat(dos, 0.85)
	var fl: StandardMaterial3D = _flat_of(md, 0.95)
	var corps := Node3D.new()
	b.add_child(corps)
	_put(corps, _tube_fn("poule:corps%d" % int(coq), [Vector3(0, 0.21, -0.13) * k, Vector3(0, 0.2, -0.05) * k, Vector3(0, 0.22, 0.05) * k, Vector3(0, 0.26, 0.12) * k],
		[0.06 * k, 0.115 * k, 0.11 * k, 0.07 * k], 12, 0.95, plume), m)
	if coq:
		# le plastron noir, la selle et le camail dorés
		_mesh(corps, _unit_sphere(), _mat(Color(0.07, 0.06, 0.05), 0.8), Vector3(0, 0.22, 0.09) * k, Vector3(0.07, 0.08, 0.06) * k)
		_mesh(corps, _unit_sphere(), fl, Vector3(0, 0.29, -0.06) * k, Vector3(0.075, 0.035, 0.08) * k)
	# la queue : relevée chez la poule, de grandes faucilles vert sombre chez le coq
	if coq:
		var faux := _mat(Color(0.04, 0.12, 0.09), 0.35)
		faux.metallic = 0.5
		for j in range(3):
			var dx: float = (float(j) - 1.0) * 0.025
			_put(corps, _tube_fn("coq:faucille%d" % j, [Vector3(dx, 0.26, -0.13) * k, Vector3(dx, 0.4 + float(j) * 0.02, -0.2) * k,
				Vector3(dx, 0.38, -0.32) * k, Vector3(dx, 0.22 + float(j) * 0.03, -0.36) * k], [0.02 * k, 0.018 * k, 0.012 * k, 0.004 * k], 6, 2.5, Callable()), faux)
	else:
		_mesh(corps, _unit_sphere(), _flat_of(m, 0.85), Vector3(0, 0.3, -0.14), Vector3(0.04, 0.07, 0.06), Vector3(-0.5, 0, 0))
	var ailes: Array = []
	for sx in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(sx * 0.085, 0.25, 0.04) * k
		corps.add_child(w)
		_mesh(w, _unit_sphere(), fl if coq else _flat_of(m, 0.85), Vector3(sx * 0.01, -0.02, -0.06) * k, Vector3(0.025, 0.06, 0.1) * k)
		ailes.append([w, sx])
	# le cou et la tête (on la penche pour picorer)
	var cou := Node3D.new()
	cou.position = Vector3(0, 0.27, 0.1) * k
	corps.add_child(cou)
	_put(cou, _tube_fn("poule:cou%d" % int(coq), [Vector3.ZERO, Vector3(0, 0.06, 0.03) * k, Vector3(0, 0.1, 0.05) * k], [0.05 * k, 0.04 * k, 0.034 * k], 8, 1.0, plume), md if coq else m)
	var head := Node3D.new()
	head.position = Vector3(0, 0.11, 0.06) * k
	cou.add_child(head)
	_mesh(head, _unit_sphere(), fl if coq else _flat_of(m, 0.9), Vector3.ZERO, Vector3(0.034, 0.036, 0.042) * k)
	var rouge := _mat(Color(0.8, 0.08, 0.06), 0.55)
	var crete: float = 1.6 if coq else 0.7
	for j in range(4 if coq else 3):
		_mesh(head, _unit_sphere(), rouge, Vector3(0, 0.035 + 0.012 * crete * (1.0 - absf(float(j) - 1.5) * 0.3), 0.025 - float(j) * 0.014) * k, Vector3(0.006, 0.014 * crete, 0.01) * k)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), rouge, Vector3(sx * 0.008, -0.035, 0.028) * k, Vector3(0.007, 0.014 * crete, 0.008) * k)
		_mesh(head, _unit_sphere(), _mat(Color(0.75, 0.42, 0.08), 0.2), Vector3(sx * 0.026, 0.008, 0.02) * k, Vector3.ONE * 0.006 * k)
	_mesh(head, _cyl(0.0, 0.01 * k, 0.03 * k), _mat(Color(0.9, 0.72, 0.3), 0.5), Vector3(0, -0.004, 0.05) * k, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	# les pattes jaunes et leurs doigts
	var pmat := _mat(Color(0.85, 0.66, 0.22), 0.6)
	var pattes: Array = []
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx * 0.04, 0.15, 0.0) * k
		b.add_child(leg)
		_mesh(leg, _cyl(0.008 * k, 0.009 * k, 0.15 * k), pmat, Vector3(0, -0.075, 0) * k)
		for d in [-0.5, 0.0, 0.5]:
			_mesh(leg, BoxMesh.new(), pmat, Vector3(sin(d) * 0.02, -0.148, cos(d) * 0.02) * k, Vector3(0.006, 0.005, 0.045) * k, Vector3(0, d, 0))
		pattes.append(leg)
	return {"corps": corps, "cou": cou, "tete": head, "ailes": ailes, "pattes": pattes}


## Le héron cendré : gris dessus, blanc dessous, le long cou blanc strié de noir, la calotte blanche
## et le sourcil noir prolongé d'une aigrette, le bec en poignard jaune orangé, de longues pattes.
func _build_heron() -> void:
	var gris := _vmat(Color(0.58, 0.6, 0.63), 0.85)
	var fl: StandardMaterial3D = _flat_of(gris, 0.95)
	var blanc := _mat(Color(0.92, 0.92, 0.9), 0.85)
	var noir := _mat(Color(0.06, 0.06, 0.07), 0.7)
	var jaune := _mat(Color(0.88, 0.62, 0.2), 0.45)
	var pattes_m := _mat(Color(0.55, 0.45, 0.25), 0.7)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("heron:corps", [Vector3(0, 0.58, -0.26), Vector3(0, 0.6, -0.12), Vector3(0, 0.63, 0.04), Vector3(0, 0.67, 0.14)],
		[0.04, 0.11, 0.11, 0.07], 12, 1.05, Callable(self, "_shade_dos")), gris)
	_mesh(body, _unit_sphere(), blanc, Vector3(0, 0.6, 0.06), Vector3(0.07, 0.07, 0.1))
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.07, 0.66, 0.1), Vector3(0.02, 0.03, 0.04))
	# les ailes : repliées le long du corps, déployées en vol (1,8 m d'envergure)
	var ws: Array = []
	for sx in [-1.0, 1.0]:
		var w := Node3D.new()
		w.position = Vector3(sx * 0.09, 0.66, 0.05)
		body.add_child(w)
		_mesh(w, _unit_sphere(), fl, Vector3(sx * 0.42, 0, -0.05), Vector3(0.44, 0.012, 0.15))
		_mesh(w, _unit_sphere(), noir, Vector3(sx * 0.72, 0, -0.08), Vector3(0.16, 0.01, 0.12))
		ws.append([w, sx])
	_wings = ws
	# le cou en S
	var neck := Node3D.new()
	neck.name = "Cou"
	neck.position = Vector3(0, 0.68, 0.16)
	body.add_child(neck)
	_pivots["cou"] = neck
	var stries := func(s: float, ang: float) -> float:
		return 0.25 if (absf(cos(ang)) < 0.25 and sin(ang) < 0.0 and fmod(s * 9.0, 1.0) < 0.45) else 1.0
	_put(neck, _tube_fn("heron:cou", [Vector3.ZERO, Vector3(0, 0.1, 0.07), Vector3(0, 0.19, 0.03), Vector3(0, 0.26, 0.07)],
		[0.035, 0.03, 0.028, 0.026], 10, 1.0, stries), _vmat(Color(0.93, 0.93, 0.91), 0.85))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.27, 0.08)
	neck.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), blanc, Vector3.ZERO, Vector3(0.028, 0.03, 0.045))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.018, 0.012, -0.01), Vector3(0.012, 0.01, 0.045))
		_mesh(head, _unit_sphere(), _mat(Color(0.9, 0.8, 0.2), 0.2), Vector3(sx * 0.021, 0.004, 0.018), Vector3.ONE * 0.006)
	_put(head, _tube_fn("heron:aigrette", [Vector3(0, 0.015, -0.03), Vector3(0, 0.01, -0.09), Vector3(0, -0.005, -0.14)], [0.004, 0.003, 0.001], 4, 1.0, Callable()), noir)
	_put(head, _tube_fn("heron:bec", [Vector3(0, -0.004, 0.035), Vector3(0, -0.007, 0.1), Vector3(0, -0.01, 0.16)], [0.013, 0.008, 0.002], 6, 1.4, Callable()), jaune)
	# les longues pattes : la jambe, le tarse, les doigts
	var legs: Array = []
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(sx * 0.04, 0.55, 0.0)
		body.add_child(leg)
		_put(leg, _tube_fn("heron:jambe", [Vector3.ZERO, Vector3(0, -0.22, -0.02), Vector3(0, -0.53, 0.0)], [0.014, 0.009, 0.008], 6, 1.0, Callable()), pattes_m)
		for d in [-0.6, 0.0, 0.6]:
			_mesh(leg, BoxMesh.new(), pattes_m, Vector3(sin(d) * 0.04, -0.545, cos(d) * 0.04), Vector3(0.006, 0.005, 0.08), Vector3(0, d, 0))
		legs.append(leg)
	_pivots["pattes"] = legs
	# le poisson qu'il attrape
	var poisson := Node3D.new()
	poisson.name = "Poisson"
	head.add_child(poisson)
	poisson.position = Vector3(0, -0.01, 0.17)
	_mesh(poisson, _unit_sphere(), _mat(Color(0.75, 0.78, 0.8), 0.25), Vector3.ZERO, Vector3(0.012, 0.02, 0.05), Vector3(0, PI * 0.5, 0))
	poisson.visible = false
	_pivots["poisson"] = poisson


## L'écureuil roux : roux vif, le ventre crème, les pinceaux au bout des oreilles, la grande queue
## en panache relevée sur le dos.
func _build_ecureuil() -> void:
	var ventre := func(s: float, ang: float) -> float:
		return 0.85 + 0.15 * smoothstep(0.0, -0.8, sin(ang)) + 0.05 * sin(s * 41.0 + ang * 7.0) + (0.6 if sin(ang) < -0.75 else 0.0)
	var fur := _vmat(Color(0.66, 0.3, 0.11), 0.95)
	_build_mammal({"long": 0.2, "haut": 0.14, "rayon": 0.045, "mat": fur, "shade": ventre, "museau": 0.02, "bout": 0.25,
		"crane": 0.75, "oreille": 0.65, "forme_oreille": "pointe", "ecart": 0.15, "queue": 0.24, "style": "dressee", "touffe": 1.35,
		"patte": 0.2, "pied": 1.0, "cou": 0.6, "port": 0.8, "taille": 0.9, "segs": 12, "oeil": 0.32, "sombre": Color(0.05, 0.03, 0.02),
		"dedans": Color(0.7, 0.4, 0.3), "teinte": 0.95})
	var head: Node3D = _pivots["tete"]
	var noir := _mat(Color(0.25, 0.12, 0.05), 0.9)
	for ear in head.get_children():
		if str(ear.name).contains("Oreille") and ear is Node3D:
			_mesh(ear as Node3D, _cyl(0.0, 0.006, 0.03), noir, Vector3(0, 0.045, 0), Vector3.ONE)
	_mesh(head, _unit_sphere(), _mat(Color(0.9, 0.82, 0.68), 0.9), Vector3(0, -0.024, 0.03), Vector3(0.012, 0.007, 0.012))


## Le lézard des murailles : brun gris tacheté de sombre, le dos un peu vert, la longue queue fine.
func _build_lezard() -> void:
	var peau := _mat(Color(1, 1, 1), 0.6)
	peau.vertex_color_use_as_albedo = true
	peau.albedo_texture = _taches_tex("lezard140", Color(0.43, 0.41, 0.29), Color(0.11, 0.09, 0.06), 95, 2.0, 4.5, 1402)
	peau.uv1_triplanar = true
	peau.uv1_scale = Vector3(9.0, 9.0, 9.0)
	var dos := func(s: float, ang: float) -> float:
		return 0.72 + 0.28 * smoothstep(-0.2, -0.9, sin(ang)) + 0.08 * sin(s * 60.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("lezard:corps", [Vector3(0, 0.012, -0.15), Vector3(0, 0.012, -0.08), Vector3(0, 0.014, -0.03), Vector3(0, 0.016, 0.02), Vector3(0, 0.017, 0.05), Vector3(0, 0.016, 0.075), Vector3(0, 0.013, 0.09)],
		[0.002, 0.005, 0.009, 0.012, 0.009, 0.009, 0.003], 8, 1.35, dos), peau)
	var noir := _mat(Color(0.03, 0.03, 0.03), 0.2)
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.007, 0.02, 0.072), Vector3.ONE * 0.0025)
	var pmat: StandardMaterial3D = _flat_of(peau, 0.8)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var z: float = 0.035 if i < 2 else -0.025
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.008, 0.012, z)
		body.add_child(leg)
		_put(leg, _tube_fn("lezard:patte", [Vector3.ZERO, Vector3(0.016, -0.002, 0.004), Vector3(0.022, -0.012, 0.01)], [0.003, 0.0025, 0.002], 5, 1.0, Callable()), pmat)
		leg.scale.x = sx2
		_legs.append([leg, sx2, i])


## La tortue d'Hermann : la carapace bombée aux écailles jaunes et noires, la tête et les pattes
## grises écailleuses.
func _build_tortue_terre() -> void:
	var shell := _mat(Color(1, 1, 1), 0.55)
	shell.albedo_texture = _hermann_tex()
	shell.uv1_triplanar = true
	shell.uv1_scale = Vector3(0.65, 0.65, 0.65)
	var peau := _mat(Color(0.55, 0.5, 0.36), 0.85)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_mesh(body, _unit_sphere(), shell, Vector3(0, 0.045, 0), Vector3(0.085, 0.065, 0.105))
	_mesh(body, _unit_sphere(), _mat(Color(0.78, 0.68, 0.38), 0.7), Vector3(0, 0.03, 0), Vector3(0.088, 0.02, 0.105))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.035, 0.09)
	body.add_child(head)
	_pivots["tete"] = head
	_put(head, _tube_fn("tortue_terre:cou", [Vector3(0, 0, -0.02), Vector3(0, 0.006, 0.02), Vector3(0, 0.012, 0.04)], [0.014, 0.013, 0.012], 6, 1.0, Callable()), peau)
	_mesh(head, _unit_sphere(), peau, Vector3(0, 0.016, 0.055), Vector3(0.017, 0.015, 0.024))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), _mat(Color(0.04, 0.03, 0.02), 0.2), Vector3(sx * 0.012, 0.022, 0.065), Vector3.ONE * 0.003)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.06, 0.03, 0.06 if i < 2 else -0.06)
		body.add_child(leg)
		_mesh(leg, _cyl(0.014, 0.016, 0.04), peau, Vector3(sx2 * 0.01, -0.012, 0.0), Vector3.ONE, Vector3(0, 0, sx2 * 0.4))
		_legs.append([leg, sx2, i])
	var tail := Node3D.new()
	tail.position = Vector3(0, 0.03, -0.1)
	body.add_child(tail)
	_pivots["queue"] = tail
	_mesh(tail, _cyl(0.008, 0.0, 0.03), peau, Vector3(0, 0, -0.012), Vector3.ONE, Vector3(-PI * 0.5, 0, 0))


## Les guêpiers d'Europe : cinq oiseaux de toutes les couleurs (le dos châtain et or, la gorge jaune
## cerclée de noir, le ventre turquoise, le bandeau noir sur l'œil, le bec noir arqué, la queue
## pointue aux deux brins).
func _build_guepiers() -> void:
	var turq := _vmat(Color(0.2, 0.64, 0.68), 0.6)
	var chat := _mat(Color(0.55, 0.23, 0.09), 0.7)
	var or_m := _mat(Color(0.88, 0.68, 0.2), 0.6)
	var jaune := _mat(Color(0.97, 0.86, 0.18), 0.6)
	var noir := _mat(Color(0.05, 0.05, 0.05), 0.5)
	var vert := _mat(Color(0.25, 0.55, 0.45), 0.55)
	for i in range(5):
		var b := Node3D.new()
		_visual.add_child(b)
		var corps := Node3D.new()
		b.add_child(corps)
		_put(corps, _tube_fn("guepier:corps", [Vector3(0, 0, -0.06), Vector3(0, 0.003, -0.01), Vector3(0, 0.005, 0.04)], [0.012, 0.022, 0.018], 8, 1.0, Callable()), turq)
		_mesh(corps, _unit_sphere(), chat, Vector3(0, 0.014, 0.02), Vector3(0.016, 0.01, 0.035))
		_mesh(corps, _unit_sphere(), or_m, Vector3(0, 0.016, -0.03), Vector3(0.014, 0.008, 0.03))
		var head := Node3D.new()
		head.position = Vector3(0, 0.008, 0.055)
		corps.add_child(head)
		_mesh(head, _unit_sphere(), chat, Vector3.ZERO, Vector3(0.015, 0.015, 0.018))
		_mesh(head, _unit_sphere(), jaune, Vector3(0, -0.008, 0.006), Vector3(0.012, 0.009, 0.012))
		_mesh(head, _unit_sphere(), noir, Vector3(0, -0.012, -0.002), Vector3(0.013, 0.003, 0.008))
		for sx in [-1.0, 1.0]:
			_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.012, 0.002, 0.004), Vector3(0.004, 0.004, 0.012))
		_put(head, _tube_fn("guepier:bec", [Vector3(0, 0, 0.012), Vector3(0, -0.002, 0.03), Vector3(0, -0.008, 0.045)], [0.004, 0.0025, 0.0008], 5, 1.0, Callable()), noir)
		_put(corps, _tube_fn("guepier:queue", [Vector3(0, 0, -0.06), Vector3(0, 0, -0.1), Vector3(0, 0, -0.14)], [0.008, 0.006, 0.0015], 4, 3.0, Callable()), vert)
		var ws: Array = []
		for sx in [-1.0, 1.0]:
			var w := Node3D.new()
			w.position = Vector3(sx * 0.014, 0.01, 0.01)
			corps.add_child(w)
			_mesh(w, _unit_sphere(), vert, Vector3(sx * 0.05, 0.0, -0.01), Vector3(0.055, 0.004, 0.02))
			_mesh(w, _unit_sphere(), chat, Vector3(sx * 0.025, 0.002, 0.0), Vector3(0.028, 0.004, 0.016))
			ws.append([w, sx])
		_bande.append([b, randf() * TAU, Vector3(randf_range(-2.0, 2.0), randf_range(-0.8, 0.8), randf_range(-2.0, 2.0)), corps, head, ws, 0.0])


# =================================================================== sons, coups

func _sound(what: String) -> void:
	if not SPECS140.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS140.get(kind, ["", ""])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * 0.3)


func alert_text() -> String:
	if SPECS140.has(kind):
		return ""
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS140.has(kind):
		return super.loot(rng)
	return []


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS140.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	# on ne leur fait pas de mal : elles s'enfuient (le coq, lui, contre-attaque)
	_flash = 0.12
	match kind:
		"poule":
			_affole(from_pos)
			if _coq_cd <= 0.0:
				_coq_fonce()
		"heron":
			if not state in ["envol", "vol", "atterrit"]:
				_envol_heron(from_pos)
		"ecureuil":
			if not state in ["grimpe", "perche"]:
				_file_ecureuil()
		"lezard":
			_file_lezard(from_pos)
		"tortue_terre":
			if state != "rentree":
				_rentre()
		"guepier":
			_orbit_c = global_position + (global_position - from_pos).normalized() * 12.0
			_orbit_c.y = 0.0
		"compsognathe":
			_sound("menace")
			if butin != "" and manager.has_method("chapardeur_lache"):
				manager.chapardeur_lache(self)
			manager.release_token(self)
			state = "detale"
			timer = 2.5
			fuites += 1
		"archeopteryx":
			if state == "perche":
				_decolle(from_pos)
		"meganeura":
			_file_libellule(from_pos)


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES140):
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
	match genre:
		"basse_cour":
			_basse_cour(delta, p, dist, dir_p)
		"echassier":
			_heron(delta, p, dist)
		"grimpeur":
			if _ecureuil(delta, p, dist, dir_p, sp):
				return
		"lezard":
			_lezard(delta, dist, dir_p, sp)
		"rentreuse":
			_tortue(delta, dist, sp)
		"voltigeur":
			_guepiers(delta, p, dist)
		"compso":
			_compso(delta, p, dist, dir_p, hero_dir, sp)
			return
		"perche":
			_archeo(delta, p, dist)
		"libellule":
			_libellule(delta, p, dist)
	_animate132(delta, 0.0)


## Marcher (sans moteur physique) : on suit le sol, on ne va ni dans le vide ni dans la mer.
func _marche140(delta: float, move: Vector3) -> void:
	if move.length() > 0.001:
		var to: Vector3 = global_position + move * delta
		var ahead: Vector3 = global_position + move.normalized() * 0.6
		if _au_vide(ahead) or _ground_at(ahead) < 0.15 or absf(_ground_at(ahead) - _ground_at(global_position)) > 1.2:
			_wander_to = Vector3.INF
			return
		global_position.x = to.x
		global_position.z = to.z
	global_position.y = _ground_at(global_position)


# ------------------------------------------------------------------- la basse-cour

func _basse_cour(delta: float, p: Vector3, dist: float, dir_p: Vector3) -> void:
	_coq_cd -= delta
	global_position.y = _ground_at(global_position)
	# le coq chante à l'aube
	var tm: Node = manager.main.get("temps_v56") if manager.main != null else null
	if tm != null and _coq_i >= 0:
		var h: float = float(tm.get("hour"))
		_chant_t -= delta
		if h > 5.3 and h < 8.0 and _chant_t <= 0.0 and dist < 80.0 and state == "picore":
			_chant_t = randf_range(25.0, 40.0)
			state = "chante"
			timer = 2.2
			chants += 1
			if manager.main.has_method("sfx"):
				manager.main.sfx("coq_chante", global_position + Vector3.UP * 0.5)
	match state:
		"picore", "chante":
			if state == "chante" and timer <= 0.0:
				state = "picore"
			# elles se promènent un peu, en picorant
			if fmod(_clock + _flank * 7.0, 9.0) < delta:
				_sound("menace")
			if dist < float(spec["vue"]) or (_hero_v > 3.2 and dist < 7.0):
				_affole(p)
			elif dist < 4.5 and _coq_cd <= 0.0:
				_calm_t += delta
				if _calm_t > 4.0:
					_calm_t = 0.0
					_coq_fonce()
			else:
				_calm_t = 0.0
		"affole":
			if timer <= 0.0:
				state = "picore"
				# le centre de la basse-cour a un peu bougé, loin du héros
				var away: Vector3 = -dir_p
				var q: Vector3 = global_position + away * 2.5
				if not _au_vide(q) and _ground_at(q) > 0.3 and absf(_ground_at(q) - global_position.y) < 1.0:
					global_position = Vector3(q.x, _ground_at(q), q.z)
		"coq_fonce", "coq_retour":
			if timer <= 0.0:
				state = "picore"
		_:
			state = "picore"


## Elles s'égaillent en caquetant, en battant des ailes.
func _affole(from: Vector3) -> void:
	if state == "affole":
		return
	state = "affole"
	timer = 2.6
	fuites += 1
	_sound("menace")
	_cible = from


## Le coq fonce sur le héros, les ailes ouvertes, et le chasse d'un coup de bec.
func _coq_fonce() -> void:
	if _coq_i < 0:
		return
	state = "coq_fonce"
	timer = 3.5
	_coq_cd = 25.0
	charges += 1
	if manager.main != null and manager.main.has_method("sfx"):
		manager.main.sfx("poule_caquette", global_position + Vector3.UP * 0.4)


# ------------------------------------------------------------------- le héron

func _etang() -> Array:
	return manager.etang_de(ile_sol) if manager != null and manager.has_method("etang_de") else []


func _r_etang(et: Array, dir: Vector3) -> float:
	if et.size() >= 3:
		var ax: float = float(et[1])
		var az: float = float(et[2])
		return 1.0 / sqrt(pow(dir.x / ax, 2.0) + pow(dir.z / az, 2.0) + 1e-9)
	return float(et[1]) if et.size() >= 2 else 6.0


## Un point de la rive, dans l'eau peu profonde (un héron s'y tient) ; loin de « loin_de ».
func _rive(et: Array, loin_de: Vector3) -> Vector3:
	var best := Vector3.INF
	var bd: float = -1.0
	for k in range(14):
		var a: float = randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		var c: Vector3 = et[0]
		var q: Vector3 = c + d * (_r_etang(et, d) - 1.2)
		var dd: float = Vector2(q.x - loin_de.x, q.z - loin_de.z).length()
		if dd > bd and dd < 90.0:
			bd = dd
			best = Vector3(q.x, _ground_at(q), q.z)
	return best


func _heron(delta: float, p: Vector3, dist: float) -> void:
	var poisson: Node3D = _pivots.get("poisson")
	match state:
		"guette", "frappe":
			global_position.y = _ground_at(global_position)
			if state == "frappe" and timer <= 0.0:
				state = "guette"
				timer = randf_range(6.0, 12.0)
				if poisson != null:
					poisson.visible = false
			elif state == "guette" and timer <= 0.0:
				# un coup de bec dans l'eau : un poisson, une fois sur deux
				state = "frappe"
				timer = 1.6
				if randf() < 0.5:
					peches += 1
					if poisson != null:
						poisson.visible = true
			elif state == "guette" and fmod(_clock + _flank * 5.0, 7.0) < delta:
				# un pas lent le long de la rive
				var et: Array = _etang()
				if not et.is_empty():
					var c: Vector3 = et[0]
					var radial: Vector3 = Vector3(global_position.x - c.x, 0, global_position.z - c.z).normalized()
					var tang := Vector3(-radial.z, 0, radial.x) * (1.0 if _flank > 0.0 else -1.0)
					var q: Vector3 = c + (radial * cos(0.01) + tang * sin(0.01)).normalized() * (_r_etang(et, radial) - 1.2)
					q = global_position + (q - global_position).limit_length(0.4)
					global_position = Vector3(q.x, _ground_at(q), q.z)
					facing = tang
			if dist < float(spec["vue"]) or (_hero_v > 3.5 and dist < 25.0):
				_envol_heron(p)
		"envol", "vol":
			var to: Vector3 = _cible - global_position
			to.y = 0.0
			var target: Vector3 = _cible
			target.y = maxf(_cible.y, _plancher(global_position)) + (4.0 if to.length() > 8.0 else 1.5)
			_voler137(delta, target, float(spec["vitesse"]) * (0.6 if state == "envol" else 1.0), 1.2)
			if state == "envol" and timer <= 0.0:
				state = "vol"
			if to.length() < 6.0:
				state = "atterrit"
				timer = 3.0
		"atterrit":
			var d2: Vector3 = _cible - global_position
			global_position += d2.limit_length(2.2 * delta)
			_visual.rotation = _visual.rotation.lerp(Vector3.ZERO, clampf(delta * 3.0, 0.0, 1.0))
			if d2.length() < 0.15 or timer <= 0.0:
				global_position = _cible
				_visual.rotation = Vector3.ZERO
				state = "guette"
				timer = randf_range(6.0, 12.0)
				home = _cible
				var et2: Array = _etang()
				if not et2.is_empty():
					var c2: Vector3 = et2[0]
					facing = Vector3(c2.x - global_position.x, 0, c2.z - global_position.z).normalized()
		_:
			state = "guette"
	rotation.y = atan2(facing.x, facing.z)


func _envol_heron(from: Vector3) -> void:
	state = "envol"
	timer = 1.2
	envols += 1
	_sound("menace")
	var poisson: Node3D = _pivots.get("poisson")
	if poisson != null:
		poisson.visible = false
	var et: Array = _etang()
	var q := Vector3.INF
	if not et.is_empty():
		q = _rive(et, from)
	if q == Vector3.INF:
		var away: Vector3 = Vector3(global_position.x - from.x, 0, global_position.z - from.z).normalized()
		q = global_position + away * 30.0
		q.y = _ground_at(q)
	_cible = q
	var d: Vector3 = Vector3(q.x - global_position.x, 0, q.z - global_position.z)
	if d.length() > 0.1:
		facing = d.normalized()
	velocity = Vector3.UP * 2.0 + facing * 1.0


# ------------------------------------------------------------------- l'écureuil

## Renvoie vrai s'il a fini son tour (il ne marche pas comme les autres : il grimpe).
func _ecureuil(delta: float, p: Vector3, dist: float, dir_p: Vector3, sp: float) -> bool:
	var vue: float = float(spec["vue"])
	match state:
		"fouille":
			var move: Vector3 = _wander(delta, sp) * 0.5
			# il avance par bonds, et s'arrête pour grignoter
			if fmod(_clock * 2.2, 1.0) > 0.55:
				move *= 0.0
			_marche140(delta, move)
			if dist < vue or (_hero_v > 3.0 and dist < 12.0):
				_file_ecureuil()
		"court":
			if _tronc == Vector3.INF:
				state = "fuite"
				timer = 2.5
			else:
				var to: Vector3 = Vector3(_tronc.x - global_position.x, 0, _tronc.z - global_position.z)
				if to.length() <= _tronc_r + 0.25 or timer <= 0.0:
					state = "grimpe"
					grimpes += 1
					_grimpe_h = 0.0
					facing = to.normalized() if to.length() > 0.01 else facing
				else:
					facing = facing.lerp(to.normalized(), clampf(delta * 10.0, 0.0, 1.0)).normalized()
					var g0: Vector3 = global_position + facing * sp * delta
					global_position = Vector3(g0.x, _ground_at(g0), g0.z)
		"grimpe":
			_grimpe_h = minf(_grimpe_h + delta * 2.6, 3.4)
			_colle_au_tronc(_grimpe_h)
			if _grimpe_h >= 3.4:
				state = "perche"
				_parti_t = 0.0
		"perche":
			_colle_au_tronc(_grimpe_h)
			if dist < vue * 1.4 and fmod(_clock, 2.4) < delta:
				_sound("menace")
			if dist > vue * 1.5:
				_parti_t += delta
				if _parti_t > 4.0:
					state = "descend"
			else:
				_parti_t = 0.0
		"descend":
			_grimpe_h = maxf(_grimpe_h - delta * 1.8, 0.0)
			_colle_au_tronc(_grimpe_h)
			if _grimpe_h <= 0.0:
				state = "fouille"
				var out: Vector3 = Vector3(global_position.x - _tronc.x, 0, global_position.z - _tronc.z).normalized()
				var q: Vector3 = Vector3(_tronc.x, 0, _tronc.z) + out * (_tronc_r + 0.35)
				global_position = Vector3(q.x, _ground_at(q), q.z)
				home = global_position
				facing = out
		"fuite":
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			_marche140(delta, facing * sp)
			if timer <= 0.0:
				state = "fouille"
				home = global_position
		_:
			state = "fouille"
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, sp if state in ["court", "fuite"] else (0.5 if state == "fouille" else 0.0))
	return true


func _file_ecureuil() -> void:
	var t: Array = manager.tronc_pres(global_position, 16.0) if manager.has_method("tronc_pres") else []
	_sound("menace")
	if t.is_empty():
		_tronc = Vector3.INF
		state = "fuite"
		timer = 2.5
		fuites += 1
		return
	_tronc = t[0]
	_tronc_r = float(t[1])
	state = "court"
	timer = 6.0


## Collé au tronc, la tête en haut (ou en bas quand il redescend), à la hauteur h.
func _colle_au_tronc(h: float) -> void:
	var out: Vector3 = Vector3(global_position.x - _tronc.x, 0, global_position.z - _tronc.z)
	out = out.normalized() if out.length() > 0.01 else Vector3.FORWARD
	var q: Vector3 = Vector3(_tronc.x, 0, _tronc.z) + out * (_tronc_r + 0.07)
	global_position = Vector3(q.x, _ground_at(Vector3(_tronc.x, 0, _tronc.z)) + h, q.z)
	facing = -out


# ------------------------------------------------------------------- le lézard

func _lezard(delta: float, dist: float, dir_p: Vector3, sp: float) -> void:
	match state:
		"soleil":
			global_position.y = _ground_at(global_position)
			if dist < float(spec["vue"]) or (_hero_v > 3.0 and dist < 7.0):
				_file_lezard(global_position + dir_p * dist)
		"file":
			# en zigzag, très vite
			var zig := Vector3(-_cible.z, 0, _cible.x) * sin(_clock * 18.0) * 0.6
			facing = (_cible + zig).normalized()
			_marche140(delta, facing * sp)
			if timer <= 0.0:
				state = "cache"
				timer = randf_range(8.0, 12.0)
				caches += 1
				_visual.visible = false
		"cache":
			if timer <= 0.0 and dist > 4.0:
				# il ressort un peu plus loin
				var a: float = randf() * TAU
				var q: Vector3 = global_position + Vector3(cos(a), 0, sin(a)) * randf_range(0.8, 2.0)
				if not _au_vide(q) and _ground_at(q) > 0.3:
					global_position = Vector3(q.x, _ground_at(q), q.z)
				_visual.visible = true
				state = "soleil"
		_:
			state = "soleil"
	rotation.y = atan2(facing.x, facing.z)


func _file_lezard(from: Vector3) -> void:
	if state in ["file", "cache"]:
		return
	var away: Vector3 = Vector3(global_position.x - from.x, 0, global_position.z - from.z)
	_cible = away.normalized() if away.length() > 0.05 else -facing
	state = "file"
	timer = 0.8
	fuites += 1


# ------------------------------------------------------------------- la tortue d'Hermann

func _tortue(delta: float, dist: float, sp: float) -> void:
	match state:
		"broute":
			_marche140(delta, _wander(delta, sp / 0.35 * 1.0) * 0.6)
			if dist < float(spec["vue"]):
				_rentre()
		"rentree":
			global_position.y = _ground_at(global_position)
			if dist > float(spec["vue"]) + 1.2:
				_parti_t += delta
				if _parti_t > 5.0:
					state = "ressort"
					timer = 1.5
			else:
				_parti_t = 0.0
		"ressort":
			if dist < float(spec["vue"]):
				_rentre()
			elif timer <= 0.0:
				state = "broute"
		_:
			state = "broute"
	rotation.y = atan2(facing.x, facing.z)


func _rentre() -> void:
	state = "rentree"
	_parti_t = 0.0
	rentrees += 1
	_sound("menace")


# ------------------------------------------------------------------- les guêpiers

func _guepiers(delta: float, p: Vector3, dist: float) -> void:
	# quand le héros marche dans le maquis, ils le suivent : il dérange les insectes
	var hd: float = Vector2(p.x - _orbit_c.x, p.z - _orbit_c.z).length()
	if _hero_v > 0.8 and hd < float(spec["vue"]):
		if state != "suit":
			state = "suit"
		_orbit_c = _orbit_c.lerp(Vector3(p.x, 0, p.z), clampf(delta * 0.8, 0.0, 1.0))
		timer = 6.0
	elif state == "suit" and timer <= 0.0:
		state = "chasse"
	_orbit_a += delta * (0.55 if state == "suit" else 0.35)
	var rr: float = (5.0 if state == "suit" else 9.0) + _flank * 1.5
	var target: Vector3 = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
	target.y = _plancher(target) + (3.5 if state == "suit" else _alt)
	_voler137(delta, target, float(spec["vitesse"]) * 0.7, 1.5)
	if fmod(_clock + _flank * 3.0, 4.5) < delta and dist < 40.0:
		_sound("menace")
	# un plongeon sur un insecte, de temps en temps (près du héros quand ils le suivent)
	for e in _bande:
		var u: float = float(e[6])
		if u <= 0.0 and randf() < delta * (0.6 if state == "suit" else 0.15):
			e[6] = 1.0
			if state == "suit":
				captures += 1


# ------------------------------------------------------------------- les compsognathes

func _compso(delta: float, p: Vector3, dist: float, dir_p: Vector3, hero_dir: Vector3, sp: float) -> void:
	var vue: float = float(spec["vue"])
	var move := Vector3.ZERO
	var nuit: bool = manager.has_method("night") and bool(manager.night())
	# le héros court droit sur eux : ils détalent
	if state in ["rode", "suit", "approche"] and _hero_v > 3.5 and dist < 5.0 and hero_dir.dot(-dir_p) > 0.4:
		manager.release_token(self)
		state = "detale"
		timer = 2.2
		fuites += 1
		_sound("menace")
	match state:
		"rode":
			move = _wander(delta, sp) * 0.6
			if nuit and dist > 5.0:
				state = "dort"
			elif dist < vue:
				state = "suit"
				_sound("menace")
		"dort":
			if dist < 3.0:
				state = "detale"
				timer = 2.2
				fuites += 1
				_sound("menace")
			elif not nuit:
				state = "rode"
		"suit":
			# en petite bande autour du héros, à trois ou quatre mètres
			var side := Vector3(-dir_p.z, 0, dir_p.x)
			var ring: Vector3 = p - dir_p * (3.6 + _flank * 0.6) + side * _flank * 2.2
			var to: Vector3 = ring - global_position
			to.y = 0.0
			if to.length() > 0.4:
				move = to.normalized() * sp * clampf(to.length() / 3.0, 0.3, 1.2)
				facing = facing.lerp(move.normalized(), clampf(delta * 8.0, 0.0, 1.0)).normalized()
			else:
				facing = facing.lerp(dir_p, clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if fmod(_clock + _flank * 4.0, 5.0) < delta:
				_sound("menace")
			# le héros reste tranquille : le plus hardi vient lui chiper à manger
			if _hero_v < 0.4:
				_calm_t += delta
				if _calm_t > 2.5 and manager.has_method("peut_chaparder") and manager.peut_chaparder() and manager.take_token(self):
					state = "approche"
					timer = 6.0
			else:
				_calm_t = 0.0
			if dist > vue * 2.0:
				state = "rode"
				home = global_position
		"approche":
			move = dir_p * sp * 1.1
			facing = facing.lerp(dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			if dist < 1.0:
				if manager.chapardeur_vole(self):
					steals += 1
					state = "emporte"
					timer = 6.0
				else:
					state = "detale"
					timer = 2.0
				manager.release_token(self)
			elif timer <= 0.0:
				manager.release_token(self)
				state = "suit"
		"emporte":
			move = -dir_p * sp * 1.4
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				manager.chapardeur_garde(self)
				home = global_position
				state = "rode"
		"detale":
			move = -dir_p * sp * 1.5
			facing = facing.lerp(-dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "rode"
				home = global_position
		_:
			state = "rode"
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 0.6
		if _au_vide(ahead) or (_ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead)) or (manager.has_method("lave") and manager.lave(ahead, ile_sol)):
			move = -move * 0.3
			_wander_to = Vector3.INF
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


# ------------------------------------------------------------------- l'archéoptéryx

func _archeo(delta: float, p: Vector3, dist: float) -> void:
	match state:
		"perche":
			if _arbre == Vector3.INF:
				var a: Vector3 = manager.arbre_pres(global_position, 0.0, 30.0, Vector3.INF) if manager.has_method("arbre_pres") else Vector3.INF
				if a == Vector3.INF:
					state = "sol"
				else:
					_arbre = a
					global_position = a
			else:
				global_position = _arbre
			if timer <= 0.0:
				timer = randf_range(8.0, 15.0)
				if dist < 40.0:
					_sound("menace")
			var hd: float = Vector2(p.x - global_position.x, p.z - global_position.z).length()
			if hd < float(spec["vue"]) and p.y < global_position.y:
				_decolle(p)
		"plane":
			var target: Vector3 = _cible
			var to: Vector3 = _cible - global_position
			if to.length() > 6.0:
				target.y = maxf(_cible.y, global_position.y - 2.0) + 1.0
			_voler137(delta, target, float(spec["vitesse"]), 1.5)
			if to.length() < 0.5 or timer <= 0.0:
				global_position = _cible
				_arbre = _cible
				_visual.rotation = Vector3.ZERO
				state = "perche"
				timer = randf_range(4.0, 8.0)
		"sol":
			# pas d'arbre : il sautille par terre, et s'envole un peu plus loin si on approche
			global_position.y = _ground_at(global_position)
			if dist < float(spec["vue"]) * 0.6:
				_decolle(p)
		_:
			state = "perche"
	rotation.y = atan2(facing.x, facing.z)


func _decolle(from: Vector3) -> void:
	var a: Vector3 = Vector3.INF
	if manager.has_method("arbre_pres"):
		a = manager.arbre_pres(global_position, 12.0, 40.0, from)
	if a == Vector3.INF:
		var away: Vector3 = Vector3(global_position.x - from.x, 0, global_position.z - from.z).normalized()
		a = global_position + away * 18.0
		a.y = _ground_at(a)
	_cible = a
	state = "plane"
	timer = 12.0
	planes += 1
	_sound("menace")
	var d: Vector3 = Vector3(a.x - global_position.x, 0, a.z - global_position.z)
	if d.length() > 0.1:
		facing = d.normalized()


# ------------------------------------------------------------------- la meganeura

func _libellule(delta: float, p: Vector3, dist: float) -> void:
	var et: Array = _etang()
	var c: Vector3 = et[0] if not et.is_empty() else home
	var r: float = _r_etang(et, Vector3.FORWARD) if not et.is_empty() else 8.0
	_fil -= delta
	match state:
		"patrouille":
			if _vise == Vector3.INF or _fil <= 0.0:
				# une nouvelle envolée, droit vers un autre point au-dessus de l'eau
				var a: float = randf() * TAU
				_vise = c + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, r * 0.85)
				_vise.y = c.y + randf_range(0.8, 2.0)
				_fil = randf_range(1.5, 3.5)
			_vole_libellule(delta, _vise)
			var hc: float = Vector2(p.x - c.x, p.z - c.z).length()
			if hc < r + 10.0 and _hero_v < 0.5 and dist < 22.0:
				_calm_t += delta
				if _calm_t > 1.5:
					_calm_t = 0.0
					state = "inspecte"
					timer = 6.0
					_vise = Vector3.INF
			else:
				_calm_t = 0.0
		"inspecte":
			# elle vient voir le héros de tout près, devant son visage
			var eye: Vector3 = p + Vector3.UP * 1.45
			if _vise == Vector3.INF or Vector2(_vise.x - eye.x, _vise.z - eye.z).length() > 1.6:
				var face: Vector3 = Vector3(global_position.x - p.x, 0, global_position.z - p.z)
				face = face.normalized() if face.length() > 0.05 else Vector3.FORWARD
				_vise = eye + face * 1.0
			var spot: Vector3 = _vise
			_vole_libellule(delta, spot, 3.0)
			var vers_oeil: Vector3 = Vector3(eye.x - global_position.x, 0, eye.z - global_position.z)
			if vers_oeil.length() > 0.05:
				facing = vers_oeil.normalized()
			if global_position.distance_to(spot) < 0.4 and timer > 1.6:
				timer = 1.6
				inspections += 1
				_sound("menace")
			if timer <= 0.0 or _hero_v > 2.0:
				_file_libellule(p)
		"file":
			_vole_libellule(delta, _vise)
			if _fil <= 0.0:
				state = "patrouille"
				_vise = Vector3.INF
		_:
			state = "patrouille"
	rotation.y = atan2(facing.x, facing.z)


func _vole_libellule(delta: float, target: Vector3, gain: float = 1.0) -> void:
	var to: Vector3 = target - global_position
	var v: Vector3 = to.normalized() * minf(float(spec["vitesse"]), to.length() * gain) if to.length() > 0.001 else Vector3.ZERO
	velocity = velocity.lerp(v, clampf(delta * 5.0, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _plancher(global_position)
	if global_position.y < g + 0.4:
		global_position.y = g + 0.4
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.5:
		facing = facing.lerp(hv.normalized(), clampf(delta * 8.0, 0.0, 1.0)).normalized()


func _file_libellule(from: Vector3) -> void:
	var et: Array = _etang()
	var c: Vector3 = et[0] if not et.is_empty() else home
	var r: float = _r_etang(et, Vector3.FORWARD) if not et.is_empty() else 8.0
	var away: Vector3 = Vector3(c.x - from.x, 0, c.z - from.z)
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	_vise = c + away * r * 0.7
	_vise.y = c.y + 1.5
	state = "file"
	_fil = 2.5


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS140.has(kind):
		super._animate132(delta, speed)
		return
	match kind:
		"poule":
			_anim_basse_cour(delta)
		"heron":
			_anim_heron(delta)
		"ecureuil":
			_anim_ecureuil(delta, speed)
		"lezard":
			_anim_lezard()
		"tortue_terre":
			_anim_tortue_terre(delta)
		"guepier":
			_anim_guepiers(delta)
		"compsognathe":
			_anim_compso(delta, speed)
		"archeopteryx":
			_anim_archeo()
		"meganeura":
			_anim_libellule()


func _anim_basse_cour(delta: float) -> void:
	var t: float = _clock
	var p: Vector3 = _player() if manager != null and manager.main != null else Vector3.INF
	var lp: Vector3 = to_local(p) if p != Vector3.INF else Vector3.ZERO
	lp.y = 0.0
	for e in _bande:
		var b: Node3D = e[0]
		var ph: float = e[1]
		var place: Vector3 = e[2]
		var parts: Dictionary = e[3]
		var coq: bool = e[4]
		var target: Vector3 = place + Vector3(sin(t * 0.3 + ph) * 0.5, 0, cos(t * 0.23 + ph) * 0.5)
		var vite: float = 0.6
		var flap: float = 0.0
		var peck: float = maxf(0.0, sin(t * 3.0 + ph)) * 0.9
		if state == "affole":
			var away: Vector3 = place - (to_local(_cible) if _cible != Vector3.INF else Vector3.ZERO)
			away.y = 0.0
			target = place + (away.normalized() if away.length() > 0.05 else place.normalized()) * 2.6
			vite = 3.2
			flap = 1.0
			peck = 0.0
		elif coq and state == "coq_fonce":
			# il fonce, les ailes ouvertes ; arrivé au héros, un coup de bec
			var vers: Vector3 = lp - b.position
			target = lp - (vers.normalized() if vers.length() > 0.05 else Vector3.FORWARD) * 0.45
			vite = 3.0
			flap = 0.6
			peck = 0.0
			if b.position.distance_to(target) < 0.25 and timer > 0.6:
				timer = 0.6
				coups_de_bec += 1
				var shove_dir: Vector3 = global_transform.basis * (vers.normalized() if vers.length() > 0.05 else Vector3.FORWARD)
				shove_dir.y = 0.0
				manager.shove(shove_dir.normalized() * 2.2)
				_texte("Le coq défend ses poules !", Color(1.0, 0.85, 0.6))
				if manager.main != null and manager.main.has_method("sfx"):
					manager.main.sfx("poule_caquette", global_position + Vector3.UP * 0.4)
		elif state == "chante" and coq:
			peck = -0.7
		var old: Vector3 = b.position
		b.position = old + (target - old).limit_length(vite * delta)
		var mv: Vector3 = b.position - old
		var gy: float = 0.0
		if manager != null:
			gy = _ground_at(b.global_position) - global_position.y
		b.position.y = gy
		var moving: bool = mv.length() > 0.002
		if moving:
			b.rotation.y = lerp_angle(b.rotation.y, atan2(mv.x, mv.z), 0.25)
		elif coq and state == "coq_fonce":
			b.rotation.y = lerp_angle(b.rotation.y, atan2(lp.x - b.position.x, lp.z - b.position.z), 0.3)
		var cou: Node3D = parts["cou"]
		cou.rotation.x = lerpf(cou.rotation.x, peck * 1.1 if not moving else 0.1, clampf(delta * 10.0, 0.0, 1.0))
		for w in parts["ailes"]:
			var wn: Node3D = w[0]
			var sx: float = w[1]
			wn.rotation.z = sx * (flap * (0.5 + 0.7 * absf(sin(t * 22.0 + ph))))
		var legs: Array = parts["pattes"]
		for li in range(legs.size()):
			(legs[li] as Node3D).rotation.x = sin(t * 14.0 + float(li) * PI) * 0.5 if moving else 0.0
		(parts["corps"] as Node3D).position.y = absf(sin(t * 7.0 + ph)) * 0.015 if moving else 0.0


func _anim_heron(delta: float) -> void:
	var t: float = _clock
	var en_vol: bool = state in ["envol", "vol"]
	var neck: Node3D = _pivots.get("cou")
	var head: Node3D = _pivots.get("tete")
	var body: Node3D = _pivots.get("corps")
	# en vol : le cou replié en S, les pattes tendues vers l'arrière, de lents battements
	for e in _wings:
		var w: Node3D = e[0]
		var sx: float = e[1]
		if en_vol or state == "atterrit":
			var amp: float = 0.55 if state == "envol" else (0.35 if state == "vol" else 0.45)
			w.rotation.y = lerpf(w.rotation.y, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			w.rotation.z = sx * sin(t * (6.0 if state == "envol" else 3.2)) * amp
		else:
			w.rotation.y = lerpf(w.rotation.y, sx * 1.5, clampf(delta * 6.0, 0.0, 1.0))
			w.rotation.z = lerpf(w.rotation.z, 0.0, clampf(delta * 6.0, 0.0, 1.0))
		# repliée, l'aile est trois fois moins longue
		w.scale.x = lerpf(w.scale.x, 1.0 if (en_vol or state == "atterrit") else 0.42, clampf(delta * 6.0, 0.0, 1.0))
	if neck != null:
		var nx: float = 0.0
		if en_vol:
			nx = -0.9
		elif state == "frappe":
			var u: float = clampf(1.6 - timer, 0.0, 1.6)
			nx = 1.2 * sin(clampf(u / 0.5, 0.0, 1.0) * PI) if u < 0.5 else 0.0
		neck.rotation.x = lerpf(neck.rotation.x, nx, clampf(delta * (14.0 if state == "frappe" else 4.0), 0.0, 1.0))
	if head != null:
		head.rotation.x = 0.9 if en_vol else (0.3 if state == "frappe" else 0.0)
	var legs: Array = _pivots.get("pattes", [])
	for lg in legs:
		(lg as Node3D).rotation.x = lerpf((lg as Node3D).rotation.x, -1.3 if en_vol else 0.0, clampf(delta * 4.0, 0.0, 1.0))
	if body != null:
		body.rotation.x = lerpf(body.rotation.x, 0.25 if en_vol else 0.0, clampf(delta * 3.0, 0.0, 1.0))


func _anim_ecureuil(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var t: float = _clock
	var body: Node3D = _pivots.get("corps")
	var tail: Node3D = _pivots.get("queue")
	# sur le tronc, à la verticale (la tête en haut, ou en bas quand il redescend)
	var vert: float = 0.0
	if state in ["grimpe", "perche"]:
		vert = -PI * 0.5
	elif state == "descend":
		vert = PI * 0.5
	_visual.rotation.x = lerpf(_visual.rotation.x, vert, clampf(delta * 10.0, 0.0, 1.0))
	if state == "fouille" and speed < 0.1 and body != null:
		# assis, il grignote
		_stand = lerpf(_stand, 1.0, clampf(delta * 6.0, 0.0, 1.0))
	else:
		_stand = lerpf(_stand, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	if body != null:
		var bas := Basis(Vector3.RIGHT, -0.9 * _stand)
		var pv := Vector3(0, 0.03, -0.08)
		body.transform = Transform3D(bas, pv - bas * pv)
		if speed > 0.1 and state in ["fouille", "court", "fuite"]:
			body.position.y += absf(sin(t * 16.0)) * 0.03
	if tail != null:
		tail.rotation.x = sin(t * (9.0 if state == "perche" else 2.0)) * (0.25 if state == "perche" else 0.1)


func _anim_lezard() -> void:
	var t: float = _clock
	var body: Node3D = _pivots.get("corps")
	var moving: bool = state == "file"
	if body != null:
		body.rotation.y = sin(t * 30.0) * 0.25 if moving else 0.0
		# au soleil : il fait des « pompes » de temps en temps
		body.position.y = (absf(sin(t * 6.0)) * 0.006 if fmod(t + _flank * 5.0, 6.0) < 0.6 else 0.0) if state == "soleil" else 0.0
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		leg.rotation.y = sin(t * 30.0 + (0.0 if i in [0, 3] else PI)) * 0.6 if moving else 0.0


func _anim_tortue_terre(delta: float) -> void:
	var t: float = _clock
	var dedans: float = 1.0 if state == "rentree" else 0.0
	_crouch = lerpf(_crouch, dedans, clampf(delta * (8.0 if dedans > 0.5 else 1.5), 0.0, 1.0))
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.position = Vector3(0, 0.035, 0.09 - 0.07 * _crouch)
		head.scale = Vector3.ONE * (1.0 - 0.7 * _crouch)
		head.rotation.x = (0.25 + sin(t * 1.3) * 0.15) if state == "broute" else 0.0
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		leg.scale = Vector3.ONE * (1.0 - 0.75 * _crouch)
		leg.rotation.x = sin(t * 3.0 + (0.0 if i in [0, 3] else PI)) * 0.35 if state == "broute" else 0.0
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = -0.025 * _crouch


func _anim_guepiers(delta: float) -> void:
	var t: float = _clock
	for e in _bande:
		var b: Node3D = e[0]
		var ph: float = e[1]
		var place: Vector3 = e[2]
		var corps: Node3D = e[3]
		var u: float = float(e[6])
		var pos: Vector3 = place + Vector3(sin(t * 1.3 + ph) * 0.8, sin(t * 1.7 + ph) * 0.5, cos(t * 1.1 + ph) * 0.8)
		if u > 0.0:
			# le plongeon sur un insecte : il descend, claque du bec, remonte
			pos.y -= sin(u * PI) * 2.5
			e[6] = maxf(0.0, u - delta * 1.2)
		var old: Vector3 = b.position
		b.position = old.lerp(pos, 0.08)
		var mv: Vector3 = b.position - old
		if mv.length() > 0.0005:
			b.rotation.y = lerp_angle(b.rotation.y, atan2(mv.x, mv.z), 0.2)
		corps.rotation.x = clampf(-mv.y * 30.0, -0.6, 0.6)
		# des battements vifs, puis de longues glissades, ailes ouvertes
		var glisse: bool = fmod(t + ph, 2.4) > 1.4
		for w in e[5]:
			var wn: Node3D = w[0]
			var sx: float = w[1]
			wn.rotation.z = sx * (0.05 if glisse else sin(t * 20.0 + ph) * 0.8)


func _anim_compso(delta: float, speed: float) -> void:
	var t: float = _clock
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.0)
	var dort: bool = state == "dort"
	_crouch = lerpf(_crouch, 1.0 if dort else 0.0, clampf(delta * 3.0, 0.0, 1.0))
	var corps: Node3D = _vox.get("corps")
	var cou: Node3D = _vox.get("cou")
	var queue: Node3D = _vox.get("queue")
	_visual.position.y = -0.12 * _crouch
	if cou != null:
		var penche: float = 0.0
		if state in ["suit", "approche"] and speed < 0.2:
			penche = sin(t * 2.0 + _flank * 3.0) * 0.25
		cou.rotation.x = lerpf(0.9, sin(t * 9.0) * 0.12 * walk, 1.0 - _crouch) if dort else sin(t * 9.0) * 0.12 * walk
		cou.rotation.z = penche
		cou.rotation.y = lerpf(0.0, 2.2, _crouch)
	if queue != null:
		queue.rotation.y = sin(t * (6.0 if walk > 0.1 else 1.5)) * (0.3 if walk > 0.1 else 0.12) + 1.6 * _crouch
	for nm in ["G", "D"]:
		var cu: Node3D = _vox.get("cuisse" + nm)
		var ja: Node3D = _vox.get("jambe" + nm)
		var ph: float = 0.0 if nm == "G" else PI
		if cu != null:
			cu.rotation.x = sin(t * 16.0 + ph) * 0.7 * minf(walk, 1.2) - 1.1 * _crouch
		if ja != null:
			ja.rotation.x = maxf(0.0, -sin(t * 16.0 + ph)) * 0.8 * minf(walk, 1.2) + 1.6 * _crouch
	if corps != null:
		corps.rotation.x = -0.15 * minf(walk, 1.0)


func _anim_archeo() -> void:
	var t: float = _clock
	var en_vol: bool = state == "plane"
	for nm in ["G", "D"]:
		var w: Node3D = _vox.get("aile" + nm)
		var sx: float = 1.0 if nm == "G" else -1.0
		if w != null:
			if en_vol:
				# des battements maladroits, puis il plane
				w.rotation.z = sx * (sin(t * 11.0) * 0.7 if fmod(t, 2.0) < 1.1 else 0.08)
				w.rotation.y = 0.0
			else:
				w.rotation.z = sx * -0.1
				w.rotation.y = sx * 1.25
			w.scale.x = 1.0 if en_vol else 0.55
	var tete: Node3D = _vox.get("tete")
	if tete != null:
		tete.rotation.y = 0.0 if en_vol else sin(t * 0.7 + _flank * 2.0) * 0.8
	var queue: Node3D = _vox.get("queue")
	if queue != null:
		queue.rotation.x = 0.1 * sin(t * 1.5) if en_vol else 0.55


func _anim_libellule() -> void:
	var t: float = _clock
	for nm in ["avantG", "avantD", "arriereG", "arriereD"]:
		var w: Node3D = _vox.get(nm)
		if w != null:
			var sx: float = 1.0 if nm.ends_with("G") else -1.0
			var ph: float = 0.0 if nm.begins_with("avant") else PI * 0.5
			w.rotation.z = sx * sin(t * 55.0 + ph) * 0.5

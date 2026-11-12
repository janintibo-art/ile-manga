extends "res://scripts/monstre_v136.gd"
## V137 : la faune des îles du ciel : le royaume des fées, l'île flottante et Astralys. (Les bêtes
## d'avant passent toujours par leurs fichiers : on ne fait ici que les nouvelles.)
## Toutes les bêtes connaissent maintenant leur île (ile_sol) : sur une île du ciel, le sol est
## celui de l'île (faune_v132.hauteur), et l'on ne s'avance pas dans le vide.
## Des caractères nouveaux :
##  - papillons (morphos bleus, chez les fées) : ils voltigent ; si le héros reste immobile près
##    d'eux, ils viennent se poser sur lui ; il bouge, ils s'envolent ;
##  - bondisseur (cerf blanc, chez les fées) : il lève la tête et observe le héros ; s'il approche
##    trop ou court, il s'enfuit en grands bonds. On ne peut pas lui faire de mal ;
##  - gardien (blaireau, la nuit) : il défend son terrier : il gronde d'abord, mord si l'on
##    s'approche encore, mais ne poursuit pas loin ;
##  - sentinelle (marmottes de l'île flottante) : l'une d'elles siffle, et toutes courent plonger
##    dans leur terrier ; elles ressortent la tête quand le héros est parti ;
##  - casse-os (gypaète) : il monte un os très haut et le lâche sur les rochers (gare à la tête !) ;
##  - embusqué (lynx, la nuit) : tapi dans l'herbe, il bondit quand on passe près de lui, puis se
##    retire et se remet à l'affût ailleurs ;
##  - dérive (méduses de ciel sauvages d'Astralys) : elles flottent sans voir personne ; leurs filaments
##    piquent qui passe dessous ; elles luisent la nuit ;
##  - planeur (raies célestes) : elles planent en larges cercles et rasent parfois le héros.

const SPECS137 := {
	"papillon_morpho": {"pv": 99, "vitesse": 1.6, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 4.0, "laisse": 30.0,
		"rayon": 0.6, "haut": 0.0, "nom": "Papillons morphos", "genre": "papillons", "vol": true, "col": ["boule", 0.4, 0.0]},
	"cerf_blanc": {"pv": 99, "vitesse": 2.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 14.0, "laisse": 80.0,
		"rayon": 0.7, "haut": 1.1, "nom": "Cerf blanc", "genre": "bondisseur", "col": ["boite", Vector3(0.5, 1.4, 1.6)]},
	"blaireau": {"pv": 16, "vitesse": 2.6, "degats": 1, "portee": 1.2, "armer": 0.5, "repos": 1.2, "vue": 7.0, "laisse": 7.0,
		"rayon": 0.45, "haut": 0.3, "nom": "Blaireau", "genre": "gardien", "col": ["boite", Vector3(0.4, 0.35, 0.8)]},
	"marmotte": {"pv": 4, "vitesse": 3.2, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 12.0, "laisse": 30.0,
		"rayon": 0.3, "haut": 0.25, "nom": "Marmotte", "genre": "sentinelle", "col": ["boite", Vector3(0.3, 0.35, 0.5)]},
	"gypaete": {"pv": 12, "vitesse": 7.0, "degats": 1, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 0.0, "laisse": 200.0,
		"rayon": 0.7, "haut": 0.0, "nom": "Gypaète barbu", "genre": "casse_os", "vol": true, "paisible": true, "col": ["boule", 0.5, 0.0]},
	"lynx": {"pv": 18, "vitesse": 4.2, "degats": 2, "portee": 1.5, "armer": 0.4, "repos": 1.5, "vue": 6.5, "laisse": 20.0,
		"rayon": 0.55, "haut": 0.45, "nom": "Lynx", "genre": "embusque", "saut": 6.0, "col": ["boite", Vector3(0.45, 0.6, 1.0)]},
	"meduse_celeste": {"pv": 5, "vitesse": 0.6, "degats": 1, "portee": 1.3, "armer": 1.5, "repos": 1.0, "vue": 0.0, "laisse": 60.0,
		"rayon": 0.55, "haut": 0.0, "nom": "Méduse de ciel", "genre": "derive", "vol": true, "paisible": true, "col": ["boule", 0.4, 0.0]},
	"raie_celeste": {"pv": 10, "vitesse": 5.0, "degats": 0, "portee": 0.0, "armer": 1.0, "repos": 1.0, "vue": 14.0, "laisse": 200.0,
		"rayon": 0.9, "haut": 0.0, "nom": "Raie céleste", "genre": "planeur", "vol": true, "col": ["boule", 0.6, 0.0]},
}
const SOUNDS137 := {
	"papillon_morpho": ["", ""], "cerf_blanc": ["cerf_brame", "cerf_brame"], "blaireau": ["blaireau_grogne", "blaireau_grogne"],
	"marmotte": ["marmotte_siffle", "marmotte_siffle"], "gypaete": ["", ""], "lynx": ["lynx_feule", "lynx_feule"],
	"meduse_celeste": ["meduse_pique", ""], "raie_celeste": ["", ""],
}
const ALERTES137 := {
	"blaireau": "Un blaireau ! Il défend son terrier : quand il gronde, recule, sinon il mord. Il ne te suivra pas loin.",
	"lynx": "Un lynx ! Il guette, tapi dans l'herbe, et bondit quand tu passes près de lui : écarte-toi quand il se ramasse, puis frappe-le.",
	"meduse_celeste": "Une méduse de ciel sauvage ! Elle dérive sans te voir, mais ses longs filaments piquent : ne passe pas dessous.",
	"gypaete": "Un gypaète ! Il lâche des os de très haut pour les casser sur les rochers : regarde en l'air quand il passe au-dessus de toi.",
}
const GENRES137 := ["papillons", "bondisseur", "gardien", "sentinelle", "casse_os", "embusque", "derive", "planeur"]

static var _tex137: Dictionary = {}

var ile_sol: String = ""                  # l'île de la bête (son sol, sur une île du ciel)
var _papillons: Array = []                # [nœud, ailes (pivot, côté, avant), phase, place sur le héros]
var _hero_v: float = 0.0                  # la vitesse du héros (les papillons, le cerf)
var _last_p: Vector3 = Vector3.INF
var _immobile: float = 0.0
var _bond_from: Vector3 = Vector3.ZERO
var _bond_to: Vector3 = Vector3.ZERO
var _bond_u: float = 1.0
var _bonds_left: int = 0
var _bond_heurt: bool = false             # le dernier bond a buté (un arbre, un rocher) : on change de cap
var _calm_t: float = 0.0
var _terrier_n: Node3D                    # le terrier (blaireau, marmottes)
var _os: Node3D                           # l'os dans les serres du gypaète
var _os_cible: Vector3 = Vector3.ZERO
var _tentacules: Array = []               # méduse : [pivot, angle, phase]
var _meduse_mats: Array = []
var _crouch: float = 0.0
var _stand: float = 0.0
# tests
var poses: int = 0
var bonds: int = 0
var grognes: int = 0
var sifflets: int = 0
var lachers: int = 0
var passages: int = 0


static func spec_of(k: String) -> Dictionary:
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
	return SPECS137.has(k) or SPECS136.has(k) or SPECS135.has(k) or SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS137.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS137[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = int(spec["degats"]) == 0 or bool(spec.get("paisible", false))
	home = at
	hp = int(spec["pv"])
	hit_radius = float(spec["rayon"])
	hit_height = float(spec["haut"])
	name = "Bete_%s_%d" % [k, get_instance_id()]
	collision_layer = 0 if vol else 1
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
		"papillon_morpho":
			_build_papillons()
		"cerf_blanc":
			_build_cerf()
		"blaireau":
			_build_blaireau()
			_creuse_terrier(at, 0.7)
		"marmotte":
			_build_marmotte()
			_creuse_terrier(at, 0.42)
		"gypaete":
			_build_gypaete()
		"lynx":
			_build_lynx()
		"meduse_celeste":
			_build_meduse()
		"raie_celeste":
			_build_raie()
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
	match k:
		"papillon_morpho":
			_alt = randf_range(0.9, 1.4)
			state = "vol"
		"gypaete":
			_alt = randf_range(20.0, 26.0)
			_cd136 = randf_range(4.0, 8.0)
			state = "vol"
		"meduse_celeste":
			_alt = randf_range(1.7, 2.4)
			state = "derive"
		"raie_celeste":
			_alt = randf_range(7.0, 11.0)
			_cd136 = randf_range(3.0, 8.0)
			state = "plane"
		"lynx":
			state = "aguet"
		_:
			state = "erre"
	_base_scale = _visual.scale


## Le terrier : un monticule de terre et son trou sombre, posé à côté de la bête (il reste là où
## elle est née ; il disparaît avec elle).
func _creuse_terrier(at: Vector3, size: float) -> void:
	var holder: Node = get_parent()
	if holder == null:
		return
	var t := Node3D.new()
	t.name = "Terrier_%d" % get_instance_id()
	holder.add_child(t)
	t.global_position = at + Vector3(0, -0.05, 0)
	t.rotation.y = randf() * TAU
	var terre := _mat(Color(0.36, 0.28, 0.19), 0.98)
	var trou := _mat(Color(0.03, 0.025, 0.02), 1.0)
	_mesh(t, _unit_sphere(), terre, Vector3(0, 0.0, -size * 0.55), Vector3(size * 1.0, size * 0.2, size * 0.8))
	_mesh(t, _unit_sphere(), trou, Vector3(0, size * 0.1, -size * 0.12), Vector3(size * 0.32, size * 0.2, size * 0.05), Vector3(-0.35, 0, 0))
	_terrier_n = t
	var libere := func() -> void:
		if is_instance_valid(t):
			t.queue_free()
	tree_exiting.connect(libere)


# =================================================================== textures

func _taches_tex(key: String, base: Color, tache: Color, n_taches: int, rmin: float, rmax: float, seed_v: int) -> Texture2D:
	if _tex137.has(key):
		return _tex137[key]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in range(n):
		for x in range(n):
			var v: float = 1.0 + 0.06 * sin(float(x) * 0.7 + float(y) * 0.2) * sin(float(y) * 0.5) + rng.randf_range(-0.06, 0.06)
			img.set_pixel(x, y, Color(base.r * v, base.g * v, base.b * v))
	for i in range(n_taches):
		_disque(img, rng.randf() * n, rng.randf() * n, rng.randf_range(rmin, rmax), tache.lightened(rng.randf_range(0.0, 0.15)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex137[key] = t
	return t


# =================================================================== modèles : le royaume des fées

## Les morphos : de grands papillons d'un bleu électrique, bordés de noir ; le dessous brun, semé
## d'ocelles dorées ; le corps sombre et fin, les antennes.
func _build_papillons() -> void:
	var bleu := _mat(Color(0.1, 0.42, 1.0), 0.22, 0.35)
	bleu.metallic = 0.35
	bleu.metallic_specular = 0.9
	var bord := _mat(Color(0.03, 0.03, 0.05), 0.5)
	var brun := _mat(Color(0.34, 0.24, 0.13), 0.8)
	var ocelle := _mat(Color(0.95, 0.75, 0.3), 0.6)
	var corps := _mat(Color(0.08, 0.06, 0.05), 0.6)
	for i in range(6):
		var b := Node3D.new()
		_visual.add_child(b)
		_put(b, _tube_fn("morpho:corps", [Vector3(0, 0, -0.028), Vector3(0, 0.001, 0.0), Vector3(0, 0.002, 0.02)], [0.0035, 0.005, 0.004], 6, 1.0, Callable()), corps)
		_mesh(b, _unit_sphere(), corps, Vector3(0, 0.003, 0.025), Vector3.ONE * 0.0045)
		for sx in [-1.0, 1.0]:
			_put(b, _tube_fn("morpho:antenne%s" % ("g" if sx < 0.0 else "d"), [Vector3(sx * 0.002, 0.004, 0.027), Vector3(sx * 0.008, 0.012, 0.045), Vector3(sx * 0.012, 0.016, 0.055)], [0.0008, 0.0007, 0.0012], 4, 1.0, Callable()), corps)
		var ailes: Array = []
		for sx in [-1.0, 1.0]:
			for avant in [true, false]:
				var w := Node3D.new()
				w.position = Vector3(sx * 0.003, 0.002, 0.006 if avant else -0.006)
				b.add_child(w)
				var c: Vector3 = Vector3(sx * 0.034, 0.0, 0.004) if avant else Vector3(sx * 0.026, 0.0, -0.014)
				var sc: Vector3 = Vector3(0.035, 0.0012, 0.024) if avant else Vector3(0.027, 0.0012, 0.022)
				_mesh(w, _unit_sphere(), bord, c + Vector3(sx * 0.002, 0.0, 0.0), sc + Vector3(0.004, -0.0001, 0.003))
				_mesh(w, _unit_sphere(), bleu, c + Vector3(0, 0.0006, 0), sc)
				_mesh(w, _unit_sphere(), brun, c - Vector3(0, 0.0006, 0), sc)
				_mesh(w, _unit_sphere(), ocelle, c + Vector3(sx * 0.008, -0.0013, -0.003), Vector3(0.006, 0.0008, 0.006))
				ailes.append([w, sx, avant])
		_papillons.append([b, ailes, randf() * TAU, i])


## Le cerf blanc : un grand cerf à la robe blanche comme la neige, le nez et les sabots sombres, les
## grands bois pâles aux nombreux andouillers.
func _build_cerf() -> void:
	var robe := _vmat(Color(0.94, 0.93, 0.9), 0.85)
	var ombre := func(s: float, ang: float) -> float:
		return 0.9 + 0.1 * (0.5 + 0.5 * sin(ang)) + 0.03 * sin(s * 29.0 + ang * 3.0)
	_build_mammal({"long": 0.95, "haut": 1.0, "rayon": 0.2, "mat": robe, "shade": ombre, "museau": 0.17, "bout": 0.2,
		"crane": 0.55, "oreille": 0.85, "forme_oreille": "pointe", "ecart": 0.9, "queue": 0.12, "style": "dressee", "touffe": 0.3,
		"patte": 0.12, "pied": 0.55, "cou": 2.2, "port": 0.95, "taille": 0.78, "oeil": 0.15, "sombre": Color(0.07, 0.06, 0.06),
		"teinte": 0.97, "garrot": 0.04, "dedans": Color(0.85, 0.75, 0.72)})
	var head: Node3D = _pivots["tete"]
	var bois := _mat(Color(0.84, 0.8, 0.7), 0.75)
	var sk: float = 0.55 * 0.2
	for sx in [-1.0, 1.0]:
		var base := Vector3(sx * sk * 0.38, sk * 0.85, sk * 0.15)
		var beam: Array = [base, base + Vector3(sx * 0.1, 0.16, -0.06), base + Vector3(sx * 0.2, 0.36, -0.05), base + Vector3(sx * 0.23, 0.54, 0.04), base + Vector3(sx * 0.17, 0.7, 0.13)]
		var side: String = "g" if sx < 0.0 else "d"
		_put(head, _tube_fn("cerf:merrain%s" % side, beam, [0.024, 0.019, 0.016, 0.012, 0.005], 8, 1.0, Callable()), bois)
		_mesh(head, _unit_sphere(), bois, base, Vector3.ONE * 0.03)
		# les andouillers : deux devant, et la couronne au sommet
		var tines: Array = [[1, Vector3(sx * 0.03, 0.08, 0.17)], [2, Vector3(sx * 0.02, 0.13, 0.16)], [3, Vector3(sx * 0.07, 0.14, 0.02)], [3, Vector3(-sx * 0.02, 0.15, 0.06)], [4, Vector3(sx * 0.06, 0.1, -0.02)]]
		for j in range(tines.size()):
			var t0: Vector3 = beam[int(tines[j][0])]
			var t1: Vector3 = t0 + (tines[j][1] as Vector3)
			_put(head, _tube_fn("cerf:andouiller%d%s" % [j, side], [t0, (t0 + t1) * 0.5 + Vector3(0, 0.01, 0), t1], [0.012, 0.009, 0.003], 6, 1.0, Callable()), bois)
	var sabot := _mat(Color(0.12, 0.1, 0.09), 0.5)
	for l in _legs:
		var kids: Array = (l[0] as Node3D).get_children()
		if kids.size() >= 2 and kids[1] is MeshInstance3D:
			(kids[1] as MeshInstance3D).material_override = sabot


## Le blaireau : trapu et bas, le dos gris argenté, les pattes et le ventre noirs, la tête blanche
## barrée de deux bandes noires qui passent sur les yeux ; de grosses griffes pour creuser.
func _build_blaireau() -> void:
	var gris := _vmat(Color(0.47, 0.46, 0.44), 0.95)
	var dos := func(s: float, ang: float) -> float:
		return lerpf(0.12, 1.0, smoothstep(-0.45, 0.45, sin(ang))) * (0.93 + 0.07 * sin(s * 47.0 + ang * 9.0))
	_build_mammal({"long": 0.62, "haut": 0.38, "rayon": 0.17, "mat": gris, "shade": dos, "museau": 0.12, "bout": 0.2,
		"crane": 0.55, "oreille": 0.22, "forme_oreille": "rond", "ecart": 0.6, "queue": 0.14, "style": "pend", "touffe": 0.35,
		"patte": 0.3, "pied": 1.4, "cou": 0.35, "port": 0.25, "taille": 0.95, "aplat": 0.95, "oeil": 0.1,
		"sombre": Color(0.03, 0.03, 0.03), "teinte": 0.9, "segs": 16})
	var blanc := _mat(Color(0.93, 0.92, 0.89), 0.9)
	var noir := _mat(Color(0.05, 0.05, 0.05), 0.9)
	var head: Node3D = _pivots["tete"]
	var kids: Array = head.get_children()
	for i in [0, 1, 3]:
		if i < kids.size() and kids[i] is MeshInstance3D:
			(kids[i] as MeshInstance3D).material_override = blanc
	var sk: float = 0.55 * 0.17
	var ml: float = 0.12
	for sx in [-1.0, 1.0]:
		var bp: Array = [Vector3(sx * sk * 0.2, sk * 0.05, sk * 0.6 + ml * 0.75), Vector3(sx * sk * 0.42, sk * 0.3, sk * 0.65), Vector3(sx * sk * 0.55, sk * 0.5, sk * 0.1), Vector3(sx * sk * 0.5, sk * 0.6, -sk * 0.4)]
		_put(head, _tube_fn("blaireau:bande%s" % ("g" if sx < 0.0 else "d"), bp, [0.012, 0.022, 0.024, 0.02], 8, 1.0, Callable()), noir)
	for l in _legs:
		var lk: Array = (l[0] as Node3D).get_children()
		for j in range(mini(2, lk.size())):
			if lk[j] is MeshInstance3D:
				(lk[j] as MeshInstance3D).material_override = noir
		if int(l[2]) < 2:
			var leg: Node3D = l[0]
			var lh: float = leg.position.y
			for f in range(3):
				var a: float = (float(f) - 1.0) * 0.35
				_mesh(leg, _cyl(0.002, 0.007, 0.05), _mat(Color(0.75, 0.72, 0.65), 0.5), Vector3(sin(a) * 0.02, -lh + 0.02, 0.06 + cos(a) * 0.01), Vector3.ONE, Vector3(PI * 0.5 + 0.3, a, 0))


# =================================================================== modèles : l'île flottante

## La marmotte : ronde et dodue, brun-gris, la calotte sombre, le museau clair, les petites oreilles
## rondes, la queue courte et touffue ; deux incisives orangées.
func _build_marmotte() -> void:
	var poil := _vmat(Color(0.52, 0.42, 0.3), 0.95)
	var fl: StandardMaterial3D = _flat_of(poil, 0.9)
	var sombre := _mat(Color(0.22, 0.17, 0.12), 0.95)
	var clair := _mat(Color(0.72, 0.64, 0.52), 0.95)
	var dos := func(s: float, ang: float) -> float:
		return 0.72 + 0.28 * (0.5 - 0.5 * sin(ang)) + 0.05 * sin(s * 37.0 + ang * 9.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_put(body, _tube_fn("marmotte:corps", [Vector3(0, 0.12, -0.2), Vector3(0, 0.15, -0.1), Vector3(0, 0.16, 0.02), Vector3(0, 0.15, 0.12), Vector3(0, 0.15, 0.18)], [0.07, 0.13, 0.135, 0.11, 0.07], 16, 1.0, dos), poil)
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.18, 0.21)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), fl, Vector3(0, 0.0, 0.0), Vector3(0.066, 0.054, 0.078))
	_mesh(head, _unit_sphere(), sombre, Vector3(0, 0.024, 0.004), Vector3(0.056, 0.032, 0.066))
	_mesh(head, _unit_sphere(), clair, Vector3(0, -0.014, 0.058), Vector3(0.042, 0.032, 0.04))
	_mesh(head, _unit_sphere(), _mat(Color(0.08, 0.06, 0.05), 0.4), Vector3(0, 0.002, 0.092), Vector3(0.012, 0.009, 0.006))
	_mesh(head, BoxMesh.new(), _mat(Color(0.9, 0.6, 0.25), 0.4), Vector3(0, -0.038, 0.08), Vector3(0.012, 0.016, 0.004))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), _mat(Color(0.03, 0.025, 0.02), 0.1), Vector3(sx * 0.044, 0.02, 0.04), Vector3.ONE * 0.011)
		_mesh(head, _unit_sphere(), _mat(Color(1, 1, 1), 0.1, 1.0), Vector3(sx * 0.047, 0.024, 0.047), Vector3.ONE * 0.0025)
		_mesh(head, _unit_sphere(), sombre, Vector3(sx * 0.05, 0.045, -0.02), Vector3(0.018, 0.016, 0.008))
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.07, 0.09, 0.12 if front else -0.1)
		body.add_child(leg)
		if front:
			_put(leg, _tube_fn("marmotte:avant", [Vector3.ZERO, Vector3(0, -0.05, 0.01), Vector3(0, -0.085, 0.025)], [0.025, 0.02, 0.018], 8, 1.0, Callable()), sombre)
		else:
			_mesh(leg, _unit_sphere(), fl, Vector3(0, 0.02, 0), Vector3(0.05, 0.07, 0.07))
			_mesh(leg, _unit_sphere(), sombre, Vector3(0, -0.075, 0.03), Vector3(0.025, 0.014, 0.05))
		_legs.append([leg, sx2, i])
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.13, -0.2)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("marmotte:queue", [Vector3.ZERO, Vector3(0, -0.02, -0.08), Vector3(0, -0.045, -0.16)], [0.035, 0.04, 0.025], 10, 1.0, dos), sombre)


## Le gypaète barbu : immense, les ailes longues et pointues gris ardoise, la queue en losange ; le
## dessous et la tête roux orangé ; un masque noir sur l'œil, la « barbe » noire sous le bec.
func _build_gypaete() -> void:
	var ardoise := _vmat(Color(0.2, 0.2, 0.22), 0.7)
	var roux := _vmat(Color(0.86, 0.56, 0.3), 0.85)
	var creme := _mat(Color(0.93, 0.8, 0.6), 0.85)
	var noir := _mat(Color(0.03, 0.03, 0.03), 0.4)
	var bec := _mat(Color(0.45, 0.45, 0.47), 0.4)
	var jaune := _mat(Color(0.65, 0.6, 0.55), 0.6)
	var rachis := func(s: float, ang: float) -> float:
		return 0.78 + 0.22 * smoothstep(0.7, 1.0, sin(s * 60.0)) + 0.05 * sin(ang * 3.0)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var sp: Array = []
	var rr: Array = []
	for i in range(9):
		var u: float = float(i) / 8.0
		sp.append(Vector3(0, -0.02 * sin(u * PI), lerpf(-0.36, 0.3, u)))
		rr.append(lerpf(0.05, 0.13, smoothstep(0.0, 0.55, u)) * (1.0 - 0.3 * smoothstep(0.82, 1.0, u)))
	_put(body, _tube_fn("gypaete:corps", sp, rr, 14, 0.95, Callable(self, "_shade_dos")), roux)
	_mesh(body, _unit_sphere(), _flat_of(ardoise, 1.0), Vector3(0, 0.05, -0.04), Vector3(0.1, 0.05, 0.26))
	var head := Node3D.new()
	head.name = "Tete"
	head.position = Vector3(0, 0.04, 0.33)
	body.add_child(head)
	_pivots["tete"] = head
	_mesh(head, _unit_sphere(), creme, Vector3.ZERO, Vector3(0.062, 0.06, 0.075))
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), noir, Vector3(sx * 0.04, 0.012, 0.045), Vector3(0.02, 0.012, 0.04))
		_mesh(head, _unit_sphere(), _mat(Color(0.8, 0.1, 0.06), 0.3), Vector3(sx * 0.045, 0.018, 0.04), Vector3.ONE * 0.011)
		_mesh(head, _unit_sphere(), _mat(Color(0.95, 0.9, 0.6), 0.2), Vector3(sx * 0.049, 0.018, 0.043), Vector3.ONE * 0.007)
	_put(head, _tube_fn("gypaete:bec", [Vector3(0, 0.01, 0.06), Vector3(0, 0.008, 0.11), Vector3(0, -0.005, 0.135), Vector3(0, -0.025, 0.14)], [0.018, 0.013, 0.008, 0.003], 8, 0.9, Callable()), bec)
	_put(head, _tube_fn("gypaete:barbe", [Vector3(0, -0.015, 0.08), Vector3(0, -0.04, 0.11), Vector3(0, -0.06, 0.12)], [0.01, 0.007, 0.002], 6, 0.6, Callable()), noir)
	for sx in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.07, 0.03, 0.08)
		body.add_child(wing)
		var ap: Array = [Vector3(0, 0, -0.06), Vector3(sx * 0.28, 0.02, -0.08), Vector3(sx * 0.56, 0.03, -0.07)]
		_put(wing, _tube_fn("gypaete:bras%s" % ("g" if sx < 0.0 else "d"), ap, [0.16, 0.15, 0.12], 10, 0.08, rachis), ardoise)
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.56, 0.03, 0.0)
		wing.add_child(hand)
		_put(hand, _tube_fn("gypaete:main%s" % ("g" if sx < 0.0 else "d"), [Vector3(0, 0, -0.06), Vector3(sx * 0.3, -0.01, -0.12), Vector3(sx * 0.55, -0.02, -0.22), Vector3(sx * 0.68, -0.03, -0.3)], [0.12, 0.09, 0.05, 0.008], 10, 0.08, rachis), ardoise)
		_wings.append([wing, hand, sx])
		_pivots["aile%d" % int(sx)] = wing
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.0, -0.34)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("gypaete:queue", [Vector3.ZERO, Vector3(0, -0.005, -0.18), Vector3(0, -0.01, -0.34), Vector3(0, -0.012, -0.46)], [0.05, 0.11, 0.1, 0.01], 10, 0.08, rachis), ardoise)
	var talons := Node3D.new()
	talons.position = Vector3(0, -0.1, 0.03)
	body.add_child(talons)
	_pivots["serres"] = talons
	for sx in [-1.0, 1.0]:
		_mesh(talons, _unit_sphere(), roux, Vector3(sx * 0.05, 0.0, 0.0), Vector3(0.045, 0.06, 0.05))
		_mesh(talons, _cyl(0.013, 0.013, 0.09), jaune, Vector3(sx * 0.05, -0.07, 0.0))
	_os = Node3D.new()
	_os.position = Vector3(0, -0.13, 0.02)
	talons.add_child(_os)
	var om := _mat(Color(0.9, 0.86, 0.76), 0.7)
	var cap := CapsuleMesh.new()
	cap.radius = 0.035
	cap.height = 0.42
	_mesh(_os, cap, om, Vector3.ZERO, Vector3.ONE, Vector3(0, 0, PI * 0.5))
	for sx in [-1.0, 1.0]:
		_mesh(_os, _unit_sphere(), om, Vector3(sx * 0.2, 0, 0), Vector3.ONE * 0.055)
	_os.visible = false


## Le lynx : haut sur pattes, la robe fauve-gris tachetée de brun, la courte queue au bout noir,
## les pinceaux noirs au bout des oreilles, les favoris sur les joues ; les yeux qui brillent la nuit.
func _build_lynx() -> void:
	var fur := _mat(Color(1, 1, 1), 0.88)
	fur.vertex_color_use_as_albedo = true
	fur.albedo_texture = _taches_tex("lynx", Color(0.64, 0.52, 0.37), Color(0.26, 0.18, 0.12), 90, 1.4, 3.0, 1371)
	fur.uv1_triplanar = true
	fur.uv1_scale = Vector3(2.2, 2.2, 2.2)
	var ventre := func(s: float, ang: float) -> float:
		return 0.85 + 0.15 * smoothstep(0.0, -0.8, sin(ang)) + 0.04 * sin(s * 31.0 + ang * 3.0)
	var queue := func(s: float, ang: float) -> float:
		return 0.12 if s > 0.75 else float(ventre.call(s, ang))
	_build_mammal({"long": 0.78, "haut": 0.66, "rayon": 0.155, "mat": fur, "shade": ventre, "shade_queue": queue, "truffe": 0.4,
		"museau": 0.07, "bout": 0.34, "crane": 0.7, "oreille": 0.55, "forme_oreille": "pointe", "ecart": 0.2, "queue": 0.14,
		"style": "pend", "touffe": 0.32, "patte": 0.24, "pied": 1.08, "teinte": 0.9, "cou": 0.5, "port": 0.45, "taille": 0.82,
		"segs": 20, "aplat": 1.15, "yeux": Color(0.88, 0.78, 0.28), "oeil": 0.14, "sombre": Color(0.22, 0.13, 0.1),
		"dedans": Color(0.9, 0.86, 0.8)})
	var head: Node3D = _pivots["tete"]
	var noir := _mat(Color(0.04, 0.035, 0.03), 0.8)
	var creme := _mat(Color(0.88, 0.82, 0.72), 0.9)
	var sk: float = 0.7 * 0.155
	for ear in head.get_children():
		if str(ear.name).contains("Oreille") and ear is Node3D:
			var oh: float = 0.55 * 0.155
			_mesh(ear as Node3D, _cyl(0.0, 0.006, 0.06), noir, Vector3(0, oh + 0.025, 0), Vector3.ONE)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), creme, Vector3(sx * sk * 0.7, -sk * 0.32, sk * 0.25), Vector3(0.03, 0.045, 0.03), Vector3(0, 0, sx * 0.4))
		_mesh(head, _unit_sphere(), noir, Vector3(sx * sk * 0.82, -sk * 0.42, sk * 0.12), Vector3(0.012, 0.035, 0.02), Vector3(0, 0, sx * 0.5))
	_mesh(head, _unit_sphere(), creme, Vector3(0, -sk * 0.45, sk * 0.75), Vector3(0.05, 0.03, 0.04))


# =================================================================== modèles : Astralys

## La méduse de ciel (sauvage) : une cloche translucide, bleutée, frangée ; dedans, quatre gonades rosées ;
## dessous, quatre bras frisés et douze longs filaments qui ondulent ; elle luit doucement la nuit.
func _build_meduse() -> void:
	var cloche_m := _mat(Color(0.72, 0.82, 1.0, 0.4), 0.12, 0.5)
	cloche_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloche_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloche_m.emission = Color(0.45, 0.6, 1.0)
	var interieur := _mat(Color(0.95, 0.55, 0.85, 0.75), 0.3, 0.8)
	interieur.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	interieur.emission = Color(0.9, 0.4, 0.8)
	var gonade := _mat(Color(0.95, 0.7, 0.9, 0.35), 0.3, 0.5)
	gonade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gonade.emission = Color(0.9, 0.5, 0.85)
	var filament := _mat(Color(0.8, 0.86, 1.0, 0.5), 0.2, 0.6)
	filament.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	filament.emission = Color(0.55, 0.7, 1.0)
	_meduse_mats = [cloche_m, interieur, filament, gonade]
	var bell := Node3D.new()
	bell.name = "Cloche"
	_visual.add_child(bell)
	_pivots["cloche"] = bell
	var dome := func(d: Vector3) -> Vector3:
		var y: float = d.y * 0.2 if d.y > 0.0 else d.y * 0.035
		return Vector3(d.x * 0.28, y, d.z * 0.28)
	var blanc := func(_d: Vector3, _p: Vector3) -> Color:
		return Color(1, 1, 1)
	_put(bell, _blob_mesh("meduse:cloche", dome, blanc, 12, 24), cloche_m)
	var rim: Array = []
	var rr: Array = []
	for k in range(25):
		var a: float = TAU * float(k) / 24.0
		rim.append(Vector3(cos(a) * 0.275, -0.012 + 0.008 * sin(a * 8.0), sin(a) * 0.275))
		rr.append(0.012)
	_put(bell, _tube_fn("meduse:frange", rim, rr, 6, 1.0, Callable()), cloche_m)
	var frise := func(s: float, ang: float) -> float:
		return 0.75 + 0.25 * sin(s * 40.0 + ang * 3.0)
	for k in range(4):
		var a2: float = TAU * float(k) / 4.0 + 0.4
		_mesh(bell, _unit_sphere(), gonade, Vector3(cos(a2) * 0.06, 0.1, sin(a2) * 0.06), Vector3(0.03, 0.01, 0.018), Vector3(0, -a2, 0))
		var arm: Array = [Vector3(cos(a2) * 0.02, -0.02, sin(a2) * 0.02), Vector3(cos(a2) * 0.04, -0.2, sin(a2) * 0.04), Vector3(cos(a2) * 0.06, -0.42, sin(a2) * 0.03), Vector3(cos(a2) * 0.05, -0.6, sin(a2) * 0.02)]
		_put(bell, _tube_fn("meduse:bras%d" % k, arm, [0.03, 0.028, 0.018, 0.006], 8, 1.0, frise), interieur)
	for k in range(12):
		var a3: float = TAU * float(k) / 12.0
		var tp := Node3D.new()
		tp.position = Vector3(cos(a3) * 0.26, -0.015, sin(a3) * 0.26)
		bell.add_child(tp)
		var path: Array = []
		var radii: Array = []
		for i in range(7):
			var u: float = float(i) / 6.0
			path.append(Vector3(0.03 * sin(u * 5.0 + float(k)), -u * 1.45, 0.03 * cos(u * 4.0 + float(k))))
			radii.append(lerpf(0.004, 0.0015, u))
		_put(tp, _tube_fn("meduse:filament%d" % (k % 4), path, radii, 4, 1.0, Callable()), filament)
		_tentacules.append([tp, a3, randf() * TAU])


## La raie céleste : une raie manta, le dos bleu nuit avec deux taches pâles aux épaules, le ventre
## blanc ; de très larges nageoires pointues qui ondulent, les deux cornes devant la bouche, la
## longue queue fine.
func _build_raie() -> void:
	var m := _mat(Color(1, 1, 1), 0.55)
	m.vertex_color_use_as_albedo = true
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var corps := func(d: Vector3) -> Vector3:
		return Vector3(d.x * 0.36, d.y * (0.12 if d.y > 0.0 else 0.08), d.z * 0.55)
	var couleur := func(d: Vector3, _p: Vector3) -> Color:
		if d.y < -0.05:
			return Color(0.92, 0.92, 0.9)
		if d.y > 0.4 and absf(d.x) > 0.5 and d.z > 0.1 and d.z < 0.5:
			return Color(0.38, 0.42, 0.48)
		return Color(0.07, 0.09, 0.15)
	var aile_c := func(d: Vector3, _p: Vector3) -> Color:
		return Color(0.92, 0.92, 0.9) if d.y < -0.05 else Color(0.07, 0.09, 0.15)
	_put(body, _blob_mesh("raie:corps", corps, couleur, 12, 24), m)
	for sx in [-1.0, 1.0]:
		var side: String = "g" if sx < 0.0 else "d"
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.3, 0.0, 0.05)
		body.add_child(wing)
		var interne := func(d: Vector3) -> Vector3:
			var u: float = d.x * 0.5 + 0.5
			return Vector3(sx * u * 0.55, d.y * 0.05 * (1.0 - u * 0.5), d.z * 0.42 * (1.0 - u * 0.45) - u * 0.12)
		_put(wing, _blob_mesh("raie:aile%s" % side, interne, aile_c, 8, 20), m)
		var tip := Node3D.new()
		tip.position = Vector3(sx * 0.5, 0.0, -0.1)
		wing.add_child(tip)
		var bout := func(d: Vector3) -> Vector3:
			var u: float = d.x * 0.5 + 0.5
			return Vector3(sx * u * 0.62, d.y * 0.03 * (1.0 - u * 0.7), d.z * 0.24 * (1.0 - u * 0.9) - u * u * 0.32)
		_put(tip, _blob_mesh("raie:bout%s" % side, bout, aile_c, 8, 20), m)
		_wings.append([wing, tip, sx])
		_pivots["aile%d" % int(sx)] = wing
		var corne := _mat(Color(0.07, 0.09, 0.15), 0.6)
		_mesh(body, _unit_sphere(), corne, Vector3(sx * 0.14, 0.0, 0.58), Vector3(0.03, 0.012, 0.1), Vector3(0, sx * 0.15, 0))
		_mesh(body, _unit_sphere(), _mat(Color(0.02, 0.02, 0.02), 0.2), Vector3(sx * 0.2, 0.03, 0.42), Vector3.ONE * 0.012)
	_mesh(body, _unit_sphere(), _mat(Color(0.03, 0.03, 0.04), 0.6), Vector3(0, -0.02, 0.54), Vector3(0.12, 0.01, 0.02))
	var tail := Node3D.new()
	tail.name = "Queue"
	tail.position = Vector3(0, 0.0, -0.52)
	body.add_child(tail)
	_pivots["queue"] = tail
	_put(tail, _tube_fn("raie:queue", [Vector3.ZERO, Vector3(0, 0.0, -0.3), Vector3(0, 0.0, -0.7)], [0.018, 0.008, 0.002], 6, 1.0, Callable()), _mat(Color(0.07, 0.09, 0.15), 0.6))


# =================================================================== sol, sons, alertes, butin

func _ground_at(p: Vector3) -> float:
	if manager != null and manager.has_method("hauteur"):
		return float(manager.hauteur(p.x, p.z, ile_sol if ile_sol != "" else "-"))
	return super._ground_at(p)


## Le plancher d'un oiseau : le sol, la mer, ou le niveau de son île du ciel (au-dessus du vide).
func _plancher(p: Vector3) -> float:
	var y0: float = -INF
	if manager != null and manager.has_method("niveau_ile"):
		y0 = float(manager.niveau_ile(ile_sol))
	return maxf(maxf(_ground_at(p), EAU), y0)


func _au_vide(p: Vector3) -> bool:
	return manager != null and manager.has_method("vide") and bool(manager.vide(p, ile_sol if ile_sol != "" else "-"))


func _sound(what: String) -> void:
	if not SPECS137.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS137.get(kind, ["", ""])
	var s: String = str(pair[0] if what == "menace" else pair[1])
	if s != "":
		manager.main.sfx(s, global_position + Vector3.UP * maxf(hit_height, 0.3))


func alert_text() -> String:
	if SPECS137.has(kind):
		return str(ALERTES137.get(kind, ""))
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS137.has(kind):
		return super.loot(rng)
	var g: Array = []
	match kind:
		"blaireau":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.2:
				g.append(["truffe", 1])
		"marmotte":
			if rng.randf() < 0.5:
				g.append(["piece", 1])
		"gypaete":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.25:
				g.append(["plume_vent", 1])
		"lynx":
			g.append(["piece", rng.randi_range(3, 6)])
			if rng.randf() < 0.1:
				g.append(["piece_or", 1])
		"meduse_celeste":
			g.append(["piece", rng.randi_range(1, 2)])
			if rng.randf() < 0.2:
				g.append(["perle_lumiere", 1])
		"raie_celeste":
			g.append(["piece", rng.randi_range(2, 3)])
			if rng.randf() < 0.15:
				g.append(["cristal_astral", 1])
	return g


func is_hittable() -> bool:
	if kind == "marmotte" and state in ["plonge", "terre"]:
		return false
	return super.is_hittable()


func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS137.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	match kind:
		"papillon_morpho":
			# ils s'envolent, sans mal
			_envol_papillons(from_pos)
			return
		"cerf_blanc":
			# on ne peut pas toucher le cerf blanc : une gerbe d'étincelles, et il s'enfuit
			_flash = 0.2
			_puff(global_position + Vector3.UP * 1.1, 12, Color(1.0, 1.0, 0.9, 0.9), 0.05, 0.18, 0.8, 0.8, 2.2)
			_bondir(from_pos)
			return
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	match kind:
		"blaireau":
			state = "grogne"
		"marmotte":
			state = "fuite"
			timer = 3.0
		"lynx":
			state = "retraite"
			timer = 1.5
		"gypaete", "raie_celeste":
			state = "fuite_air"
			timer = 3.0
			if _os != null:
				_os.visible = false
		"meduse_celeste":
			state = "derive"


func _die() -> void:
	if _os != null:
		_os.visible = false
	super._die()


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES137):
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
		"papillons":
			_fly_papillons(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"casse_os":
			_fly_gypaete(delta, p)
			_animate132(delta, 1.0)
			return
		"derive":
			_fly_meduse(delta, p)
			_animate132(delta, 1.0)
			return
		"planeur":
			_fly_raie(delta, p, dist)
			_animate132(delta, 1.0)
			return
		"bondisseur":
			if state == "bonds":
				_tick_bond(delta, p)
				_animate132(delta, 0.0)
				return
		"embusque":
			if state == "saut":
				_jump_tick(delta, p)
				_animate132(delta, 0.0)
				return
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	var move := Vector3.ZERO
	match genre:
		"bondisseur":
			move = _bondisseur(delta, dist, dir_p, p, sp, vue)
		"gardien":
			move = _gardien(delta, dist, dir_p, dy, p, sp, vue, from_home)
		"sentinelle":
			move = _sentinelle(delta, dist, p, sp, vue)
		"embusque":
			move = _embusque(delta, dist, dir_p, dy, p, sp, vue)
	# ni dans la mer, ni dans le vide au bord d'une île du ciel
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		if _au_vide(ahead) or (_ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead)):
			move = -move * 0.3
			_wander_to = Vector3.INF
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


# ------------------------------------------------------------------- les papillons

func _fly_papillons(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"vol":
			target = home + Vector3(cos(_clock * 0.4 + _flank * 3.0) * 1.5, 0, sin(_clock * 0.53) * 1.5)
			target.y = _ground_at(target) + _alt + sin(_clock * 1.7) * 0.3
			speed *= 0.6
			if dist < float(spec["vue"]) and _hero_v < 0.4:
				_immobile += delta
			else:
				_immobile = 0.0
			if _immobile > 2.0:
				state = "pose"
				poses += 1
				_immobile = 0.0
		"pose":
			target = p + Vector3(0, 1.45, 0)
			speed *= 2.0
			if _hero_v > 1.0 or dist > 3.5:
				_envol_papillons(p)
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


func _envol_papillons(from: Vector3) -> void:
	var away: Vector3 = global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	_cible = global_position + away.rotated(Vector3.UP, randf_range(-0.7, 0.7)) * 6.0 + Vector3.UP * 0.8
	if _au_vide(_cible):
		_cible = home + Vector3.UP * _alt
	state = "envol"
	timer = 3.0


# ------------------------------------------------------------------- le cerf blanc

func _bondisseur(delta: float, dist: float, dir_p: Vector3, p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre":
			move = _wander(delta, sp)
			if dist < vue and _calm_t <= 0.0:
				state = "observe"
				timer = 0.0
		"observe":
			# il lève la tête et regarde ; on approche trop, ou l'on court : il s'en va en bondissant
			facing = facing.lerp(dir_p, clampf(delta * 2.5, 0.0, 1.0)).normalized()
			timer += delta * 2.0
			if dist < 9.0 or (_hero_v > 3.5 and dist < vue):
				_bondir(p)
			elif dist > vue * 1.3:
				state = "erre"
			elif _hero_v < 0.3 and timer > 8.0:
				# le héros ne bouge plus : il se remet à brouter
				state = "erre"
				_calm_t = 6.0
		_:
			state = "erre"
	_calm_t -= delta
	return move


func _bondir(from: Vector3) -> void:
	var away: Vector3 = global_position - from
	away.y = 0.0
	facing = away.normalized() if away.length() > 0.1 else -facing
	_bonds_left = randi_range(5, 7)
	_sound("menace")
	_bond_suivant()


func _bond_suivant() -> void:
	var d: Vector3 = facing
	for k in range(8):
		var q: Vector3 = global_position + d * 4.6
		if not _au_vide(q) and not _au_vide(q + d * 2.0) and _ground_at(q) > 0.2:
			break
		d = d.rotated(Vector3.UP, (0.6 if k % 2 == 0 else -1.2) * float(k + 1) * 0.5)
	facing = d
	_bond_from = global_position
	_bond_to = global_position + d * 4.6
	_bond_to.y = _ground_at(_bond_to) + 0.05
	_bond_u = 0.0
	state = "bonds"
	bonds += 1


func _tick_bond(delta: float, p: Vector3) -> void:
	_bond_u = minf(_bond_u + delta / 0.55, 1.0)
	var q: Vector3 = _bond_from.lerp(_bond_to, _bond_u)
	q.y = lerpf(_bond_from.y, _bond_to.y, _bond_u) + 4.0 * 1.1 * _bond_u * (1.0 - _bond_u)
	var col: KinematicCollision3D = move_and_collide(q - global_position)
	rotation.y = atan2(facing.x, facing.z)
	if col != null and _bond_u > 0.3:
		_bond_u = 1.0
		_bond_heurt = true
	if _bond_u >= 1.0:
		var g: float = _ground_at(global_position)
		if global_position.y < g:
			global_position.y = g
		_bonds_left -= 1
		var away: Vector3 = global_position - p
		away.y = 0.0
		if _bonds_left > 0:
			facing = facing.lerp(away.normalized() if away.length() > 0.1 else facing, 0.5).normalized().rotated(Vector3.UP, randf_range(-0.25, 0.25))
			if _bond_heurt:
				# il a buté : il repart de biais, d'un côté ou de l'autre
				facing = facing.rotated(Vector3.UP, randf_range(1.0, 1.6) * (1.0 if randf() < 0.5 else -1.0))
				_bond_heurt = false
			_bond_suivant()
		else:
			state = "observe"
			timer = 0.0
			home = global_position


# ------------------------------------------------------------------- le blaireau

func _gardien(delta: float, dist: float, dir_p: Vector3, dy: float, p: Vector3, sp: float, vue: float, from_home: float) -> Vector3:
	var move := Vector3.ZERO
	var hero_home: float = Vector2(p.x - home.x, p.z - home.z).length()
	match state:
		"erre":
			move = _wander(delta, sp) * 0.6
			if from_home > float(spec["laisse"]):
				state = "retour"
			elif dist < vue and hero_home < 10.0 and dy < 2.5:
				state = "grogne"
				grognes += 1
				_sound("menace")
				manager.alert(self)
		"grogne", "recul":
			if state == "recul" and timer > 0.0:
				pass
			else:
				state = "grogne"
				facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
				if dist < 3.2 and from_home < float(spec["laisse"]):
					state = "armer"
					timer = float(spec["armer"])
				elif dist > vue + 1.5 or hero_home > 11.0:
					state = "retour"
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				state = "frappe"
				timer = 0.25
				_knock = facing * 6.0
				_blow = false
		"frappe":
			if not _blow and timer < 0.15:
				_blow = true
				if dist < float(spec["portee"]) + 0.4 and facing.dot(dir_p) > 0.3 and dy < 1.5:
					manager.hurt_player(int(spec["degats"]), global_position)
					landed_hits += 1
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() > 1.0:
				move = back.normalized() * sp * 0.5
			if timer <= 0.0:
				state = "grogne" if dist < vue and hero_home < 10.0 else "retour"
		"retour":
			var back2: Vector3 = home - global_position
			back2.y = 0.0
			if back2.length() < 1.2:
				state = "erre"
			else:
				move = back2.normalized() * sp * 0.8
				facing = facing.lerp(back2.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
		_:
			state = "erre"
	return move


# ------------------------------------------------------------------- les marmottes

func _sentinelle(delta: float, dist: float, _p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"erre", "debout":
			if state == "erre":
				move = _wander(delta, sp) * 0.35
				_cd136 -= delta
				if _cd136 <= 0.0:
					_cd136 = randf_range(6.0, 11.0)
					state = "debout"
					timer = randf_range(2.0, 3.5)
			elif timer <= 0.0:
				state = "erre"
			if dist < vue:
				_alarme()
		"siffle":
			if timer <= 0.0:
				state = "fuite"
				timer = 4.0
		"fuite":
			var to: Vector3 = home - global_position
			to.y = 0.0
			if to.length() > 0.5:
				facing = facing.lerp(to.normalized(), clampf(delta * 10.0, 0.0, 1.0)).normalized()
				move = facing * sp * 1.2
			if to.length() < 0.6 or timer <= 0.0:
				state = "plonge"
				timer = 0.3
				terriers += 1
		"plonge":
			_down = minf(_down + delta / 0.3, 1.0)
			if timer <= 0.0:
				state = "terre"
				timer = randf_range(8.0, 12.0)
				collision_layer = 0
				visible = false
		"terre":
			if timer <= 0.0:
				if dist > vue:
					global_position = Vector3(home.x, _ground_at(home) + 0.05, home.z)
					visible = true
					collision_layer = 1
					state = "guette"
					timer = 1.8
					_down = 0.6
					sorties += 1
				else:
					timer = 1.0
		"guette":
			_down = move_toward(_down, 0.55, delta)
			if dist < vue * 0.8:
				state = "plonge"
				timer = 0.3
			elif timer <= 0.0:
				_down = 0.0
				state = "erre"
		_:
			state = "erre"
	return move


## La sentinelle siffle : toutes les marmottes alentour courent à leur terrier.
func _alarme() -> void:
	sifflets += 1
	_sound("menace")
	state = "siffle"
	timer = 0.5
	if manager == null or manager.get("betes") == null:
		return
	for b in manager.betes:
		if b != self and is_instance_valid(b) and str(b.kind) == kind and str(b.state) in ["erre", "debout", "guette"] and (b as Node3D).global_position.distance_to(global_position) < 25.0:
			b.state = "fuite"
			b.timer = 4.0


# ------------------------------------------------------------------- le lynx

func _embusque(delta: float, dist: float, dir_p: Vector3, dy: float, p: Vector3, sp: float, vue: float) -> Vector3:
	var move := Vector3.ZERO
	match state:
		"aguet", "erre":
			state = "aguet"
			if dist < vue and dy < 2.0:
				state = "armer"
				timer = float(spec["armer"])
				_sound("menace")
				manager.alert(self)
		"armer":
			facing = facing.lerp(dir_p, clampf(delta * 10.0, 0.0, 1.0)).normalized()
			if timer <= 0.0:
				_start_jump(p, dist, dir_p)
		"souffle":
			if timer <= 0.0:
				if dist < 5.0:
					state = "retraite"
					timer = 2.5
				else:
					state = "aguet"
		"retraite", "recul":
			if state == "recul":
				state = "retraite"
				timer = 1.5
			facing = facing.lerp(-dir_p, clampf(delta * 8.0, 0.0, 1.0)).normalized()
			move = facing * sp
			if timer <= 0.0:
				state = "aguet"
				home = global_position
		_:
			state = "aguet"
	return move


# ------------------------------------------------------------------- en vol : gypaète, méduses, raies

func _voler137(delta: float, target: Vector3, speed: float, rate: float) -> void:
	var v: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * rate, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _plancher(global_position)
	if global_position.y < g + 0.4:
		global_position.y = g + 0.4
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.3:
		var nf: Vector3 = facing.lerp(hv.normalized(), clampf(delta * 2.5, 0.0, 1.0)).normalized()
		_visual.rotation.z = lerpf(_visual.rotation.z, clampf(facing.cross(nf).y * 25.0, -0.6, 0.6), clampf(delta * 3.0, 0.0, 1.0))
		facing = nf
	rotation.y = atan2(facing.x, facing.z)
	_visual.rotation.x = lerpf(_visual.rotation.x, clampf(-velocity.y * 0.07, -0.5, 0.9), clampf(delta * 3.0, 0.0, 1.0))


func _fly_gypaete(delta: float, p: Vector3) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	var rate: float = 1.0
	match state:
		"vol":
			_orbit_a += delta * 0.14
			var rr: float = 26.0 + _flank * 5.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _plancher(target) + _alt
			_cd136 -= delta
			if _cd136 <= 0.0:
				# un os : il le lâchera sur les rochers, pas loin du héros
				var ok: bool = false
				for k in range(10):
					var a: float = randf() * TAU
					var q: Vector3 = p + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 7.0)
					if not _au_vide(q) and _ground_at(q) > 0.3:
						_os_cible = Vector3(q.x, _ground_at(q), q.z)
						ok = true
						break
				if ok:
					state = "monte_os"
					timer = 16.0
					if _os != null:
						_os.visible = true
				else:
					_cd136 = 3.0
		"monte_os":
			target = _os_cible + Vector3.UP * 14.0
			speed *= 0.9
			var hd: float = Vector2(global_position.x - _os_cible.x, global_position.z - _os_cible.z).length()
			if (hd < 2.5 and absf(global_position.y - target.y) < 4.0) or timer <= 0.0:
				if manager.has_method("spit"):
					manager.spit(global_position + Vector3.DOWN * 0.3, _os_cible, int(spec["degats"]), "os")
				lachers += 1
				if _os != null:
					_os.visible = false
				state = "plane_bas"
				timer = 5.0
		"plane_bas":
			_orbit_a += delta * 0.6
			target = _os_cible + Vector3(cos(_orbit_a) * 8.0, 6.0, sin(_orbit_a) * 8.0)
			speed *= 0.6
			if timer <= 0.0:
				state = "vol"
				_cd136 = randf_range(14.0, 22.0)
		"fuite_air":
			target = global_position + Vector3(facing.x, 0, facing.z) * 10.0 + Vector3.UP * 8.0
			if timer <= 0.0:
				state = "vol"
				_cd136 = randf_range(10.0, 16.0)
		_:
			state = "vol"
			target = global_position
	_voler137(delta, target, speed, rate)


func _fly_meduse(delta: float, p: Vector3) -> void:
	# elle dérive au gré de l'air, sans rien voir ; la cloche se contracte et la soulève un peu
	var pulse: float = sin(_clock * 1.8 + _flank * 4.0)
	var target: Vector3 = home + Vector3(cos(_clock * 0.12 + _flank * 3.0) * 3.0, 0, sin(_clock * 0.09 + _flank) * 3.0)
	target.y = _plancher(target) + _alt + 0.25 * pulse
	var v: Vector3 = (target - global_position).limit_length(float(spec["vitesse"]))
	velocity = velocity.lerp(v, clampf(delta * 1.0, 0.0, 1.0))
	global_position += velocity * delta
	# ses filaments pendent sous elle : qui passe dessous se fait piquer
	_sting_t -= delta
	var hd: float = Vector2(p.x - global_position.x, p.z - global_position.z).length()
	if hd < float(spec["portee"]) and p.y + 1.7 > global_position.y - 1.6 and p.y < global_position.y + 0.3 and _sting_t <= 0.0:
		_sting_t = float(spec["armer"])
		stings += 1
		landed_hits += 1
		manager.hurt_player(int(spec["degats"]), global_position)
		var away: Vector3 = p - global_position
		away.y = 0.0
		manager.shove((away.normalized() if away.length() > 0.05 else Vector3.FORWARD) * 3.0)
		_sound("menace")
		manager.alert(self)
	state = "derive"


func _fly_raie(delta: float, p: Vector3, dist: float) -> void:
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"plane":
			_orbit_a += delta * (0.22 + _flank * 0.03)
			var rr: float = 18.0 + _flank * 4.0
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a) * rr)
			target.y = _plancher(target) + _alt + sin(_clock * 0.5 + _flank) * 0.8
			speed *= 0.6
			_cd136 -= delta
			if _cd136 <= 0.0 and dist < float(spec["vue"]) * 2.0:
				_cible = Vector3(p.x, _plancher(p) + 2.6, p.z)
				state = "rase"
				timer = 7.0
		"rase":
			target = _cible
			speed *= 1.1
			var hd: float = Vector2(global_position.x - _cible.x, global_position.z - _cible.z).length()
			if hd < 3.0 or timer <= 0.0:
				if hd < 3.0:
					passages += 1
				state = "remonte"
				timer = 3.0
		"remonte", "fuite_air":
			target = global_position + Vector3(facing.x, 0, facing.z) * 12.0 + Vector3.UP * 5.0
			if timer <= 0.0:
				state = "plane"
				_cd136 = randf_range(10.0, 18.0)
		_:
			state = "plane"
			target = global_position
	_voler137(delta, target, speed, 1.2)


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS137.has(kind):
		super._animate132(delta, speed)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	var night: bool = manager != null and manager.has_method("night") and bool(manager.night())
	for m in _eye_glow:
		(m as StandardMaterial3D).emission_energy_multiplier = 2.5 if night else 0.3
	match kind:
		"papillon_morpho":
			_anim_papillons()
		"cerf_blanc":
			_anim_cerf(delta, speed)
		"blaireau":
			_anim_blaireau(delta, speed)
		"marmotte":
			_anim_marmotte(delta, walk)
		"gypaete":
			_anim_gypaete()
		"lynx":
			_anim_lynx(delta, speed)
		"meduse_celeste":
			_anim_meduse(night)
		"raie_celeste":
			_anim_raie()


func _anim_papillons() -> void:
	var t: float = _clock
	var pose: bool = state == "pose"
	# les places sur le héros : les épaules, les bras, le haut de la tête
	var places: Array = [Vector3(0.2, 0.05, 0.0), Vector3(-0.21, 0.04, 0.02), Vector3(0.0, 0.33, 0.0), Vector3(0.3, -0.25, 0.08), Vector3(-0.3, -0.22, 0.06), Vector3(0.05, -0.1, 0.17)]
	for e in _papillons:
		var b: Node3D = e[0]
		var ph: float = e[2]
		var i: int = e[3]
		var pos: Vector3
		if pose:
			pos = places[i % places.size()]
		else:
			var r: float = 0.6 + 0.3 * sin(t * 0.7 + ph)
			pos = Vector3(cos(t * 0.9 + ph) * r, sin(t * 2.3 + ph * 2.0) * 0.25, sin(t * 1.1 + ph) * r * 0.8)
		b.position = b.position.lerp(pos, 0.08)
		b.rotation.y = (t * 0.9 + ph + PI * 0.5) if not pose else ph
		# posés : les ailes s'ouvrent et se ferment lentement ; en vol : battements vifs, quelques glissades
		var flap: float
		if pose:
			flap = 0.6 + 0.6 * sin(t * 1.5 + ph)
		else:
			flap = 0.25 + 0.9 * absf(sin(t * 11.0 + ph)) * (0.3 if fmod(t + ph, 3.0) < 0.5 else 1.0)
		for w in e[1]:
			(w[0] as Node3D).rotation.z = float(w[1]) * flap
			(w[0] as Node3D).rotation.y = 0.0 if bool(w[2]) else float(w[1]) * 0.1


func _anim_cerf(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		var up: float = -0.35 if state == "observe" else (0.55 if (state == "erre" and _graze > 0.0) else 0.0)
		head.rotation.x = lerpf(head.rotation.x, up, clampf(delta * 4.0, 0.0, 1.0))
	if state == "bonds":
		# en plein bond : les antérieurs repliés devant, les postérieurs tendus derrière
		var k: float = sin(_bond_u * PI)
		for l in _legs:
			var leg: Node3D = l[0]
			leg.rotation.x = (-0.9 if int(l[2]) < 2 else 0.8) * k
		var body: Node3D = _pivots.get("corps")
		if body != null:
			body.rotation.x = lerpf(-0.25, 0.25, _bond_u)
	else:
		var body2: Node3D = _pivots.get("corps")
		if body2 != null:
			body2.rotation.x = lerpf(body2.rotation.x, 0.0, clampf(delta * 6.0, 0.0, 1.0))
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.x = -0.6 if state == "bonds" else 0.0


func _anim_blaireau(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var low: float = 1.0 if state in ["grogne", "armer"] else 0.0
	_crouch = lerpf(_crouch, low, clampf(delta * 6.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = -0.04 * _crouch + (0.03 * sin(_clock * 30.0) if state == "grogne" else 0.0) * 0.3
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 0.25 * _crouch + (-0.3 if state == "frappe" else 0.0)


func _anim_marmotte(delta: float, walk: float) -> void:
	var t: float = _clock
	var up: float = 1.0 if state in ["debout", "siffle"] else 0.0
	_stand = lerpf(_stand, up, clampf(delta * 6.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		var bas := Basis(Vector3.RIGHT, -1.15 * _stand)
		var pv := Vector3(0, 0.06, -0.14)
		body.transform = Transform3D(bas, pv - bas * pv + Vector3(0, -0.07 * _stand, 0))
		if walk > 0.05 and _stand < 0.1:
			body.position.y += absf(sin(t * 12.0)) * 0.025 * minf(walk, 1.2)
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 1.0 * _stand + (0.4 if (state == "erre" and _graze > 0.0) else 0.0)
		head.rotation.y = sin(t * 0.8) * 0.5 * _stand
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		if i < 2 and _stand > 0.3:
			leg.rotation.x = -1.3 * _stand
		else:
			leg.rotation.x = sin(t * 14.0 + (0.0 if i in [0, 3] else PI)) * 0.6 * minf(walk, 1.0)
	_visual.position.y = -_down * 0.35


func _anim_gypaete() -> void:
	var t: float = _clock
	var flap: float = sin(t * 1.8) * 0.04
	if state == "monte_os":
		flap = sin(t * 3.0) * 0.3
	elif state == "fuite_air":
		flap = sin(t * 4.0) * 0.45
	for e in _wings:
		var wing: Node3D = e[0]
		var hand: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * (flap + 0.04)
		hand.rotation.z = sx * (flap * 0.6 - 0.05)
	var talons: Node3D = _pivots.get("serres")
	if talons != null:
		talons.rotation.x = 0.4 if _os != null and _os.visible else 1.0
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(t * 0.7) * 0.08


func _anim_lynx(delta: float, speed: float) -> void:
	super._animate132(delta, speed)
	var low: float = 0.0
	if state == "aguet":
		low = 1.0
	elif state == "armer":
		low = 1.2
	_crouch = lerpf(_crouch, low, clampf(delta * 5.0, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		body.position.y = -0.17 * _crouch
	for l in _legs:
		if speed < 0.1:
			(l[0] as Node3D).rotation.x = (0.5 if int(l[2]) < 2 else -0.45) * _crouch
	var head: Node3D = _pivots.get("tete")
	if head != null:
		head.rotation.x = 0.2 * _crouch
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(_clock * (9.0 if state == "armer" else 1.5)) * (0.3 if state == "armer" else 0.1)


func _anim_meduse(night: bool) -> void:
	var t: float = _clock
	var pulse: float = sin(t * 1.8 + _flank * 4.0)
	var bell: Node3D = _pivots.get("cloche")
	if bell != null:
		bell.scale = Vector3(1.0 - 0.1 * pulse, 1.0 + 0.14 * pulse, 1.0 - 0.1 * pulse)
	for e in _tentacules:
		var tp: Node3D = e[0]
		var a: float = e[1]
		var ph: float = e[2]
		tp.rotation = Vector3(sin(t * 0.9 + ph) * 0.12 * cos(a), 0.0, sin(t * 0.8 + ph) * 0.12 * sin(a) - 0.05 * pulse)
	var glow: float = 1.6 if night else 0.35
	for m in _meduse_mats:
		(m as StandardMaterial3D).emission_energy_multiplier = glow * (0.85 + 0.15 * pulse)


func _anim_raie() -> void:
	var t: float = _clock
	var amp: float = 0.32 if state == "plane" else 0.45
	for e in _wings:
		var wing: Node3D = e[0]
		var tip: Node3D = e[1]
		var sx: float = e[2]
		wing.rotation.z = sx * sin(t * 1.4 + _flank) * amp
		tip.rotation.z = sx * sin(t * 1.4 + _flank - 0.9) * amp * 1.2
	var tail: Node3D = _pivots.get("queue")
	if tail != null:
		tail.rotation.y = sin(t * 0.9) * 0.15
		tail.rotation.x = sin(t * 1.4 - 1.6) * 0.1

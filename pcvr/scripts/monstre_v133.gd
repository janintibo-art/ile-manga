extends "res://scripts/monstre_v132.gd"
## V133 : la faune sauvage de la grande île de l'est, de l'Île Al Dente et de l'Île Crayonnée.
## (Les bêtes de la V132 passent toujours par monstre_v132.gd : on ne fait ici que les nouvelles.)
## Cinq caractères nouveaux :
##  - colosse (ours des landes, gomme géante) : lent et lourd ; il se dresse (ou se cabre)… puis
##    s'abat devant lui. Les coups ne l'arrêtent pas : on recule, on roule, on frappe après ;
##  - sauteur (crapaud des vasières, tache d'encre) : il se tasse sur lui-même, puis bondit en
##    cloche là où se tenait le héros. On s'écarte, on le frappe quand il retombe ;
##  - rouleur (boulette enragée) : elle roule droit sur le héros et vire lentement : un pas de
##    côté au dernier moment… Coupée en deux, elle fait deux petites boulettes ;
##  - fouet (spaghetti sauvage) : un nid de pâtes qui avance à peine, mais dont les brins
##    fouettent loin. Il les ramène en arrière avant de frapper ;
##  - kamikaze (tomate) : elle sautille vers le héros, gonfle… et éclate (de la sauce !).
## Et des cousins des caractères de la V132 : l'aurochs (chargeur), le loup des plaines et les
## gribouillis (meute), le scorpion des dunes (dard), le serpent des sables (embuscade), le feu
## follet des marais (volant).

const SPECS133 := {
	"aurochs": {"pv": 34, "vitesse": 2.2, "degats": 2, "portee": 2.0, "armer": 1.1, "repos": 2.0, "vue": 11.0, "laisse": 30.0,
		"rayon": 0.85, "haut": 1.0, "nom": "Aurochs des prairies", "genre": "chargeur", "charge": 9.0, "col": ["boite", Vector3(0.9, 1.3, 2.0)]},
	"loup_plaine": {"pv": 12, "vitesse": 4.6, "degats": 1, "portee": 1.8, "armer": 0.45, "repos": 1.2, "vue": 20.0, "laisse": 50.0,
		"rayon": 0.55, "haut": 0.8, "nom": "Loup des plaines", "genre": "meute", "col": ["boite", Vector3(0.7, 0.9, 1.5)]},
	"ours_lande": {"pv": 48, "vitesse": 2.0, "degats": 3, "portee": 2.3, "armer": 1.0, "repos": 2.2, "vue": 9.0, "laisse": 22.0,
		"rayon": 0.85, "haut": 1.1, "nom": "Ours des landes", "genre": "colosse", "territoire": true, "col": ["boite", Vector3(1.0, 1.2, 1.8)]},
	"crapaud_vase": {"pv": 14, "vitesse": 1.4, "degats": 1, "portee": 1.4, "armer": 0.65, "repos": 1.5, "vue": 11.0, "laisse": 26.0,
		"rayon": 0.5, "haut": 0.4, "nom": "Crapaud des vasières", "genre": "sauteur", "saut": 7.0, "col": ["boite", Vector3(0.7, 0.45, 0.8)]},
	"feu_follet": {"pv": 3, "vitesse": 3.6, "degats": 1, "portee": 1.0, "armer": 0.5, "repos": 1.5, "vue": 14.0, "laisse": 40.0,
		"rayon": 0.35, "haut": 0.1, "nom": "Feu follet des marais", "genre": "volant", "vol": true, "col": ["boule", 0.25, 0.0]},
	"scorpion_dunes": {"pv": 20, "vitesse": 2.6, "degats": 2, "portee": 2.0, "armer": 0.7, "repos": 1.4, "vue": 10.0, "laisse": 26.0,
		"rayon": 0.7, "haut": 0.45, "nom": "Scorpion des dunes", "genre": "dard", "col": ["boite", Vector3(1.0, 0.5, 1.4)]},
	"serpent_sable": {"pv": 12, "vitesse": 3.2, "degats": 2, "portee": 1.8, "armer": 0.45, "repos": 1.6, "vue": 4.2, "laisse": 14.0,
		"rayon": 0.4, "haut": 0.25, "nom": "Serpent des sables", "genre": "embuscade", "col": ["boite", Vector3(0.4, 0.3, 1.4)]},
	"boulette": {"pv": 16, "vitesse": 3.4, "degats": 1, "portee": 1.0, "armer": 0.5, "repos": 1.0, "vue": 13.0, "laisse": 30.0,
		"rayon": 0.5, "haut": 0.45, "nom": "Boulette enragée", "genre": "rouleur", "col": ["boule", 0.42, 0.42]},
	"boulette_mini": {"pv": 4, "vitesse": 4.2, "degats": 1, "portee": 0.8, "armer": 0.4, "repos": 1.0, "vue": 13.0, "laisse": 30.0,
		"rayon": 0.3, "haut": 0.25, "nom": "Petite boulette", "genre": "rouleur", "col": ["boule", 0.24, 0.24]},
	"spaghetti_sauvage": {"pv": 22, "vitesse": 0.9, "degats": 2, "portee": 2.0, "armer": 0.75, "repos": 1.5, "vue": 9.0, "laisse": 14.0,
		"rayon": 0.7, "haut": 0.7, "nom": "Spaghetti sauvage", "genre": "fouet", "col": ["boule", 0.6, 0.6]},
	"tomate_kamikaze": {"pv": 2, "vitesse": 3.0, "degats": 1, "portee": 1.7, "armer": 0.75, "repos": 1.0, "vue": 14.0, "laisse": 40.0,
		"rayon": 0.35, "haut": 0.3, "nom": "Tomate kamikaze", "genre": "kamikaze", "col": ["boule", 0.27, 0.27]},
	"gribouillis": {"pv": 7, "vitesse": 4.2, "degats": 1, "portee": 1.5, "armer": 0.4, "repos": 1.1, "vue": 16.0, "laisse": 40.0,
		"rayon": 0.4, "haut": 0.4, "nom": "Gribouillis", "genre": "meute", "col": ["boule", 0.32, 0.32]},
	"tache_encre": {"pv": 10, "vitesse": 1.6, "degats": 1, "portee": 1.4, "armer": 0.55, "repos": 1.3, "vue": 12.0, "laisse": 28.0,
		"rayon": 0.5, "haut": 0.2, "nom": "Tache d'encre", "genre": "sauteur", "saut": 6.0, "col": ["boite", Vector3(0.8, 0.3, 0.8)]},
	"gomme_geante": {"pv": 44, "vitesse": 1.5, "degats": 3, "portee": 2.3, "armer": 1.1, "repos": 2.3, "vue": 10.0, "laisse": 24.0,
		"rayon": 0.95, "haut": 0.9, "nom": "Gomme géante", "genre": "colosse", "col": ["boite", Vector3(1.0, 0.8, 1.7)]},
}
const SOUNDS133 := {
	"aurochs": ["aurochs_meugle", "aurochs_meugle"], "loup_plaine": ["loup_menace", "loup_hurle"],
	"ours_lande": ["ours_rugit", "ours_rugit"], "crapaud_vase": ["grenouille_coasse", "grenouille_coasse"],
	"feu_follet": ["follet_menace", "follet_mort"], "scorpion_dunes": ["scorpion_menace", "scorpion_mort"],
	"serpent_sable": ["serpent_menace", "monstre_mort"], "boulette": ["boulette_grogne", "slime_divise"],
	"boulette_mini": ["boulette_grogne", "splotch"], "spaghetti_sauvage": ["spaghetti_fouet", "plante_mort"],
	"tomate_kamikaze": ["champi_boing", "tomate_splat"], "gribouillis": ["gribouillis_griffe", "gribouillis_griffe"],
	"tache_encre": ["slime_saut", "splotch"], "gomme_geante": ["gomme_couine", "gomme_couine"],
}
const ALERTES133 := {
	"aurochs": "Un aurochs ! Quand il baisse ses grandes cornes et gratte le sol, il va charger : écarte-toi au dernier moment, puis frappe-le pendant qu'il souffle.",
	"loup_plaine": "Des loups des plaines ! Ils chassent en meute : garde-les devant toi, et pare quand l'un d'eux bondit.",
	"ours_lande": "Un ours des landes ! Quand il se dresse sur ses pattes arrière, il va abattre ses griffes devant lui : recule ou roule sur le côté, puis frappe-le pendant qu'il reprend son souffle. Tes coups ne l'arrêtent pas.",
	"crapaud_vase": "Un crapaud des vasières ! Quand il se tasse sur ses pattes, il va bondir sur toi : écarte-toi, puis frappe-le quand il retombe.",
	"feu_follet": "Un feu follet ! Il danse devant toi pour t'attirer… puis il fonce sur toi. Frappe-le au moment où il approche.",
	"scorpion_dunes": "Un scorpion des dunes ! Quand il relève la queue, son dard va frapper par-dessus sa tête : recule, puis frappe-le.",
	"serpent_sable": "Un serpent des sables ! Il se cache sous le sable et jaillit quand on passe : regarde où tu marches.",
	"boulette": "Une boulette enragée ! Elle roule droit sur toi : fais un pas de côté au dernier moment. Et attention : coupée en deux, elle fait deux petites boulettes !",
	"spaghetti_sauvage": "Un spaghetti sauvage ! Il avance à peine, mais ses brins fouettent loin : quand il les ramène en arrière, recule hors de portée, puis frappe-le.",
	"tomate_kamikaze": "Une tomate kamikaze ! Quand elle gonfle, elle va éclater : éloigne-toi vite… ou frappe-la avant !",
	"gribouillis": "Des gribouillis ! Ils filent dans tous les sens et attaquent en bande : garde-les devant toi.",
	"tache_encre": "Une tache d'encre ! Elle se tasse avant de bondir : écarte-toi, puis frappe-la quand elle s'étale.",
	"gomme_geante": "Une gomme géante ! Quand elle se cabre, elle va s'abattre devant elle pour t'effacer : recule ou roule, puis frappe-la. Tes coups ne l'arrêtent pas.",
}
const GENRES133 := ["colosse", "sauteur", "rouleur", "fouet", "kamikaze"]

var _rear: float = 0.0
var _jump_from: Vector3 = Vector3.ZERO
var _jump_to: Vector3 = Vector3.ZERO
var _jump_t: float = 0.0
var _jump_dur: float = 0.6
var _jump_h: float = 1.0
var _land_t: float = 0.0
var _roll_v: float = 0.0
var _hit_cd: float = 0.0
var _swell: float = 0.0
var _explose: bool = false              # la tomate a éclaté d'elle-même (ni butin ni expérience)
var _blow: bool = false                 # le coup est parti (frappe du colosse, du fouet)
var _whips: Array = []                  # spaghetti : [[trois jointures], angle, devant]
var _boil: Array = []                   # gribouillis : les traits qui « bouillonnent »
var _boil_mi: MeshInstance3D
var _boil_t: float = 0.0
var _boil_i: int = 0
var _steam_t: float = 1.0
var _segs133: Array = []                # serpent : les anneaux, de la tête à la queue
var _tail133: Array = []                # scorpion : [anneau, angle au repos]
var _pinces: Array = []                 # scorpion : [doigt mobile, côté]
var _glow_mat: StandardMaterial3D
var _glow_light: OmniLight3D
var _throat: MeshInstance3D
var jumps: int = 0                      # tests
var landed_hits: int = 0                # tests


static func spec_of(k: String) -> Dictionary:
	if SPECS133.has(k):
		return SPECS133[k]
	return SPECS132.get(k, {})


static func has_kind(k: String) -> bool:
	return SPECS133.has(k) or SPECS132.has(k)


func setup(m: Node, k: String, at: Vector3) -> void:
	if not SPECS133.has(k):
		super.setup(m, k, at)
		return
	manager = m
	kind = k
	spec = SPECS133[k]
	genre = str(spec["genre"])
	vol = bool(spec.get("vol", false))
	peaceful = int(spec["degats"]) == 0
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
		"aurochs":
			_build_aurochs()
		"loup_plaine":
			# le même gabarit que le loup du Bois-Doré, le pelage des plaines (fauve et gris)
			kind = "loup_bois"
			_build_quadrupede({"long": 1.15, "haut": 0.72, "rayon": 0.24, "dos": Color(0.56, 0.49, 0.38), "tete": 0.5, "museau": 0.3,
				"queue": 0.6, "patte": 0.05, "poil": 0.92, "oreilles": 0.16, "bosse": 0.04, "yeux": Color(1.0, 0.75, 0.25)})
			kind = k
		"ours_lande":
			_build_ours()
		"crapaud_vase":
			_build_crapaud()
		"feu_follet":
			_build_follet()
		"scorpion_dunes":
			_build_scorpion()
		"serpent_sable":
			_build_serpent()
		"boulette", "boulette_mini":
			_build_boulette()
			if k == "boulette_mini":
				_visual.scale = Vector3.ONE * 0.56
		"spaghetti_sauvage":
			_build_spaghetti()
		"tomate_kamikaze":
			_build_tomate()
		"gribouillis":
			_build_gribouillis()
		"tache_encre":
			_build_encre()
		"gomme_geante":
			_build_gomme()
	add_to_group("cibles_v28")
	add_to_group("faune_v132")
	global_position = at
	facing = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if facing.length() < 0.5:
		facing = Vector3.FORWARD
	_flank = randf_range(-1.0, 1.0)
	_wander_t = randf_range(0.5, 3.0)
	if genre == "embuscade":
		_hidden = true
		state = "cache"
	if vol:
		_alt = randf_range(1.5, 2.4)
		_orbit_c = Vector3(at.x, 0.0, at.z)
		_orbit_a = randf() * TAU
		state = "vol"
	elif state != "cache":
		state = "erre"
	_base_scale = _visual.scale
	if _hidden:
		_visual.scale = Vector3(_base_scale.x, _base_scale.y * 0.35, _base_scale.z)
		_visual.position.y = -0.3


# =================================================================== petits outils de modelage

func _tube_fn(key: String, path: Array, radii: Array, segs: int, aplat: float, fn: Callable) -> ArrayMesh:
	if _meshes132.has(key):
		return _meshes132[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Armes132._add_tube(st, path, radii, segs, aplat, Transform3D.IDENTITY, fn)
	var m: ArrayMesh = st.commit()
	_meshes132[key] = m
	return m


## Une boule déformée (boulette, tomate, encre, gomme) : pos_fn(direction) -> point de la
## surface, col_fn(direction, point) -> couleur. Les normales sont lissées.
func _blob_mesh(key: String, pos_fn: Callable, col_fn: Callable, nlat: int, nlon: int) -> ArrayMesh:
	if _meshes132.has(key):
		return _meshes132[key]
	var rows: Array = []
	for i in range(nlat + 1):
		var th: float = PI * float(i) / float(nlat)
		var row: Array = []
		for j in range(nlon):
			var ph: float = TAU * float(j) / float(nlon)
			var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			if i == 0:
				d = Vector3.UP
			elif i == nlat:
				d = Vector3.DOWN
			var p: Vector3 = pos_fn.call(d)
			row.append([p, col_fn.call(d, p)])
		rows.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(nlat):
		for j in range(nlon):
			var j2: int = (j + 1) % nlon
			if i > 0:
				_otri(st, rows[i][j], rows[i][j2], rows[i + 1][j2])
			if i < nlat - 1:
				_otri(st, rows[i][j], rows[i + 1][j2], rows[i + 1][j])
	st.index()
	st.generate_normals()
	var m: ArrayMesh = st.commit()
	_meshes132[key] = m
	return m


## Un triangle tourné vers l'extérieur (la normale générée vaut -(b-a)×(c-a)).
func _otri(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	var n: Vector3 = -(pb - pa).cross(pc - pa)
	if n.length_squared() < 1e-14:
		return
	var q: Array = [a, b, c]
	if n.dot(pa + pb + pc) < 0.0:
		q = [a, c, b]
	for v in q:
		st.set_color(v[1])
		st.add_vertex(v[0])


func _unit_sphere() -> Mesh:
	if not _meshes132.has("133:sphere"):
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 16
		s.rings = 10
		_meshes132["133:sphere"] = s
	return _meshes132["133:sphere"]


## Deux yeux ronds : le blanc, la pupille noire, un éclat ; et des sourcils froncés si on veut.
func _eyes(parent: Node3D, at: Vector3, gap: float, r: float, brows: Color = Color(0, 0, 0, 0), flat: float = 0.7) -> void:
	var blanc := _mat(Color(0.96, 0.95, 0.92), 0.25)
	var noir := _mat(Color(0.02, 0.02, 0.025), 0.1)
	var eclat := _mat(Color(1, 1, 1), 0.1, 2.0)
	for sx in [-1.0, 1.0]:
		var e: Vector3 = at + Vector3(sx * gap, 0, 0)
		_mesh(parent, _unit_sphere(), blanc, e, Vector3(r, r * 1.12, r * flat))
		_mesh(parent, _unit_sphere(), noir, e + Vector3(-sx * r * 0.12, -r * 0.05, r * flat * 0.78), Vector3(r * 0.5, r * 0.58, r * 0.35))
		_mesh(parent, _unit_sphere(), eclat, e + Vector3(-sx * r * 0.02, r * 0.18, r * flat * 0.98), Vector3.ONE * r * 0.14)
		_eye_mats.append(noir)
		if brows.a > 0.0:
			var bm := BoxMesh.new()
			bm.size = Vector3(r * 1.9, r * 0.32, r * 0.4)
			_mesh(parent, bm, _mat(brows, 0.6), e + Vector3(sx * r * 0.1, r * 1.25, r * 0.35), Vector3.ONE, Vector3(0, 0, sx * 0.38))


func _fx() -> Node:
	if manager == null or manager.main == null:
		return null
	return manager.main.get("combat_fx_v129")


func _puff(at: Vector3, n: int, col: Color, s0: float, s1: float, life: float = 0.8, v0: float = 0.6, v1: float = 2.0) -> void:
	var fx: Node = _fx()
	if fx != null and fx.has_method("_puffs"):
		fx._puffs(at, n, col, s0, s1, life, v0, v1, 0.4, 0.2)


# =================================================================== modèles : la grande île

## L'aurochs : un grand bovin sauvage, robe presque noire, raie claire sur le dos, mufle clair,
## et de longues cornes en lyre, pâles aux pointes noires.
func _build_aurochs() -> void:
	var R: float = 0.4
	var hl: float = 0.56
	var L: float = 1.55
	var H: float = 1.02
	var bosse: float = 0.22
	_build_quadrupede({"long": L, "haut": H, "rayon": R, "dos": Color(0.16, 0.115, 0.085), "tete": hl, "museau": 0.26,
		"queue": 0.62, "patte": 0.085, "poil": 0.9, "oreilles": 0.13, "bosse": bosse})
	var head: Node3D = _pivots["tete"]
	var corne := _vmat(Color(0.9, 0.86, 0.74), 0.3)
	var tip := func(s: float, _a: float) -> float: return lerpf(1.0, 0.18, smoothstep(0.62, 0.95, s))
	for sx in [-1.0, 1.0]:
		var cp: Array = []
		var cr: Array = []
		for i in range(14):
			var u: float = float(i) / 13.0
			# vers l'extérieur, puis vers l'avant ; la pointe remonte et rentre un peu
			cp.append(Vector3(sx * (R * 0.3 + u * 0.46 - u * u * 0.16), R * 0.6 + u * 0.06 + u * u * 0.3, hl * 0.08 + sin(u * PI * 0.85) * 0.24))
			cr.append(lerpf(0.065, 0.01, pow(u, 0.8)))
		_put(head, _tube_fn("aurochs:corne%d" % int(sx), cp, cr, 9, 1.0, tip), corne)
	_mesh(head, _unit_sphere(), _mat(Color(0.6, 0.53, 0.44), 0.85), Vector3(0, -0.1, hl * 0.7 + 0.2), Vector3(0.17, 0.13, 0.12))
	# la raie claire le long de l'échine
	var body: Node3D = _pivots["corps"]
	var sp: Array = []
	var sr: Array = []
	for i in range(9):
		var u2: float = float(i) / 8.0
		var y: float = H + 0.06 * sin(u2 * PI) + bosse * smoothstep(0.55, 0.85, u2)
		var r: float = R * (0.78 + 0.32 * sin(u2 * PI * 0.95 + 0.1)) * (1.0 + bosse * 0.8 * smoothstep(0.6, 0.9, u2))
		sp.append(Vector3(0, y + r * 1.18 * 0.93, lerpf(-L * 0.42, L * 0.44, u2)))
		sr.append(0.05 * sin(u2 * PI) + 0.012)
	_put(body, _tube_fn("aurochs:raie", sp, sr, 8, 0.45, Callable()), _mat(Color(0.5, 0.4, 0.3), 0.95))
	var tail: Node3D = _pivots["queue"]
	_mesh(tail, _unit_sphere(), _mat(Color(0.08, 0.06, 0.05), 0.95), Vector3(0, -0.6, -0.42), Vector3(0.06, 0.13, 0.06))


## L'ours des landes : massif, la bosse des épaules, de petites oreilles rondes, le museau plus
## clair, et de longues griffes aux pattes avant.
func _build_ours() -> void:
	var dos := Color(0.3, 0.21, 0.14)
	_build_quadrupede({"long": 1.42, "haut": 0.82, "rayon": 0.42, "dos": dos, "tete": 0.42, "museau": 0.2,
		"queue": 0.1, "patte": 0.12, "poil": 0.97, "oreilles": 0.001, "bosse": 0.3})
	var head: Node3D = _pivots["tete"]
	var fur := _vmat(dos.lightened(0.05), 0.97)
	for sx in [-1.0, 1.0]:
		_mesh(head, _unit_sphere(), fur, Vector3(sx * 0.21, 0.27, 0.0), Vector3(0.085, 0.085, 0.045))
		_mesh(head, _unit_sphere(), _mat(dos.darkened(0.5), 0.9), Vector3(sx * 0.21, 0.27, 0.02), Vector3(0.05, 0.05, 0.03))
	_mesh(head, _unit_sphere(), _mat(Color(0.52, 0.42, 0.31), 0.9), Vector3(0, -0.06, 0.42 * 0.7 + 0.1), Vector3(0.13, 0.11, 0.14))
	var griffe := _mat(Color(0.86, 0.82, 0.72), 0.35)
	for l in _legs:
		if int(l[2]) >= 2:
			continue
		var leg: Node3D = l[0]
		var foot_y: float = -(0.82 - 0.042) + 0.03
		for c in range(4):
			var x: float = (float(c) - 1.5) * 0.045
			_mesh(leg, _cyl(0.0, 0.016, 0.1), griffe, Vector3(x, foot_y - 0.02, 0.17), Vector3.ONE, Vector3(PI * 0.5 + 0.35, 0, 0))


## Le crapaud des vasières : trapu, la peau grumeleuse couleur de vase, de gros yeux d'or à
## pupille couchée, un sac vocal qui se gonfle, les pattes arrière repliées, prêtes à détendre.
func _build_crapaud() -> void:
	var skin := _vmat(Color(0.37, 0.34, 0.2), 0.5)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var path: Array = [Vector3(0, 0.25, -0.33), Vector3(0, 0.3, -0.22), Vector3(0, 0.33, -0.05), Vector3(0, 0.32, 0.1),
		Vector3(0, 0.29, 0.24), Vector3(0, 0.25, 0.34), Vector3(0, 0.21, 0.41)]
	var radii: Array = [0.05, 0.22, 0.29, 0.29, 0.25, 0.17, 0.05]
	var mottle := func(s: float, a: float) -> float:
		return 0.5 + 0.5 * (0.5 - 0.5 * sin(a)) + 0.09 * sin(s * 37.0 + a * 6.0) * sin(s * 13.0 - a * 3.0)
	_put(body, _tube_fn("crapaud:corps", path, radii, 18, 0.6, mottle), skin)
	# pustules et glandes
	var wart := _mat(Color(0.27, 0.22, 0.11), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1330
	for i in range(30):
		var u: float = rng.randf_range(0.12, 0.8)
		var f: float = u * 6.0
		var i0: int = int(f)
		var t: float = f - i0
		var P: Vector3 = (path[i0] as Vector3).lerp(path[i0 + 1], t)
		var r: float = lerpf(float(radii[i0]), float(radii[i0 + 1]), t)
		var a: float = rng.randf_range(0.15, 0.85) * PI
		var q := Vector3(cos(a) * r * 0.95, sin(a) * r * 0.6 * 0.95, 0)
		var w: float = rng.randf_range(0.016, 0.034)
		_mesh(body, _unit_sphere(), wart, P + q, Vector3(w, w * 0.7, w))
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), wart, Vector3(sx * 0.13, 0.4, 0.1), Vector3(0.05, 0.035, 0.1))
		# l'œil d'or, la paupière, la pupille couchée
		var e := Vector3(sx * 0.12, 0.41, 0.25)
		var oeil := _mat(Color(0.85, 0.6, 0.12), 0.06)
		_mesh(body, _unit_sphere(), oeil, e, Vector3.ONE * 0.055)
		_mesh(body, _unit_sphere(), _mat(Color(0.02, 0.02, 0.02), 0.05), e + Vector3(sx * 0.012, 0.004, 0.044), Vector3(0.028, 0.012, 0.014))
		_eye_mats.append(oeil)
		_mesh(body, _unit_sphere(), skin, e + Vector3(0, 0.018, -0.012), Vector3(0.062, 0.035, 0.062))
	_throat = _mesh(body, _unit_sphere(), _mat(Color(0.66, 0.6, 0.38), 0.45), Vector3(0, 0.16, 0.29), Vector3(0.08, 0.055, 0.075))
	# les pattes : avant courtes, arrière repliées (cuisse, jambe, pied palmé)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var front: bool = i < 2
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.18, 0.24, 0.2) if front else Vector3(sx2 * 0.2, 0.25, -0.2)
		body.add_child(leg)
		if front:
			_put(leg, _tube_fn("crapaud:avant%d" % int(sx2), [Vector3.ZERO, Vector3(sx2 * 0.08, -0.12, 0.04), Vector3(sx2 * 0.1, -0.22, 0.07)], [0.05, 0.04, 0.03], 8, 1.0, Callable()), skin)
			_mesh(leg, _unit_sphere(), skin, Vector3(sx2 * 0.1, -0.235, 0.09), Vector3(0.05, 0.016, 0.055))
		else:
			_put(leg, _tube_fn("crapaud:arriere%d" % int(sx2), [Vector3.ZERO, Vector3(sx2 * 0.15, -0.08, 0.2), Vector3(sx2 * 0.14, -0.2, -0.05), Vector3(sx2 * 0.18, -0.235, 0.1)],
				[0.1, 0.07, 0.05, 0.03], 9, 1.0, Callable()), skin)
			_mesh(leg, _unit_sphere(), skin, Vector3(sx2 * 0.19, -0.24, 0.15), Vector3(0.07, 0.014, 0.09))
		_legs.append([leg, sx2, i])


## Le feu follet des marais : une flamme pâle, verte et bleutée, qui ne brûle rien ; un cœur
## blanc, un halo, des étincelles qui montent.
func _build_follet() -> void:
	var body := Node3D.new()
	body.name = "Flamme"
	_visual.add_child(body)
	_pivots["corps"] = body
	var path: Array = [Vector3(0, -0.15, 0), Vector3(0, -0.08, 0), Vector3(0, 0.02, 0), Vector3(0, 0.13, 0), Vector3(0, 0.24, 0), Vector3(0, 0.36, 0)]
	var radii: Array = [0.0, 0.1, 0.13, 0.1, 0.05, 0.0]
	var flame: ArrayMesh = _tube_fn("follet:flamme", path, radii, 14, 1.0, Callable())
	for layer in [[1.0, Color(0.35, 1.0, 0.65, 0.42)], [0.58, Color(0.75, 1.0, 0.9, 0.85)]]:
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		fm.cull_mode = BaseMaterial3D.CULL_DISABLED
		fm.albedo_color = layer[1]
		fm.disable_receive_shadows = true
		var mi := _put(body, flame, fm)
		mi.scale = Vector3.ONE * float(layer[0])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var core := _mat(Color(0.9, 1.0, 0.95), 0.2, 6.0)
	_mesh(body, _unit_sphere(), core, Vector3(0, 0.0, 0), Vector3.ONE * 0.04)
	if manager != null and manager.main != null and manager.main.has_method("_soft_dot_v24"):
		var halo := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.4, 1.4)
		var hm := StandardMaterial3D.new()
		hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hm.albedo_color = Color(0.3, 1.0, 0.6, 0.35)
		hm.albedo_texture = manager.main._soft_dot_v24()
		q.material = hm
		halo.mesh = q
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(halo)
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = Color(0.5, 1.0, 0.72)
	_glow_light.light_energy = 1.4
	_glow_light.omni_range = 7.0
	_glow_light.shadow_enabled = false
	body.add_child(_glow_light)
	var fx: Node = _fx()
	if fx != null and fx.has_method("_burst") and DisplayServer.get_name() != "headless":
		fx._burst(Vector3.ZERO, {"amount": 10, "life": 1.1, "v0": 0.05, "v1": 0.25, "radius": 0.08, "grav": Vector3(0, 0.6, 0), "size": 0.04,
			"explo": 0.0, "loop": true, "parent": body, "cols": [Color(0.85, 1.0, 0.92), Color(0.4, 1.0, 0.6), Color(0.2, 0.8, 0.5, 0.0)]})


## Le scorpion des dunes : la carapace en plaques couleur de sable, les pinces brun-rouge, la
## queue en anneaux recourbée au-dessus du dos, l'ampoule et son dard noir.
func _build_scorpion() -> void:
	var cuti := _vmat(Color(0.72, 0.54, 0.3), 0.36)
	cuti.metallic_specular = 0.65
	var pince := _vmat(Color(0.5, 0.29, 0.14), 0.32)
	pince.metallic_specular = 0.65
	var noir := _mat(Color(0.08, 0.05, 0.03), 0.2)
	var body := Node3D.new()
	body.name = "Corps"
	body.position.y = -0.08
	_visual.add_child(body)
	_pivots["corps"] = body
	var plates := func(s: float, a: float) -> float:
		var v: float = 0.62 + 0.38 * (0.5 - 0.5 * sin(a))
		if s > 0.3:
			var f: float = fposmod((s - 0.3) / 0.7 * 7.0, 1.0)
			v *= 1.0 - 0.38 * smoothstep(0.72, 1.0, f)
		return v
	var path: Array = []
	var radii: Array = []
	for i in range(57):
		var u: float = float(i) / 56.0
		path.append(Vector3(0, 0.3 + 0.03 * sin(u * PI), lerpf(0.52, -0.5, u)))
		var base: float = lerpf(0.1, 0.18, smoothstep(0.0, 0.3, u)) if u < 0.3 else lerpf(0.19, 0.1, smoothstep(0.3, 1.0, u))
		var plate: float = 1.0
		if u > 0.3:
			var f2: float = fposmod((u - 0.3) / 0.7 * 7.0, 1.0)
			plate = 1.0 - 0.1 * f2 * f2
		radii.append(base * plate * (1.0 - smoothstep(0.96, 1.0, u) * 0.4))
	_put(body, _tube_fn("scorpion:corps", path, radii, 14, 0.42, plates), cuti)
	# les yeux sur le dessus de la tête
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.022, 0.355, 0.43), Vector3.ONE * 0.016)
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.08, 0.335, 0.49), Vector3.ONE * 0.009)
	# la queue : cinq anneaux, puis l'ampoule et le dard
	var ring := func(s: float, a: float) -> float: return (0.66 + 0.34 * (0.5 - 0.5 * sin(a))) * (1.0 - 0.3 * smoothstep(0.85, 1.0, s))
	var parent: Node3D = body
	var pos := Vector3(0, 0.32, -0.47)
	var rest: Array = [0.75, 0.6, 0.55, 0.5, 0.45]
	for i in range(5):
		var seg := Node3D.new()
		seg.position = pos
		seg.rotation.x = float(rest[i])
		parent.add_child(seg)
		var ln: float = 0.165 - i * 0.008
		var r0: float = 0.078 - i * 0.006
		_put(seg, _tube_fn("scorpion:queue%d" % i, [Vector3(0, 0, 0.02), Vector3(0, 0.012, -ln * 0.5), Vector3(0, 0, -ln - 0.01)], [r0 * 0.8, r0, r0 * 0.78], 10, 0.9, ring), cuti)
		_tail133.append([seg, float(rest[i])])
		parent = seg
		pos = Vector3(0, 0, -ln)
	var tel := Node3D.new()
	tel.position = pos
	tel.rotation.x = 0.4
	parent.add_child(tel)
	_tail133.append([tel, 0.4])
	_put(tel, _tube_fn("scorpion:ampoule", [Vector3(0, 0, 0.01), Vector3(0, -0.012, -0.07), Vector3(0, -0.02, -0.135)], [0.05, 0.072, 0.03], 12, 0.85, Callable()), pince)
	_put(tel, _tube_fn("scorpion:dard", [Vector3(0, -0.02, -0.13), Vector3(0, -0.05, -0.19), Vector3(0, -0.1, -0.215), Vector3(0, -0.14, -0.2)], [0.024, 0.014, 0.006, 0.001], 8, 1.0, Callable()), noir)
	# les pinces : le bras, la main renflée, le doigt fixe, le doigt mobile
	for sx in [-1.0, 1.0]:
		_put(body, _tube_fn("scorpion:bras%d" % int(sx), [Vector3(sx * 0.07, 0.3, 0.44), Vector3(sx * 0.21, 0.31, 0.52), Vector3(sx * 0.3, 0.31, 0.63), Vector3(sx * 0.28, 0.3, 0.77)],
			[0.034, 0.04, 0.034, 0.04], 9, 0.85, Callable()), pince)
		var hand := Node3D.new()
		hand.position = Vector3(sx * 0.28, 0.3, 0.8)
		body.add_child(hand)
		_put(hand, _tube_fn("scorpion:main", [Vector3(0, 0, -0.05), Vector3(0, 0.0, 0.04), Vector3(0, 0, 0.11)], [0.05, 0.078, 0.05], 12, 0.7, Callable()), pince)
		_put(hand, _tube_fn("scorpion:doigt%d" % int(sx), [Vector3(sx * 0.03, 0, 0.09), Vector3(sx * 0.035, 0, 0.18), Vector3(sx * 0.0, 0, 0.26)], [0.03, 0.022, 0.004], 8, 0.8, Callable()), pince)
		var fing := Node3D.new()
		fing.position = Vector3(-sx * 0.028, 0, 0.09)
		hand.add_child(fing)
		_put(fing, _tube_fn("scorpion:mobile%d" % int(sx), [Vector3.ZERO, Vector3(-sx * 0.01, 0, 0.09), Vector3(sx * 0.02, 0, 0.16)], [0.026, 0.018, 0.003], 8, 0.8, Callable()), noir)
		_pinces.append([fing, sx])
	# huit pattes, genoux hauts
	for i in range(8):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var rowi: int = int(i / 2)
		var z: float = 0.34 - rowi * 0.13
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.12, 0.27, z)
		body.add_child(leg)
		var dz: float = 0.17 - rowi * 0.12
		_put(leg, _tube_fn("scorpion:patte%d_%d" % [rowi, int(side)], [Vector3.ZERO, Vector3(side * 0.15, 0.1, dz * 0.45), Vector3(side * 0.28, 0.03, dz * 0.85), Vector3(side * 0.36, -0.08, dz * 1.1), Vector3(side * 0.41, -0.185, dz * 1.2)],
			[0.034, 0.03, 0.024, 0.016, 0.006], 7, 1.0, Callable()), cuti)
		_legs.append([leg, side, i])


## Le serpent des sables : couleur de dune, des losanges bruns sur le dos, deux petites cornes
## au-dessus des yeux ; il dort sous le sable.
func _build_serpent() -> void:
	var skin := _vmat(Color(0.82, 0.7, 0.5), 0.55)
	var dark := _mat(Color(0.45, 0.32, 0.19), 0.6)
	var sph: Mesh = _unit_sphere()
	for k in range(28):
		var t: float = float(k) / 27.0
		var seg := Node3D.new()
		seg.position = Vector3(0, 0.09, 0.6 - k * 0.07)
		_visual.add_child(seg)
		var r: float = lerpf(0.08, 0.018, pow(t, 1.3)) * (0.88 if k < 2 else 1.0)
		_mesh(seg, sph, skin, Vector3.ZERO, Vector3(r, r * 0.78, r * 1.6))
		if k % 2 == 0 and k > 2 and k < 24:
			_mesh(seg, sph, dark, Vector3(0, r * 0.6, 0), Vector3(r * 0.72, r * 0.26, r * 0.85))
		_segs133.append(seg)
	var head: Node3D = _segs133[0]
	_mesh(head, sph, skin, Vector3(0, 0.02, 0.08), Vector3(0.085, 0.048, 0.12))
	var oeil := _mat(Color(0.95, 0.7, 0.2), 0.1)
	for sx in [-1.0, 1.0]:
		_mesh(head, sph, oeil, Vector3(sx * 0.055, 0.05, 0.1), Vector3.ONE * 0.02)
		_mesh(head, sph, _mat(Color(0.02, 0.02, 0.02), 0.1), Vector3(sx * 0.068, 0.05, 0.106), Vector3(0.006, 0.016, 0.008))
		_mesh(head, _cyl(0.0, 0.012, 0.05), dark, Vector3(sx * 0.05, 0.075, 0.085), Vector3.ONE, Vector3(-0.3, 0, sx * -0.25))
		_eye_mats.append(oeil)
	var langue := _mat(Color(0.2, 0.05, 0.08), 0.4)
	var tg := Node3D.new()
	tg.name = "Langue"
	tg.position = Vector3(0, 0.0, 0.2)
	head.add_child(tg)
	_pivots["langue"] = tg
	for sx in [-1.0, 1.0]:
		_mesh(tg, _cyl(0.002, 0.005, 0.07), langue, Vector3(sx * 0.008, 0, 0.03), Vector3.ONE, Vector3(PI * 0.5, sx * 0.25, 0))


# =================================================================== modèles : l'Île Al Dente

## La boulette enragée : une boulette de viande bien grillée, nappée de sauce tomate, des brins
## de persil ; deux yeux furieux qui, eux, ne roulent pas.
func _build_boulette() -> void:
	var r: float = 0.4
	var nz := FastNoiseLite.new()
	nz.seed = 133
	nz.frequency = 1.6
	var pos_fn := func(d: Vector3) -> Vector3:
		return d * r * (1.0 + 0.085 * nz.get_noise_3dv(d * 1.3) + 0.04 * nz.get_noise_3dv(d * 3.4 + Vector3(5, 1, 2)))
	var col_fn := func(d: Vector3, _p: Vector3) -> Color:
		var c := Color(0.43, 0.25, 0.15)
		c = c.lerp(Color(0.22, 0.12, 0.07), smoothstep(0.0, 0.45, nz.get_noise_3dv(d * 2.6 + Vector3(9, 3, 1))))
		var sauce: float = smoothstep(0.05, 0.4, nz.get_noise_3dv(d * 1.2 + Vector3(2, 7, 4))) * smoothstep(-0.4, 0.5, d.y)
		return c.lerp(Color(0.6, 0.11, 0.04), sauce * 0.9)
	var boule := Node3D.new()
	boule.name = "Boule"
	boule.position = Vector3(0, r, 0)
	_visual.add_child(boule)
	_pivots["boule"] = boule
	var m := _vmat(Color(1, 1, 1), 0.4)
	m.metallic_specular = 0.6
	_put(boule, _blob_mesh("boulette", pos_fn, col_fn, 18, 30), m)
	var persil := _mat(Color(0.18, 0.4, 0.1), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1333
	for i in range(16):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)).normalized()
		_mesh(boule, _unit_sphere(), persil, d * r * 1.0, Vector3(0.022, 0.012, 0.016))
	var face := Node3D.new()
	face.name = "Visage"
	_visual.add_child(face)
	_pivots["visage"] = face
	_eyes(face, Vector3(0, r + 0.15, r * 0.84), 0.13, 0.07, Color(0.16, 0.08, 0.04), 0.7)


## Le spaghetti sauvage : un nid de pâtes luisantes, nappé de sauce, une feuille de basilic ;
## cinq brins tressés qui ondulent… et fouettent.
func _build_spaghetti() -> void:
	var pates := _vmat(Color(0.97, 0.85, 0.52), 0.3)
	pates.metallic_specular = 0.7
	var sauce := _vmat(Color(0.66, 0.14, 0.05), 0.26)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	_mesh(body, _unit_sphere(), _mat(Color(0.72, 0.58, 0.32), 0.5), Vector3(0, 0.14, 0), Vector3(0.52, 0.4, 0.52))
	for which in ["pates", "sauce"]:
		var key: String = "spaghetti:nid_" + which
		if not _meshes132.has(key):
			var rng := RandomNumberGenerator.new()
			rng.seed = 1331 if which == "pates" else 1337
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var count: int = 44 if which == "pates" else 12
			for s in range(count):
				var a: float = rng.randf() * TAU
				var b: float = rng.randf_range(0.1, 1.45) if which == "pates" else rng.randf_range(0.05, 0.7)
				var da: float = rng.randf_range(-1.3, 1.3)
				var db: float = rng.randf_range(-0.7, 0.7)
				var path: Array = []
				var radii: Array = []
				for i in range(16):
					var u: float = float(i) / 15.0
					var aa: float = a + da * u * 2.0 + 0.3 * sin(u * 9.0 + s)
					var bb: float = clampf(b + db * u * 1.4 + 0.15 * sin(u * 7.0 + s * 2.0), 0.04, 1.5)
					var rr: float = 0.53 + 0.035 * sin(u * 13.0 + s) + (0.02 if which == "sauce" else 0.0)
					path.append(Vector3(sin(bb) * cos(aa) * rr * 1.08, 0.13 + cos(bb) * rr * 0.82, sin(bb) * sin(aa) * rr * 1.08))
					radii.append(0.021 if which == "pates" else 0.026)
				Armes132._add_tube(st, path, radii, 5, 1.0, Transform3D.IDENTITY, Callable(), true)
			_meshes132[key] = st.commit()
		_put(body, _meshes132[key], pates if which == "pates" else sauce)
	for i in range(4):
		var a2: float = TAU * i / 4.0 + 0.4
		_mesh(body, _unit_sphere(), sauce, Vector3(cos(a2) * 0.16, 0.58, sin(a2) * 0.16), Vector3(0.11, 0.035, 0.09))
	var basilic := _mat(Color(0.15, 0.42, 0.12), 0.4)
	_mesh(body, _unit_sphere(), basilic, Vector3(0.04, 0.62, -0.05), Vector3(0.08, 0.012, 0.045), Vector3(0, 0.6, 0.15))
	_mesh(body, _unit_sphere(), basilic, Vector3(-0.05, 0.615, 0.0), Vector3(0.07, 0.012, 0.04), Vector3(0, -0.5, -0.1))
	_eyes(body, Vector3(0, 0.5, 0.4), 0.14, 0.065, Color(0, 0, 0, 0), 0.7)
	# les brins-fouets : trois pâtes tressées par segment
	for si in range(3):
		var key2: String = "spaghetti:fouet%d" % si
		if not _meshes132.has(key2):
			var st2 := SurfaceTool.new()
			st2.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in range(3):
				var p2: Array = []
				var r2: Array = []
				for i in range(12):
					var u2: float = float(i) / 11.0
					var g: float = (si + u2) / 3.0
					var ph: float = TAU * j / 3.0 + g * 14.0
					var w: float = lerpf(0.03, 0.008, g)
					# chaque segment est un arc (la tresse ploie d'elle-même) et déborde un peu sur le
					# suivant : elle reste continue quand elle plie
					var th: float = 0.4 * u2
					var ax := Vector3(0, sin(th), 1.0 - cos(th)) * (0.52 / 0.4)
					p2.append(ax + Vector3(cos(ph) * w, 0, sin(ph) * w) + Vector3(0, u2 * 0.0, 0))
					r2.append(lerpf(0.022, 0.009, g))
				Armes132._add_tube(st2, p2, r2, 5, 1.0, Transform3D.IDENTITY, Callable(), true)
			_meshes132[key2] = st2.commit()
	for ang in [-0.55, 0.55, -1.9, 1.9, PI]:
		var yaw := Node3D.new()
		yaw.rotation.y = ang
		yaw.position = Vector3(sin(ang) * 0.34, 0.38, cos(ang) * 0.34)
		body.add_child(yaw)
		var chain: Array = []
		var par: Node3D = yaw
		var tip_end := Vector3(0, sin(0.4), 1.0 - cos(0.4)) * (0.52 / 0.4)
		for si2 in range(3):
			var jn := Node3D.new()
			jn.position = tip_end if si2 > 0 else Vector3.ZERO
			jn.rotation.x = 0.55 if si2 == 0 else 0.2
			par.add_child(jn)
			_put(jn, _meshes132["spaghetti:fouet%d" % si2], pates)
			chain.append(jn)
			par = jn
		_whips.append([chain, ang, absf(ang) < 1.0])


## La tomate kamikaze : une belle cœur-de-bœuf côtelée, rouge brillant, les épaules orangées,
## la collerette verte, un œil mauvais.
func _build_tomate() -> void:
	var r: float = 0.27
	var pos_fn := func(d: Vector3) -> Vector3:
		var az: float = atan2(d.z, d.x)
		var side: float = 1.0 - absf(d.y)
		var p: Vector3 = d * r * (1.0 + 0.07 * cos(az * 6.0) * smoothstep(0.0, 0.8, side))
		p.y *= 0.8
		p.y -= 0.045 * exp(-pow((1.0 - d.y) / 0.1, 2.0))
		return p
	var col_fn := func(d: Vector3, _p: Vector3) -> Color:
		var c := Color(0.8, 0.07, 0.03)
		c = c.lerp(Color(0.88, 0.4, 0.06), smoothstep(0.6, 0.95, d.y) * 0.45)
		return c.lerp(Color(0.55, 0.04, 0.02), smoothstep(-0.3, -0.9, d.y) * 0.5)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var ctr := Node3D.new()
	ctr.position = Vector3(0, r * 0.8, 0)
	body.add_child(ctr)
	_glow_mat = _vmat(Color(1, 1, 1), 0.16)
	_glow_mat.metallic_specular = 0.8
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.15, 0.05)
	_glow_mat.emission_energy_multiplier = 0.0
	_put(ctr, _blob_mesh("tomate", pos_fn, col_fn, 18, 36), _glow_mat)
	var vert := _mat(Color(0.2, 0.42, 0.12), 0.6)
	for k in range(6):
		var a: float = TAU * k / 6.0 + 0.2
		var yaw := Node3D.new()
		yaw.rotation.y = a
		yaw.position = Vector3(0, r * 0.8 - 0.035, 0)
		ctr.add_child(yaw)
		_mesh(yaw, _cyl(0.0, 0.026, 0.14), vert, Vector3(0, 0.0, 0.06), Vector3(1.0, 1.0, 0.3), Vector3(PI * 0.5 - 0.3, 0, 0))
	_mesh(ctr, _cyl(0.011, 0.016, 0.07), vert, Vector3(0, r * 0.8 - 0.005, 0))
	_eyes(ctr, Vector3(0, 0.05, r * 0.9), 0.095, 0.058, Color(0.12, 0.25, 0.08), 0.6)


# =================================================================== modèles : l'Île Crayonnée

## Le gribouillis : une pelote de traits de crayon qui ne tient jamais en place (les traits
## « bouillonnent », comme un dessin animé image par image), deux yeux de papier, des pattes
## en zigzag.
func _build_gribouillis() -> void:
	var graphite := _mat(Color(0.12, 0.12, 0.13), 0.3)
	graphite.metallic = 0.4
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	for v in range(3):
		var key: String = "gribouillis:%d" % v
		if not _meshes132.has(key):
			var rng := RandomNumberGenerator.new()
			rng.seed = 900 + v * 17
			var fr: Array = []
			for i in range(9):
				fr.append([rng.randf_range(2.0, 7.0), rng.randf_range(0.0, TAU), rng.randf_range(0.4, 1.0)])
			var path: Array = []
			var radii: Array = []
			for i in range(260):
				var u: float = float(i) / 259.0 * TAU * 3.0
				var p := Vector3.ZERO
				for ax in range(3):
					var s: float = 0.0
					for b in range(3):
						var f: Array = fr[ax * 3 + b]
						s += sin(u * float(f[0]) + float(f[1])) * float(f[2])
					p[ax] = s / 1.9
				path.append(Vector3(p.x * 0.3, 0.44 + p.y * 0.25, p.z * 0.3))
				radii.append(0.011)
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			Armes132._add_tube(st, path, radii, 4, 1.0, Transform3D.IDENTITY, Callable(), true)
			_meshes132[key] = st.commit()
		_boil.append(_meshes132[key])
	_boil_mi = _put(body, _boil[0], graphite)
	var papier := _mat(Color(0.97, 0.97, 0.95), 0.9)
	var noir := _mat(Color(0.02, 0.02, 0.02), 0.5)
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), papier, Vector3(sx * 0.1, 0.52, 0.27), Vector3(0.075, 0.09, 0.03))
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.09, 0.51, 0.295), Vector3(0.03, 0.036, 0.012))
		_eye_mats.append(noir)
	for i in range(4):
		var sx2: float = -1.0 if i % 2 == 0 else 1.0
		var sz: float = 1.0 if i < 2 else -1.0
		var leg := Node3D.new()
		leg.position = Vector3(sx2 * 0.11, 0.24, sz * 0.09)
		body.add_child(leg)
		var lp: Array = []
		var lr: Array = []
		for j in range(7):
			var u3: float = float(j) / 6.0
			lp.append(Vector3(sx2 * (0.04 + u3 * 0.08) + (0.03 if j % 2 == 0 else -0.03), -u3 * 0.24, sz * u3 * 0.07))
			lr.append(0.01)
		_put(leg, _tube_fn("gribouillis:patte%d" % i, lp, lr, 4, 1.0, Callable()), graphite)
		_legs.append([leg, sx2, i])


## La tache d'encre : une flaque d'encre de Chine qui se tient debout, luisante comme un miroir,
## des gouttes tout autour, deux yeux de papier.
func _build_encre() -> void:
	var nz := FastNoiseLite.new()
	nz.seed = 1334
	nz.frequency = 1.4
	var pos_fn := func(d: Vector3) -> Vector3:
		var p: Vector3 = d * 0.36 * (1.0 + 0.14 * nz.get_noise_3dv(d * 1.6) + 0.05 * nz.get_noise_3dv(d * 4.2 + Vector3(3, 3, 1)))
		p.y *= 0.6 if p.y > 0.0 else 0.12
		return p
	var col_fn := func(_d: Vector3, _p: Vector3) -> Color: return Color(1, 1, 1)
	var encre := _mat(Color(0.015, 0.015, 0.02), 0.2)
	encre.metallic_specular = 0.45
	encre.clearcoat_enabled = true
	encre.clearcoat = 0.6
	encre.clearcoat_roughness = 0.08
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var blob: MeshInstance3D = _put(body, _blob_mesh("encre", pos_fn, col_fn, 16, 32), encre)
	blob.position = Vector3(0, 0.05, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1335
	for i in range(8):
		var a: float = TAU * i / 8.0 + rng.randf_range(-0.3, 0.3)
		var dd: float = rng.randf_range(0.38, 0.5)
		var w: float = rng.randf_range(0.03, 0.065)
		_mesh(body, _unit_sphere(), encre, Vector3(cos(a) * dd, 0.02, sin(a) * dd), Vector3(w, w * 0.5, w))
	var papier := _mat(Color(0.97, 0.97, 0.95), 0.6)
	var noir := _mat(Color(0.0, 0.0, 0.0), 0.3)
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), papier, Vector3(sx * 0.11, 0.25, 0.21), Vector3(0.07, 0.085, 0.04))
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.1, 0.24, 0.245), Vector3(0.03, 0.036, 0.012))
		_eye_mats.append(noir)


## La gomme géante : un gros bloc de gomme blanche aux arêtes arrondies, son étui de carton
## gris rayé, le bout usé noirci de mine ; deux yeux noirs furieux.
func _build_gomme() -> void:
	var W: float = 0.95
	var Hh: float = 0.78
	var L: float = 1.6
	var rr: float = 0.13
	var inner := Vector3(W * 0.5 - rr, Hh * 0.5 - rr, L * 0.5 - rr)
	var pos_fn := func(d: Vector3) -> Vector3:
		var q: Vector3 = d * 10.0
		var c: Vector3 = q.clamp(-inner, inner)
		var n: Vector3 = (q - c).normalized()
		return c + n * rr
	var nz := FastNoiseLite.new()
	nz.seed = 1336
	nz.frequency = 2.0
	var col_fn := func(_d: Vector3, p: Vector3) -> Color:
		var c := Color(0.94, 0.93, 0.91)
		var worn: float = smoothstep(L * 0.5 - 0.32, L * 0.5, p.z) * (0.55 + 0.45 * nz.get_noise_3dv(p * 3.0))
		return c.lerp(Color(0.42, 0.42, 0.44), clampf(worn, 0.0, 1.0) * 0.75)
	var body := Node3D.new()
	body.name = "Corps"
	_visual.add_child(body)
	_pivots["corps"] = body
	var caout := _vmat(Color(1, 1, 1), 0.78)
	var bloc: MeshInstance3D = _put(body, _blob_mesh("gomme", pos_fn, col_fn, 22, 40), caout)
	bloc.position = Vector3(0, Hh * 0.5, 0)
	# l'étui de carton (sur l'arrière), sa bande blanche et ses lettres
	var carton := _mat(Color(0.36, 0.36, 0.37), 0.85)
	var blanc := _mat(Color(0.95, 0.95, 0.94), 0.8)
	var noir := _mat(Color(0.03, 0.03, 0.03), 0.6)
	var ls: float = 0.95
	var zc: float = -L * 0.5 + 0.06 + ls * 0.5
	var top := BoxMesh.new()
	top.size = Vector3(W + 0.03, 0.014, ls)
	_mesh(body, top, carton, Vector3(0, Hh + 0.007, zc))
	var sidem := BoxMesh.new()
	sidem.size = Vector3(0.014, Hh + 0.02, ls)
	var band := BoxMesh.new()
	band.size = Vector3(0.016, 0.12, ls)
	var lettre := BoxMesh.new()
	lettre.size = Vector3(0.018, 0.16, 0.035)
	for sx in [-1.0, 1.0]:
		_mesh(body, sidem, carton, Vector3(sx * (W * 0.5 + 0.007), Hh * 0.5, zc))
		_mesh(body, band, blanc, Vector3(sx * (W * 0.5 + 0.009), Hh * 0.72, zc))
		for k in range(5):
			_mesh(body, lettre, noir, Vector3(sx * (W * 0.5 + 0.011), Hh * 0.38, zc - 0.3 + k * 0.15))
	var top_band := BoxMesh.new()
	top_band.size = Vector3(W * 0.6, 0.016, 0.1)
	_mesh(body, top_band, blanc, Vector3(0, Hh + 0.009, zc))
	# les yeux sur le bout avant, sous la mine
	for sx in [-1.0, 1.0]:
		_mesh(body, _unit_sphere(), noir, Vector3(sx * 0.2, Hh * 0.62, L * 0.5 - 0.005), Vector3(0.07, 0.09, 0.025))
		_mesh(body, _unit_sphere(), blanc, Vector3(sx * 0.18, Hh * 0.62 + 0.03, L * 0.5 + 0.012), Vector3(0.018, 0.018, 0.008))
		var bm := BoxMesh.new()
		bm.size = Vector3(0.17, 0.03, 0.02)
		_mesh(body, bm, noir, Vector3(sx * 0.2, Hh * 0.62 + 0.12, L * 0.5 + 0.004), Vector3.ONE, Vector3(0, 0, sx * 0.4))
	_eye_mats.append(noir)


# =================================================================== sons, alertes, butin

func _sound(what: String) -> void:
	if not SPECS133.has(kind):
		super._sound(what)
		return
	if manager == null or manager.main == null or not manager.main.has_method("sfx"):
		return
	var pair: Array = SOUNDS133.get(kind, ["monstre_menace", "monstre_mort"])
	manager.main.sfx(str(pair[0] if what == "menace" else pair[1]), global_position + Vector3.UP * hit_height)


func alert_text() -> String:
	if SPECS133.has(kind):
		return str(ALERTES133.get(kind, ""))
	return super.alert_text()


func loot(rng: RandomNumberGenerator) -> Array:
	if not SPECS133.has(kind):
		return super.loot(rng)
	var g: Array = []
	if _explose:
		return g
	match kind:
		"aurochs":
			g.append(["piece", rng.randi_range(3, 7)])
			if rng.randf() < 0.15:
				g.append(["piece_or", 1])
		"loup_plaine":
			g.append(["piece", rng.randi_range(1, 3)])
		"ours_lande":
			g.append(["piece", rng.randi_range(4, 8)])
			if rng.randf() < 0.45:
				g.append(["miel", 1])
			if rng.randf() < 0.1:
				g.append(["piece_or", 1])
		"crapaud_vase":
			g.append(["piece", rng.randi_range(1, 3)])
			if rng.randf() < 0.25:
				g.append(["champignon", 1])
		"feu_follet":
			if rng.randf() < 0.5:
				g.append(["piece", rng.randi_range(1, 2)])
			if rng.randf() < 0.12:
				g.append(["eclat_cristal", 1])
		"scorpion_dunes":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.08:
				g.append(["rubis", 1])
		"serpent_sable":
			g.append(["piece", rng.randi_range(1, 4)])
			if rng.randf() < 0.08:
				g.append(["bague", 1])
		"boulette":
			g.append(["piece", rng.randi_range(2, 4)])
			if rng.randf() < 0.25:
				g.append(["sauce_volcan", 1])
		"boulette_mini":
			if rng.randf() < 0.4:
				g.append(["piece", 1])
		"spaghetti_sauvage":
			g.append(["piece", rng.randi_range(2, 5)])
			if rng.randf() < 0.2:
				g.append(["spaghettis_secs", 1])
		"tomate_kamikaze":
			if rng.randf() < 0.45:
				g.append(["tomate_coeur", 1])
		"gribouillis":
			if rng.randf() < 0.5:
				g.append(["piece", rng.randi_range(1, 2)])
		"tache_encre":
			g.append(["piece", rng.randi_range(1, 3)])
		"gomme_geante":
			g.append(["piece", rng.randi_range(4, 8)])
			if rng.randf() < 0.15:
				g.append(["piece_or", 1])
	return g


# =================================================================== coups reçus, mort

func take_hit(damage: int, from_pos: Vector3) -> void:
	if not SPECS133.has(kind):
		super.take_hit(damage, from_pos)
		return
	if state == "mort":
		return
	var st0: String = str(state)
	var t0: float = timer
	super.take_hit(damage, from_pos)
	if state == "mort":
		return
	match genre:
		"colosse":
			# trop lourd : un coup ne l'arrête pas
			_knock *= 0.15
			if st0 in ["armer", "frappe", "chasse", "souffle"]:
				state = st0
				timer = t0
		"sauteur":
			if st0 == "saut":
				state = st0
				timer = t0
		"rouleur":
			_roll_v = 0.0
			_knock *= 2.2


func _reveal() -> void:
	var was: bool = _hidden
	super._reveal()
	if was and kind == "serpent_sable":
		_puff(global_position + Vector3.UP * 0.15, 10, Color(0.85, 0.75, 0.55, 0.9), 0.25, 0.9, 0.9, 0.8, 2.5)


func _die() -> void:
	if not SPECS133.has(kind):
		super._die()
		return
	match kind:
		"boulette":
			# coupée en deux : deux petites boulettes, encore plus nerveuses
			var side := Vector3(-facing.z, 0, facing.x)
			for s in [-1.0, 1.0]:
				manager.call_deferred("spawn_extra", "boulette_mini", global_position + side * s * 0.6 + Vector3.UP * 0.1)
		"tomate_kamikaze":
			_splat_tomate()
		"tache_encre":
			if manager.has_method("decal"):
				manager.decal(global_position, "encre", 1.6, 7.0)
	super._die()


func _death_tick(delta: float) -> void:
	if not SPECS133.has(kind):
		super._death_tick(delta)
		return
	match kind:
		"tomate_kamikaze":
			visible = false
			timer += delta
			if timer > 0.3:
				set_physics_process(false)
				queue_free()
		"feu_follet":
			timer += delta
			_visual.scale = _base_scale * clampf(1.0 - timer / 0.9, 0.01, 1.0)
			global_position.y += delta * 0.8
			if _glow_light != null:
				_glow_light.light_energy = maxf(0.0, 1.4 * (1.0 - timer))
			if timer > 1.0:
				set_physics_process(false)
				queue_free()
		"tache_encre":
			timer += delta
			var k: float = clampf(timer / 1.2, 0.0, 1.0)
			_visual.scale = Vector3(_base_scale.x * (1.0 + k * 0.5), _base_scale.y * maxf(1.0 - k, 0.02), _base_scale.z * (1.0 + k * 0.5))
			if timer > 1.4:
				set_physics_process(false)
				queue_free()
		"gribouillis":
			# effacé : il clignote et s'efface
			timer += delta
			_visual.visible = fmod(timer * 14.0, 1.0) > 0.35
			_visual.scale = _base_scale * clampf(1.0 - timer / 1.0, 0.01, 1.0)
			if timer > 1.0:
				set_physics_process(false)
				queue_free()
		_:
			super._death_tick(delta)


func _splat_tomate() -> void:
	var at: Vector3 = global_position + Vector3.UP * 0.25
	_puff(at, 14, Color(0.78, 0.08, 0.04, 0.95), 0.1, 0.32, 0.6, 2.0, 5.0)
	_puff(at, 6, Color(0.95, 0.86, 0.5, 0.95), 0.04, 0.07, 0.5, 2.0, 4.0)
	if manager != null and manager.has_method("decal"):
		manager.decal(global_position, "sauce", 1.7, 8.0)


# =================================================================== comportement

func _physics_process(delta: float) -> void:
	if not (genre in GENRES133):
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
		return
	_hit_cd -= delta
	var p: Vector3 = _player()
	var to_p: Vector3 = p - global_position
	var dy: float = absf(to_p.y)
	to_p.y = 0.0
	var dist: float = to_p.length()
	var dir_p: Vector3 = to_p / dist if dist > 0.01 else facing
	if state == "saut":
		_jump_tick(delta, p)
		_animate132(delta, 0.0)
		return
	var move := Vector3.ZERO
	timer -= delta
	var sp: float = float(spec["vitesse"])
	var vue: float = float(spec["vue"])
	var from_home: float = Vector2(global_position.x - home.x, global_position.z - home.z).length()
	match state:
		"erre":
			move = _wander(delta, sp) * (1.6 if genre == "rouleur" else 1.0)
			if dist < vue and dy < 3.0:
				state = "chasse"
				_sound("menace")
				manager.alert(self)
		"chasse":
			if dist > vue * 1.8 or from_home > float(spec["laisse"]) or dy > 4.0:
				state = "retour"
			else:
				move = _chase(delta, dist, dir_p, dy, sp)
		"armer":
			if genre != "rouleur":
				facing = facing.lerp(dir_p, clampf(delta * (2.5 if genre == "colosse" else 6.0), 0.0, 1.0)).normalized()
			if bool(spec.get("territoire", false)) and dist > vue * 1.3:
				state = "erre"
			elif timer <= 0.0:
				_release(dist, dir_p, dy, p)
		"frappe":
			if not _blow and timer < 0.28:
				_blow = true
				if genre == "colosse":
					_slam(dist, dir_p, dy)
				elif genre == "fouet":
					_lash(dist, dir_p, dy)
			if timer <= 0.0:
				state = "souffle"
				timer = float(spec["repos"])
		"souffle":
			if timer <= 0.0:
				state = "erre" if (bool(spec.get("territoire", false)) and dist > vue) else "chasse"
		"recul":
			if timer <= 0.0:
				state = "chasse"
		"retour":
			var back: Vector3 = home - global_position
			back.y = 0.0
			if back.length() < 2.0:
				state = "erre"
			else:
				move = back.normalized() * sp * 0.7
				facing = facing.lerp(back.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
			if dist < vue * 0.6:
				state = "chasse"
	# on ne s'avance pas dans la mer
	if move.length() > 0.01:
		var ahead: Vector3 = global_position + move.normalized() * 1.2
		if _ground_at(ahead) < 0.15 and _ground_at(global_position) > _ground_at(ahead):
			move = -move * 0.3
			_wander_to = Vector3.INF
			_roll_v = 0.0
	if _knock.length() > 0.05:
		move += _knock
		_knock = _knock.move_toward(Vector3.ZERO, delta * 14.0)
	velocity.x = move.x
	velocity.z = move.z
	velocity.y = 0.0 if is_on_floor() else maxf(velocity.y - 18.0 * delta, -20.0)
	move_and_slide()
	rotation.y = atan2(facing.x, facing.z)
	_animate132(delta, Vector2(move.x, move.z).length())


func _chase(delta: float, dist: float, dir_p: Vector3, dy: float, sp: float) -> Vector3:
	var portee: float = float(spec["portee"])
	match genre:
		"rouleur":
			# elle roule droit devant et vire lentement : on l'esquive d'un pas de côté
			facing = facing.lerp(dir_p, clampf(delta * 1.6, 0.0, 1.0)).normalized()
			_roll_v = move_toward(_roll_v, sp, delta * 2.5)
			if dist < hit_radius + 0.55 and dy < 1.5 and _hit_cd <= 0.0:
				_hit_cd = 1.4
				manager.hurt_player(int(spec["degats"]), global_position)
				_shove_player(dir_p * 5.0)
				_knock = -dir_p * 5.5
				_roll_v = 0.0
				landed_hits += 1
				state = "recul"
				timer = 0.7
				_sound("menace")
			return facing * _roll_v
		"sauteur":
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if dist <= float(spec.get("saut", 6.0)) and dist > 1.2:
				state = "armer"
				timer = float(spec["armer"])
				_sound("menace")
				return Vector3.ZERO
			if dist <= 1.2:
				return -dir_p * sp * 0.8
			return dir_p * sp
		"kamikaze":
			facing = facing.lerp(dir_p, clampf(delta * 6.0, 0.0, 1.0)).normalized()
			if dist <= portee and dy < 2.0:
				state = "armer"
				timer = float(spec["armer"])
				_sound("menace")
				return Vector3.ZERO
			var hop: float = maxf(0.0, sin(_clock * 8.0))
			return dir_p * sp * (0.3 + 1.4 * hop)
		_:
			facing = facing.lerp(dir_p, clampf(delta * (2.5 if genre == "colosse" else 5.0), 0.0, 1.0)).normalized()
			if dist <= portee and facing.dot(dir_p) > 0.6:
				state = "armer"
				timer = float(spec["armer"])
				_sound("menace")
				return Vector3.ZERO
			if dist <= portee * 0.8:
				return Vector3.ZERO
			return dir_p * sp


func _release(dist: float, dir_p: Vector3, dy: float, p: Vector3) -> void:
	_blow = false
	match genre:
		"colosse":
			state = "frappe"
			timer = 0.45
		"fouet":
			state = "frappe"
			timer = 0.4
			_sound("menace")
		"sauteur":
			_start_jump(p, dist, dir_p)
		"kamikaze":
			if dist < 2.3 and dy < 2.0:
				manager.hurt_player(int(spec["degats"]), global_position)
				landed_hits += 1
			_explose = true
			hp = 0
			_die()
		_:
			state = "chasse"


## Le colosse s'abat devant lui : le sol tremble, la poussière (ou les miettes de gomme) vole.
func _slam(dist: float, dir_p: Vector3, dy: float) -> void:
	var reach: float = float(spec["portee"]) + 0.45
	if dist <= reach and facing.dot(dir_p) > 0.25 and dy < 2.2:
		manager.hurt_player(int(spec["degats"]), global_position)
		_shove_player(dir_p * 6.0)
		landed_hits += 1
	var at: Vector3 = global_position + facing * float(spec["portee"]) * 0.75
	at.y = _ground_at(at) + 0.1
	var fx: Node = _fx()
	if fx != null and dist < 10.0:
		fx.shake(0.06 * (1.0 - dist / 10.0) + 0.02)
	if kind == "gomme_geante":
		_puff(at, 12, Color(0.55, 0.55, 0.56, 0.9), 0.06, 0.16, 0.7, 1.5, 3.5)
		if manager.has_method("decal"):
			manager.decal(at, "gomme", 2.4, 8.0)
	else:
		_puff(at, 10, Color(0.6, 0.55, 0.48, 0.85), 0.35, 1.3, 0.9, 1.0, 2.6)
	if manager.main.has_method("sfx"):
		manager.main.sfx("touche_lourd", at)


## Le fouet du spaghetti : les brins s'abattent loin devant.
func _lash(dist: float, dir_p: Vector3, dy: float) -> void:
	if dist <= float(spec["portee"]) + 0.3 and facing.dot(dir_p) > 0.4 and dy < 2.0:
		manager.hurt_player(int(spec["degats"]), global_position)
		landed_hits += 1
	var at: Vector3 = global_position + facing * float(spec["portee"]) * 0.85
	at.y = _ground_at(at) + 0.1
	_puff(at, 6, Color(0.66, 0.2, 0.08, 0.8), 0.06, 0.2, 0.5, 1.0, 2.5)


func _start_jump(p: Vector3, dist: float, dir_p: Vector3) -> void:
	_jump_from = global_position
	var d: float = clampf(dist - 0.2, 1.5, float(spec.get("saut", 6.0)))
	_jump_to = global_position + dir_p * d
	_jump_to.y = _ground_at(_jump_to)
	_jump_dur = clampf(d / 7.5, 0.4, 0.85)
	_jump_h = 0.8 + d * 0.18
	_jump_t = 0.0
	facing = dir_p
	state = "saut"
	jumps += 1
	_sound("menace")
	if kind == "crapaud_vase":
		_puff(global_position + Vector3.UP * 0.1, 5, Color(0.4, 0.36, 0.25, 0.8), 0.15, 0.5, 0.7, 0.5, 1.5)


func _jump_tick(delta: float, p: Vector3) -> void:
	_jump_t += delta
	var u: float = clampf(_jump_t / _jump_dur, 0.0, 1.0)
	var q: Vector3 = _jump_from.lerp(_jump_to, u)
	q.y = lerpf(_jump_from.y, _jump_to.y, u) + 4.0 * _jump_h * u * (1.0 - u)
	var col: KinematicCollision3D = move_and_collide(q - global_position)
	rotation.y = atan2(facing.x, facing.z)
	if col != null and u > 0.2:
		u = 1.0
	if u >= 1.0:
		var g: float = _ground_at(global_position)
		if global_position.y < g:
			global_position.y = g
		_land(p)


func _land(p: Vector3) -> void:
	_land_t = 0.35
	velocity = Vector3.ZERO
	var to: Vector3 = p - global_position
	var dyy: float = absf(to.y)
	to.y = 0.0
	if to.length() < hit_radius + 0.9 and dyy < 1.8:
		manager.hurt_player(int(spec["degats"]), global_position)
		_shove_player(to.normalized() * 4.0 if to.length() > 0.05 else facing * 4.0)
		landed_hits += 1
	state = "souffle"
	timer = float(spec["repos"])
	if kind == "tache_encre":
		if manager.has_method("decal"):
			manager.decal(global_position, "encre", 1.3, 6.0)
		if manager.main.has_method("sfx"):
			manager.main.sfx("splotch", global_position)
	else:
		_puff(global_position + Vector3.UP * 0.1, 6, Color(0.36, 0.32, 0.22, 0.85), 0.15, 0.55, 0.7, 0.6, 1.8)


## Les gribouillis filent en tous sens, même en meute.
func _pack_move(dist: float, dir_p: Vector3, p: Vector3, sp: float) -> Vector3:
	var m: Vector3 = super._pack_move(dist, dir_p, p, sp)
	if kind == "gribouillis" and state == "chasse":
		var side := Vector3(-dir_p.z, 0, dir_p.x)
		m += side * sin(_clock * 7.0 + _flank * 5.0) * sp * 0.7 + dir_p * sin(_clock * 11.0 + _flank) * sp * 0.3
	return m


# =================================================================== en vol : le feu follet

func _fly_tick(delta: float, p: Vector3, dist: float, dir_p: Vector3) -> void:
	if kind != "feu_follet":
		super._fly_tick(delta, p, dist, dir_p)
		return
	timer -= delta
	var target: Vector3
	var speed: float = float(spec["vitesse"])
	match state:
		"vol":
			# il flâne au-dessus des mares, en huit paresseux
			_orbit_a += delta * 0.5
			var rr: float = 3.0 + _flank * 1.5
			target = _orbit_c + Vector3(cos(_orbit_a) * rr, 0, sin(_orbit_a * 2.0) * rr * 0.6)
			target.y = _ground_at(target) + _alt + sin(_clock * 1.7) * 0.3
			if dist < float(spec["vue"]):
				state = "chasse"
				timer = randf_range(1.5, 3.0)
				manager.alert(self)
				_sound("menace")
		"chasse":
			# il danse devant le héros, à quelques pas, comme pour l'attirer…
			var side := Vector3(-dir_p.z, 0, dir_p.x)
			target = p - dir_p * (3.6 + _flank * 0.5) + side * sin(_clock * 1.3 + _flank * 3.0) * 2.2
			target.y = p.y + 1.5 + sin(_clock * 2.3) * 0.35
			if timer <= 0.0 and manager.take_token(self):
				state = "pique"
				timer = 1.0
				_sound("menace")
			if dist > float(spec["vue"]) * 1.8:
				state = "vol"
				_orbit_c = Vector3(global_position.x, 0.0, global_position.z)
		"pique":
			target = p + Vector3.UP * 1.3
			speed *= 2.4
			if global_position.distance_to(target) < 0.8 and not has_meta("mordu"):
				set_meta("mordu", true)
				manager.hurt_player(int(spec["degats"]), global_position)
				landed_hits += 1
			if timer <= 0.0 or has_meta("mordu"):
				if has_meta("mordu"):
					remove_meta("mordu")
				manager.release_token(self)
				state = "recul"
				timer = 0.9
		_:
			# touché, ou après sa ruée : il file en arrière, puis revient danser
			var out: Vector3 = global_position - p
			out.y = 0.0
			out = out.normalized() if out.length() > 0.1 else Vector3.FORWARD
			target = global_position + out * 3.0 + Vector3.UP * 0.6
			if timer <= 0.0:
				state = "chasse"
				timer = randf_range(2.0, 3.5)
	var to: Vector3 = target - global_position
	var v: Vector3 = to.limit_length(speed)
	velocity = velocity.lerp(v, clampf(delta * 2.5, 0.0, 1.0))
	global_position += velocity * delta
	var g: float = _ground_at(global_position)
	if global_position.y < g + 0.4:
		global_position.y = g + 0.4
	var hv := Vector3(velocity.x, 0, velocity.z)
	if hv.length() > 0.3:
		facing = facing.lerp(hv.normalized(), clampf(delta * 5.0, 0.0, 1.0)).normalized()
	rotation.y = atan2(facing.x, facing.z)


# =================================================================== animation

func _animate132(delta: float, speed: float) -> void:
	if not SPECS133.has(kind):
		super._animate132(delta, speed)
		return
	var walk: float = clampf(speed / maxf(float(spec["vitesse"]), 0.1), 0.0, 2.2)
	match kind:
		"aurochs", "loup_plaine":
			super._animate132(delta, speed)
		"ours_lande":
			super._animate132(delta, speed)
			_update_rear(delta)
			var th: float = _rear * 0.95
			_pose_corps(th, Vector3(0, 0.82, -1.42 * 0.36))
			for l in _legs:
				var leg: Node3D = l[0]
				if int(l[2]) >= 2:
					leg.rotation.x += th
				else:
					leg.rotation.x = leg.rotation.x * (1.0 - _rear) + th - 0.9 * _rear + sin(_clock * 7.0) * 0.25 * _rear
			var head: Node3D = _pivots.get("tete")
			if head != null:
				head.rotation.x += th * 0.55
		"gomme_geante":
			_update_rear(delta)
			_pose_corps(_rear * 0.7, Vector3(0, 0, -0.8))
			_visual.position.y = absf(sin(_clock * 5.0)) * 0.1 * minf(walk, 1.0)
			_visual.scale = _base_scale * Vector3(1.0, 1.0, 1.0 + sin(_clock * 10.0) * 0.04 * minf(walk, 1.0))
		"crapaud_vase":
			_anim_crapaud(delta, walk)
		"tache_encre":
			_anim_encre(delta, walk)
		"feu_follet":
			_anim_follet(delta)
		"scorpion_dunes":
			_anim_scorpion(delta, walk)
		"serpent_sable":
			_anim_serpent(delta, walk)
		"boulette", "boulette_mini":
			var boule: Node3D = _pivots.get("boule")
			if boule != null:
				boule.rotation.x += speed * delta / maxf(0.4 * _base_scale.y, 0.05)
			var face: Node3D = _pivots.get("visage")
			if face != null:
				face.position.y = absf(sin(boule.rotation.x * 2.0)) * 0.02
			_steam_t -= delta
			if kind == "boulette" and _steam_t <= 0.0 and DisplayServer.get_name() != "headless":
				_steam_t = randf_range(0.6, 1.3)
				_puff(global_position + Vector3.UP * 0.85, 1, Color(0.97, 0.97, 0.97, 0.3), 0.12, 0.5, 1.4, 0.15, 0.35)
		"spaghetti_sauvage":
			_anim_spaghetti(delta)
		"tomate_kamikaze":
			_anim_tomate(delta, walk)
		"gribouillis":
			_anim_gribouillis(delta, walk)


func _update_rear(delta: float) -> void:
	var tgt: float = 0.0
	if state == "armer":
		tgt = smoothstep(0.0, 0.8, 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0))
	var rate: float = 30.0 if state == "frappe" else 6.0
	_rear = lerpf(_rear, tgt, clampf(delta * rate, 0.0, 1.0))


## Le corps bascule autour d'un pivot (les hanches de l'ours, l'arête arrière de la gomme).
func _pose_corps(theta: float, pivot: Vector3) -> void:
	var b: Node3D = _pivots.get("corps")
	if b == null:
		return
	var bas := Basis(Vector3.RIGHT, -theta)
	b.transform = Transform3D(bas, pivot - bas * pivot)


func _anim_crapaud(delta: float, walk: float) -> void:
	var body: Node3D = _pivots["corps"]
	var crouch: float = 0.0
	if state == "armer":
		crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	var air: float = 1.0 if state == "saut" else 0.0
	_land_t = maxf(_land_t - delta, 0.0)
	var squash: float = _land_t / 0.35
	var k: float = clampf(delta * 14.0, 0.0, 1.0)
	body.scale = body.scale.lerp(Vector3(1.0 + 0.08 * crouch + 0.1 * squash, 1.0 - 0.16 * crouch - 0.12 * squash + 0.05 * air, 1.0 - 0.05 * crouch + 0.12 * air), k)
	body.rotation.x = lerpf(body.rotation.x, -0.35 * air + 0.1 * crouch, k)
	_visual.position.y = absf(sin(_clock * 6.0)) * 0.1 * minf(walk, 1.0) if air == 0.0 else 0.0
	for l in _legs:
		var leg: Node3D = l[0]
		var hind: bool = int(l[2]) >= 2
		var w: float = sin(_clock * 6.0 + (0.0 if hind else PI)) * 0.3 * minf(walk, 1.0)
		var t_rot: float = (1.3 * air - 0.2 * crouch + w) if hind else (-0.6 * air + w)
		leg.rotation.x = lerpf(leg.rotation.x, t_rot, k)
	if _throat != null:
		var croak: float = (0.5 + 0.5 * sin(_clock * 10.0)) if (state == "armer" or fmod(_clock + _flank * 3.0, 6.0) < 0.9) else 0.0
		_throat.scale = _throat.scale.lerp(Vector3(0.08, 0.055, 0.075) * (1.0 + croak * 1.1), k)


func _anim_encre(delta: float, walk: float) -> void:
	var body: Node3D = _pivots["corps"]
	var crouch: float = 0.0
	if state == "armer":
		crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	var air: float = 1.0 if state == "saut" else 0.0
	_land_t = maxf(_land_t - delta, 0.0)
	var squash: float = _land_t / 0.35
	var wob: float = sin(_clock * 3.0 + _flank) * 0.05 + sin(_clock * 9.0) * 0.06 * minf(walk, 1.0)
	var sx: float = 1.0 + 0.22 * crouch - 0.22 * air + 0.4 * squash + wob
	var sy: float = 1.0 - 0.42 * crouch + 0.6 * air - 0.5 * squash - wob
	body.scale = body.scale.lerp(Vector3(sx, maxf(sy, 0.3), sx), clampf(delta * 14.0, 0.0, 1.0))


func _anim_follet(_delta: float) -> void:
	var body: Node3D = _pivots.get("corps")
	if body == null:
		return
	var flick: float = 1.0 + sin(_clock * 13.0) * 0.06 + sin(_clock * 23.0 + 1.0) * 0.04
	var hot: float = 1.0 if state == "pique" else 0.0
	body.scale = Vector3(flick, flick * (1.0 + 0.1 * sin(_clock * 7.0)), flick) * (1.0 + 0.3 * hot)
	body.position.y = sin(_clock * 2.1) * 0.08
	if _glow_light != null:
		_glow_light.light_energy = 1.4 * flick + hot * 1.6


func _anim_scorpion(delta: float, walk: float) -> void:
	for l in _legs:
		var leg: Node3D = l[0]
		var i: int = int(l[2])
		var ph: float = _clock * 13.0 + i * 1.7
		leg.rotation.y = sin(ph) * 0.32 * minf(walk, 1.2)
		leg.rotation.z = maxf(0.0, sin(ph + 1.57)) * 0.22 * minf(walk, 1.2) * float(l[1])
	var cock: float = 0.0
	if state == "armer":
		cock = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	var strike: float = 1.0 if state == "frappe" else 0.0
	_swell = lerpf(_swell, strike, clampf(delta * (22.0 if strike > _swell else 4.0), 0.0, 1.0))
	var add_cock: Array = [-0.25, 0.08, 0.1, 0.1, 0.08, 0.15]
	var add_strike: Array = [0.6, 0.14, 0.1, 0.05, 0.0, -0.3]
	for i in range(_tail133.size()):
		var seg: Node3D = _tail133[i][0]
		seg.rotation.x = float(_tail133[i][1]) + float(add_cock[i]) * cock + float(add_strike[i]) * _swell + sin(_clock * 2.0 + i) * 0.03
	var open: float = 0.15 + 0.35 * maxf(cock, (0.5 + 0.5 * sin(_clock * 3.0)) if state == "chasse" else 0.0)
	for f in _pinces:
		(f[0] as Node3D).rotation.y = -float(f[1]) * open


func _anim_serpent(delta: float, walk: float) -> void:
	var slither: float = clampf(walk, 0.0, 1.0)
	var coil: float = 0.0
	if state == "armer":
		coil = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	elif state == "frappe":
		coil = 0.6
	var lunge: float = 0.28 if state == "frappe" else 0.0
	for k in range(_segs133.size()):
		var seg: Node3D = _segs133[k]
		var wave: float = sin(_clock * 9.0 - k * 0.42) * (0.04 + k * 0.006) * maxf(slither, 0.3)
		var z0: float = 0.6 - k * 0.07
		var tx: float = lerpf(wave, sin(k * 0.5) * 0.2 * (1.0 - float(k) / 28.0), coil)
		var tz: float = lerpf(z0, z0 * 0.55 - 0.1, coil) + lunge * maxf(0.0, 1.0 - k / 8.0)
		var ty: float = 0.09 + maxf(0.0, 5.0 - k) * 0.06 * coil
		seg.position = seg.position.lerp(Vector3(tx, ty, tz), clampf(delta * 18.0, 0.0, 1.0))
	var tg: Node3D = _pivots.get("langue")
	if tg != null:
		tg.scale = Vector3.ONE * (1.0 if fmod(_clock * 1.7 + _flank, 1.0) < 0.25 else 0.01)


func _anim_spaghetti(delta: float) -> void:
	var cock: float = 0.0
	if state == "armer":
		cock = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	var lash: bool = state == "frappe"
	var busy: bool = state in ["chasse", "armer", "frappe", "souffle"]
	for i in range(_whips.size()):
		var w: Array = _whips[i]
		var chain: Array = w[0]
		var front: bool = w[2]
		var rate: float = 4.0
		for j in range(chain.size()):
			var jn: Node3D = chain[j]
			# au repos, les brins retombent en ondulant (l'onde court vers la pointe)
			var tgt: float = (0.55 if j == 0 else 0.2) + sin(_clock * (1.6 if not busy else 4.5) - j * 0.9 + i * 1.3) * (0.18 + 0.12 * j)
			rate = 4.0
			if front and lash:
				tgt = [1.35, 0.05, 0.0][j]
				rate = 26.0 - j * 6.0
			elif front and cock > 0.0:
				tgt = lerpf(tgt, [-0.8, -0.6, -0.5][j], cock)
				rate = 8.0
			jn.rotation.x = lerpf(jn.rotation.x, tgt, clampf(delta * rate, 0.0, 1.0))
	var body: Node3D = _pivots.get("corps")
	if body != null:
		var s: float = sin(_clock * 3.0) * 0.03
		body.scale = Vector3(1.0 + s, 1.0 - s, 1.0 + s)


func _anim_tomate(delta: float, walk: float) -> void:
	var body: Node3D = _pivots["corps"]
	if state == "armer":
		var k: float = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
		body.scale = Vector3.ONE * (1.0 + 0.45 * k) + Vector3(sin(_clock * 40.0) * 0.05 * k, 0, cos(_clock * 37.0) * 0.05 * k)
		body.position.y = lerpf(body.position.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		if _glow_mat != null and _flash <= 0.0:
			_glow_mat.emission_energy_multiplier = k * 1.6 * (0.55 + 0.45 * sin(_clock * 22.0))
		return
	if _glow_mat != null and _flash <= 0.0:
		_glow_mat.emission_energy_multiplier = 0.0
	var hop: float = absf(sin(_clock * 8.0))
	var amt: float = minf(walk + 0.15, 1.0) if state in ["chasse", "erre", "retour"] else 0.1
	body.position.y = hop * 0.28 * amt
	var s: float = 1.0 - (1.0 - hop) * 0.14 * amt
	body.scale = Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))


func _anim_gribouillis(delta: float, walk: float) -> void:
	_boil_t -= delta
	if _boil_t <= 0.0 and _boil_mi != null and not _boil.is_empty():
		_boil_t = 0.11
		_boil_i = (_boil_i + 1) % _boil.size()
		_boil_mi.mesh = _boil[_boil_i]
		var body: Node3D = _pivots.get("corps")
		if body != null:
			body.position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.012
	for l in _legs:
		var leg: Node3D = l[0]
		leg.rotation.x = sin(_clock * 16.0 + int(l[2]) * PI * 0.5) * 0.5 * minf(walk, 1.2)
	var crouch: float = 0.0
	if state == "armer":
		crouch = 1.0 - clampf(timer / float(spec["armer"]), 0.0, 1.0)
	_visual.scale = _base_scale * Vector3(1.0 + 0.1 * crouch, 1.0 - 0.18 * crouch, 1.0 + 0.1 * crouch)
